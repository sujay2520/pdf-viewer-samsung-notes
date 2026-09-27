import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SampleDocsService {
  static final SampleDocsService instance = SampleDocsService._();
  SampleDocsService._();

  Future<File> getOrCreateSamplePdf() async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/drive_notes_guide.pdf');
    if (await file.exists()) {
      return file;
    }

    final doc = pw.Document(
      title: 'Drive Notes & PDF Guide',
      author: 'Drive Notes & PDF Team',
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
                    pw.Text('Drive Notes & PDF Viewer',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.Text('Guide v1.0', style: const pw.TextStyle(color: PdfColors.grey600)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Paragraph(
                text:
                    'This sample document demonstrates the powerful features of your cross-platform PDF Viewer and Notebook studio. You can test page inversion, annotations, text search, and printing directly on this document.',
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
                    pw.Text('Smart Dark Inversion Technology',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900, fontSize: 13)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Turn blinding white pages into eye-friendly dark pages without losing images or readability! Try the moon icon in the top toolbar:',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('• OLED Dark: Pure black background for minimum battery and OLED screens.\n'
                        '• Midnight Charcoal: Soft dark grey (Google Drive dark style).\n'
                        '• Warm Sepia: Relaxing reading warmth for late nights.\n'
                        '• High Contrast: Maximum legibility for low vision.',
                        style: const pw.TextStyle(fontSize: 10, lineSpacing: 2)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Key Viewer & Studio Features:',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
              pw.SizedBox(height: 8),
              pw.Bullet(
                text: 'Global Windows Shortcut: Press Win + Z from anywhere in Windows to summon Notes instantly.',
              ),
              pw.Bullet(
                text: 'In-Document Text Search: Search any word with real-time match count and jumping.',
              ),
              pw.Bullet(
                text: 'Print & Save as PDF: Print to paper or PDF printer with annotations and dark mode options.',
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
                  pw.Text('Drive Notes & PDF', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
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
              pw.Text('Notebook Templates Comparison:',
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
                  '• Ctrl + P: Open Print Dialog\n'
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
                  pw.Text('Drive Notes & PDF', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
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
