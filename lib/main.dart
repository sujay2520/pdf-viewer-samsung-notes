import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'screens/home_screen.dart';
import 'screens/quick_note_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final isQuickNote = args.contains('--quicknote');
  final isBackground = args.contains('--background') || args.contains('--hidden');

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      await windowManager.ensureInitialized();

      if (isQuickNote) {
        // ── Quick Note Mode: Small dark sticky note ──
        const quickNoteOptions = WindowOptions(
          size: Size(380, 440),
          minimumSize: Size(280, 300),
          center: false,
          backgroundColor: Color(0xFF1E1F22),
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.hidden,
          title: 'Quick Note',
        );

        await windowManager.setPreventClose(true);

        windowManager.waitUntilReadyToShow(quickNoteOptions, () async {
          await windowManager.show();
          await windowManager.focus();
        });

        runApp(const QuickNoteApp());
        return;
      }

      // ── Full App Mode ──
      const windowOptions = WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(450, 600),
        center: true,
        backgroundColor: Colors.white,
        skipTaskbar: false,
        title: 'Drive Notes & PDF',
      );

      // Prevent closing so clicking 'X' hides to background
      await windowManager.setPreventClose(true);

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        if (!isBackground) {
          await windowManager.show();
          await windowManager.focus();
        }
      });

      // Register shortcuts (Dart-level fallback, C++ hook is primary)
      if (Platform.isWindows) {
        await _registerGlobalShortcuts();
      }
    } catch (e) {
      debugPrint('Window or hotkey init warning: $e');
    }
  }

  runApp(const DriveNotesPdfApp());
}

Future<void> _registerGlobalShortcuts() async {
  try {
    await hotKeyManager.unregisterAll();

    // Ctrl + Alt + Z as fallback to summon main app
    try {
      final ctrlAltZHotKey = HotKey(
        key: PhysicalKeyboardKey.keyZ,
        modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
        scope: HotKeyScope.system,
      );
      await hotKeyManager.register(
        ctrlAltZHotKey,
        keyDownHandler: (hotKey) async {
          await windowManager.show();
          await windowManager.focus();
        },
      );
    } catch (_) {}
  } catch (e) {
    debugPrint('Could not register hotkeys: $e');
  }
}

class DriveNotesPdfApp extends StatefulWidget {
  const DriveNotesPdfApp({super.key});

  static void exitApp() {
    exit(0);
  }

  @override
  State<DriveNotesPdfApp> createState() => _DriveNotesPdfAppState();
}

class _DriveNotesPdfAppState extends State<DriveNotesPdfApp> with WindowListener {
  final ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // When user clicks 'X', hide the window to background (Sticky Notes style)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Modern Google Drive Material 3 Light Theme
    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A73E8), // Google Drive Blue
        brightness: Brightness.light,
        surface: const Color(0xFFFFFFFF),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F9FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );

    // Modern Google Drive Material 3 Dark Theme
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8AB4F8), // Google Drive Dark Blue
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1F22),
      ),
      scaffoldBackgroundColor: const Color(0xFF141517),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1F22),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );

    return MaterialApp(
      title: 'Drive Notes & PDF',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: const HomeScreen(),
    );
  }
}
