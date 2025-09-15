import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:mente_clara/models/shopping_item.dart';
import 'package:mente_clara/models/category.dart';
import 'package:mente_clara/services/storage_service.dart';

class SimpleShoppingScreen extends StatefulWidget {
  final VoidCallback onDataChanged;
  
  const SimpleShoppingScreen({super.key, required this.onDataChanged});

  @override
  State<SimpleShoppingScreen> createState() => _SimpleShoppingScreenState();
}

class _SimpleShoppingScreenState extends State<SimpleShoppingScreen> {
  static const Uuid _uuid = Uuid();
  
  List<SimpleShoppingItem> _items = [];
  List<SimpleShoppingItem> _filteredItems = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _showCompleted = true;
  String _searchQuery = '';
  Category? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quickAddController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final items = await StorageService.getSimpleShoppingItems();
    final categories = await StorageService.getCategories();
    
    items.sort((a, b) {
      if (a.isPurchased != b.isPurchased) {
        return a.isPurchased ? 1 : -1; // Non-purchased first
      }
      return b.createdAt.compareTo(a.createdAt); // Most recent first
    });
    
    setState(() {
      _items = items;
      _categories = categories;
      _isLoading = false;
    });
    
    _filterItems();
  }

  void _filterItems() {
    setState(() {
      _filteredItems = _items.where((item) {
        final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            item.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
        
        final matchesCategory = _selectedCategory == null || item.category?.id == _selectedCategory!.id;
        
        final matchesCompletion = _showCompleted || !item.isPurchased;
        
        return matchesSearch && matchesCategory && matchesCompletion;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _filterItems();
  }

  void _onCategorySelected(Category? category) {
    setState(() => _selectedCategory = category);
    _filterItems();
  }

  Future<void> _quickAddItem() async {
    final name = _quickAddController.text.trim();
    if (name.isEmpty) return;

    final now = DateTime.now();
    final newItem = SimpleShoppingItem(
      id: _uuid.v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
    );

    final updatedItems = [newItem, ..._items];
    await StorageService.saveSimpleShoppingItems(updatedItems);
    
    _quickAddController.clear();
    _loadData();
    widget.onDataChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item "$name" adicionado!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleItemStatus(SimpleShoppingItem item) async {
    final updatedItem = item.copyWith(
      isPurchased: !item.isPurchased,
      updatedAt: DateTime.now(),
    );

    final updatedItems = _items.map((i) => i.id == item.id ? updatedItem : i).toList();
    await StorageService.saveSimpleShoppingItems(updatedItems);
    
    _loadData();
    widget.onDataChanged();
  }

  Future<void> _editItem(SimpleShoppingItem item) async {
    final result = await _showEditDialog(item);
    if (result != null) {
      final updatedItems = _items.map((i) => i.id == item.id ? result : i).toList();
      await StorageService.saveSimpleShoppingItems(updatedItems);
      _loadData();
      widget.onDataChanged();
    }
  }

  Future<void> _deleteItem(SimpleShoppingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Item'),
        content: Text('Deseja realmente excluir "${item.name}"?'),
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
      final updatedItems = _items.where((i) => i.id != item.id).toList();
      await StorageService.saveSimpleShoppingItems(updatedItems);
      _loadData();
      widget.onDataChanged();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item "${item.name}" excluído'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<SimpleShoppingItem?> _showEditDialog(SimpleShoppingItem item) async {
    final nameController = TextEditingController(text: item.name);
    final tagController = TextEditingController();
    Category? selectedCategory = item.category;
    List<String> tags = List.from(item.tags);

    return showDialog<SimpleShoppingItem>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Item'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do item',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Category?>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Nenhuma categoria'),
                    ),
                    ..._categories.map((category) => DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Text(category.emoji),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    )),
                  ],
                  onChanged: (value) => setDialogState(() => selectedCategory = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tagController,
                        decoration: InputDecoration(
                          labelText: 'Adicionar tag',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              final tag = tagController.text.trim();
                              if (tag.isNotEmpty && !tags.contains(tag)) {
                                setDialogState(() {
                                  tags.add(tag);
                                  tagController.clear();
                                });
                              }
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: tags.map((tag) => Chip(
                      label: Text('#$tag'),
                      onDeleted: () => setDialogState(() => tags.remove(tag)),
                      deleteIcon: const Icon(Icons.close, size: 18),
                    )).toList(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final updatedItem = item.copyWith(
                    name: nameController.text.trim(),
                    category: selectedCategory,
                    tags: tags,
                    updatedAt: DateTime.now(),
                  );
                  Navigator.pop(context, updatedItem);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildQuickAdd(),
        _buildFilters(),
        _buildToggleCompleted(),
        Expanded(
          child: _filteredItems.isEmpty
              ? _buildEmptyState()
              : _buildItemsList(),
        ),
      ],
    );
  }

  Widget _buildQuickAdd() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _quickAddController,
              decoration: InputDecoration(
                hintText: 'Digite um item e pressione Enter...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.add_shopping_cart),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onSubmitted: (_) => _quickAddItem(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            onPressed: _quickAddItem,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        // Search
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Pesquisar itens...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Category filter
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildCategoryChip(null, 'Todas'),
              ..._categories.map((category) => _buildCategoryChip(category, category.name)),
            ],
          ),
        ),
      ],
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
      ),
    );
  }

  Widget _buildToggleCompleted() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Switch(
            value: _showCompleted,
            onChanged: (value) {
              setState(() => _showCompleted = value);
              _filterItems();
            },
          ),
          const SizedBox(width: 8),
          Text(
            'Mostrar itens comprados',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Lista vazia',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione itens à sua lista de compras',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    final pendingItems = _filteredItems.where((item) => !item.isPurchased).toList();
    final completedItems = _filteredItems.where((item) => item.isPurchased).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (pendingItems.isNotEmpty) ...[
          _buildSectionHeader('Pendentes', Icons.shopping_cart, Colors.orange),
          ...pendingItems.map((item) => _buildItemCard(item)),
          const SizedBox(height: 16),
        ],
        if (completedItems.isNotEmpty && _showCompleted) ...[
          _buildSectionHeader('Comprados', Icons.check_circle, Colors.green),
          ...completedItems.map((item) => _buildItemCard(item)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(SimpleShoppingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Checkbox(
            value: item.isPurchased,
            onChanged: (_) => _toggleItemStatus(item),
            activeColor: Colors.green,
          ),
          title: Text(
            item.name,
            style: TextStyle(
              decoration: item.isPurchased ? TextDecoration.lineThrough : null,
              color: item.isPurchased 
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                  : null,
            ),
          ),
          subtitle: item.category != null || item.tags.isNotEmpty
              ? Row(
                  children: [
                    if (item.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.category!.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.category!.emoji, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              item.category!.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: item.category!.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (item.tags.isNotEmpty)
                      ...item.tags.take(2).map((tag) => Container(
                        margin: const EdgeInsets.only(right: 4),
                        child: Chip(
                          label: Text('#$tag', style: const TextStyle(fontSize: 10)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      )),
                  ],
                )
              : null,
          trailing: PopupMenuButton(
            onSelected: (value) {
              if (value == 'edit') {
                _editItem(item);
              } else if (value == 'delete') {
                _deleteItem(item);
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
        ),
      ),
    );
  }
}