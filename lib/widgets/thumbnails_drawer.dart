import 'package:flutter/material.dart';

class ThumbnailsDrawer extends StatelessWidget {
  final int totalPages;
  final int currentPage;
  final ValueChanged<int> onPageSelected;
  final VoidCallback onClose;

  const ThumbnailsDrawer({
    super.key,
    required this.totalPages,
    required this.currentPage,
    required this.onPageSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F22) : const Color(0xFFF1F3F4),
        border: Border(
          left: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.grid_view, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Pages ($totalPages)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Close Thumbnails',
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Pages list / grid
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: totalPages,
              itemBuilder: (context, index) {
                final pageNum = index + 1;
                final isSelected = pageNum == currentPage;

                return GestureDetector(
                  onTap: () => onPageSelected(pageNum),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2B2D31) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white12 : Colors.black12),
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isSelected ? 0.2 : 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Page preview dummy layout
                        AspectRatio(
                          aspectRatio: 1 / 1.414, // A4 ratio
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 32,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : (isDark ? Colors.white38 : Colors.black38),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 60,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white12 : Colors.black12,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 45,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white12 : Colors.black12,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Page number label
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer
                                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$pageNum',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
