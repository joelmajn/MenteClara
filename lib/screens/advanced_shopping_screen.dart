import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:mente_clara/models/shopping_item.dart';
import 'package:mente_clara/models/category.dart';
import 'package:mente_clara/services/storage_service.dart';
import 'package:mente_clara/screens/advanced_item_detail_screen.dart';

class AdvancedShoppingScreen extends StatefulWidget {
  final VoidCallback onDataChanged;
  
  const AdvancedShoppingScreen({super.key, required this.onDataChanged});

  @override
  State<AdvancedShoppingScreen> createState() => _AdvancedShoppingScreenState();
}

class _AdvancedShoppingScreenState extends State<AdvancedShoppingScreen> {
  List<AdvancedShoppingItem> _items = [];
  List<AdvancedShoppingItem> _filteredItems = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _showInactive = false;
  String _searchQuery = '';
  Category? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final items = await StorageService.getAdvancedShoppingItems();
    final categories = await StorageService.getCategories();
    
    items.sort((a, b) {
      // Sort by running out status first, then by estimated end date
      if (a.isRunningOut != b.isRunningOut) {
        return a.isRunningOut ? -1 : 1;
      }
      return a.estimatedEndDate.compareTo(b.estimatedEndDate);
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
        
        final matchesActive = _showInactive || item.isActive;
        
        return matchesSearch && matchesCategory && matchesActive;
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

  Future<void> _navigateToItemDetail([AdvancedShoppingItem? item]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedItemDetailScreen(item: item),
      ),
    );
    
    if (result == true) {
      _loadData();
      widget.onDataChanged();
    }
  }

  Future<void> _toggleItemStatus(AdvancedShoppingItem item) async {
    final updatedItem = item.copyWith(
      isActive: !item.isActive,
      updatedAt: DateTime.now(),
    );

    final updatedItems = _items.map((i) => i.id == item.id ? updatedItem : i).toList();
    await StorageService.saveAdvancedShoppingItems(updatedItems);
    
    _loadData();
    widget.onDataChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedItem.isActive 
                ? 'Item "${item.name}" reativado'
                : 'Item "${item.name}" pausado',
          ),
          backgroundColor: updatedItem.isActive 
              ? Colors.green 
              : Colors.orange,
        ),
      );
    }
  }

  Future<void> _deleteItem(AdvancedShoppingItem item) async {
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
      await StorageService.saveAdvancedShoppingItems(updatedItems);
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

  Future<void> _markAsPurchased(AdvancedShoppingItem item) async {
    final now = DateTime.now();
    final updatedItem = item.copyWith(
      purchaseDate: now,
      updatedAt: now,
    );

    final updatedItems = _items.map((i) => i.id == item.id ? updatedItem : i).toList();
    await StorageService.saveAdvancedShoppingItems(updatedItems);
    
    _loadData();
    widget.onDataChanged();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item "${item.name}" marcado como comprado!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildFilters(),
        _buildToggleInactive(),
        Expanded(
          child: _filteredItems.isEmpty
              ? _buildEmptyState()
              : _buildItemsList(),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        // Search
        Container(
          margin: const EdgeInsets.all(16),
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

  Widget _buildToggleInactive() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Switch(
            value: _showInactive,
            onChanged: (value) {
              setState(() => _showInactive = value);
              _filterItems();
            },
          ),
          const SizedBox(width: 8),
          Text(
            'Mostrar itens pausados',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _navigateToItemDetail(),
            icon: const Icon(Icons.add),
            label: const Text('Novo Item'),
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
            Icons.inventory_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum item avançado',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione itens para monitorar quando vão acabar',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    final runningOutItems = _filteredItems.where((item) => item.isRunningOut && item.isActive).toList();
    final activeItems = _filteredItems.where((item) => !item.isRunningOut && item.isActive).toList();
    final inactiveItems = _filteredItems.where((item) => !item.isActive).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (runningOutItems.isNotEmpty) ...[
          _buildSectionHeader('Acabando', Icons.warning, Colors.red),
          ...runningOutItems.map((item) => _buildItemCard(item)),
          const SizedBox(height: 16),
        ],
        if (activeItems.isNotEmpty) ...[
          _buildSectionHeader('Ativos', Icons.inventory, Colors.blue),
          ...activeItems.map((item) => _buildItemCard(item)),
          const SizedBox(height: 16),
        ],
        if (inactiveItems.isNotEmpty && _showInactive) ...[
          _buildSectionHeader('Pausados', Icons.pause_circle, Colors.grey),
          ...inactiveItems.map((item) => _buildItemCard(item)),
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

  Widget _buildItemCard(AdvancedShoppingItem item) {
    final daysRemaining = item.daysRemaining;
    final isRunningOut = item.isRunningOut;
    
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;
    String statusText = 'OK';
    
    if (isRunningOut) {
      if (daysRemaining <= 0) {
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Acabou';
      } else if (daysRemaining <= item.daysToAlert) {
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        statusText = '$daysRemaining dias';
      }
    } else if (daysRemaining > 0) {
      statusText = '$daysRemaining dias';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isRunningOut 
                ? Colors.red.withValues(alpha: 0.3)
                : (item.isActive 
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3)),
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToItemDetail(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.category != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.category!.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category!.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: item.isActive 
                              ? null 
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!item.isActive)
                      Icon(
                        Icons.pause,
                        color: Colors.grey,
                        size: 20,
                      ),
                    PopupMenuButton(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _navigateToItemDetail(item);
                            break;
                          case 'toggle':
                            _toggleItemStatus(item);
                            break;
                          case 'purchased':
                            _markAsPurchased(item);
                            break;
                          case 'delete':
                            _deleteItem(item);
                            break;
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
                        PopupMenuItem(
                          value: 'toggle',
                          child: ListTile(
                            leading: Icon(
                              item.isActive ? Icons.pause : Icons.play_arrow,
                              color: item.isActive ? Colors.orange : Colors.green,
                            ),
                            title: Text(
                              item.isActive ? 'Pausar' : 'Ativar',
                              style: TextStyle(
                                color: item.isActive ? Colors.orange : Colors.green,
                              ),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'purchased',
                          child: ListTile(
                            leading: Icon(Icons.shopping_cart, color: Colors.green),
                            title: Text('Marcar como comprado', style: TextStyle(color: Colors.green)),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      statusIcon,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Acaba em ${DateFormat('dd/MM').format(item.estimatedEndDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                if (item.purchaseDate != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        size: 14,
                        color: Colors.green.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Comprado em ${DateFormat('dd/MM').format(item.purchaseDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: item.tags.map((tag) => Chip(
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}