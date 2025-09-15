import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mente_clara/models/reminder.dart';
import 'package:mente_clara/models/category.dart';
import 'package:mente_clara/services/storage_service.dart';
import 'package:mente_clara/screens/reminder_detail_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> with TickerProviderStateMixin {
  List<Reminder> _reminders = [];
  List<Reminder> _filteredReminders = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Category? _selectedCategory;
  ReminderStatus? _statusFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    
    final reminders = await StorageService.getReminders();
    final categories = await StorageService.getCategories();
    
    reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    setState(() {
      _reminders = reminders;
      _filteredReminders = reminders;
      _categories = categories;
      _isLoading = false;
    });
  }

  void _filterReminders() {
    setState(() {
      _filteredReminders = _reminders.where((reminder) {
        final matchesSearch = reminder.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            (reminder.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                            reminder.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
        
        final matchesCategory = _selectedCategory == null || reminder.category?.id == _selectedCategory!.id;
        
        final matchesStatus = _statusFilter == null || reminder.getCurrentStatus() == _statusFilter;
        
        return matchesSearch && matchesCategory && matchesStatus;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _filterReminders();
  }

  void _onCategorySelected(Category? category) {
    setState(() => _selectedCategory = category);
    _filterReminders();
  }

  void _onStatusSelected(ReminderStatus? status) {
    setState(() => _statusFilter = status);
    _filterReminders();
  }

  Future<void> _navigateToReminderDetail([Reminder? reminder]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderDetailScreen(reminder: reminder),
      ),
    );
    
    if (result == true) {
      _loadReminders();
    }
  }

  Future<void> _toggleReminderStatus(Reminder reminder) async {
    final newStatus = reminder.status == ReminderStatus.completed
        ? ReminderStatus.pending
        : ReminderStatus.completed;
    
    final updatedReminder = reminder.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );

    final reminders = await StorageService.getReminders();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    
    if (index != -1) {
      reminders[index] = updatedReminder;
      await StorageService.saveReminders(reminders);
      _loadReminders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == ReminderStatus.completed
                  ? 'Lembrete marcado como concluído'
                  : 'Lembrete reativado',
            ),
            backgroundColor: newStatus == ReminderStatus.completed 
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Lembrete'),
        content: Text('Deseja realmente excluir "${reminder.title}"?'),
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
      final updatedReminders = _reminders.where((r) => r.id != reminder.id).toList();
      await StorageService.saveReminders(updatedReminders);
      _loadReminders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lembrete "${reminder.title}" excluído'),
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
          _buildStatusFilter(),
          Expanded(
            child: _filteredReminders.isEmpty
                ? _buildEmptyState()
                : _buildRemindersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToReminderDetail(),
        icon: const Icon(Icons.add),
        label: const Text('Novo Lembrete'),
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
          hintText: 'Pesquisar lembretes...',
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

  Widget _buildStatusFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatusChip(null, 'Todos', Icons.all_inclusive),
          _buildStatusChip(ReminderStatus.pending, 'Pendentes', Icons.schedule),
          _buildStatusChip(ReminderStatus.completed, 'Concluídos', Icons.check_circle),
          _buildStatusChip(ReminderStatus.overdue, 'Atrasados', Icons.warning),
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

  Widget _buildStatusChip(ReminderStatus? status, String label, IconData icon) {
    final isSelected = _statusFilter == status;
    Color chipColor = Theme.of(context).colorScheme.primary;
    
    switch (status) {
      case ReminderStatus.pending:
        chipColor = Colors.orange;
        break;
      case ReminderStatus.completed:
        chipColor = Colors.green;
        break;
      case ReminderStatus.overdue:
        chipColor = Colors.red;
        break;
      default:
        chipColor = Theme.of(context).colorScheme.primary;
    }
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (_) => _onStatusSelected(isSelected ? null : status),
        selectedColor: chipColor.withValues(alpha: 0.2),
        backgroundColor: Theme.of(context).colorScheme.surface,
        side: BorderSide(
          color: isSelected 
              ? chipColor
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
            Icons.notifications_none,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum lembrete encontrado',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no botão + para criar seu primeiro lembrete',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    final overdueReminders = _filteredReminders.where((r) => 
        r.getCurrentStatus() == ReminderStatus.overdue).toList();
    final todayReminders = _filteredReminders.where((r) => 
        r.dateTime.isAfter(today) && r.dateTime.isBefore(tomorrow) && 
        r.getCurrentStatus() != ReminderStatus.overdue).toList();
    final upcomingReminders = _filteredReminders.where((r) => 
        r.dateTime.isAfter(tomorrow) && 
        r.getCurrentStatus() != ReminderStatus.overdue).toList();
    final completedReminders = _filteredReminders.where((r) => 
        r.status == ReminderStatus.completed).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (overdueReminders.isNotEmpty) ...[
          _buildSectionHeader('Atrasados', Icons.warning, Colors.red),
          ...overdueReminders.map((reminder) => _buildReminderCard(reminder)),
          const SizedBox(height: 16),
        ],
        if (todayReminders.isNotEmpty) ...[
          _buildSectionHeader('Hoje', Icons.today, Colors.orange),
          ...todayReminders.map((reminder) => _buildReminderCard(reminder)),
          const SizedBox(height: 16),
        ],
        if (upcomingReminders.isNotEmpty) ...[
          _buildSectionHeader('Próximos', Icons.schedule, Colors.blue),
          ...upcomingReminders.map((reminder) => _buildReminderCard(reminder)),
          const SizedBox(height: 16),
        ],
        if (completedReminders.isNotEmpty) ...[
          _buildSectionHeader('Concluídos', Icons.check_circle, Colors.green),
          ...completedReminders.map((reminder) => _buildReminderCard(reminder)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  Widget _buildReminderCard(Reminder reminder) {
    final currentStatus = reminder.getCurrentStatus();
    Color statusColor = Theme.of(context).colorScheme.primary;
    IconData statusIcon = Icons.schedule;
    
    switch (currentStatus) {
      case ReminderStatus.overdue:
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
      case ReminderStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case ReminderStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: statusColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToReminderDetail(reminder),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (reminder.category != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: reminder.category!.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          reminder.category!.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        reminder.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: reminder.status == ReminderStatus.completed 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _toggleReminderStatus(reminder),
                      icon: Icon(
                        reminder.status == ReminderStatus.completed
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: reminder.status == ReminderStatus.completed
                            ? Colors.green
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    PopupMenuButton(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _navigateToReminderDetail(reminder);
                        } else if (value == 'delete') {
                          _deleteReminder(reminder);
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
                if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    reminder.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd/MM/yyyy - HH:mm').format(reminder.dateTime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (reminder.tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 4,
                        children: reminder.tags.take(2).map((tag) => Chip(
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
                      if (reminder.tags.length > 2)
                        Text(
                          '+${reminder.tags.length - 2}',
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