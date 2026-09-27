import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/note_model.dart';

class NotePageBackground extends StatelessWidget {
  final NotePageTemplate template;
  final bool isDark;
  final Widget? child;

  const NotePageBackground({
    super.key,
    required this.template,
    this.isDark = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1E1F22) : Colors.white;

    return Container(
      color: bgColor,
      child: CustomPaint(
        painter: _TemplatePainter(template: template, isDark: isDark),
        child: child,
      ),
    );
  }
}

class _TemplatePainter extends CustomPainter {
  final NotePageTemplate template;
  final bool isDark;

  _TemplatePainter({required this.template, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final ruleColor = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : const Color(0xFFE2E8F0);
    final marginColor = isDark
        ? Colors.red.shade300.withValues(alpha: 0.3)
        : Colors.red.shade200;

    switch (template) {
      case NotePageTemplate.blank:
        break;

      case NotePageTemplate.ruled:
        final linePaint = Paint()
          ..color = ruleColor
          ..strokeWidth = 1.0;
        const lineSpacing = 32.0;

        for (double y = 48.0; y < size.height - 30; y += lineSpacing) {
          canvas.drawLine(Offset(24, y), Offset(size.width - 24, y), linePaint);
        }

        // Left vertical margin line
        final marginPaint = Paint()
          ..color = marginColor
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(60, 20), Offset(60, size.height - 20), marginPaint);
        break;

      case NotePageTemplate.grid:
        final gridPaint = Paint()
          ..color = ruleColor
          ..strokeWidth = 0.8;
        const gridSize = 24.0;

        for (double x = 20.0; x < size.width - 20; x += gridSize) {
          canvas.drawLine(Offset(x, 20), Offset(x, size.height - 20), gridPaint);
        }
        for (double y = 20.0; y < size.height - 20; y += gridSize) {
          canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), gridPaint);
        }
        break;

      case NotePageTemplate.dotGrid:
        final dotPaint = Paint()
          ..color = isDark ? Colors.white.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.2)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        const dotSpacing = 24.0;

        for (double x = 24.0; x < size.width - 20; x += dotSpacing) {
          for (double y = 24.0; y < size.height - 20; y += dotSpacing) {
            canvas.drawPoints(PointMode.points, [Offset(x, y)], dotPaint);
          }
        }
        break;

      case NotePageTemplate.cornell:
        final dividerPaint = Paint()
          ..color = isDark ? Colors.white24 : Colors.blueGrey.shade200
          ..strokeWidth = 1.5;

        // Title header line
        canvas.drawLine(Offset(20, 70), Offset(size.width - 20, 70), dividerPaint);

        // Cue column separator line
        const cueWidth = 160.0;
        canvas.drawLine(
          const Offset(cueWidth, 70),
          Offset(cueWidth, size.height - 90),
          dividerPaint,
        );

        // Summary footer line
        canvas.drawLine(
          Offset(20, size.height - 90),
          Offset(size.width - 20, size.height - 90),
          dividerPaint,
        );

        // Ruling lines in main notes section
        final linePaint = Paint()
          ..color = ruleColor
          ..strokeWidth = 0.8;
        for (double y = 96.0; y < size.height - 100; y += 26.0) {
          canvas.drawLine(Offset(cueWidth + 8, y), Offset(size.width - 20, y), linePaint);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _TemplatePainter oldDelegate) {
    return oldDelegate.template != template || oldDelegate.isDark != isDark;
  }
}
