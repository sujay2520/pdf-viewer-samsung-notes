import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SampleDocsService {
  static final SampleDocsService instance = SampleDocsService._();
  SampleDocsService._();

  Future<File> getOrCreateSamplePdf() async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/sample_document.pdf');
    if (await file.exists()) {
      return file;
    }

    final doc = pw.Document(
      title: 'Google Drive & Samsung Notes PDF Guide',
      author: 'PDF Expert Team',
    );

    // Page 1: Overview & Inversion Mode
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Drive PDF Viewer & Samsung Notes',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.Text('Guide v1.0', style: const pw.TextStyle(color: PdfColors.grey600)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Paragraph(
                text:
                    'This sample document demonstrates the powerful features of your cross-platform PDF Viewer and Samsung Notes PC studio. You can test page inversion, annotations, text search, and printing directly on this document.',
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  border: pw.Border.all(color: PdfColors.blue300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('🌙 Smart Dark Inversion Technology',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900, fontSize: 13)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Unlike conventional viewers that keep white pages glaring while darkening only the app borders, this viewer converts white pages to deep OLED dark (#000000) or Midnight charcoal (#1E1F22) with crisp off-white text. Toggle the Sun/Moon icon in the top toolbar to see it live!',
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.blueGrey800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Key Adobe Acrobat & Samsung Features:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
              pw.SizedBox(height: 8),
              pw.Bullet(
                text: 'Global Windows Shortcut: Press Win + Z from anywhere in Windows to summon Samsung Notes instantly.',
              ),
              pw.Bullet(
                text: 'Freehand Drawing & Markup: Choose Pen, Fountain Pen, Highlighter, Shapes (Rectangles, Arrows), and Eraser.',
              ),
              pw.Bullet(
                text: 'In-Document Text Search: Search any word with real-time match count and jumping.',
              ),
              pw.Bullet(
                text: 'Samsung Print & Save as PDF: Print to paper or PDF printer with annotations and dark mode options.',
              ),
              pw.Bullet(
                text: 'Page Navigation: Thumbnail grid drawer, fit-to-width, fit-to-page, and smooth continuous scroll.',
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Page 1 of 2', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  pw.Text('Drive PDF & Samsung Notes', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Page 2: Note Templates & Cheat Sheet
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 1,
                child: pw.Text('Note Taking & Annotation Guide',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Samsung Note Templates Comparison:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Template', 'Best For', 'Features'],
                data: [
                  ['Ruled / Lined', 'Writing & Journaling', 'Standard line spacing with left margin marker'],
                  ['Grid / Graph', 'Diagrams & Engineering', '20px grid boxes for precise geometry'],
                  ['Dot Grid', 'Bullet Journaling', 'Clean dot matrix for flexible layouts'],
                  ['Cornell Notes', 'Lectures & Study', '3-section system: Cue column, Notes, and Summary'],
                  ['Blank Page', 'Freehand sketching', 'Empty canvas with zero distractions'],
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellPadding: const pw.EdgeInsets.all(6),
                cellStyle: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Keyboard & Touch Gestures:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 6),
              pw.Text('• Ctrl + F (or Search button): Open Find in Page\n'
                  '• Ctrl + P: Open Samsung Print Dialog\n'
                  '• Ctrl + S: Save as PDF\n'
                  '• Win + Z: System-wide shortcut to summon Notes\n'
                  '• Pinch / Mouse Wheel: Zoom in and out',
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 4)),
              pw.Spacer(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Page 2 of 2', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  pw.Text('Drive PDF & Samsung Notes', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await doc.save();
    await file.writeAsBytes(bytes);
    return file;
  }
}
