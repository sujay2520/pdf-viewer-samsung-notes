import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note_model.dart';
import '../models/annotation_model.dart';

class NotesStorageService {
  static final NotesStorageService instance = NotesStorageService._();
  NotesStorageService._();

  List<SamsungNote> _cachedNotes = [];

  List<SamsungNote> get notes => List.unmodifiable(_cachedNotes);

  Future<Directory> get _notesDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/SamsungNotesPro');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<List<SamsungNote>> loadAllNotes() async {
    try {
      final dir = await _notesDirectory;
      final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));

      final loaded = <SamsungNote>[];
      for (final file in files) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          loaded.add(SamsungNote.fromJson(json));
        } catch (e) {
          debugPrint('Error loading note from ${file.path}: $e');
        }
      }

      // If empty, create initial sample Samsung Notes
      if (loaded.isEmpty) {
        loaded.addAll(_createStarterNotes());
        for (final note in loaded) {
          await saveNote(note);
        }
      }

      loaded.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _cachedNotes = loaded;
      return _cachedNotes;
    } catch (e) {
      debugPrint('Failed to load notes: $e');
      if (_cachedNotes.isEmpty) {
        _cachedNotes = _createStarterNotes();
      }
      return _cachedNotes;
    }
  }

  Future<void> saveNote(SamsungNote note) async {
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

  List<SamsungNote> _createStarterNotes() {
    // 1. Welcome Guide note
    final welcomeNote = SamsungNote(
      title: 'Welcome to Samsung Notes & Drive PDF',
      folder: 'Tutorial',
      isFavorite: true,
      pages: [
        NotePage(
          pageNumber: 1,
          template: NotePageTemplate.ruled,
          textContent: 'Welcome to your modern cross-platform PDF & Notes workstation!\n\n'
              'Features included:\n'
              '• Press Win + Z anywhere in Windows to instantly open/focus this app.\n'
              '• Google Drive-style clean Material 3 viewer with dark & light themes.\n'
              '• Smart Inversion: Convert white PDF pages to true OLED dark or Midnight charcoal.\n'
              '• Adobe Acrobat features: In-document text search, thumbnails drawer, zoom.\n'
              '• Samsung features: Pen, highlighter, shapes, eraser, direct printing, save as PDF.\n'
              '• Templates: Blank, Ruled, Grid, Dot Grid, and Cornell.',
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

    // 2. Project Ideas note
    final ideasNote = SamsungNote(
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
