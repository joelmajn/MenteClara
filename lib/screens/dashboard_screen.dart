import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mente_clara/models/note.dart';
import 'package:mente_clara/models/reminder.dart';
import 'package:mente_clara/models/shopping_item.dart';
import 'package:mente_clara/services/storage_service.dart';
import 'package:mente_clara/services/data_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Note> _recentNotes = [];
  List<Reminder> _urgentReminders = [];
  List<AdvancedShoppingItem> _runningOutItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    await DataService.checkAdvancedItemsAndAddToSimpleList();

    final notes = await StorageService.getNotes();
    final reminders = await StorageService.getReminders();
    final advancedItems = await StorageService.getAdvancedShoppingItems();

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    setState(() {
      _recentNotes = notes.take(3).toList();
      _urgentReminders = reminders
          .where((r) => r.status != ReminderStatus.completed && r.dateTime.isBefore(tomorrow))
          .take(3)
          .toList();
      _runningOutItems = advancedItems
          .where((item) => item.isRunningOut && item.isActive)
          .take(3)
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              _buildQuickStats(),
              const SizedBox(height: 24),
              _buildUrgentRemindersSection(),
              const SizedBox(height: 24),
              _buildRecentNotesSection(),
              const SizedBox(height: 24),
              _buildRunningOutItemsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Bom dia! ☀️';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 18) {
      greeting = 'Boa tarde! 🌤️';
      greetingIcon = Icons.wb_cloudy;
    } else {
      greeting = 'Boa noite! 🌙';
      greetingIcon = Icons.nightlight_round;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(greetingIcon, 
                color: Theme.of(context).colorScheme.onPrimary, 
                size: 28),
              const SizedBox(width: 8),
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Aqui está um resumo do seu dia',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.note_alt,
            label: 'Notas',
            value: _recentNotes.length.toString(),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.notifications,
            label: 'Lembretes',
            value: _urgentReminders.length.toString(),
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.shopping_cart,
            label: 'Acabando',
            value: _runningOutItems.length.toString(),
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentRemindersSection() {
    return _buildSection(
      title: 'Lembretes Urgentes',
      icon: Icons.access_time,
      items: _urgentReminders,
      emptyMessage: 'Nenhum lembrete urgente! 🎉',
      itemBuilder: (reminder) => _buildReminderCard(reminder as Reminder),
    );
  }

  Widget _buildRecentNotesSection() {
    return _buildSection(
      title: 'Notas Recentes',
      icon: Icons.note,
      items: _recentNotes,
      emptyMessage: 'Nenhuma nota recente',
      itemBuilder: (note) => _buildNoteCard(note as Note),
    );
  }

  Widget _buildRunningOutItemsSection() {
    return _buildSection(
      title: 'Itens Acabando',
      icon: Icons.warning,
      items: _runningOutItems,
      emptyMessage: 'Tudo sob controle! ✨',
      itemBuilder: (item) => _buildShoppingItemCard(item as AdvancedShoppingItem),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<dynamic> items,
    required String emptyMessage,
    required Widget Function(dynamic) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
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
              emptyMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          )
        else
          Column(
            children: items.map(itemBuilder).toList(),
          ),
      ],
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final isOverdue = reminder.dateTime.isBefore(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue 
            ? Colors.red.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue 
              ? Colors.red.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: reminder.category?.color ?? Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              reminder.category?.emoji ?? '⏰',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (reminder.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    reminder.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM - HH:mm').format(reminder.dateTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isOverdue ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: note.category?.color ?? Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              note.category?.emoji ?? '📝',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (note.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note.content,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM - HH:mm').format(note.updatedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingItemCard(AdvancedShoppingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.category?.color ?? Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.category?.emoji ?? '🛒',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.daysRemaining} dias restantes',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.warning, color: Colors.orange),
        ],
      ),
    );
  }
}