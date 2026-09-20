import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../models/note_model.dart';
import 'pdf_export_service.dart';

class PrintService {
  static final PrintService instance = PrintService._();
  PrintService._();

  /// Prints an existing PDF file directly via system print dialog
  Future<void> printPdfFile({
    required File pdfFile,
    String? jobName,
  }) async {
    final bytes = await pdfFile.readAsBytes();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: jobName ?? pdfFile.uri.pathSegments.last,
    );
  }

  /// Prints a Samsung Note using system print dialog
  Future<void> printNote({
    required SamsungNote note,
    bool printDarkMode = false,
  }) async {
    final pdfFile = await PdfExportService.instance.exportNoteToPdf(
      note,
      exportDarkMode: printDarkMode,
    );
    await printPdfFile(pdfFile: pdfFile, jobName: note.title);
  }

  /// Shows the Samsung-style Print configuration dialog
  static Future<void> showPrintDialog({
    required BuildContext context,
    required String documentTitle,
    required Future<void> Function({required bool printDarkMode, required bool includeAnnotations}) onConfirm,
  }) async {
    bool isDarkMode = false;
    bool includeAnnotations = true;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.print_rounded, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text('Samsung Print'),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      documentTitle,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Include Annotations & Drawings'),
                      subtitle: const Text('Print hand-drawn notes and highlighters'),
                      value: includeAnnotations,
                      onChanged: (val) => setState(() => includeAnnotations = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Print in Dark Inversion Mode'),
                      subtitle: const Text('Dark background for inverted night style'),
                      value: isDarkMode,
                      onChanged: (val) => setState(() => isDarkMode = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print Document'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm(
                      printDarkMode: isDarkMode,
                      includeAnnotations: includeAnnotations,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
