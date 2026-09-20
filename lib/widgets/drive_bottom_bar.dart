import 'package:flutter/material.dart';

class DriveBottomBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final double currentZoom;
  final ValueChanged<int> onPageSelected;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitWidth;
  final VoidCallback onFitPage;
  final ValueChanged<double> onZoomSelected;
  final VoidCallback onToggleThumbnails;

  const DriveBottomBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.currentZoom,
    required this.onPageSelected,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitWidth,
    required this.onFitPage,
    required this.onZoomSelected,
    required this.onToggleThumbnails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 16, right: 16),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            elevation: 8,
            shadowColor: Colors.black45,
            borderRadius: BorderRadius.circular(32),
            color: isDark ? const Color(0xFF28292A) : Colors.white,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              constraints: const BoxConstraints(maxWidth: 620),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Thumbnails toggle
                  IconButton(
                    icon: const Icon(Icons.view_sidebar_outlined, size: 20),
                    tooltip: 'Page Thumbnails',
                    onPressed: onToggleThumbnails,
                  ),

                  // 2. Previous page
                  IconButton(
                    icon: const Icon(Icons.navigate_before, size: 22),
                    tooltip: 'Previous Page',
                    onPressed: currentPage > 1 ? () => onPageSelected(currentPage - 1) : null,
                  ),

                  // Page indicator & Scrubber Popover
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showPageScrubberDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$currentPage / ${totalPages > 0 ? totalPages : 1}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  // 3. Next page
                  IconButton(
                    icon: const Icon(Icons.navigate_next, size: 22),
                    tooltip: 'Next Page',
                    onPressed:
                        currentPage < totalPages ? () => onPageSelected(currentPage + 1) : null,
                  ),

                  const SizedBox(
                    height: 24,
                    child: VerticalDivider(width: 16, thickness: 1),
                  ),

                  // 4. Zoom Out
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    tooltip: 'Zoom Out',
                    onPressed: onZoomOut,
                  ),

                  // 5. Zoom Percentage Popup
                  PopupMenuButton<double>(
                    tooltip: 'Zoom Level',
                    onSelected: onZoomSelected,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: Text(
                        '${(currentZoom * 100).round()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    itemBuilder: (context) => [
                      _buildZoomMenuItem(0.5, '50%'),
                      _buildZoomMenuItem(0.75, '75%'),
                      _buildZoomMenuItem(1.0, '100%'),
                      _buildZoomMenuItem(1.25, '125%'),
                      _buildZoomMenuItem(1.5, '150%'),
                      _buildZoomMenuItem(2.0, '200%'),
                      _buildZoomMenuItem(3.0, '300%'),
                    ],
                  ),

                  // 6. Zoom In
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: 'Zoom In',
                    onPressed: onZoomIn,
                  ),

                  const SizedBox(
                    height: 24,
                    child: VerticalDivider(width: 16, thickness: 1),
                  ),

                  // 7. Fit Width
                  IconButton(
                    icon: const Icon(Icons.fit_screen_outlined, size: 18),
                    tooltip: 'Fit to Width',
                    onPressed: onFitWidth,
                  ),

                  // 8. Fit Page
                  IconButton(
                    icon: const Icon(Icons.fullscreen, size: 20),
                    tooltip: 'Fit to Page',
                    onPressed: onFitPage,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<double> _buildZoomMenuItem(double value, String label) {
    return PopupMenuItem<double>(
      value: value,
      child: Text(label),
    );
  }

  void _showPageScrubberDialog(BuildContext context) {
    int selected = currentPage;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Jump to Page'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Page $selected of $totalPages',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    min: 1,
                    max: totalPages > 0 ? totalPages.toDouble() : 1,
                    divisions: totalPages > 1 ? totalPages - 1 : 1,
                    value: selected.toDouble().clamp(1.0, totalPages > 0 ? totalPages.toDouble() : 1.0),
                    onChanged: (val) {
                      setState(() => selected = val.round());
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onPageSelected(selected);
                  },
                  child: const Text('Jump'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
