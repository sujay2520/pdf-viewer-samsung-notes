import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/notes_storage_service.dart';

/// A compact dark sticky note app launched by Win+Z.
/// Each instance creates a new note, auto-saves, and exits on close.
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
        scaffoldBackgroundColor: const Color(0xFF2D2D30),
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

class _QuickNoteScreenState extends State<QuickNoteScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late NoteDocument _note;
  Timer? _saveTimer;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    // Create a new blank dark note
    _note = NoteDocument(
      title: 'Quick Note',
      pages: [
        NotePage(
          pageNumber: 1,
          template: NotePageTemplate.blank,
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
    // Load storage so save works (initializes the directory)
    await NotesStorageService.instance.loadAllNotes();
    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _saveNow();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    _note.firstPage.textContent = text;

    // Auto-title from first line
    final firstLine = text.split('\n').first.trim();
    if (firstLine.isNotEmpty && firstLine.length <= 60) {
      _note.title = firstLine;
    } else if (firstLine.length > 60) {
      _note.title = '${firstLine.substring(0, 57)}...';
    }

    // Debounced save (500ms)
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _saveNow);
  }

  Future<void> _saveNow() async {
    if (_controller.text.trim().isEmpty) return;
    try {
      _note.firstPage.textContent = _controller.text;
      await NotesStorageService.instance.saveNote(_note);
    } catch (e) {
      debugPrint('Quick note save error: $e');
    }
  }

  Future<void> _saveAndClose() async {
    _saveTimer?.cancel();
    await _saveNow();
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D30),
      body: Column(
        children: [
          // ── Compact Title Bar ──
          _buildTitleBar(),

          // ── Text Editor ──
          Expanded(
            child: Container(
              color: const Color(0xFF1E1F22),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                cursorColor: Colors.amber,
                cursorWidth: 2,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
                decoration: InputDecoration(
                  hintText: _initialized ? 'Start typing...' : 'Loading...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onChanged: _onTextChanged,
              ),
            ),
          ),

          // ── Bottom Status Bar ──
          Container(
            height: 28,
            color: const Color(0xFF252526),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.edit_note, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text(
                  'Win+Z = New Note  •  Win+Alt+Z = Full App',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return GestureDetector(
      // Allow dragging the window from the title bar
      onPanStart: (_) {
        // Window drag handled natively by titleBarStyle: hidden
      },
      child: Container(
        height: 36,
        color: const Color(0xFF3C3C3C),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            // Amber color dot (like Sticky Notes)
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),

            // Title
            const Text(
              'Quick Note',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),

            const Spacer(),

            // Close button
            InkWell(
              onTap: _saveAndClose,
              borderRadius: BorderRadius.circular(4),
              hoverColor: Colors.red.withValues(alpha: 0.8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: Colors.white60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
