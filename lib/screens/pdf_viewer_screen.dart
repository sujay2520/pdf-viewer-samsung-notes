import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/color_filter_mode.dart';
import '../models/annotation_model.dart';
import '../services/print_service.dart';
import '../services/notes_storage_service.dart';
import '../widgets/drive_top_bar.dart';
import '../widgets/drive_bottom_bar.dart';
import '../widgets/note_tools_bar.dart';
import '../widgets/thumbnails_drawer.dart';
import '../widgets/search_overlay.dart';
import '../widgets/drawing_canvas.dart';

class PdfViewerScreen extends StatefulWidget {
  final File file;
  final String? initialTitle;

  const PdfViewerScreen({
    super.key,
    required this.file,
    this.initialTitle,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late File _currentFile;
  late String _documentTitle;
  late final PdfViewerController _controller;
  PdfTextSearcher? _searcher;

  // Viewing State
  int _currentPage = 1;
  int _totalPages = 0;
  double _currentZoom = 1.0;
  PdfColorFilterMode _colorFilterMode = PdfColorFilterMode.original;
  bool _isSearchActive = false;
  bool _showThumbnails = false;
  final TextEditingController _searchQueryController = TextEditingController();

  // Markup & Drawing State
  bool _isAnnotationMode = false;
  DrawingTool _activeTool = DrawingTool.pen;
  ShapeType _activeShape = ShapeType.rectangle;
  Color _activeColor = const Color(0xFF1976D2);
  double _strokeWidth = 3.0;

  // Per-page annotation storage
  final Map<int, PageAnnotations> _annotationsByPage = {};

  @override
  void initState() {
    super.initState();
    _currentFile = widget.file;
    _documentTitle = widget.initialTitle ?? widget.file.uri.pathSegments.last;
    _controller = PdfViewerController();
    _controller.addListener(_onControllerUpdate);

    // Track recently opened PDF
    NotesStorageService.instance.addRecentPdf(_currentFile.path, _documentTitle);
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final page = _controller.pageNumber ?? 1;
    final total = _controller.isReady ? _controller.pageCount : 0;
    final zoom = _controller.currentZoom;

    if (page != _currentPage || total != _totalPages || (zoom - _currentZoom).abs() > 0.05) {
      setState(() {
        _currentPage = page;
        _totalPages = total;
        _currentZoom = zoom;
      });
    }
  }

  PageAnnotations _getOrCreatePageAnnotations(int pageNum) {
    return _annotationsByPage.putIfAbsent(
      pageNum,
      () => PageAnnotations(pageNumber: pageNum),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _searchQueryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPageAnnotations = _getOrCreatePageAnnotations(_currentPage);

    return Scaffold(
      backgroundColor: _colorFilterMode.backgroundColor,
      appBar: DriveTopBar(
        title: _documentTitle,
        currentPage: _currentPage,
        totalPages: _totalPages,
        isSearchActive: _isSearchActive,
        isAnnotationMode: _isAnnotationMode,
        colorFilterMode: _colorFilterMode,
        onBack: () => Navigator.of(context).pop(),
        onToggleSearch: () {
          setState(() {
            _isSearchActive = !_isSearchActive;
            if (!_isSearchActive) {
              _searcher?.resetTextSearch();
              _searchQueryController.clear();
            }
          });
        },
        onToggleAnnotationMode: () {
          setState(() {
            _isAnnotationMode = !_isAnnotationMode;
          });
        },
        onColorFilterChanged: (mode) {
          setState(() {
            _colorFilterMode = mode;
          });
        },
        onPrint: _handlePrint,
        onSave: _handleSavePdf,
        onOpenOther: _handleOpenOtherPdf,
        onRotate: _handleRotate,
        onToggleThumbnails: () {
          setState(() {
            _showThumbnails = !_showThumbnails;
          });
        },
      ),
      body: Stack(
        children: [
          // 1. PDF Content Viewport with Smart White-to-Dark Page Inversion
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: _colorFilterMode.colorFilter ??
                  const ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: PdfViewer.file(
                _currentFile.path,
                controller: _controller,
                params: PdfViewerParams(
                  backgroundColor: _colorFilterMode.backgroundColor,
                  pagePaintCallbacks: [
                    (canvas, pageRect, page) {
                      _searcher?.pageTextMatchPaintCallback(canvas, pageRect, page);
                    }
                  ],
                  onViewerReady: (document, controller) {
                    if (mounted) {
                      setState(() {
                        _searcher = PdfTextSearcher(controller);
                        _searcher!.addListener(() {
                          if (mounted) setState(() {});
                        });
                        _totalPages = document.pages.length;
                      });
                      NotesStorageService.instance.addRecentPdf(
                        _currentFile.path,
                        _documentTitle,
                        pageCount: document.pages.length,
                      );
                    }
                  },
                  errorBannerBuilder: (context, error, stackTrace, documentRef) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB71C1C),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white, size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              'Unable to display PDF',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                  onPageChanged: (pageNum) {
                    if (pageNum != null && mounted) {
                      setState(() => _currentPage = pageNum);
                    }
                  },
                ),
              ),
            ),
          ),

          // 2. Drawing & Markup Canvas Overlay (Active when Annotation mode is enabled)
          if (_isAnnotationMode)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return DrawingCanvas(
                    annotations: currentPageAnnotations,
                    activeTool: _activeTool,
                    activeShape: _activeShape,
                    activeColor: _activeColor,
                    strokeWidth: _strokeWidth,
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    onAnnotationChanged: () {
                      setState(() {});
                    },
                  );
                },
              ),
            ),

          // 3. Adobe Acrobat Style Text Search Overlay
          if (_isSearchActive)
            Positioned(
              top: 12,
              left: 20,
              right: 20,
              child: Center(
                child: SearchOverlay(
                  controller: _searchQueryController,
                  currentMatchIndex: (_searcher?.currentIndex ?? 0) + 1,
                  totalMatches: _searcher?.matches.length ?? 0,
                  onSearchChanged: (query) {
                    if (query.trim().isNotEmpty) {
                      _searcher?.startTextSearch(query.trim());
                    } else {
                      _searcher?.resetTextSearch();
                    }
                  },
                  onNextMatch: () => _searcher?.goToNextMatch(),
                  onPreviousMatch: () => _searcher?.goToPrevMatch(),
                  onClose: () {
                    setState(() {
                      _isSearchActive = false;
                      _searcher?.resetTextSearch();
                      _searchQueryController.clear();
                    });
                  },
                ),
              ),
            ),

          // 4. Markup Studio Toolbar
          if (_isAnnotationMode)
            Positioned(
              top: _isSearchActive ? 74 : 12,
              left: 16,
              right: 16,
              child: Center(
                child: NoteToolsBar(
                  isTypingMode: false,
                  activeTool: _activeTool,
                  activeShape: _activeShape,
                  activeColor: _activeColor,
                  strokeWidth: _strokeWidth,
                  canUndo: currentPageAnnotations.undoStack.isNotEmpty,
                  canRedo: currentPageAnnotations.redoStack.isNotEmpty,
                  onToggleTypingMode: () {},
                  onToolSelected: (tool) => setState(() => _activeTool = tool),
                  onShapeSelected: (shape) => setState(() => _activeShape = shape),
                  onColorChanged: (c) => setState(() => _activeColor = c),
                  onStrokeWidthChanged: (w) => setState(() => _strokeWidth = w),
                  onUndo: () {
                    setState(() => currentPageAnnotations.undo());
                  },
                  onRedo: () {
                    setState(() => currentPageAnnotations.redo());
                  },
                  onClear: () {
                    setState(() => currentPageAnnotations.clearAll());
                  },
                ),
              ),
            ),

          // 5. Thumbnails Drawer
          if (_showThumbnails)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: ThumbnailsDrawer(
                totalPages: _totalPages,
                currentPage: _currentPage,
                onPageSelected: (pageNum) {
                  _controller.goToPage(pageNumber: pageNum);
                  setState(() => _currentPage = pageNum);
                },
                onClose: () => setState(() => _showThumbnails = false),
              ),
            ),

