import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/note_model.dart';

class PdfExportService {
  static final PdfExportService instance = PdfExportService._();
  PdfExportService._();

  /// Converts a NoteDocument into a PDF document with full multi-page support
  Future<File> exportNoteToPdf(NoteDocument note, {String? targetPath, bool exportDarkMode = false}) async {
    final doc = pw.Document(
      title: note.title,
      author: 'Drive Notes & PDF',
    );

    for (final page in note.pages) {
      final isDark = exportDarkMode || page.isDark;
      final bgColor = isDark ? PdfColors.grey900 : PdfColors.white;
      final textColor = isDark ? PdfColors.white : PdfColors.grey900;
      final lineColor = isDark ? PdfColors.grey700 : PdfColors.blueGrey100;

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(40, 48, 40, 48),
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.fromLTRB(40, 48, 40, 48),
            buildBackground: (pw.Context context) {
              return pw.Container(
                color: bgColor,
                child: _buildPdfTemplateBackground(page.template, lineColor, isDark),
              );
            },
          ),
          header: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.only(bottom: 6),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: isDark ? PdfColors.grey700 : PdfColors.grey300,
                    width: 0.5,
                  ),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      note.title,
                      style: pw.TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                    ),
                  ),
                  pw.Text(
                    'Drive Notes & PDF',
                    style: pw.TextStyle(
                      color: isDark ? PdfColors.grey400 : PdfColors.grey600,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 12),
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(
                  color: isDark ? PdfColors.grey400 : PdfColors.grey600,
                  fontSize: 9,
                ),
              ),
            );
          },
          build: (pw.Context context) {
            final widgets = <pw.Widget>[];

            // 1. Multi-line text content — automatically flows across all pages!
            if (page.textContent.isNotEmpty) {
              final lines = page.textContent.split('\n');
              for (final line in lines) {
                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(
                      line.isEmpty ? ' ' : line,
                      style: pw.TextStyle(
                        color: textColor,
                        fontSize: 11,
                        lineSpacing: 4,
                      ),
                    ),
                  ),
                );
              }
            }

            // 2. Text annotations overlay
            for (final t in page.annotations.textAnnotations) {
              widgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 8, bottom: 8),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            }

            return widgets;
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
          size: const PdfPoint(595, 842),
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
          size: const PdfPoint(595, 842),
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
          size: const PdfPoint(595, 842),
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
          size: const PdfPoint(595, 842),
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
