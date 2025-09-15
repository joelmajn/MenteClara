import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:mente_clara/models/note.dart';
import 'package:mente_clara/models/category.dart';
import 'package:mente_clara/services/storage_service.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note? note;
  
  const NoteDetailScreen({super.key, this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> with TickerProviderStateMixin {
  static const Uuid _uuid = Uuid();
  
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  
  List<Category> _categories = [];
  Category? _selectedCategory;
  List<String> _tags = [];
  NoteContentType _contentType = NoteContentType.text;
  List<NoteChecklistItem> _checklistItems = [];
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _initializeFields();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await StorageService.getCategories();
    setState(() => _categories = categories);
  }

  void _initializeFields() {
    if (widget.note != null) {
      final note = widget.note!;
      _titleController.text = note.title;
      _contentController.text = note.content;
      _selectedCategory = note.category;
      _tags = List.from(note.tags);
      _contentType = note.contentType;
      _checklistItems = List.from(note.checklistItems);
      _selectedDate = note.noteDate;
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _addChecklistItem() {
    setState(() {
      _checklistItems.add(
        NoteChecklistItem(
          id: _uuid.v4(),
          text: 'Novo item',
        ),
      );
    });
  }

  void _removeChecklistItem(String id) {
    setState(() {
      _checklistItems.removeWhere((item) => item.id == id);
    });
  }

  void _updateChecklistItem(String id, String text, bool isCompleted) {
    setState(() {
      final index = _checklistItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _checklistItems[index] = _checklistItems[index].copyWith(
          text: text,
          isCompleted: isCompleted,
        );
      }
    });
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O título da nota é obrigatório'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final noteId = widget.note?.id ?? _uuid.v4();
      
      final note = Note(
        id: noteId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        contentType: _contentType,
        checklistItems: _checklistItems,
        noteDate: _selectedDate,
        category: _selectedCategory,
        tags: _tags,
        createdAt: widget.note?.createdAt ?? now,
        updatedAt: now,
      );

      final notes = await StorageService.getNotes();
      final existingIndex = notes.indexWhere((n) => n.id == noteId);
      
      if (existingIndex != -1) {
        notes[existingIndex] = note;
      } else {
        notes.insert(0, note);
      }

      await StorageService.saveNotes(notes);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar nota: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Nova Nota' : 'Editar Nota'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveNote,
              child: const Text('Salvar'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleField(),
            const SizedBox(height: 24),
            _buildCategorySelection(),
            const SizedBox(height: 24),
            _buildContentTypeSelection(),
            const SizedBox(height: 24),
            _buildContentField(),
            const SizedBox(height: 24),
            _buildDateSelection(),
            const SizedBox(height: 24),
            _buildTagsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Título',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Digite o título da nota...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoria',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildCategoryChip(null, 'Nenhuma'),
              ..._categories.map((category) => _buildCategoryChip(category, category.name)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(Category? category, String label) {
    final isSelected = _selectedCategory?.id == category?.id;
    
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
        onSelected: (_) {
          setState(() {
            _selectedCategory = isSelected ? null : category;
          });
        },
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

  Widget _buildContentTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Conteúdo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildContentTypeChip(
                NoteContentType.text,
                'Texto',
                Icons.text_fields,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildContentTypeChip(
                NoteContentType.checklist,
                'Checklist',
                Icons.checklist,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContentTypeChip(NoteContentType type, String label, IconData icon) {
    final isSelected = _contentType == type;
    
    return Container(
      height: 50,
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (_) {
          setState(() => _contentType = type);
        },
        selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildContentField() {
    if (_contentType == NoteContentType.checklist) {
      return _buildChecklistContent();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conteúdo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentController,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: 'Digite o conteúdo da nota...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildChecklistContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Checklist',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addChecklistItem,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_checklistItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'Nenhum item na checklist. Toque em "Adicionar" para começar.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          )
        else
          ...(_checklistItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: item.isCompleted,
                    onChanged: (value) {
                      _updateChecklistItem(item.id, item.text, value ?? false);
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: item.text),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Digite o item...',
                      ),
                      onChanged: (text) {
                        _updateChecklistItem(item.id, text, item.isCompleted);
                      },
                      style: TextStyle(
                        decoration: item.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeChecklistItem(item.id),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
            );
          })),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data (Opcional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                      : 'Selecionar data',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _selectedDate != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                if (_selectedDate != null)
                  IconButton(
                    onPressed: () => setState(() => _selectedDate = null),
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'Adicionar tag...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    onPressed: _addTag,
                    icon: const Icon(Icons.add),
                  ),
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => Chip(
              label: Text('#$tag'),
              onDeleted: () => _removeTag(tag),
              deleteIcon: const Icon(Icons.close, size: 18),
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              ),
            )).toList(),
          ),
      ],
    );
  }
}