import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mente_clara/models/note.dart';
import 'package:mente_clara/models/category.dart';
import 'package:mente_clara/services/storage_service.dart';
import 'package:mente_clara/screens/note_detail_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with TickerProviderStateMixin {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Category? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    
    final notes = await StorageService.getNotes();
    final categories = await StorageService.getCategories();
    
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    setState(() {
      _notes = notes;
      _filteredNotes = notes;
      _categories = categories;
      _isLoading = false;
    });
  }

  void _filterNotes() {
    setState(() {
      _filteredNotes = _notes.where((note) {
        final matchesSearch = note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            note.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            note.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
        
        final matchesCategory = _selectedCategory == null || note.category?.id == _selectedCategory!.id;
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _filterNotes();
  }

  void _onCategorySelected(Category? category) {
    setState(() => _selectedCategory = category);
    _filterNotes();
  }

  Future<void> _navigateToNoteDetail([Note? note]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: note),
      ),
    );
    
    if (result == true) {
      _loadNotes();
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Nota'),
        content: Text('Deseja realmente excluir "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedNotes = _notes.where((n) => n.id != note.id).toList();
      await StorageService.saveNotes(updatedNotes);
      _loadNotes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nota "${note.title}" excluída'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildCategoryFilter(),
          Expanded(
            child: _filteredNotes.isEmpty
                ? _buildEmptyState()
                : _buildNotesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToNoteDetail(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Nota'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Pesquisar notas...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip(null, 'Todas'),
          ..._categories.map((category) => _buildCategoryChip(category, category.name)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(Category? category, String label) {
    final isSelected = _selectedCategory?.id == category?.id && category != null ||
                      (_selectedCategory == null && category == null);
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != null) ...[
              Text(category.emoji),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        onSelected: (_) => _onCategorySelected(isSelected ? null : category),
        selectedColor: category?.color.withValues(alpha: 0.2) ?? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        backgroundColor: Theme.of(context).colorScheme.surface,
        side: BorderSide(
          color: isSelected 
              ? (category?.color ?? Theme.of(context).colorScheme.primary)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma nota encontrada',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão + para criar sua primeira nota',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: note.category?.color.withValues(alpha: 0.3) ?? Colors.transparent,
            width: note.category != null ? 2 : 0,
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToNoteDetail(note),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (note.category != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: note.category!.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          note.category!.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        note.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _navigateToNoteDetail(note);
                        } else if (value == 'delete') {
                          _deleteNote(note);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Editar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Excluir', style: TextStyle(color: Colors.red)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (note.content.isNotEmpty || note.checklistItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  if (note.contentType == NoteContentType.text && note.content.isNotEmpty)
                    Text(
                      note.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (note.contentType == NoteContentType.checklist && note.checklistItems.isNotEmpty) ...[
                    ...note.checklistItems.take(3).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            item.isCompleted 
                                ? Icons.check_box 
                                : Icons.check_box_outline_blank,
                            size: 16,
                            color: item.isCompleted 
                                ? Theme.of(context).colorScheme.primary 
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.text,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                decoration: item.isCompleted 
                                    ? TextDecoration.lineThrough 
                                    : null,
                                color: item.isCompleted
                                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (note.checklistItems.length > 3)
                      Text(
                        '+${note.checklistItems.length - 3} itens...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (note.noteDate != null) ...[
                      Icon(
                        Icons.date_range,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yy').format(note.noteDate!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM - HH:mm').format(note.updatedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const Spacer(),
                    if (note.tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 4,
                        children: note.tags.take(2).map((tag) => Chip(
                          label: Text(
                            '#$tag',
                            style: const TextStyle(fontSize: 10),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          side: BorderSide.none,
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        )).toList(),
                      ),
                      if (note.tags.length > 2)
                        Text(
                          '+${note.tags.length - 2}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}