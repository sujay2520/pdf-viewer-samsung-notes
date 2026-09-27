import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../models/note_model.dart';
import '../services/notes_storage_service.dart';
import '../widgets/note_page_background.dart';

/// A compact dark sticky note app launched by Win+Z.
/// Freely draggable, auto-saves on typing and closing, and spawns new notes on Win+Z.
class QuickNoteApp extends StatelessWidget {
  const QuickNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Note',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
          surface: const Color(0xFF2D2D30),
        ),
        scaffoldBackgroundColor: const Color(0xFF202124),
      ),
      home: const QuickNoteScreen(),
    );
  }
}

class QuickNoteScreen extends StatefulWidget {
  const QuickNoteScreen({super.key});

  @override
  State<QuickNoteScreen> createState() => _QuickNoteScreenState();
}

class _QuickNoteScreenState extends State<QuickNoteScreen> with WindowListener {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late NoteDocument _note;
  NotePageTemplate _template = NotePageTemplate.ruled;
  Timer? _saveTimer;
  bool _initialized = false;
  bool _isSavedBefore = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    // Register window listener so we can intercept close and save reliably
    windowManager.addListener(this);
    windowManager.setPreventClose(true);

    // Create a new dark lined note
    _note = NoteDocument(
      title: 'Quick Note',
      pages: [
        NotePage(
          pageNumber: 1,
          template: _template,
          isDark: true,
        ),
      ],
    );

    // Auto-focus after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _initStorage();
    });
  }

  Future<void> _initStorage() async {
    await NotesStorageService.instance.loadAllNotes();
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _saveTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // Intercept native close event (Alt+F4, taskbar close, or window X)
    _saveTimer?.cancel();
    await _saveNow();
    await windowManager.destroy();
  }

  void _onTextChanged(String text) {
    _note.firstPage.textContent = text;

    // Auto-title from first non-empty line
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);
    if (lines.isNotEmpty) {
      final firstLine = lines.first;
      _note.title = firstLine.length > 50 ? '${firstLine.substring(0, 47)}...' : firstLine;
    } else {
      _note.title = 'Quick Note';
    }

    // Debounced auto-save (300ms)
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), _saveNow);
  }

  Future<void> _saveNow() async {
    final text = _controller.text.trim();
    if (text.isEmpty && !_isSavedBefore) return;

    try {
      _note.firstPage.textContent = _controller.text;
      _note.firstPage.template = _template;
      _note.firstPage.isDark = true;
      await NotesStorageService.instance.saveNote(_note);
      _isSavedBefore = true;
    } catch (e) {
      debugPrint('Quick note save error: $e');
    }
  }

  Future<void> _saveAndClose() async {
    _saveTimer?.cancel();
    await _saveNow();
    await windowManager.destroy();
  }

  void _openAnotherQuickNote() {
    try {
      Process.run(Platform.resolvedExecutable, ['--quicknote']);
    } catch (e) {
      debugPrint('Error opening another quick note: $e');
    }
  }

  void _toggleTemplate() {
    setState(() {
      if (_template == NotePageTemplate.ruled) {
        _template = NotePageTemplate.blank;
      } else if (_template == NotePageTemplate.blank) {
        _template = NotePageTemplate.grid;
      } else {
        _template = NotePageTemplate.ruled;
      }
      _note.firstPage.template = _template;
    });
    _saveNow();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F22),
      body: Column(
        children: [
          // ── Draggable Title Bar ──
          _buildDraggableTitleBar(),

          // ── Text Editor with Lined Paper Canvas ──
          Expanded(
            child: Stack(
              children: [
                // 1. Template Paper Canvas (Ruled, Blank, or Grid)
                Positioned.fill(
                  child: NotePageBackground(
                    template: _template,
                    isDark: true,
                  ),
                ),

                // 2. Direct Typing Text Field
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      _template == NotePageTemplate.ruled ? 68 : 20,
                      18,
                      20,
                      16,
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      cursorColor: Colors.amber,
                      cursorWidth: 2,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 2.0, // Aligns with 32px ruled line spacing
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                      decoration: InputDecoration(
                        hintText: _initialized ? 'Start typing...' : 'Loading...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 16,
                          height: 2.0,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: _onTextChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Status Bar ──
          Container(
            height: 26,
            color: const Color(0xFF18191B),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 12, color: Colors.green.shade400),
                const SizedBox(width: 5),
                Text(
                  _isSavedBefore ? 'Saved' : 'Auto-saves on type & close',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                Text(
                  'Win+Z = New  •  Win+Alt+Z = App',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableTitleBar() {
    return Container(
      height: 38,
      color: const Color(0xFF2C2D30),
      child: Row(
        children: [
          // 1. New note button (+)
          IconButton(
            icon: const Icon(Icons.add, size: 18, color: Colors.white70),
            tooltip: 'New Sticky Note (Win+Z)',
            splashRadius: 16,
            onPressed: _openAnotherQuickNote,
          ),

          // 2. Freely Draggable Title Bar Area
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) {
                windowManager.startDragging();
              },
              onDoubleTap: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
              child: DragToMoveArea(
                child: Container(
                  height: double.infinity,
                  color: Colors.transparent,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sticky Note',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),

                      // Template toggle button (Ruled / Blank / Grid)
                      InkWell(
                        onTap: _toggleTemplate,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _template == NotePageTemplate.ruled
                                    ? Icons.view_headline
                                    : (_template == NotePageTemplate.grid ? Icons.grid_on : Icons.crop_portrait),
                                size: 13,
                                color: Colors.white60,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _template.displayName.split(' ').first,
                                style: const TextStyle(fontSize: 10, color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Close button (X) with instant auto-save
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.white70),
            tooltip: 'Close & Save',
            splashRadius: 16,
            hoverColor: Colors.red.withValues(alpha: 0.8),
            onPressed: _saveAndClose,
          ),
        ],
      ),
    );
  }
}
