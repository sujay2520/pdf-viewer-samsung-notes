import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop Window & Global Hotkey initialization
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(450, 600),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        title: 'Drive Notes & PDF',
      );

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      // Register Win + Z global hotkey on Windows
      if (Platform.isWindows) {
        await _registerGlobalWinZShortcut();
      }
    } catch (e) {
      debugPrint('Window or hotkey init warning: $e');
    }
  }

  runApp(const DriveNotesPdfApp());
}

Future<void> _registerGlobalWinZShortcut() async {
  try {
    await hotKeyManager.unregisterAll();

    // 1. Register Win + Z via hotkey_manager
    try {
      final winZHotKey = HotKey(
        key: PhysicalKeyboardKey.keyZ,
        modifiers: [HotKeyModifier.meta],
        scope: HotKeyScope.system,
      );
      await hotKeyManager.register(
        winZHotKey,
        keyDownHandler: (hotKey) async {
          await windowManager.show();
          await windowManager.focus();
        },
      );
    } catch (_) {}

    // 2. Register Ctrl + Alt + Z as an alternate global shortcut
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

  @override
  State<DriveNotesPdfApp> createState() => _DriveNotesPdfAppState();
}

class _DriveNotesPdfAppState extends State<DriveNotesPdfApp> {
  final ThemeMode _themeMode = ThemeMode.system;

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
