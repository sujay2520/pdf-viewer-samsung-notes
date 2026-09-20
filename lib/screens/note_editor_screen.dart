import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/note_model.dart';
import '../models/annotation_model.dart';
import '../services/notes_storage_service.dart';
import '../services/print_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/samsung_tools_bar.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/note_page_background.dart';

class NoteEditorScreen extends StatefulWidget {
  final SamsungNote note;

  const NoteEditorScreen({super.key, required this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late SamsungNote _note;
  int _currentPageIndex = 0;
  late final TextEditingController _titleController;
  late final TextEditingController _textEditingController;

  // Samsung Notes Studio Tools State
  DrawingTool _activeTool = DrawingTool.pen;
  ShapeType _activeShape = ShapeType.rectangle;
  Color _activeColor = const Color(0xFF1976D2);
  double _strokeWidth = 3.0;
  bool _isTypingMode = false;

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
    _titleController.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  void _saveCurrentNote() {
    _currentPage.textContent = _textEditingController.text;
    _note.title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Untitled Note';
    NotesStorageService.instance.saveNote(_note);
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
            onChanged: (val) => _saveCurrentNote(),
          ),
          actions: [
            // Mode toggle: Drawing vs Text Typing
            IconButton(
              icon: Icon(
                _isTypingMode ? Icons.keyboard : Icons.edit_note,
                color: _isTypingMode ? theme.colorScheme.primary : null,
              ),
              tooltip: _isTypingMode ? 'Switch to Pen Drawing' : 'Switch to Text Typing',
              onPressed: () {
                setState(() {
                  _isTypingMode = !_isTypingMode;
                  if (_isTypingMode) {
                    _activeTool = DrawingTool.select;
                  } else {
                    _activeTool = DrawingTool.pen;
                  }
                });
              },
            ),

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

            // Samsung Print
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Print Note',
              onPressed: _handlePrintNote,
            ),

            // Save as PDF
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Export / Save as PDF',
              onPressed: _handleExportPdf,
            ),

            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Top Toolbar: Samsung Tools Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: isDark ? const Color(0xFF1E1F22) : const Color(0xFFE9EEF4),
              alignment: Alignment.center,
              child: SamsungToolsBar(
                activeTool: _activeTool,
                activeShape: _activeShape,
                activeColor: _activeColor,
                strokeWidth: _strokeWidth,
                canUndo: _currentPage.annotations.undoStack.isNotEmpty,
                canRedo: _currentPage.annotations.redoStack.isNotEmpty,
                onToolSelected: (tool) {
                  setState(() {
                    _activeTool = tool;
                    _isTypingMode = false;
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

                          // 2. Text typing layer (if typing mode active or text exists)
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(70, 48, 30, 40),
                              child: TextField(
                                controller: _textEditingController,
                                maxLines: null,
                                expands: true,
                                enabled: _isTypingMode,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 2.0, // Aligns with ruled lines
                                  color: _currentPage.isDark ? Colors.white : Colors.black87,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Tap to start typing notes...',
                                  border: InputBorder.none,
                                ),
                                onChanged: (val) => _saveCurrentNote(),
                              ),
                            ),
                          ),

                          // 3. Vector Drawing & Markup Canvas Layer
                          Positioned.fill(
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
                  Row(
                    children: [
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Page'),
                        onPressed: () {
                          _saveCurrentNote();
                          setState(() {
                            final newPage = NotePage(
                              pageNumber: _note.pages.length + 1,
                              template: _currentPage.template,
                              isDark: _currentPage.isDark,
                            );
                            _note.pages.add(newPage);
                            _currentPageIndex = _note.pages.length - 1;
                            _textEditingController.clear();
                          });
                          _saveCurrentNote();
                        },
                      ),
                      if (_note.pages.length > 1) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Delete Current Page',
                          onPressed: () {
                            if (_note.pages.length > 1) {
                              setState(() {
                                _note.pages.removeAt(_currentPageIndex);
                                if (_currentPageIndex >= _note.pages.length) {
                                  _currentPageIndex = _note.pages.length - 1;
                                }
                                _textEditingController.text = _currentPage.textContent;
                              });
                              _saveCurrentNote();
                            }
                          },
                        ),
                      ],
                    ],
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
            const SnackBar(content: Text('Preparing print document...')),
          );
          await PrintService.instance.printNote(
            note: _note,
            printDarkMode: printDarkMode,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Print error: $e')),
            );
          }
        }
      },
    );
  }

  Future<void> _handleExportPdf() async {
    _saveCurrentNote();
    try {
      final defaultName = '${_note.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}.pdf';
      final exportedFile = await PdfExportService.instance.exportNoteToPdf(
        _note,
        exportDarkMode: _currentPage.isDark,
      );
      final bytes = await exportedFile.readAsBytes();

      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save Note as PDF',
        fileName: defaultName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (uri != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported PDF: ${uri.path}'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }
}