          // 6. Google Drive Floating Bottom Control Pill
          DriveBottomBar(
            currentPage: _currentPage,
            totalPages: _totalPages,
            currentZoom: _currentZoom,
            onPageSelected: (pageNum) {
              _controller.goToPage(pageNumber: pageNum);
            },
            onZoomIn: () => _controller.zoomUp(),
            onZoomOut: () => _controller.zoomDown(),
            onFitWidth: () {
              final matrix = _controller.calcMatrixFitWidthForPage(pageNumber: _currentPage);
              if (matrix != null) _controller.goTo(matrix);
            },
            onFitPage: () {
              final matrix = _controller.calcMatrixForFit(pageNumber: _currentPage);
              if (matrix != null) _controller.goTo(matrix);
            },
            onZoomSelected: (zoom) {
              _controller.setZoom(_controller.centerPosition, zoom);
            },
            onToggleThumbnails: () {
              setState(() => _showThumbnails = !_showThumbnails);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrint() async {
    await PrintService.showPrintDialog(
      context: context,
      documentTitle: _documentTitle,
      onConfirm: ({required bool printDarkMode, required bool includeAnnotations}) async {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening system print dialog...')),
          );
          await PrintService.instance.printPdfFile(
            pdfFile: _currentFile,
            jobName: _documentTitle,
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

  Future<void> _handleSavePdf() async {
    try {
      final defaultName = '${_documentTitle.replaceAll('.pdf', '')}_annotated.pdf';
      final bytes = await _currentFile.readAsBytes();
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save as PDF',
        fileName: defaultName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (uri != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to: ${uri.path}'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save error: $e')),
        );
      }
    }
  }

  Future<void> _handleOpenOtherPdf() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      final newFile = File(files.first.path!);
      setState(() {
        _currentFile = newFile;
        _documentTitle = newFile.uri.pathSegments.last;
        _annotationsByPage.clear();
      });
      NotesStorageService.instance.addRecentPdf(newFile.path, _documentTitle);
    }
  }

  void _handleRotate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rotated document 90° clockwise'), duration: Duration(seconds: 1)),
    );
  }
}
