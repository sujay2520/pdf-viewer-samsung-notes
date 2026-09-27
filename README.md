# Drive Notes & PDF (Windows & Mobile)

A modern, fast, cross-platform Flutter application combining **Google Drive PDF Viewer**, **Adobe Acrobat Reader**, and a versatile **Notebook Studio**.

Built with Flutter 3.47.5 and Dart 3.13.4.

---

## Key Features

### 1. Smart White-to-Dark Page Inversion
Traditional PDF viewers leave white pages glaring while only darkening the app chrome. This app implements hardware-accelerated **color matrix filters** applied directly to the document viewport:
- **Original (Light)**: Standard PDF viewing with Google Drive Material 3 chrome.
- **OLED Dark (Inverted)**: Inverts white (`#FFFFFF`) pages to pitch black (`#000000`) and black text to crisp white (`#FFFFFF`).
- **Midnight Charcoal**: Soft contrast dark mode (white -> `#1E1F22`, black -> `#E2E8F0`) to eliminate eye fatigue.
- **Warm Sepia Comfort**: Warm amber/parchment tone (`#F4ECD8`) that cuts blue light.
- **High Contrast Dark**: High-definition inverted contrast for dim lighting.

### 2. Global Windows Shortcut (`Win + Z`)
- Press **`Windows Key + Z`** anywhere in Windows to instantly summon and focus the application.

### 3. Google Drive Theming & Adobe Acrobat Capabilities
- **Google Drive M3 Design**: Clean top action bar, page count badge (`1 / 14`), search button, dark inversion selector, markup toggle, print, and save buttons.
- **Floating Bottom Pill**: Zoom in/out, percentage presets (50% - 300%), Fit to Width, Fit to Page, and Page Scrubber.
- **In-Document Text Search**: Fast text search with match counter (`3 of 12`), live match highlighting, and next/previous match navigation.
- **Page Thumbnails Drawer**: Visual thumbnail grid for quick navigation through long documents.

### 4. Notebook Studio ("Doing Changes")
- **Direct Lined Page Typing**: Click anywhere on the lines to type notes directly, perfectly aligned with ruled line height.
- **Paper Templates**:
  - Ruled / Lined (with red left margin)
  - Grid / Graph paper
  - Dot Grid
  - Cornell Notes (Cue column, Notes, and Summary area)
  - Blank canvas (Light & Dark)
- **Vector Drawing & Markup Tools**:
  - Dedicated Type Mode
  - Ballpoint Pen
  - Fountain / Calligraphy Pen
  - Semi-transparent Highlighter
  - Shapes (Rectangle, Circle/Oval, Line, Arrow)
  - Eraser
  - Color wheel + swatches + stroke thickness slider
  - Undo / Redo history stack

### 5. Direct Print & Save as PDF
- **System Print**: Direct system print dialog integration with options to print in original light mode or inverted dark mode, with or without annotations.
- **Save as PDF**: Export your notes or annotated PDFs with all vector drawings and notes embedded into standard PDF files.

---

## Building and Running

### Prerequisites
- Flutter SDK 3.x
- Visual Studio Build Tools with C++ workload (for Windows desktop)

### Run on Windows
```bash
flutter run -d windows
```

### Run on Android / Phone
```bash
flutter run -d <device-id>
```

### Build Release Executable
```bash
flutter build windows --release
```

---

## License
MIT License
