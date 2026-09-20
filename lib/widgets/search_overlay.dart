import 'package:flutter/material.dart';

class SearchOverlay extends StatelessWidget {
  final TextEditingController controller;
  final int currentMatchIndex;
  final int totalMatches;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onNextMatch;
  final VoidCallback onPreviousMatch;
  final VoidCallback onClose;

  const SearchOverlay({
    super.key,
    required this.controller,
    required this.currentMatchIndex,
    required this.totalMatches,
    required this.onSearchChanged,
    required this.onNextMatch,
    required this.onPreviousMatch,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: isDark ? const Color(0xFF2B2D31) : Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Find in document...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            if (controller.text.isNotEmpty) ...[
              Text(
                totalMatches > 0
                    ? '$currentMatchIndex of $totalMatches'
                    : '0 matches',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: totalMatches > 0
                      ? theme.colorScheme.onSurfaceVariant
                      : Colors.red.shade400,
                  fontSize: 12,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                tooltip: 'Previous Match (Shift+Enter)',
                onPressed: totalMatches > 0 ? onPreviousMatch : null,
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                tooltip: 'Next Match (Enter)',
                onPressed: totalMatches > 0 ? onNextMatch : null,
              ),
            ],
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Close Search (Esc)',
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
