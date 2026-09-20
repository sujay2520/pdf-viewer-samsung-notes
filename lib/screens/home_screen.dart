import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../services/notes_storage_service.dart';
import '../services/sample_docs_service.dart';
import 'pdf_viewer_screen.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onQuickNoteRequested;

  const HomeScreen({super.key, this.onQuickNoteRequested});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SamsungNote> _notes = [];
  bool _isLoading = true;
  String _selectedFolder = 'All Notes';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final notes = await NotesStorageService.instance.loadAllNotes();
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  List<SamsungNote> get _filteredNotes {
    return _notes.where((note) {
      if (_selectedFolder == 'Favorites' && !note.isFavorite) {
        return false;
      }
      if (_selectedFolder != 'All Notes' &&
          _selectedFolder != 'Favorites' &&
          note.folder != _selectedFolder) {
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141517) : const Color(0xFFF8F9FA),
      body: Row(
        children: [
          // 1. Samsung Notes Left Navigation Sidebar (PC layout)
          Container(
            width: 260,
            color: isDark ? const Color(0xFF1E1F22) : const Color(0xFFFFFFFF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Brand & Logo
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
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
                        ),
                        child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Samsung Notes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '& Drive PDF Viewer',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Quick Action: New Note
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('New Note', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _createNewNote,
                  ),
                ),

                // Folder & Category Navigation
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildNavItem(
                        title: 'All Notes',
                        icon: Icons.notes,
                        isSelected: _selectedFolder == 'All Notes',
                        onTap: () => setState(() => _selectedFolder = 'All Notes'),
                      ),
                      _buildNavItem(
                        title: 'Favorites',
                        icon: Icons.star_border,
                        isSelected: _selectedFolder == 'Favorites',
                        onTap: () => setState(() => _selectedFolder = 'Favorites'),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 6),
                        child: Text(
                          'FOLDERS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      _buildNavItem(
                        title: 'General',
                        icon: Icons.folder_outlined,
                        isSelected: _selectedFolder == 'General',
                        onTap: () => setState(() => _selectedFolder = 'General'),
                      ),
                      _buildNavItem(
                        title: 'Tutorial',
                        icon: Icons.folder_outlined,
                        isSelected: _selectedFolder == 'Tutorial',
                        onTap: () => setState(() => _selectedFolder = 'Tutorial'),
                      ),
                      _buildNavItem(
                        title: 'Personal',
                        icon: Icons.folder_outlined,
                        isSelected: _selectedFolder == 'Personal',
                        onTap: () => setState(() => _selectedFolder = 'Personal'),
                      ),
                    ],
                  ),
                ),

                // Global Windows Shortcut Banner
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2B2D31) : const Color(0xFFEFF4FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.flash_on, size: 16, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Global Shortcut',
                              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Press Win + Z anywhere to summon Notes!',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const VerticalDivider(width: 1),

          // 2. Main Workspace Dashboard
          Expanded(
            child: Column(
              children: [
                // Top Bar: Search & Action Buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: isDark ? const Color(0xFF1E1F22) : Colors.white,
                  child: Row(
                    children: [
                      // Search Input
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2B2D31) : const Color(0xFFF1F3F4),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              hintText: 'Search notes and PDF documents...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Button 1: Open External PDF
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.file_open_outlined),
                        label: const Text('Open PDF'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: _pickAndOpenPdf,
                      ),
                      const SizedBox(width: 10),

                      // Button 2: Open Sample Guide PDF
                      OutlinedButton.icon(
                        icon: const Icon(Icons.auto_stories_outlined),
                        label: const Text('Guide PDF'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: _openSampleGuidePdf,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Content: Notes Cards Grid
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredNotes.isEmpty
                          ? _buildEmptyState(theme)
                          : GridView.builder(
                              padding: const EdgeInsets.all(24),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 280,
                                crossAxisSpacing: 18,
                                mainAxisSpacing: 18,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: _filteredNotes.length,
                              itemBuilder: (context, index) {
                                final note = _filteredNotes[index];
                                return _buildNoteCard(note, theme, isDark);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
      onTap: onTap,
    );
  }

  Widget _buildNoteCard(SamsungNote note, ThemeData theme, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(note.updatedAt);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openNoteEditor(note),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1F22) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Folder badge + Favorite Star
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    note.folder,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    note.isFavorite ? Icons.star : Icons.star_border,
                    color: note.isFavorite ? Colors.amber : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      note.isFavorite = !note.isFavorite;
                    });
                    NotesStorageService.instance.saveNote(note);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Note Title
            Text(
              note.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Note Text Preview
            Expanded(
              child: Text(
                note.firstPage.textContent.isNotEmpty
                    ? note.firstPage.textContent
                    : '(Hand-drawn notes or sketches)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.4,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const Divider(height: 16),

            // Footer: Date + Page Count + Delete Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      '${note.pages.length} ${note.pages.length == 1 ? 'page' : 'pages'}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                  tooltip: 'Delete Note',
                  onPressed: () => _confirmDeleteNote(note),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No notes found',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Create a new note or open a PDF document to begin.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create New Note'),
            onPressed: _createNewNote,
          ),
        ],
      ),
    );
  }

  void _createNewNote() async {
    final newNote = SamsungNote(
      title: 'New Note ${DateFormat('MMM d, h:mm a').format(DateTime.now())}',
      folder: _selectedFolder == 'All Notes' || _selectedFolder == 'Favorites'
          ? 'General'
          : _selectedFolder,
      pages: [
        NotePage(pageNumber: 1, template: NotePageTemplate.ruled),
      ],
    );
    await NotesStorageService.instance.saveNote(newNote);
    await _loadNotes();
    if (mounted) {
      _openNoteEditor(newNote);
    }
  }

  void _openNoteEditor(SamsungNote note) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: note),
      ),
    );
    _loadNotes();
  }

  void _pickAndOpenPdf() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      final file = File(files.first.path!);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(
              file: file,
              initialTitle: files.first.name,
            ),
          ),
        );
      }
    }
  }

  void _openSampleGuidePdf() async {
    final file = await SampleDocsService.instance.getOrCreateSamplePdf();
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            file: file,
            initialTitle: 'Google Drive & Samsung Notes Guide.pdf',
          ),
        ),
      );
    }
  }

  void _confirmDeleteNote(SamsungNote note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              await NotesStorageService.instance.deleteNote(note.id);
              _loadNotes();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
