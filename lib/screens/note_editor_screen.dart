import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/note_model.dart';
import '../models/annotation_model.dart';
import '../services/notes_storage_service.dart';
import '../services/print_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/note_tools_bar.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/note_page_background.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteDocument note;

  const NoteEditorScreen({super.key, required this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late NoteDocument _note;
  int _currentPageIndex = 0;
  late final TextEditingController _titleController;
  late final TextEditingController _textEditingController;
  final FocusNode _textFocusNode = FocusNode();
  Timer? _saveDebounceTimer;

  // Note Studio Tools State
  bool _isTypingMode = true; // Enabled by default so user can immediately type on lines!
  DrawingTool _activeTool = DrawingTool.select;
  ShapeType _activeShape = ShapeType.rectangle;
  Color _activeColor = const Color(0xFF1976D2);
  double _strokeWidth = 3.0;

  NotePage get _currentPage => _note.pages[_currentPageIndex];

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _titleController = TextEditingController(text: _note.title);
    _textEditingController = TextEditingController(text: _currentPage.textContent);
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    _saveCurrentNote();
    _titleController.dispose();
    _textEditingController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _debounceSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _saveCurrentNote();
    });
  }

  void _saveCurrentNote() {
    _saveDebounceTimer?.cancel();
    _currentPage.textContent = _textEditingController.text;
    _note.title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Untitled Note';
    NotesStorageService.instance.saveNote(_note);
  }

  EdgeInsets _getTextPaddingForTemplate(NotePageTemplate template) {
    switch (template) {
      case NotePageTemplate.ruled:
        // Margin line is at x=60, first rule line at y=48.
        // top: 24 with height: 2.0 font 16 positions text baseline exactly on y=48!
        return const EdgeInsets.fromLTRB(72, 24, 32, 32);
      case NotePageTemplate.cornell:
        // Cue column is x=160, main area starts right after
        return const EdgeInsets.fromLTRB(172, 72, 32, 70);
      case NotePageTemplate.grid:
      case NotePageTemplate.dotGrid:
      case NotePageTemplate.blank:
        return const EdgeInsets.fromLTRB(36, 24, 36, 32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark || _currentPage.isDark;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _saveCurrentNote();
      },
      child: Scaffold(
        backgroundColor: _currentPage.isDark ? const Color(0xFF121212) : const Color(0xFFF1F3F4),
        appBar: AppBar(
          elevation: 1,
          backgroundColor: isDark ? const Color(0xFF1E1F22) : Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Save & Return to Library',
            onPressed: () {
              _saveCurrentNote();
              Navigator.of(context).pop();
            },
          ),
          title: TextField(
            controller: _titleController,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Note Title...',
            ),
            onChanged: (val) => _debounceSave(),
          ),
          actions: [
            // Mode Indicator / Toggle: Typing vs Drawing
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: Icon(
                _isTypingMode ? Icons.keyboard : Icons.edit,
                size: 18,
              ),
              label: Text(_isTypingMode ? 'Type Mode' : 'Draw Mode'),
              onPressed: () {
                setState(() {
                  _isTypingMode = !_isTypingMode;
                  if (_isTypingMode) {
                    _activeTool = DrawingTool.select;
                    _textFocusNode.requestFocus();
                  } else {
                    _activeTool = DrawingTool.pen;
                    _textFocusNode.unfocus();
                  }
                });
              },
            ),
            const SizedBox(width: 8),

            // Template selector menu
            PopupMenuButton<NotePageTemplate>(
              tooltip: 'Page Template: ${_currentPage.template.displayName}',
              icon: Icon(_currentPage.template.icon),
              onSelected: (template) {
                setState(() {
                  _currentPage.template = template;
                });
                _saveCurrentNote();
              },
              itemBuilder: (context) => NotePageTemplate.values.map((t) {
                return PopupMenuItem(
                  value: t,
                  child: Row(
                    children: [
                      Icon(t.icon, size: 20),
                      const SizedBox(width: 10),
                      Text(t.displayName),
                    ],
                  ),
                );
              }).toList(),
            ),

            // Dark Mode Page Toggle
            IconButton(
              icon: Icon(
                _currentPage.isDark ? Icons.dark_mode : Icons.light_mode,
                color: _currentPage.isDark ? Colors.amber.shade400 : null,
              ),
              tooltip: 'Toggle Dark / Light Page',
              onPressed: () {
                setState(() {
                  _currentPage.isDark = !_currentPage.isDark;
                });
                _saveCurrentNote();
              },
            ),

            // Print Document
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Print Note',
              onPressed: _handlePrintNote,
            ),

            // Save / Export as PDF
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Export as PDF',
              onPressed: _handleExportPdf,
            ),

            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Top Toolbar: Note Tools Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: isDark ? const Color(0xFF1E1F22) : const Color(0xFFE9EEF4),
              alignment: Alignment.center,
              child: NoteToolsBar(
                isTypingMode: _isTypingMode,
                activeTool: _activeTool,
                activeShape: _activeShape,
                activeColor: _activeColor,
                strokeWidth: _strokeWidth,
                canUndo: _currentPage.annotations.undoStack.isNotEmpty,
                canRedo: _currentPage.annotations.redoStack.isNotEmpty,
                onToggleTypingMode: () {
                  setState(() {
                    _isTypingMode = true;
                    _activeTool = DrawingTool.select;
                    _textFocusNode.requestFocus();
                  });
                },
                onToolSelected: (tool) {
                  setState(() {
                    _activeTool = tool;
                    _isTypingMode = false;
                    _textFocusNode.unfocus();
                  });
                },
                onShapeSelected: (shape) => setState(() => _activeShape = shape),
                onColorChanged: (c) => setState(() => _activeColor = c),
                onStrokeWidthChanged: (w) => setState(() => _strokeWidth = w),
                onUndo: () {
                  setState(() => _currentPage.annotations.undo());
                  _saveCurrentNote();
                },
                onRedo: () {
                  setState(() => _currentPage.annotations.redo());
                  _saveCurrentNote();
                },
                onClear: () {
                  setState(() => _currentPage.annotations.clearAll());
                  _saveCurrentNote();
                },
              ),
            ),

            // Note Content Canvas: Centered A4 ratio page
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Material(
                    elevation: 6,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      width: 700,
                      height: 980, // A4 ratio
                      color: _currentPage.isDark ? const Color(0xFF1E1F22) : Colors.white,
                      child: Stack(
                        children: [
                          // 1. Template background (Ruled, Grid, Dot Grid, Cornell, Blank)
                          Positioned.fill(
                            child: NotePageBackground(
                              template: _currentPage.template,
                              isDark: _currentPage.isDark,
                            ),
                          ),

                          // 2. Direct Lined Text Typing Layer (Always accessible!)
                          Positioned.fill(
                            child: Padding(
                              padding: _getTextPaddingForTemplate(_currentPage.template),
                              child: TextField(
                                controller: _textEditingController,
                                focusNode: _textFocusNode,
                                maxLines: null,
                                expands: true,
                                enabled: _isTypingMode,
                                cursorColor: theme.colorScheme.primary,
                                cursorWidth: 2.0,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  height: 2.0, // Aligns exactly with 32px ruled lines!
                                  letterSpacing: 0.2,
                                  color: _currentPage.isDark ? Colors.white : Colors.black87,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Click anywhere on the lines to start typing...',
                                  hintStyle: TextStyle(color: Colors.black26),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                onChanged: (val) => _debounceSave(),
                              ),
                            ),
                          ),

                          // 3. Vector Drawing & Markup Canvas Layer
                          // When typing mode is active, IgnorePointer ensures clicks pass 100% to TextField!
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: _isTypingMode,
                              child: DrawingCanvas(
                                annotations: _currentPage.annotations,
                                activeTool: _activeTool,
                                activeShape: _activeShape,
                                activeColor: _activeColor,
                                strokeWidth: _strokeWidth,
                                size: const Size(700, 980),
                                onAnnotationChanged: () {
                                  _saveCurrentNote();
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom bar: Page Navigation & Add Page
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: isDark ? const Color(0xFF1E1F22) : Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        tooltip: 'Previous Page',
                        onPressed: _currentPageIndex > 0
                            ? () {
                                _saveCurrentNote();
                                setState(() {
                                  _currentPageIndex--;
                                  _textEditingController.text = _currentPage.textContent;
                                });
                              }
                            : null,
                      ),
                      Text(
                        'Page ${_currentPageIndex + 1} of ${_note.pages.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        tooltip: 'Next Page',
                        onPressed: _currentPageIndex < _note.pages.length - 1
                            ? () {
                                _saveCurrentNote();
                                setState(() {
                                  _currentPageIndex++;
                                  _textEditingController.text = _currentPage.textContent;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),

                  // Add Page button
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Page'),
                    onPressed: () {
                      _saveCurrentNote();
                      setState(() {
                        final newPageNum = _note.pages.length + 1;
                        _note.pages.add(
                          NotePage(
                            pageNumber: newPageNum,
                            template: _currentPage.template,
                            isDark: _currentPage.isDark,
                          ),
                        );
                        _currentPageIndex = _note.pages.length - 1;
                        _textEditingController.text = '';
                      });
                      _saveCurrentNote();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePrintNote() async {
    _saveCurrentNote();
    await PrintService.showPrintDialog(
      context: context,
      documentTitle: _note.title,
      onConfirm: ({required bool printDarkMode, required bool includeAnnotations}) async {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preparing note for print...')),
          );
          await PrintService.instance.printNote(
            note: _note,
            printDarkMode: printDarkMode,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Print failed: $e')),
            );
          }
        }
      },
    );
  }

  Future<void> _handleExportPdf() async {
    _saveCurrentNote();
    try {
      final sanitizedTitle = _note.title.replaceAll(RegExp(r'[^\w\s-]'), '_');
      final exportFile = await PdfExportService.instance.exportNoteToPdf(
        _note,
        exportDarkMode: _currentPage.isDark,
      );

      final saveUri = await FilePicker.saveFile(
        dialogTitle: 'Save Note as PDF',
        fileName: '$sanitizedTitle.pdf',
        bytes: await exportFile.readAsBytes(),
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (saveUri != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note exported to: ${saveUri.path}'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}
