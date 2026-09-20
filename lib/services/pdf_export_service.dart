import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/note_model.dart';

class PdfExportService {
  static final PdfExportService instance = PdfExportService._();
  PdfExportService._();

  /// Converts a SamsungNote into a PDF document and saves it
  Future<File> exportNoteToPdf(SamsungNote note, {String? targetPath, bool exportDarkMode = false}) async {
    final doc = pw.Document(
      title: note.title,
      author: 'Samsung Notes & Drive PDF',
    );

    for (final page in note.pages) {
      final isDark = exportDarkMode || page.isDark;
      final bgColor = isDark ? PdfColors.grey900 : PdfColors.white;
      final textColor = isDark ? PdfColors.white : PdfColors.grey900;
      final lineColor = isDark ? PdfColors.grey700 : PdfColors.blueGrey100;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return pw.Container(
              color: bgColor,
              child: pw.Stack(
                children: [
                  // 1. Template Background (Ruled, Grid, Cornell, Blank)
                  _buildPdfTemplateBackground(page.template, lineColor, isDark),

                  // 2. Text content
                  if (page.textContent.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(20),
                      child: pw.Text(
                        page.textContent,
                        style: pw.TextStyle(
                          color: textColor,
                          fontSize: 14,
                          lineSpacing: 8,
                        ),
                      ),
                    ),

                  // 3. Annotations overlay (Text notes & drawings)
                  ...page.annotations.textAnnotations.map((t) {
                    return pw.Positioned(
                      left: t.position.dx,
                      top: t.position.dy,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(t.backgroundColor.toARGB32()),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          t.text,
                          style: pw.TextStyle(
                            color: PdfColor.fromInt(t.color.toARGB32()),
                            fontSize: t.fontSize,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      );
    }

    final bytes = await doc.save();
    File outFile;
    if (targetPath != null) {
      outFile = File(targetPath);
    } else {
      final tempDir = await getTemporaryDirectory();
      final sanitizedTitle = note.title.replaceAll(RegExp(r'[^\w\s-]'), '_');
      outFile = File('${tempDir.path}/${sanitizedTitle}_exported.pdf');
    }

    await outFile.writeAsBytes(bytes);
    return outFile;
  }

  pw.Widget _buildPdfTemplateBackground(NotePageTemplate template, PdfColor lineColor, bool isDark) {
    switch (template) {
      case NotePageTemplate.blank:
        return pw.Container();

      case NotePageTemplate.ruled:
        return pw.CustomPaint(
          size: const PdfPoint(500, 750),
          painter: (PdfGraphics canvas, PdfPoint size) {
            canvas
              ..setColor(lineColor)
              ..setLineWidth(0.5);
            for (double y = 40; y < size.y - 40; y += 28) {
              canvas.drawLine(20, y, size.x - 20, y);
            }
            canvas.strokePath();

            // Red vertical margin line on left
            canvas
              ..setColor(isDark ? PdfColors.red300 : PdfColors.red200)
              ..setLineWidth(0.8)
              ..drawLine(55, 20, 55, size.y - 20)
              ..strokePath();
          },
        );

      case NotePageTemplate.grid:
        return pw.CustomPaint(
          size: const PdfPoint(500, 750),
          painter: (PdfGraphics canvas, PdfPoint size) {
            canvas
              ..setColor(lineColor)
              ..setLineWidth(0.3);
            for (double x = 20; x < size.x - 20; x += 22) {
              canvas.drawLine(x, 20, x, size.y - 20);
            }
            for (double y = 20; y < size.y - 20; y += 22) {
              canvas.drawLine(20, y, size.x - 20, y);
            }
            canvas.strokePath();
          },
        );

      case NotePageTemplate.dotGrid:
        return pw.CustomPaint(
          size: const PdfPoint(500, 750),
          painter: (PdfGraphics canvas, PdfPoint size) {
            canvas.setColor(lineColor);
            for (double x = 25; x < size.x - 25; x += 22) {
              for (double y = 25; y < size.y - 25; y += 22) {
                canvas.drawEllipse(x, y, 0.8, 0.8);
              }
            }
            canvas.fillPath();
          },
        );

      case NotePageTemplate.cornell:
        return pw.CustomPaint(
          size: const PdfPoint(500, 750),
          painter: (PdfGraphics canvas, PdfPoint size) {
            canvas
              ..setColor(lineColor)
              ..setLineWidth(0.8)
              // Header line
              ..drawLine(20, size.y - 70, size.x - 20, size.y - 70)
              // Left cue column
              ..drawLine(150, 90, 150, size.y - 70)
              // Summary footer line
              ..drawLine(20, 90, size.x - 20, 90)
              ..strokePath();

            // Notes area ruling
            canvas
              ..setColor(lineColor)
              ..setLineWidth(0.3);
            for (double y = 110; y < size.y - 80; y += 24) {
              canvas.drawLine(155, y, size.x - 20, y);
            }
            canvas.strokePath();
          },
        );
    }
  }
}
