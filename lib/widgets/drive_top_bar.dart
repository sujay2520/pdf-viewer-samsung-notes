import 'package:flutter/material.dart';
import '../models/color_filter_mode.dart';

class DriveTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int currentPage;
  final int totalPages;
  final bool isSearchActive;
  final bool isAnnotationMode;
  final PdfColorFilterMode colorFilterMode;
  final VoidCallback onBack;
  final VoidCallback onToggleSearch;
  final VoidCallback onToggleAnnotationMode;
  final ValueChanged<PdfColorFilterMode> onColorFilterChanged;
  final VoidCallback onPrint;
  final VoidCallback onSave;
  final VoidCallback onOpenOther;
  final VoidCallback onRotate;
  final VoidCallback onToggleThumbnails;

  const DriveTopBar({
    super.key,
    required this.title,
    required this.currentPage,
    required this.totalPages,
    required this.isSearchActive,
    required this.isAnnotationMode,
    required this.colorFilterMode,
    required this.onBack,
    required this.onToggleSearch,
    required this.onToggleAnnotationMode,
    required this.onColorFilterChanged,
    required this.onPrint,
    required this.onSave,
    required this.onOpenOther,
    required this.onRotate,
    required this.onToggleThumbnails,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      elevation: 1,
      scrolledUnderElevation: 2,
      backgroundColor: isDark ? const Color(0xFF1E1F22) : const Color(0xFFF8F9FA),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back to Notes Library',
        onPressed: onBack,
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          // Google Drive / Samsung icon indicator
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (totalPages > 0)
                  Text(
                    'Page $currentPage of $totalPages',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // 1. Text Search Button
        IconButton(
          icon: Icon(
            Icons.search,
            color: isSearchActive ? theme.colorScheme.primary : null,
          ),
          tooltip: 'Find in Page (Ctrl+F)',
          onPressed: onToggleSearch,
        ),

        // 2. White Pages to Dark Theme Toggle (Drive / Samsung Night Inversion)
        PopupMenuButton<PdfColorFilterMode>(
          tooltip: 'Page Dark Theme / Inversion',
          icon: Icon(
            colorFilterMode.icon,
            color: colorFilterMode != PdfColorFilterMode.original
                ? Colors.amber.shade700
                : null,
          ),
          initialValue: colorFilterMode,
          onSelected: onColorFilterChanged,
          itemBuilder: (context) {
            return PdfColorFilterMode.values.map((mode) {
              return PopupMenuItem<PdfColorFilterMode>(
                value: mode,
                child: Row(
                  children: [
                    Icon(
                      mode.icon,
                      size: 20,
                      color: mode == colorFilterMode ? theme.colorScheme.primary : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      mode.displayName,
                      style: TextStyle(
                        fontWeight: mode == colorFilterMode ? FontWeight.bold : FontWeight.normal,
                        color: mode == colorFilterMode ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
        ),

        // 3. Samsung Notes Markup / Draw Mode Toggle
        IconButton(
          icon: Icon(
            Icons.edit_outlined,
            color: isAnnotationMode ? theme.colorScheme.primary : null,
          ),
          style: isAnnotationMode
              ? IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                )
              : null,
          tooltip: 'Samsung Notes Annotate / Draw',
          onPressed: onToggleAnnotationMode,
        ),

        // 4. Samsung Print Button
        IconButton(
          icon: const Icon(Icons.print_outlined),
          tooltip: 'Samsung Print (Ctrl+P)',
          onPressed: onPrint,
        ),

        // 5. Save as PDF Button
        IconButton(
          icon: const Icon(Icons.save_outlined),
          tooltip: 'Save as PDF (Ctrl+S)',
          onPressed: onSave,
        ),

        // 6. Overflow Menu
        PopupMenuButton<String>(
          tooltip: 'More Options',
          onSelected: (value) {
            switch (value) {
              case 'open':
                onOpenOther();
                break;
              case 'rotate':
                onRotate();
                break;
              case 'thumbnails':
                onToggleThumbnails();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'thumbnails',
              child: Row(
                children: [
                  Icon(Icons.grid_view, size: 20),
                  SizedBox(width: 12),
                  Text('Page Thumbnails Grid'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'rotate',
              child: Row(
                children: [
                  Icon(Icons.rotate_right, size: 20),
                  SizedBox(width: 12),
                  Text('Rotate Clockwise 90°'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.folder_open, size: 20),
                  SizedBox(width: 12),
                  Text('Open Another PDF...'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
