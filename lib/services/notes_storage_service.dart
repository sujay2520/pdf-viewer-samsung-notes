import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note_model.dart';
import '../models/annotation_model.dart';

class RecentPdfItem {
  final String path;
  final String title;
  final DateTime lastOpened;
  final int pageCount;

  RecentPdfItem({
    required this.path,
    required this.title,
    required this.lastOpened,
    this.pageCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'title': title,
        'lastOpened': lastOpened.toIso8601String(),
        'pageCount': pageCount,
      };

  factory RecentPdfItem.fromJson(Map<String, dynamic> json) => RecentPdfItem(
        path: json['path'] as String,
        title: json['title'] as String,
        lastOpened: DateTime.tryParse(json['lastOpened'] as String? ?? '') ?? DateTime.now(),
        pageCount: json['pageCount'] as int? ?? 0,
      );
}

class NotesStorageService {
  static final NotesStorageService instance = NotesStorageService._();
  NotesStorageService._();

  List<NoteDocument> _cachedNotes = [];
  List<RecentPdfItem> _cachedRecentPdfs = [];

  List<NoteDocument> get notes => List.unmodifiable(_cachedNotes);
  List<RecentPdfItem> get recentPdfs => List.unmodifiable(_cachedRecentPdfs);

  Future<Directory> get _notesDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final newDir = Directory('${appDir.path}/DriveNotesPro');
    final oldDir = Directory('${appDir.path}/SamsungNotesPro');

    // Auto-migrate from legacy folder if exists
    if (!await newDir.exists() && await oldDir.exists()) {
      try {
        await oldDir.rename(newDir.path);
      } catch (_) {
        // Fallback to creating new directory
      }
    }

    if (!await newDir.exists()) {
      await newDir.create(recursive: true);
    }
    return newDir;
  }

  Future<List<NoteDocument>> loadAllNotes() async {
    try {
      final dir = await _notesDirectory;
      final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json') && !f.path.endsWith('recent_pdfs.json'));

      final loaded = <NoteDocument>[];
      for (final file in files) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          loaded.add(NoteDocument.fromJson(json));
        } catch (e) {
          debugPrint('Error loading note from ${file.path}: $e');
        }
      }

      // If empty, create initial starter note
      if (loaded.isEmpty) {
        loaded.addAll(_createStarterNotes());
        for (final note in loaded) {
          await saveNote(note);
        }
      }

      loaded.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _cachedNotes = loaded;

      // Also load recent PDFs
      await loadRecentPdfs();

      return _cachedNotes;
    } catch (e) {
      debugPrint('Failed to load notes: $e');
      if (_cachedNotes.isEmpty) {
        _cachedNotes = _createStarterNotes();
      }
      return _cachedNotes;
    }
  }

  Future<void> saveNote(NoteDocument note) async {
    try {
      note.updatedAt = DateTime.now();
      final dir = await _notesDirectory;
      final file = File('${dir.path}/${note.id}.json');
      final jsonString = const JsonEncoder.withIndent('  ').convert(note.toJson());
      await file.writeAsString(jsonString);

      final index = _cachedNotes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        _cachedNotes[index] = note;
      } else {
        _cachedNotes.insert(0, note);
      }
    } catch (e) {
      debugPrint('Error saving note ${note.id}: $e');
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      final dir = await _notesDirectory;
      final file = File('${dir.path}/$noteId.json');
      if (await file.exists()) {
        await file.delete();
      }
      _cachedNotes.removeWhere((n) => n.id == noteId);
    } catch (e) {
      debugPrint('Error deleting note $noteId: $e');
    }
  }

  // --- Recent PDFs tracking ---
  Future<List<RecentPdfItem>> loadRecentPdfs() async {
    try {
      final dir = await _notesDirectory;
      final file = File('${dir.path}/recent_pdfs.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        _cachedRecentPdfs = list
            .map((item) => RecentPdfItem.fromJson(item as Map<String, dynamic>))
            .where((item) => File(item.path).existsSync())
            .toList();
        _cachedRecentPdfs.sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
      }
    } catch (e) {
      debugPrint('Error loading recent PDFs: $e');
    }
    return _cachedRecentPdfs;
  }

  Future<void> addRecentPdf(String path, String title, {int pageCount = 0}) async {
    try {
      _cachedRecentPdfs.removeWhere((p) => p.path == path);
      _cachedRecentPdfs.insert(
        0,
        RecentPdfItem(
          path: path,
          title: title,
          lastOpened: DateTime.now(),
          pageCount: pageCount,
        ),
      );
      if (_cachedRecentPdfs.length > 20) {
        _cachedRecentPdfs = _cachedRecentPdfs.sublist(0, 20);
      }
      final dir = await _notesDirectory;
      final file = File('${dir.path}/recent_pdfs.json');
      await file.writeAsString(jsonEncode(_cachedRecentPdfs.map((p) => p.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving recent PDF: $e');
    }
  }

  Future<void> removeRecentPdf(String path) async {
    try {
      _cachedRecentPdfs.removeWhere((p) => p.path == path);
      final dir = await _notesDirectory;
      final file = File('${dir.path}/recent_pdfs.json');
      await file.writeAsString(jsonEncode(_cachedRecentPdfs.map((p) => p.toJson()).toList()));
    } catch (e) {
      debugPrint('Error removing recent PDF: $e');
    }
  }

  List<NoteDocument> _createStarterNotes() {
    final welcomeNote = NoteDocument(
      title: 'Welcome to Drive Notes & PDF',
      folder: 'General',
      isFavorite: true,
      pages: [
        NotePage(
          pageNumber: 1,
          template: NotePageTemplate.ruled,
          textContent: 'Welcome to your modern cross-platform PDF & Notes workstation!\n\n'
              'Features included:\n'
              '• Press Win + Z anywhere in Windows to instantly summon the app.\n'
              '• Lined Page Typing: Click anywhere on the lines to type naturally.\n'
              '• Vector Studio: Pen, calligraphy, highlighter, geometric shapes, and eraser.\n'
              '• Smart Inversion: Convert white PDF pages to true OLED dark or Midnight charcoal.\n'
              '• Adobe Acrobat features: Fast text search, page thumbnails, zoom controls.\n'
              '• Print & Save as PDF: Direct system printing and high-res PDF exports.\n'
              '• Multiple Templates: Blank, Ruled, Grid, Dot Grid, and Cornell.',
          annotations: PageAnnotations(
            pageNumber: 1,
            textAnnotations: [
              TextAnnotation(
                id: '1',
                text: '💡 Tip: Use Win + Z to quickly take notes!',
                position: const Offset(40, 260),
                color: const Color(0xFF1E88E5),
                backgroundColor: const Color(0x221E88E5),
                fontSize: 15,
              ),
            ],
          ),
        ),
      ],
    );

    final ideasNote = NoteDocument(
      title: 'Ideas & Sketchpad',
      folder: 'Personal',
      pages: [
        NotePage(
          pageNumber: 1,
          template: NotePageTemplate.grid,
          textContent: 'Graph paper template for wireframing, architecture diagrams, and math.',
        ),
      ],
    );

    return [welcomeNote, ideasNote];
  }
}
