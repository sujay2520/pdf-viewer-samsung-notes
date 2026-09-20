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
        title: 'Samsung Notes & Google Drive PDF',
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

  runApp(const DrivePdfSamsungNotesApp());
}

Future<void> _registerGlobalWinZShortcut() async {
  try {
    await hotKeyManager.unregisterAll();
    final winZHotKey = HotKey(
      key: PhysicalKeyboardKey.keyZ,
      modifiers: [HotKeyModifier.meta], // Meta key represents the Windows key on Windows
      scope: HotKeyScope.system, // System-wide global shortcut
    );

    await hotKeyManager.register(
      winZHotKey,
      keyDownHandler: (hotKey) async {
        debugPrint('Win + Z triggered! Bringing app to front.');
        await windowManager.show();
        await windowManager.focus();
      },
    );
  } catch (e) {
    debugPrint('Could not register global Win+Z shortcut: $e');
  }
}

class DrivePdfSamsungNotesApp extends StatefulWidget {
  const DrivePdfSamsungNotesApp({super.key});

  @override
  State<DrivePdfSamsungNotesApp> createState() => _DrivePdfSamsungNotesAppState();
}

class _DrivePdfSamsungNotesAppState extends State<DrivePdfSamsungNotesApp> {
  final ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    // Google Drive Material 3 Light Theme
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

    // Google Drive Material 3 Dark Theme
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
      title: 'Samsung Notes & Drive PDF',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: const HomeScreen(),
    );
  }
}
