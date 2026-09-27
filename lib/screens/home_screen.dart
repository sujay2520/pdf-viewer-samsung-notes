import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../services/notes_storage_service.dart';
import '../services/sample_docs_service.dart';
import '../services/print_service.dart';
import '../services/pdf_export_service.dart';
import 'pdf_viewer_screen.dart';
import 'note_editor_screen.dart';

enum DocumentTab {
  all,
  notes,
  pdfs,
  favorites,
}

class HomeScreen extends StatefulWidget {
  final VoidCallback? onQuickNoteRequested;

  const HomeScreen({super.key, this.onQuickNoteRequested});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<NoteDocument> _notes = [];
  List<RecentPdfItem> _recentPdfs = [];
  bool _isLoading = true;
  DocumentTab _currentTab = DocumentTab.all;
  bool _isGridView = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final notes = await NotesStorageService.instance.loadAllNotes();
    final pdfs = await NotesStorageService.instance.loadRecentPdfs();
    if (mounted) {
      setState(() {
        _notes = notes;
        _recentPdfs = pdfs;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NoteDocument> get _filteredNotes {
    return _notes.where((note) {
      if (_currentTab == DocumentTab.favorites && !note.isFavorite) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = note.title.toLowerCase().contains(q);
        final matchesContent = note.pages.any((p) => p.textContent.toLowerCase().contains(q));
        if (!matchesTitle && !matchesContent) return false;
      }
      return true;
    }).toList();
  }

  List<RecentPdfItem> get _filteredPdfs {
    if (_currentTab == DocumentTab.notes) return [];
    return _recentPdfs.where((pdf) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return pdf.title.toLowerCase().contains(q) || pdf.path.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131416) : const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Google Drive Modern Top Navigation Bar
            _buildTopNavBar(theme, isDark),

            // 2. Main Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: CustomScrollView(
                        slivers: [
                          // A. Hero Quick Action Cards
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
                              child: _buildQuickActionHero(theme, isDark),
                            ),
                          ),

                          // B. Segmented Tabs & View Controls
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(28, 12, 28, 16),
                              child: _buildFilterTabsRow(theme, isDark),
                            ),
                          ),

