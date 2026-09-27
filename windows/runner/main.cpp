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

  // Single Instance Protection:
  // If an instance is already running (e.g. hidden in background),
  // summon it to the foreground immediately instead of opening a duplicate.
  HANDLE hMutex = ::CreateMutex(nullptr, TRUE, L"DriveNotesAndPdfSingleInstanceMutex");
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND existingHwnd = ::FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", nullptr);
    if (existingHwnd && ::IsWindow(existingHwnd)) {
      ::PostMessage(existingHwnd, WM_USER_SUMMON_APP, 0, 0);
    }
    if (hMutex) ::CloseHandle(hMutex);
    return EXIT_SUCCESS;
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  bool start_hidden = false;
  if (command_line && (wcsstr(command_line, L"--background") != nullptr ||
                       wcsstr(command_line, L"--hidden") != nullptr ||
                       wcsstr(command_line, L"--minimized") != nullptr)) {
    start_hidden = true;
  }

  FlutterWindow window(project, start_hidden);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"pdf_viewer_pro", origin, size)) {
    if (hMutex) ::CloseHandle(hMutex);
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (hMutex) ::CloseHandle(hMutex);
  return EXIT_SUCCESS;
}
