import 'package:flutter/material.dart';

enum ShapeType {
  rectangle,
  circle,
  line,
  arrow,
}

enum DrawingTool {
  select,
  pen,
  fountainPen,
  highlighter,
  shape,
  text,
  eraser,
}

class StrokePoint {
  final double x;
  final double y;
  final double pressure;

  StrokePoint(this.x, this.y, [this.pressure = 1.0]);

  Offset get offset => Offset(x, y);

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'pressure': pressure,
      };

  factory StrokePoint.fromJson(Map<String, dynamic> json) => StrokePoint(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
        (json['pressure'] as num?)?.toDouble() ?? 1.0,
      );
}

class DrawingStroke {
  final String id;
  final List<StrokePoint> points;
  final Color color;
  final double strokeWidth;
  final bool isHighlighter;
  final bool isCalligraphy;

  DrawingStroke({
    required this.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isHighlighter = false,
    this.isCalligraphy = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points.map((p) => p.toJson()).toList(),
        'color': color.toARGB32(),
        'strokeWidth': strokeWidth,
        'isHighlighter': isHighlighter,
        'isCalligraphy': isCalligraphy,
      };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) => DrawingStroke(
        id: json['id'] as String,
        points: (json['points'] as List)
            .map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
            .toList(),
        color: Color(json['color'] as int),
        strokeWidth: (json['strokeWidth'] as num).toDouble(),
        isHighlighter: json['isHighlighter'] as bool? ?? false,
        isCalligraphy: json['isCalligraphy'] as bool? ?? false,
      );
}

class NoteShape {
  final String id;
  final ShapeType type;
  final Offset start;
  final Offset end;
  final Color color;
  final double strokeWidth;
  final bool isFilled;

  NoteShape({
    required this.id,
    required this.type,
    required this.start,
    required this.end,
    required this.color,
    required this.strokeWidth,
    this.isFilled = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'startX': start.dx,
        'startY': start.dy,
        'endX': end.dx,
        'endY': end.dy,
        'color': color.toARGB32(),
        'strokeWidth': strokeWidth,
        'isFilled': isFilled,
      };

  factory NoteShape.fromJson(Map<String, dynamic> json) => NoteShape(
        id: json['id'] as String,
        type: ShapeType.values.byName(json['type'] as String),
        start: Offset((json['startX'] as num).toDouble(), (json['startY'] as num).toDouble()),
        end: Offset((json['endX'] as num).toDouble(), (json['endY'] as num).toDouble()),
        color: Color(json['color'] as int),
        strokeWidth: (json['strokeWidth'] as num).toDouble(),
        isFilled: json['isFilled'] as bool? ?? false,
      );
}

class TextAnnotation {
  final String id;
  String text;
  Offset position;
  Color color;
  Color backgroundColor;
  double fontSize;

  TextAnnotation({
    required this.id,
    required this.text,
    required this.position,
    this.color = Colors.black,
    this.backgroundColor = const Color(0x33FFEB3B),
    this.fontSize = 16.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'x': position.dx,
        'y': position.dy,
        'color': color.toARGB32(),
        'backgroundColor': backgroundColor.toARGB32(),
        'fontSize': fontSize,
      };

  factory TextAnnotation.fromJson(Map<String, dynamic> json) => TextAnnotation(
        id: json['id'] as String,
        text: json['text'] as String,
        position: Offset((json['x'] as num).toDouble(), (json['y'] as num).toDouble()),
        color: Color(json['color'] as int),
        backgroundColor: Color(json['backgroundColor'] as int),
        fontSize: (json['fontSize'] as num).toDouble(),
      );
}

class PageAnnotations {
  final int pageNumber;
  final List<DrawingStroke> strokes;
  final List<NoteShape> shapes;
  final List<TextAnnotation> textAnnotations;

  // History for Undo / Redo
  final List<Object> undoStack = [];
  final List<Object> redoStack = [];

  PageAnnotations({
    required this.pageNumber,
    List<DrawingStroke>? strokes,
    List<NoteShape>? shapes,
    List<TextAnnotation>? textAnnotations,
  })  : strokes = strokes ?? [],
        shapes = shapes ?? [],
        textAnnotations = textAnnotations ?? [];

  bool get isEmpty => strokes.isEmpty && shapes.isEmpty && textAnnotations.isEmpty;

  void addStroke(DrawingStroke stroke) {
    strokes.add(stroke);
    undoStack.add(stroke);
    redoStack.clear();
  }

  void addShape(NoteShape shape) {
    shapes.add(shape);
    undoStack.add(shape);
    redoStack.clear();
  }

  void addText(TextAnnotation text) {
    textAnnotations.add(text);
    undoStack.add(text);
    redoStack.clear();
  }

  bool undo() {
    if (undoStack.isEmpty) return false;
    final item = undoStack.removeLast();
    if (item is DrawingStroke) {
      strokes.remove(item);
    } else if (item is NoteShape) {
      shapes.remove(item);
    } else if (item is TextAnnotation) {
      textAnnotations.remove(item);
    }
    redoStack.add(item);
    return true;
  }

  bool redo() {
    if (redoStack.isEmpty) return false;
    final item = redoStack.removeLast();
    if (item is DrawingStroke) {
      strokes.add(item);
    } else if (item is NoteShape) {
      shapes.add(item);
    } else if (item is TextAnnotation) {
      textAnnotations.add(item);
    }
    undoStack.add(item);
    return true;
  }

  void eraseAt(Offset point, double radius) {
    strokes.removeWhere((stroke) {
      for (final p in stroke.points) {
        if ((p.offset - point).distance <= radius + stroke.strokeWidth / 2) {
          undoStack.remove(stroke);
          return true;
        }
      }
      return false;
    });

    shapes.removeWhere((shape) {
      final rect = Rect.fromPoints(shape.start, shape.end).inflate(radius);
      if (rect.contains(point)) {
        undoStack.remove(shape);
        return true;
      }
      return false;
    });
  }

  void clearAll() {
    strokes.clear();
    shapes.clear();
    textAnnotations.clear();
    undoStack.clear();
    redoStack.clear();
  }

  Map<String, dynamic> toJson() => {
        'pageNumber': pageNumber,
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'shapes': shapes.map((s) => s.toJson()).toList(),
        'textAnnotations': textAnnotations.map((t) => t.toJson()).toList(),
      };

  factory PageAnnotations.fromJson(Map<String, dynamic> json) => PageAnnotations(
        pageNumber: json['pageNumber'] as int,
        strokes: (json['strokes'] as List?)
                ?.map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        shapes: (json['shapes'] as List?)
                ?.map((s) => NoteShape.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        textAnnotations: (json['textAnnotations'] as List?)
                ?.map((t) => TextAnnotation.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