                          // C. Documents Grid or List
                          _buildDocumentsView(theme, isDark),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 48),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. Top Navigation Bar ---
  Widget _buildTopNavBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F22) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // App Logo & Brand Name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFF1E88E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Drive Notes & PDF',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Smart Inversion Viewer & Notebook Studio',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 32),

          // Central Google Drive Style Search Bar
          Expanded(
            child: Container(
              height: 44,
              constraints: const BoxConstraints(maxWidth: 580),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2B2D31) : const Color(0xFFEEF2F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search notes, PDFs, or typed content...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                },
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Global Shortcut Hint Pill
          Tooltip(
            message: 'Global Windows shortcut to summon this app anytime',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard, size: 15, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Win + Z',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Quick Action Primary Buttons
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Note'),
            onPressed: () => _createNewNote(template: NotePageTemplate.ruled),
          ),

          const SizedBox(width: 10),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Open PDF'),
            onPressed: _openPdfFilePicker,
          ),

          const SizedBox(width: 8),

          // Window & App Options Menu
          PopupMenuButton<String>(
            tooltip: 'App Options',
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (val) {
              if (val == 'hide') {
                if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
                  windowManager.hide();
                }
              } else if (val == 'exit') {
                exit(0);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'hide',
                child: Row(
                  children: [
                    Icon(Icons.visibility_off_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Hide Window (Press Win+Z to summon)'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'exit',
                child: Row(
                  children: [
                    Icon(Icons.power_settings_new, color: Colors.red, size: 18),
                    SizedBox(width: 10),
                    Text('Exit Application Completely', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. Hero Quick Actions Section ---
  Widget _buildQuickActionHero(ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 32) / 3;

        return Row(
          children: [
            // Hero Card 1: Open Any PDF
            _buildHeroCard(
              title: 'Open Any PDF',
              subtitle: 'Smart white-to-dark inversion, Acrobat search & system printing',
              icon: Icons.picture_as_pdf_rounded,
              gradientColors: [const Color(0xFFD32F2F), const Color(0xFFE57373)],
              buttonText: 'Browse PDF',
              width: cardWidth,
              onTap: _openPdfFilePicker,
              isDark: isDark,
            ),

            const SizedBox(width: 16),

            // Hero Card 2: New Lined Note
            _buildHeroCard(
              title: 'New Lined Note',
              subtitle: 'Direct typing on ruled lines + handwriting & highlighter studio',
              icon: Icons.edit_note_rounded,
              gradientColors: [const Color(0xFF1976D2), const Color(0xFF42A5F5)],
              buttonText: 'Create Note',
              width: cardWidth,
              onTap: () => _createNewNote(template: NotePageTemplate.ruled),
              isDark: isDark,
            ),

            const SizedBox(width: 16),

            // Hero Card 3: Interactive Guide PDF
            _buildHeroCard(
              title: 'PDF & Notes Guide',
              subtitle: 'Interactive tour showing dark mode inversion & shortcuts',
              icon: Icons.auto_stories_rounded,
              gradientColors: [const Color(0xFF7B1FA2), const Color(0xFFBA68C8)],
              buttonText: 'Open Guide',
              width: cardWidth,
              onTap: _openGuidePdf,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required String buttonText,
    required double width,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: isDark ? const Color(0xFF1E1F22) : Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            buttonText,
                            style: TextStyle(
                              color: gradientColors[0],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14, color: gradientColors[0]),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 3. Filter Tabs Row ---
  Widget _buildFilterTabsRow(ThemeData theme, bool isDark) {
    final noteCount = _notes.length;
    final pdfCount = _recentPdfs.length;
    final totalCount = noteCount + pdfCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Pill Tabs
        Row(
          children: [
            _buildTabPill('All Files ($totalCount)', DocumentTab.all, Icons.dashboard_outlined, isDark),
            const SizedBox(width: 8),
            _buildTabPill('Notes ($noteCount)', DocumentTab.notes, Icons.edit_note, isDark),
            const SizedBox(width: 8),
            _buildTabPill('PDF Documents ($pdfCount)', DocumentTab.pdfs, Icons.picture_as_pdf_outlined, isDark),
            const SizedBox(width: 8),
            _buildTabPill('Favorites', DocumentTab.favorites, Icons.star_border, isDark),
          ],
        ),

        // Grid / List Toggle & Template Quick Add
        Row(
          children: [
            // Quick Template Dropdown
            PopupMenuButton<NotePageTemplate>(
              tooltip: 'New Note with Template',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2B2D31) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.style_outlined, size: 16),
                    const SizedBox(width: 6),
                    const Text('Templates', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
              onSelected: (template) => _createNewNote(template: template),
              itemBuilder: (context) => NotePageTemplate.values.map((t) {
                return PopupMenuItem(
                  value: t,
                  child: Row(
                    children: [
                      Icon(t.icon, size: 18),
                      const SizedBox(width: 10),
                      Text('New ${t.displayName} Note'),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(width: 10),

            // Grid View Button
            IconButton(
              icon: Icon(Icons.grid_view_rounded, size: 20, color: _isGridView ? theme.colorScheme.primary : null),
              tooltip: 'Grid View',
              onPressed: () => setState(() => _isGridView = true),
            ),

            // List View Button
            IconButton(
              icon: Icon(Icons.view_list_rounded, size: 20, color: !_isGridView ? theme.colorScheme.primary : null),
              tooltip: 'List View',
              onPressed: () => setState(() => _isGridView = false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabPill(String title, DocumentTab tab, IconData icon, bool isDark) {
    final isSelected = _currentTab == tab;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _currentTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF383A40) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white24 : Colors.black12)
                : Colors.transparent,
          ),
          boxShadow: isSelected
              ? const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. Documents Grid or List ---
  Widget _buildDocumentsView(ThemeData theme, bool isDark) {
    final notes = _filteredNotes;
    final pdfs = _filteredPdfs;

    if (notes.isEmpty && pdfs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.folder_open_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty ? 'No matches found for "$_searchQuery"' : 'No documents in this view',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Click "New Note" to start writing or "Open PDF" to view any PDF file',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create Lined Note'),
                  onPressed: () => _createNewNote(template: NotePageTemplate.ruled),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isGridView) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 310,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: 0.88,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              // Show notes first, then PDFs
              if (index < notes.length) {
                return _buildNoteCard(notes[index], theme, isDark);
              } else {
                final pdfIndex = index - notes.length;
                return _buildPdfCard(pdfs[pdfIndex], theme, isDark);
              }
            },
            childCount: notes.length + pdfs.length,
          ),
        ),
      );
    } else {
      // List View
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index < notes.length) {
                return _buildNoteListTile(notes[index], theme, isDark);
              } else {
                final pdfIndex = index - notes.length;
                return _buildPdfListTile(pdfs[pdfIndex], theme, isDark);
              }
            },
            childCount: notes.length + pdfs.length,
          ),
        ),
      );
    }
  }

  // --- Note Card (Ruled Paper Preview) ---
  Widget _buildNoteCard(NoteDocument note, ThemeData theme, bool isDark) {
    final firstPage = note.firstPage;
    final previewText = firstPage.textContent.trim();
    final timeStr = DateFormat('MMM d, h:mm a').format(note.updatedAt);

    return Material(
      color: isDark ? const Color(0xFF1E1F22) : Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openNoteEditor(note),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Preview: Notebook paper style with ruled lines
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                decoration: BoxDecoration(
                  color: firstPage.isDark ? const Color(0xFF25262B) : const Color(0xFFFAFBFC),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    // Subtle background ruled lines preview
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          5,
                          (i) => Divider(
                            height: 1,
                            thickness: 0.8,
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.blueGrey.shade100,
                          ),
                        ),
                      ),
                    ),

                    // Typed note snippet
                    Positioned.fill(
                      child: Text(
                        previewText.isNotEmpty ? previewText : 'Tap to start typing on lined paper...',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.6,
                          color: previewText.isNotEmpty
                              ? (firstPage.isDark ? Colors.white70 : Colors.black87)
                              : (firstPage.isDark ? Colors.white30 : Colors.black38),
                          fontStyle: previewText.isEmpty ? FontStyle.italic : FontStyle.normal,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.fade,
                      ),
                    ),

                    // Template pill badge in top right
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          firstPage.template.displayName,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom metadata & action row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note, size: 18, color: Color(0xFF1E88E5)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          note.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          note.isFavorite ? Icons.star : Icons.star_border,
                          size: 18,
                          color: note.isFavorite ? Colors.amber : null,
                        ),
                        tooltip: note.isFavorite ? 'Remove Favorite' : 'Mark Favorite',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() => note.isFavorite = !note.isFavorite);
                          NotesStorageService.instance.saveNote(note);
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (val) {
                          if (val == 'delete') _confirmDeleteNote(note);
                          if (val == 'print') PrintService.instance.printNote(note: note);
                          if (val == 'export') PdfExportService.instance.exportNoteToPdf(note);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'print',
                            child: Row(children: [Icon(Icons.print, size: 18), SizedBox(width: 8), Text('Print Note')]),
                          ),
                          const PopupMenuItem(
                            value: 'export',
                            child: Row(children: [Icon(Icons.picture_as_pdf, size: 18), SizedBox(width: 8), Text('Save as PDF')]),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete')]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
                      ),
                      Text(
                        '${note.pages.length} ${note.pages.length == 1 ? 'page' : 'pages'}',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PDF Document Card ---
  Widget _buildPdfCard(RecentPdfItem pdf, ThemeData theme, bool isDark) {
    final file = File(pdf.path);
    final exists = file.existsSync();
    final timeStr = DateFormat('MMM d, h:mm a').format(pdf.lastOpened);

    return Material(
      color: isDark ? const Color(0xFF1E1F22) : Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (exists) {
            _openPdfViewer(file, initialTitle: pdf.title);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('File not found at: ${pdf.path}')),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Preview: PDF icon & cover
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2325) : const Color(0xFFFDF2F2),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.picture_as_pdf, color: Color(0xFFD32F2F), size: 36),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD32F2F).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PDF DOCUMENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD32F2F),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom metadata & action row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, size: 18, color: Color(0xFFD32F2F)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pdf.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (val) {
                          if (val == 'open' && exists) _openPdfViewer(file, initialTitle: pdf.title);
                          if (val == 'print' && exists) PrintService.instance.printPdfFile(pdfFile: file);
                          if (val == 'remove') {
                            NotesStorageService.instance.removeRecentPdf(pdf.path);
                            _loadData();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'open',
                            child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 8), Text('Open PDF')]),
                          ),
                          const PopupMenuItem(
                            value: 'print',
                            child: Row(children: [Icon(Icons.print, size: 18), SizedBox(width: 8), Text('Print')]),
                          ),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Row(children: [Icon(Icons.close, color: Colors.red, size: 18), SizedBox(width: 8), Text('Remove from Recents')]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
                      ),
                      if (pdf.pageCount > 0)
                        Text(
                          '${pdf.pageCount} pages',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- List View Tiles ---
  Widget _buildNoteListTile(NoteDocument note, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.edit_note, color: theme.colorScheme.primary),
        ),
        title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          note.firstPage.textContent.trim().isNotEmpty
              ? note.firstPage.textContent.trim().replaceAll('\n', ' ')
              : 'Lined Note',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
        ),
        trailing: Text(
          DateFormat('MMM d, h:mm a').format(note.updatedAt),
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
        ),
        onTap: () => _openNoteEditor(note),
      ),
    );
  }

  Widget _buildPdfListTile(RecentPdfItem pdf, ThemeData theme, bool isDark) {
    final file = File(pdf.path);
    final exists = file.existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1F22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.picture_as_pdf, color: Color(0xFFD32F2F)),
        ),
        title: Text(pdf.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          pdf.path,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
        ),
        trailing: Text(
          DateFormat('MMM d, h:mm a').format(pdf.lastOpened),
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
        ),
        onTap: () {
          if (exists) {
            _openPdfViewer(file, initialTitle: pdf.title);
          }
        },
      ),
    );
  }

  // --- Actions ---
  void _createNewNote({NotePageTemplate template = NotePageTemplate.ruled}) async {
    final newNote = NoteDocument(
      title: 'Untitled Note',
      pages: [
        NotePage(
          pageNumber: 1,
          template: template,
        ),
      ],
    );

    await NotesStorageService.instance.saveNote(newNote);
    await _loadData();
    _openNoteEditor(newNote);
  }

  void _openNoteEditor(NoteDocument note) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => NoteEditorScreen(note: note)),
    );
    _loadData();
  }

  void _openPdfFilePicker() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      final file = File(files.first.path!);
      final title = files.first.name;
      _openPdfViewer(file, initialTitle: title);
    }
  }

  void _openGuidePdf() async {
    try {
      final guideFile = await SampleDocsService.instance.getOrCreateSamplePdf();
      _openPdfViewer(guideFile, initialTitle: 'Drive Notes & PDF Guide.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating guide: $e')),
        );
      }
    }
  }

  void _openPdfViewer(File file, {String? initialTitle}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          file: file,
          initialTitle: initialTitle,
        ),
      ),
    );
    _loadData();
  }

  void _confirmDeleteNote(NoteDocument note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await NotesStorageService.instance.deleteNote(note.id);
              _loadData();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
