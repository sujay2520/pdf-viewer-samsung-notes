import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/annotation_model.dart';

class NoteToolsBar extends StatelessWidget {
  final bool isTypingMode;
  final DrawingTool activeTool;
  final ShapeType activeShape;
  final Color activeColor;
  final double strokeWidth;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onToggleTypingMode;
  final ValueChanged<DrawingTool> onToolSelected;
  final ValueChanged<ShapeType> onShapeSelected;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;

  const NoteToolsBar({
    super.key,
    this.isTypingMode = false,
    required this.activeTool,
    required this.activeShape,
    required this.activeColor,
    required this.strokeWidth,
    required this.canUndo,
    required this.canRedo,
    required this.onToggleTypingMode,
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
              // 1. Text / Typing Mode Toggle (First-class typing on lines)
              _buildTypeModeButton(theme),

              const SizedBox(
                height: 22,
                child: VerticalDivider(width: 14, thickness: 1),
              ),

              // 2. Ballpoint Pen
              _buildToolButton(
                tool: DrawingTool.pen,
                icon: Icons.edit,
                tooltip: 'Pen / Freehand Draw',
                theme: theme,
              ),

              // 3. Fountain Pen / Calligraphy
              _buildToolButton(
                tool: DrawingTool.fountainPen,
                icon: Icons.draw_outlined,
                tooltip: 'Calligraphy Pen',
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

              // 6. Eraser
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

              // 7. Active Color & Palette button
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

              // 8. Stroke Width Slider Popover
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

              // 9. Undo button
              IconButton(
                icon: const Icon(Icons.undo, size: 20),
                tooltip: 'Undo',
                onPressed: canUndo ? onUndo : null,
              ),

              // 10. Redo button
              IconButton(
                icon: const Icon(Icons.redo, size: 20),
                tooltip: 'Redo',
                onPressed: canRedo ? onRedo : null,
              ),

              // 11. Clear All button
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

  Widget _buildTypeModeButton(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isTypingMode ? theme.colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(
          Icons.keyboard,
          size: 18,
          color: isTypingMode ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        ),
        label: Text(
          'Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isTypingMode ? FontWeight.bold : FontWeight.w500,
            color: isTypingMode ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        onPressed: onToggleTypingMode,
      ),
    );
  }

  Widget _buildToolButton({
    required DrawingTool tool,
    required IconData icon,
    required String tooltip,
    required ThemeData theme,
  }) {
    final isSelected = !isTypingMode && activeTool == tool;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onToolSelected(tool),
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildShapeMenuButton(BuildContext context, ThemeData theme) {
    final isShapeSelected = !isTypingMode && activeTool == DrawingTool.shape;

    return PopupMenuButton<ShapeType>(
      tooltip: 'Draw Geometric Shapes',
      initialValue: activeShape,
      onSelected: (shape) {
        onShapeSelected(shape);
        onToolSelected(DrawingTool.shape);
      },
      itemBuilder: (context) => [
        _buildShapeMenuItem(ShapeType.rectangle, 'Rectangle', Icons.crop_square),
        _buildShapeMenuItem(ShapeType.circle, 'Circle / Ellipse', Icons.circle_outlined),
        _buildShapeMenuItem(ShapeType.line, 'Straight Line', Icons.horizontal_rule),
        _buildShapeMenuItem(ShapeType.arrow, 'Directional Arrow', Icons.arrow_right_alt),
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isShapeSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getShapeIcon(activeShape),
          size: 20,
          color: isShapeSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  PopupMenuItem<ShapeType> _buildShapeMenuItem(ShapeType type, String title, IconData icon) {
    return PopupMenuItem<ShapeType>(
      value: type,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Text(title),
        ],
      ),
    );
  }

  IconData _getShapeIcon(ShapeType shape) {
    switch (shape) {
      case ShapeType.rectangle:
        return Icons.crop_square;
      case ShapeType.circle:
        return Icons.circle_outlined;
      case ShapeType.line:
        return Icons.horizontal_rule;
      case ShapeType.arrow:
        return Icons.arrow_right_alt;
    }
  }

  void _showColorPickerDialog(BuildContext context) {
    Color tempColor = activeColor;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select Color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick presets palette
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _palette.map((c) {
                    final isCurrent = c.toARGB32() == activeColor.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        onColorChanged(c);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCurrent ? Colors.blueAccent : Colors.grey.shade400,
                            width: isCurrent ? 3 : 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                          ],
                        ),
                        child: isCurrent
                            ? Icon(
                                Icons.check,
                                size: 20,
                                color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // Full HSV Color Picker
                ColorPicker(
                  pickerColor: tempColor,
                  onColorChanged: (c) => tempColor = c,
                  labelTypes: const [],
                  pickerAreaHeightPercent: 0.6,
                  enableAlpha: false,
                  displayThumbColor: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                onColorChanged(tempColor);
                Navigator.of(ctx).pop();
              },
              child: const Text('Apply Color'),
            ),
          ],
        );
      },
    );
  }

  void _showStrokeWidthDialog(BuildContext context) {
    double tempWidth = strokeWidth;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Pen Thickness', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${tempWidth.toInt()} px',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    Slider(
                      value: tempWidth,
                      min: 1.0,
                      max: 24.0,
                      divisions: 23,
                      onChanged: (val) {
                        setDialogState(() => tempWidth = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    // Visual stroke preview
                    Center(
                      child: Container(
                        width: 180,
                        height: 30,
                        alignment: Alignment.center,
                        child: Container(
                          height: tempWidth,
                          decoration: BoxDecoration(
                            color: activeColor,
                            borderRadius: BorderRadius.circular(tempWidth / 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () {
                    onStrokeWidthChanged(tempWidth);
                    Navigator.of(ctx).pop();
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

// Backward compatibility alias
typedef SamsungToolsBar = NoteToolsBar;
