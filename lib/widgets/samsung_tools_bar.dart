import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/annotation_model.dart';

class SamsungToolsBar extends StatelessWidget {
  final DrawingTool activeTool;
  final ShapeType activeShape;
  final Color activeColor;
  final double strokeWidth;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<DrawingTool> onToolSelected;
  final ValueChanged<ShapeType> onShapeSelected;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;

  const SamsungToolsBar({
    super.key,
    required this.activeTool,
    required this.activeShape,
    required this.activeColor,
    required this.strokeWidth,
    required this.canUndo,
    required this.canRedo,
    required this.onToolSelected,
    required this.onShapeSelected,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
  });

  static const List<Color> _palette = [
    Colors.black,
    Color(0xFF1976D2), // Blue
    Color(0xFFD32F2F), // Red
    Color(0xFF388E3C), // Green
    Color(0xFFFBC02D), // Yellow
    Color(0xFFF57C00), // Orange
    Color(0xFF7B1FA2), // Purple
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      elevation: 6,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(28),
      color: isDark ? const Color(0xFF2C2D30) : Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Pan / Hand tool
              _buildToolButton(
                tool: DrawingTool.select,
                icon: Icons.pan_tool_outlined,
                tooltip: 'Pan / Navigate',
                theme: theme,
              ),

              // 2. Ballpoint Pen
              _buildToolButton(
                tool: DrawingTool.pen,
                icon: Icons.edit,
                tooltip: 'Ballpoint Pen',
                theme: theme,
              ),

              // 3. Fountain Pen / Calligraphy
              _buildToolButton(
                tool: DrawingTool.fountainPen,
                icon: Icons.draw_outlined,
                tooltip: 'Fountain / Calligraphy Pen',
                theme: theme,
              ),

              // 4. Highlighter
              _buildToolButton(
                tool: DrawingTool.highlighter,
                icon: Icons.highlight,
                tooltip: 'Highlighter',
                theme: theme,
              ),

              // 5. Shapes menu
              _buildShapeMenuButton(context, theme),

              // 6. Text Note Tool
              _buildToolButton(
                tool: DrawingTool.text,
                icon: Icons.text_fields,
                tooltip: 'Insert Text Note',
                theme: theme,
              ),

              // 7. Eraser
              _buildToolButton(
                tool: DrawingTool.eraser,
                icon: Icons.auto_fix_normal_outlined,
                tooltip: 'Eraser',
                theme: theme,
              ),

              const SizedBox(
                height: 22,
                child: VerticalDivider(width: 14, thickness: 1),
              ),

              // 8. Active Color & Palette button
              GestureDetector(
                onTap: () => _showColorPickerDialog(context),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white70 : Colors.black26,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 9. Stroke Width Slider Popover
              IconButton(
                icon: Icon(
                  Icons.line_weight,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                tooltip: 'Stroke Thickness: ${strokeWidth.toInt()}px',
                onPressed: () => _showStrokeWidthDialog(context),
              ),

              const SizedBox(
                height: 22,
                child: VerticalDivider(width: 14, thickness: 1),
              ),

              // 10. Undo button
              IconButton(
                icon: const Icon(Icons.undo, size: 20),
                tooltip: 'Undo',
                onPressed: canUndo ? onUndo : null,
              ),

              // 11. Redo button
              IconButton(
                icon: const Icon(Icons.redo, size: 20),
                tooltip: 'Redo',
                onPressed: canRedo ? onRedo : null,
              ),

              // 12. Clear All button
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Clear Annotations on Page',
                onPressed: onClear,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required DrawingTool tool,
    required IconData icon,
    required String tooltip,
    required ThemeData theme,
  }) {
    final isSelected = activeTool == tool;
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      style: isSelected
          ? IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.primary,
            )
          : null,
      onPressed: () => onToolSelected(tool),
    );
  }

  Widget _buildShapeMenuButton(BuildContext context, ThemeData theme) {
    final isSelected = activeTool == DrawingTool.shape;
    IconData shapeIcon;
    switch (activeShape) {
      case ShapeType.rectangle:
        shapeIcon = Icons.crop_square;
        break;
      case ShapeType.circle:
        shapeIcon = Icons.circle_outlined;
        break;
      case ShapeType.line:
        shapeIcon = Icons.horizontal_rule;
        break;
      case ShapeType.arrow:
        shapeIcon = Icons.arrow_right_alt;
        break;
    }

    return PopupMenuButton<ShapeType>(
      tooltip: 'Shapes',
      initialValue: activeShape,
      onSelected: (shape) {
        onShapeSelected(shape);
        onToolSelected(DrawingTool.shape);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          shapeIcon,
          size: 20,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: ShapeType.rectangle,
          child: Row(children: [Icon(Icons.crop_square), SizedBox(width: 10), Text('Rectangle')]),
        ),
        const PopupMenuItem(
          value: ShapeType.circle,
          child: Row(children: [Icon(Icons.circle_outlined), SizedBox(width: 10), Text('Circle / Oval')]),
        ),
        const PopupMenuItem(
          value: ShapeType.line,
          child: Row(children: [Icon(Icons.horizontal_rule), SizedBox(width: 10), Text('Straight Line')]),
        ),
        const PopupMenuItem(
          value: ShapeType.arrow,
          child: Row(children: [Icon(Icons.arrow_right_alt), SizedBox(width: 10), Text('Arrow')]),
        ),
      ],
    );
  }

  void _showColorPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        Color pickerColor = activeColor;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select Tool Color'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick Palette Swatches
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _palette.map((c) {
                    return GestureDetector(
                      onTap: () {
                        onColorChanged(c);
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade400, width: 2),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // Full Color Picker
                ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: (c) => pickerColor = c,
                  pickerAreaHeightPercent: 0.5,
                  enableAlpha: true,
                  displayThumbColor: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                onColorChanged(pickerColor);
                Navigator.of(context).pop();
              },
              child: const Text('Apply Color'),
            ),
          ],
        );
      },
    );
  }

  void _showStrokeWidthDialog(BuildContext context) {
    double current = strokeWidth;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Stroke Thickness'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${current.toInt()} px',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    min: 1,
                    max: 30,
                    value: current,
                    onChanged: (val) => setState(() => current = val),
                  ),
                  const SizedBox(height: 10),
                  // Visual Preview Dot
                  Center(
                    child: Container(
                      width: current,
                      height: current,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    onStrokeWidthChanged(current);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
