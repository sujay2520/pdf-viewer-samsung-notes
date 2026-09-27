#include "flutter_window.h"

#include <optional>
#include <windows.h>
#include <shellapi.h>

#include "flutter/generated_plugin_registrant.h"

#define WM_USER_SUMMON_APP (WM_USER + 777)

static HHOOK g_keyboard_hook = NULL;
static HWND g_flutter_hwnd = NULL;

static void ForceForegroundWindow(HWND hwnd) {
  if (!hwnd || !::IsWindow(hwnd)) return;

  // Restore if minimized or hidden
  if (::IsIconic(hwnd)) {
    ::ShowWindow(hwnd, SW_RESTORE);
  } else {
    ::ShowWindow(hwnd, SW_SHOW);
  }
  ::SetWindowPos(hwnd, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_SHOWWINDOW);

  // Bypass Windows LockSetForegroundWindow restriction using Alt-key event
  ::keybd_event(VK_MENU, 0, 0, 0);
  ::keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, 0);

  HWND foregroundWnd = ::GetForegroundWindow();
  DWORD foregroundThreadId = ::GetWindowThreadProcessId(foregroundWnd, NULL);
  DWORD currentThreadId = ::GetCurrentThreadId();

  if (foregroundThreadId != currentThreadId) {
    ::AttachThreadInput(currentThreadId, foregroundThreadId, TRUE);
    ::BringWindowToTop(hwnd);
    ::SetForegroundWindow(hwnd);
    ::SetFocus(hwnd);
    ::AttachThreadInput(currentThreadId, foregroundThreadId, FALSE);
  } else {
    ::BringWindowToTop(hwnd);
    ::SetForegroundWindow(hwnd);
    ::SetFocus(hwnd);
  }
}

static LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
  if (nCode == HC_ACTION) {
    if (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN) {
      KBDLLHOOKSTRUCT* pKey = reinterpret_cast<KBDLLHOOKSTRUCT*>(lParam);
      // 'Z' key has virtual key code 0x5A
      if (pKey->vkCode == 0x5A || pKey->vkCode == 'Z') {
        bool winPressed = ((::GetAsyncKeyState(VK_LWIN) & 0x8000) != 0) ||
                          ((::GetAsyncKeyState(VK_RWIN) & 0x8000) != 0) ||
                          (::GetKeyState(VK_LWIN) < 0) ||
                          (::GetKeyState(VK_RWIN) < 0);
        bool altPressed = ((::GetAsyncKeyState(VK_MENU) & 0x8000) != 0) ||
                          (::GetKeyState(VK_MENU) < 0);
        bool ctrlPressed = ((::GetAsyncKeyState(VK_CONTROL) & 0x8000) != 0) ||
                           (::GetKeyState(VK_CONTROL) < 0);

        if (winPressed && altPressed) {
          // Win + Alt + Z → Summon the main app window
          HWND target = g_flutter_hwnd;
          if (target && ::IsWindow(target)) {
            ::PostMessage(target, WM_USER_SUMMON_APP, 0, 0);
          }
          return 1;
        } else if (winPressed && !altPressed && !ctrlPressed) {
          // Win + Z → Launch a new quick sticky note (separate process)
          wchar_t exePath[MAX_PATH];
          ::GetModuleFileName(NULL, exePath, MAX_PATH);
          ::ShellExecute(NULL, L"open", exePath, L"--quicknote", NULL, SW_SHOWNORMAL);
          return 1;
        } else if (ctrlPressed && altPressed) {
          // Ctrl + Alt + Z → Summon the main app (fallback)
          HWND target = g_flutter_hwnd;
          if (target && ::IsWindow(target)) {
            ::PostMessage(target, WM_USER_SUMMON_APP, 0, 0);
          }
          return 1;
        }
      }
    }
  }
  return ::CallNextHookEx(g_keyboard_hook, nCode, wParam, lParam);
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project,
                             bool is_quicknote, bool start_hidden)
    : project_(project), is_quicknote_(is_quicknote), start_hidden_(start_hidden) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  // Only install global keyboard hook for the main app, not quicknotes
  if (!is_quicknote_) {
    g_flutter_hwnd = GetHandle();
    if (!g_keyboard_hook) {
      g_keyboard_hook = ::SetWindowsHookEx(
          WH_KEYBOARD_LL,
          LowLevelKeyboardProc,
          ::GetModuleHandle(nullptr),
          0);
    }
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  if (!start_hidden_) {
    flutter_controller_->engine()->SetNextFrameCallback([&]() {
      this->Show();
    });
  }

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  // Only unhook keyboard for the main app process
  if (!is_quicknote_) {
    if (g_keyboard_hook) {
      ::UnhookWindowsHookEx(g_keyboard_hook);
      g_keyboard_hook = NULL;
    }
    g_flutter_hwnd = NULL;
  }

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Only the main app handles summon messages
  if (!is_quicknote_ && message == WM_USER_SUMMON_APP) {
    ForceForegroundWindow(hwnd);
    return 0;
  }

  // WM_CLOSE behavior differs:
  if (message == WM_CLOSE) {
    if (is_quicknote_) {
      // Quicknotes: Let Flutter's onWindowClose handler save, then destroy
      // The Dart side calls exit(0) after saving
      ::DestroyWindow(hwnd);
    } else {
      // Main app: Hide to background (Sticky Notes style)
      ::ShowWindow(hwnd, SW_HIDE);
    }
    return 0;
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
