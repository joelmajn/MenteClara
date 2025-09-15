import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:mente_clara/models/shopping_item.dart';
import 'package:mente_clara/models/category.dart';
import 'package:mente_clara/services/storage_service.dart';

class AdvancedItemDetailScreen extends StatefulWidget {
  final AdvancedShoppingItem? item;
  
  const AdvancedItemDetailScreen({super.key, this.item});

  @override
  State<AdvancedItemDetailScreen> createState() => _AdvancedItemDetailScreenState();
}

class _AdvancedItemDetailScreenState extends State<AdvancedItemDetailScreen> {
  static const Uuid _uuid = Uuid();
  
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  
  List<Category> _categories = [];
  Category? _selectedCategory;
  List<String> _tags = [];
  DateTime? _purchaseDate;
  DateTime _estimatedEndDate = DateTime.now().add(const Duration(days: 30));
  int _daysToAlert = 3;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _initializeFields();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await StorageService.getCategories();
    setState(() => _categories = categories);
  }

  void _initializeFields() {
    if (widget.item != null) {
      final item = widget.item!;
      _nameController.text = item.name;
      _selectedCategory = item.category;
      _tags = List.from(item.tags);
      _purchaseDate = item.purchaseDate;
      _estimatedEndDate = item.estimatedEndDate;
      _daysToAlert = item.daysToAlert;
      _isActive = item.isActive;
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

  Future<void> _selectPurchaseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _purchaseDate = date);
    }
  }

  Future<void> _selectEstimatedEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _estimatedEndDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      setState(() => _estimatedEndDate = date);
    }
  }

  Future<void> _saveItem() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O nome do item é obrigatório'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_estimatedEndDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A data estimada deve ser futura'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final itemId = widget.item?.id ?? _uuid.v4();
      
      final item = AdvancedShoppingItem(
        id: itemId,
        name: _nameController.text.trim(),
        purchaseDate: _purchaseDate,
        estimatedEndDate: _estimatedEndDate,
        daysToAlert: _daysToAlert,
        category: _selectedCategory,
        tags: _tags,
        isActive: _isActive,
        createdAt: widget.item?.createdAt ?? now,
        updatedAt: now,
      );

      final items = await StorageService.getAdvancedShoppingItems();
      final existingIndex = items.indexWhere((i) => i.id == itemId);
      
      if (existingIndex != -1) {
        items[existingIndex] = item;
      } else {
        items.insert(0, item);
      }

      await StorageService.saveAdvancedShoppingItems(items);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar item: $e'),
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
        title: Text(widget.item == null ? 'Novo Item Avançado' : 'Editar Item'),
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
              onPressed: _saveItem,
              child: const Text('Salvar'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNameField(),
            const SizedBox(height: 24),
            _buildCategorySelection(),
            const SizedBox(height: 24),
            _buildDatesSection(),
            const SizedBox(height: 24),
            _buildAlertSettings(),
            const SizedBox(height: 24),
            _buildStatusSwitch(),
            const SizedBox(height: 24),
            _buildTagsSection(),
            const SizedBox(height: 24),
            _buildPreview(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nome do Item',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Digite o nome do item...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            prefixIcon: const Icon(Icons.inventory),
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

  Widget _buildDatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Datas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectPurchaseDate,
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
                const Icon(Icons.shopping_cart, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data de Compra (Opcional)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      _purchaseDate != null
                          ? DateFormat('dd/MM/yyyy').format(_purchaseDate!)
                          : 'Selecionar data de compra',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _purchaseDate != null
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_purchaseDate != null)
                  IconButton(
                    onPressed: () => setState(() => _purchaseDate = null),
                    icon: const Icon(Icons.clear),
                  )
                else
                  const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectEstimatedEndDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Estimada de Término *',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_estimatedEndDate),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações de Alerta',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Alertar com',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: _daysToAlert.toDouble(),
                      min: 1,
                      max: 15,
                      divisions: 14,
                      label: '$_daysToAlert dias',
                      onChanged: (value) {
                        setState(() => _daysToAlert = value.round());
                      },
                    ),
                  ),
                  Text(
                    '$_daysToAlert dias',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você será notificado $_daysToAlert ${_daysToAlert == 1 ? 'dia' : 'dias'} antes do item acabar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSwitch() {
    return Container(
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
            _isActive ? Icons.play_circle : Icons.pause_circle,
            color: _isActive ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status do Item',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isActive 
                      ? 'Ativo - Monitoramento ligado'
                      : 'Pausado - Monitoramento desligado',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            activeColor: Colors.green,
          ),
        ],
      ),
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
                  prefixIcon: const Icon(Icons.tag),
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

  Widget _buildPreview() {
    if (_nameController.text.trim().isEmpty) return const SizedBox.shrink();
    
    final now = DateTime.now();
    final daysRemaining = _estimatedEndDate.difference(now).inDays;
    final isRunningOut = daysRemaining <= _daysToAlert;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prévia',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isRunningOut && _isActive 
                  ? Colors.red.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
            color: isRunningOut && _isActive 
                ? Colors.red.withValues(alpha: 0.05)
                : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.05),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_selectedCategory != null) ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _selectedCategory!.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_selectedCategory!.emoji, style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      _nameController.text.trim(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!_isActive)
                    const Icon(Icons.pause, color: Colors.orange, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    isRunningOut && _isActive ? Icons.warning : Icons.check_circle,
                    size: 14,
                    color: isRunningOut && _isActive ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    daysRemaining <= 0 && _isActive
                        ? 'Acabou!'
                        : '$daysRemaining dias restantes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isRunningOut && _isActive ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (isRunningOut && _isActive) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Será adicionado automaticamente à lista simples',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}