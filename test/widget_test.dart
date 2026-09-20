import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_viewer_pro/models/color_filter_mode.dart';
import 'package:pdf_viewer_pro/models/note_model.dart';
import 'package:pdf_viewer_pro/models/annotation_model.dart';

void main() {
  group('PDF Smart Dark Mode Inversion Tests', () {
    test('All color filter modes provide valid matrix and background color', () {
      for (final mode in PdfColorFilterMode.values) {
        expect(mode.displayName.isNotEmpty, isTrue);
        expect(mode.backgroundColor, isNotNull);
        if (mode != PdfColorFilterMode.original) {
          expect(mode.colorFilter, isNotNull);
        } else {
          expect(mode.colorFilter, isNull);
        }
      }
    });
  });

  group('Samsung Notes Model Tests', () {
    test('SamsungNote serializes and deserializes correctly', () {
      final note = SamsungNote(
        title: 'Meeting Notes',
        folder: 'Work',
        isFavorite: true,
        pages: [
          NotePage(
            pageNumber: 1,
            template: NotePageTemplate.ruled,
            textContent: 'Action items for project',
          ),
        ],
      );

      final json = note.toJson();
      final revived = SamsungNote.fromJson(json);

      expect(revived.title, equals('Meeting Notes'));
      expect(revived.folder, equals('Work'));
      expect(revived.isFavorite, isTrue);
      expect(revived.pages.length, equals(1));
      expect(revived.pages.first.template, equals(NotePageTemplate.ruled));
      expect(revived.pages.first.textContent, equals('Action items for project'));
    });

    test('PageAnnotations undo and redo stack functions properly', () {
      final annotations = PageAnnotations(pageNumber: 1);
      final stroke = DrawingStroke(
        id: 'stroke-1',
        points: [StrokePoint(10, 10), StrokePoint(20, 20)],
        color: const Color(0xFF1976D2),
        strokeWidth: 3.0,
      );

      annotations.addStroke(stroke);
      expect(annotations.strokes.length, equals(1));
      expect(annotations.undoStack.length, equals(1));

      final didUndo = annotations.undo();
      expect(didUndo, isTrue);
      expect(annotations.strokes.length, equals(0));
      expect(annotations.redoStack.length, equals(1));

      final didRedo = annotations.redo();
      expect(didRedo, isTrue);
      expect(annotations.strokes.length, equals(1));
    });
  });
}
