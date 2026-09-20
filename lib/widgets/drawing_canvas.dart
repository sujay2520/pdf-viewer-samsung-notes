import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/annotation_model.dart';

class DrawingCanvas extends StatefulWidget {
  final PageAnnotations annotations;
  final DrawingTool activeTool;
  final ShapeType activeShape;
  final Color activeColor;
  final double strokeWidth;
  final Size size;
  final VoidCallback onAnnotationChanged;

  const DrawingCanvas({
    super.key,
    required this.annotations,
    required this.activeTool,
    required this.activeShape,
    required this.activeColor,
    required this.strokeWidth,
    required this.size,
    required this.onAnnotationChanged,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<StrokePoint>? _currentStrokePoints;
  Offset? _shapeStart;
  Offset? _shapeEnd;

  @override
  Widget build(BuildContext context) {
    final isDrawingActive = widget.activeTool != DrawingTool.select;

    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: Stack(
        children: [
          // 1. Gesture Detector for drawing when a drawing tool is active
          Positioned.fill(
            child: GestureDetector(
              behavior: isDrawingActive
                  ? HitTestBehavior.opaque
                  : HitTestBehavior.translucent,
              onPanStart: isDrawingActive ? _onPanStart : null,
              onPanUpdate: isDrawingActive ? _onPanUpdate : null,
              onPanEnd: isDrawingActive ? _onPanEnd : null,
              child: CustomPaint(
                size: widget.size,
                painter: _CanvasPainter(
                  annotations: widget.annotations,
                  currentPoints: _currentStrokePoints,
                  currentTool: widget.activeTool,
                  currentColor: widget.activeColor,
                  currentStrokeWidth: widget.strokeWidth,
                  shapeStart: _shapeStart,
                  shapeEnd: _shapeEnd,
                  activeShape: widget.activeShape,
                ),
              ),
            ),
          ),

          // 2. Text Annotations overlay
          ...widget.annotations.textAnnotations.map((t) {
            return Positioned(
              left: t.position.dx,
              top: t.position.dy,
              child: GestureDetector(
                onTap: () => _editTextAnnotation(t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: t.color.withValues(alpha: 0.4), width: 1),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    t.text,
                    style: TextStyle(
                      color: t.color,
                      fontSize: t.fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final localPos = details.localPosition;

    if (widget.activeTool == DrawingTool.eraser) {
      widget.annotations.eraseAt(localPos, widget.strokeWidth * 1.5);
      widget.onAnnotationChanged();
      setState(() {});
      return;
    }

    if (widget.activeTool == DrawingTool.text) {
      _promptAddTextAnnotation(localPos);
      return;
    }

    if (widget.activeTool == DrawingTool.shape) {
      setState(() {
        _shapeStart = localPos;
        _shapeEnd = localPos;
      });
      return;
    }

    // Pen, Fountain Pen, Highlighter
    setState(() {
      _currentStrokePoints = [StrokePoint(localPos.dx, localPos.dy)];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final localPos = details.localPosition;

    if (widget.activeTool == DrawingTool.eraser) {
      widget.annotations.eraseAt(localPos, widget.strokeWidth * 1.5);
      widget.onAnnotationChanged();
      setState(() {});
      return;
    }

    if (widget.activeTool == DrawingTool.shape) {
      setState(() {
        _shapeEnd = localPos;
      });
      return;
    }

    if (_currentStrokePoints != null) {
      setState(() {
        _currentStrokePoints!.add(StrokePoint(localPos.dx, localPos.dy));
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.activeTool == DrawingTool.shape && _shapeStart != null && _shapeEnd != null) {
      if ((_shapeStart! - _shapeEnd!).distance > 5) {
        final shape = NoteShape(
          id: const Uuid().v4(),
          type: widget.activeShape,
          start: _shapeStart!,
          end: _shapeEnd!,
          color: widget.activeColor,
          strokeWidth: widget.strokeWidth,
        );
        widget.annotations.addShape(shape);
        widget.onAnnotationChanged();
      }
      setState(() {
        _shapeStart = null;
        _shapeEnd = null;
      });
      return;
    }

    if (_currentStrokePoints != null && _currentStrokePoints!.length > 1) {
      final isHighlighter = widget.activeTool == DrawingTool.highlighter;
      final isCalligraphy = widget.activeTool == DrawingTool.fountainPen;

      final stroke = DrawingStroke(
        id: const Uuid().v4(),
        points: List.from(_currentStrokePoints!),
        color: isHighlighter ? widget.activeColor.withValues(alpha: 0.38) : widget.activeColor,
        strokeWidth: isHighlighter ? widget.strokeWidth * 2.5 : widget.strokeWidth,
        isHighlighter: isHighlighter,
        isCalligraphy: isCalligraphy,
      );
      widget.annotations.addStroke(stroke);
      widget.onAnnotationChanged();
    }

    setState(() {
      _currentStrokePoints = null;
    });
  }

  void _promptAddTextAnnotation(Offset pos) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Text Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter your note...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final textNote = TextAnnotation(
                  id: const Uuid().v4(),
                  text: controller.text.trim(),
                  position: pos,
                  color: widget.activeColor == Colors.white ? Colors.black : widget.activeColor,
                  backgroundColor: widget.activeColor == Colors.white
                      ? const Color(0x33FFEB3B)
                      : widget.activeColor.withValues(alpha: 0.18),
                  fontSize: 14,
                );
                widget.annotations.addText(textNote);
                widget.onAnnotationChanged();
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add Note'),
          ),
        ],
      ),
    );
  }

  void _editTextAnnotation(TextAnnotation note) {
    final controller = TextEditingController(text: note.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Note',
            onPressed: () {
              widget.annotations.textAnnotations.remove(note);
              widget.onAnnotationChanged();
              setState(() {});
              Navigator.of(context).pop();
            },
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              note.text = controller.text.trim();
              widget.onAnnotationChanged();
              setState(() {});
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final PageAnnotations annotations;
  final List<StrokePoint>? currentPoints;
  final DrawingTool currentTool;
  final Color currentColor;
  final double currentStrokeWidth;
  final Offset? shapeStart;
  final Offset? shapeEnd;
  final ShapeType activeShape;

  _CanvasPainter({
    required this.annotations,
    required this.currentPoints,
    required this.currentTool,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.shapeStart,
    required this.shapeEnd,
    required this.activeShape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw existing strokes
    for (final stroke in annotations.strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.strokeWidth, stroke.isHighlighter);
    }

    // 2. Draw existing shapes
    for (final shape in annotations.shapes) {
      _drawShape(canvas, shape.type, shape.start, shape.end, shape.color, shape.strokeWidth);
    }

    // 3. Draw in-progress live stroke
    if (currentPoints != null && currentPoints!.isNotEmpty) {
      final isHighlighter = currentTool == DrawingTool.highlighter;
      final color = isHighlighter ? currentColor.withValues(alpha: 0.38) : currentColor;
      final width = isHighlighter ? currentStrokeWidth * 2.5 : currentStrokeWidth;
      _drawStroke(canvas, currentPoints!, color, width, isHighlighter);
    }

    // 4. Draw in-progress live shape
    if (shapeStart != null && shapeEnd != null) {
      _drawShape(canvas, activeShape, shapeStart!, shapeEnd!, currentColor, currentStrokeWidth);
    }
  }

  void _drawStroke(
    Canvas canvas,
    List<StrokePoint> points,
    Color color,
    double width,
    bool isHighlighter,
  ) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (isHighlighter) {
      paint.blendMode = BlendMode.srcOver;
    }

    if (points.length == 1) {
      canvas.drawCircle(points.first.offset, width / 2, paint..style = PaintingStyle.fill);
      return;
    }

    final path = Path();
    path.moveTo(points.first.x, points.first.y);

    for (int i = 1; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      path.quadraticBezierTo(p0.x, p0.y, (p0.x + p1.x) / 2, (p0.y + p1.y) / 2);
    }
    path.lineTo(points.last.x, points.last.y);
    canvas.drawPath(path, paint);
  }

  void _drawShape(
    Canvas canvas,
    ShapeType type,
    Offset start,
    Offset end,
    Color color,
    double width,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (type) {
      case ShapeType.rectangle:
        canvas.drawRect(Rect.fromPoints(start, end), paint);
        break;

      case ShapeType.circle:
        canvas.drawOval(Rect.fromPoints(start, end), paint);
        break;

      case ShapeType.line:
        canvas.drawLine(start, end, paint);
        break;

      case ShapeType.arrow:
        canvas.drawLine(start, end, paint);
        // Draw arrow head
        final delta = end - start;
        final angle = delta.direction;
        const arrowLength = 16.0;
        const arrowAngle = 0.45; // ~25 deg

        final p1 = end - Offset.fromDirection(angle - arrowAngle, arrowLength);
        final p2 = end - Offset.fromDirection(angle + arrowAngle, arrowLength);

        final arrowHeadPath = Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(p1.dx, p1.dy)
          ..moveTo(end.dx, end.dy)
          ..lineTo(p2.dx, p2.dy);
        canvas.drawPath(arrowHeadPath, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
