#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

#define WM_USER_SUMMON_APP (WM_USER + 777)

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Detect launch mode from command-line flags
  bool is_quicknote = command_line && wcsstr(command_line, L"--quicknote") != nullptr;
  bool is_background = command_line && (wcsstr(command_line, L"--background") != nullptr ||
                                        wcsstr(command_line, L"--hidden") != nullptr);

  // For the main app only: single-instance check.
  // Quicknotes always create new windows (each Win+Z = new note).
  if (!is_quicknote) {
    HWND existingHwnd = ::FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Drive Notes & PDF");
    if (existingHwnd && ::IsWindow(existingHwnd)) {
      if (!is_background) {
        ::PostMessage(existingHwnd, WM_USER_SUMMON_APP, 0, 0);
      }
      return EXIT_SUCCESS;
    }
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project, is_quicknote, is_background);

  if (is_quicknote) {
    // Quicknote: small sticky note window, positioned near center of screen
    int screenW = ::GetSystemMetrics(SM_CXSCREEN);
    int screenH = ::GetSystemMetrics(SM_CYSCREEN);
    int noteW = 380;
    int noteH = 440;
    // Offset each new quicknote slightly using current tick to avoid overlap
    int offset = (int)(::GetTickCount64() % 200);
    int x = (screenW - noteW) / 2 + offset;
    int y = (screenH - noteH) / 2 + offset;

    Win32Window::Point origin(x, y);
    Win32Window::Size size(noteW, noteH);
    if (!window.Create(L"Quick Note", origin, size)) {
      return EXIT_FAILURE;
    }
  } else {
    // Full main app
    Win32Window::Point origin(10, 10);
    Win32Window::Size size(1280, 720);
    if (!window.Create(L"Drive Notes & PDF", origin, size)) {
      return EXIT_FAILURE;
    }
  }

  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
