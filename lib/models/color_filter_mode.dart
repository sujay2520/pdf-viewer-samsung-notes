import 'package:flutter/material.dart';

enum PdfColorFilterMode {
  original,
  oledDark,
  softMidnight,
  warmSepia,
  highContrast,
}

extension PdfColorFilterModeExtension on PdfColorFilterMode {
  String get displayName {
    switch (this) {
      case PdfColorFilterMode.original:
        return 'Original (Light)';
      case PdfColorFilterMode.oledDark:
        return 'OLED Dark (Inverted)';
      case PdfColorFilterMode.softMidnight:
        return 'Midnight Charcoal';
      case PdfColorFilterMode.warmSepia:
        return 'Warm Sepia Comfort';
      case PdfColorFilterMode.highContrast:
        return 'High Contrast Dark';
    }
  }

  IconData get icon {
    switch (this) {
      case PdfColorFilterMode.original:
        return Icons.wb_sunny_outlined;
      case PdfColorFilterMode.oledDark:
        return Icons.dark_mode;
      case PdfColorFilterMode.softMidnight:
        return Icons.bedtime_outlined;
      case PdfColorFilterMode.warmSepia:
        return Icons.menu_book_outlined;
      case PdfColorFilterMode.highContrast:
        return Icons.contrast;
    }
  }

  ColorFilter? get colorFilter {
    switch (this) {
      case PdfColorFilterMode.original:
        return null;

      case PdfColorFilterMode.oledDark:
        // Pure inversion: white -> black, black -> white
        return const ColorFilter.matrix([
          -1.0,  0.0,  0.0, 0.0, 255.0,
           0.0, -1.0,  0.0, 0.0, 255.0,
           0.0,  0.0, -1.0, 0.0, 255.0,
           0.0,  0.0,  0.0, 1.0,   0.0,
        ]);

      case PdfColorFilterMode.softMidnight:
        // Maps white (#FFFFFF) to soft charcoal (#1E1F22)
        // and black (#000000) to soft off-white (#E2E8F0)
        return const ColorFilter.matrix([
          -0.769,  0.0,    0.0,   0.0, 226.0,
           0.0,   -0.769,  0.0,   0.0, 228.0,
           0.0,    0.0,   -0.769, 0.0, 232.0,
           0.0,    0.0,    0.0,   1.0,   0.0,
        ]);

      case PdfColorFilterMode.warmSepia:
        // Warm paper/sepia tone to reduce blue light eye strain
        return const ColorFilter.matrix([
          0.393 * 1.15, 0.769 * 0.95, 0.189 * 0.7, 0.0, 25.0,
          0.349 * 1.05, 0.686 * 0.90, 0.168 * 0.7, 0.0, 18.0,
          0.272 * 0.85, 0.534 * 0.75, 0.131 * 0.6, 0.0, 10.0,
          0.0,          0.0,          0.0,         1.0,  0.0,
        ]);

      case PdfColorFilterMode.highContrast:
        // High contrast inverted with boosted text edges
        return const ColorFilter.matrix([
          -1.2,  0.0,  0.0, 0.0, 275.0,
           0.0, -1.2,  0.0, 0.0, 275.0,
           0.0,  0.0, -1.2, 0.0, 275.0,
           0.0,  0.0,  0.0, 1.0,   0.0,
        ]);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case PdfColorFilterMode.original:
        return const Color(0xFFF1F3F4); // Google Drive light surface
      case PdfColorFilterMode.oledDark:
        return const Color(0xFF000000); // OLED black
      case PdfColorFilterMode.softMidnight:
        return const Color(0xFF141517); // Soft dark
      case PdfColorFilterMode.warmSepia:
        return const Color(0xFFEFE8D6); // Parchment
      case PdfColorFilterMode.highContrast:
        return const Color(0xFF0A0A0A);
    }
  }
}
