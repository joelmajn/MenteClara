import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:mente_clara/models/reminder.dart';
import 'package:mente_clara/models/category.dart';
import 'package:mente_clara/services/storage_service.dart';
import 'package:mente_clara/services/notification_service.dart';

class ReminderDetailScreen extends StatefulWidget {
  final Reminder? reminder;
  
  const ReminderDetailScreen({super.key, this.reminder});

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen> {
  static const Uuid _uuid = Uuid();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  
  List<Category> _categories = [];
  Category? _selectedCategory;
  List<String> _tags = [];
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
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
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await StorageService.getCategories();
    setState(() => _categories = categories);
  }

  void _initializeFields() {
    if (widget.reminder != null) {
      final reminder = widget.reminder!;
      _titleController.text = reminder.title;
      _descriptionController.text = reminder.description ?? '';
      _selectedCategory = reminder.category;
      _tags = List.from(reminder.tags);
      _selectedDate = DateTime(
        reminder.dateTime.year,
        reminder.dateTime.month,
        reminder.dateTime.day,
      );
      _selectedTime = TimeOfDay.fromDateTime(reminder.dateTime);
    } else {
      // Set default time to next hour
      final now = DateTime.now();
      final nextHour = now.add(const Duration(hours: 1));
      _selectedTime = TimeOfDay(hour: nextHour.hour, minute: 0);
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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  DateTime get _combinedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _saveReminder() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O título do lembrete é obrigatório'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final combinedDateTime = _combinedDateTime;
    if (combinedDateTime.isBefore(DateTime.now()) && widget.reminder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A data e hora devem ser futuras'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final reminderId = widget.reminder?.id ?? _uuid.v4();
      
      final reminder = Reminder(
        id: reminderId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        dateTime: combinedDateTime,
        category: _selectedCategory,
        tags: _tags,
        status: widget.reminder?.status ?? ReminderStatus.pending,
        createdAt: widget.reminder?.createdAt ?? now,
        updatedAt: now,
      );

      final reminders = await StorageService.getReminders();
      final existingIndex = reminders.indexWhere((r) => r.id == reminderId);
      
      if (existingIndex != -1) {
        reminders[existingIndex] = reminder;
      } else {
        reminders.add(reminder);
      }

      await StorageService.saveReminders(reminders);

      // Schedule notification if reminder is not completed and is in the future
      if (reminder.status != ReminderStatus.completed && 
          combinedDateTime.isAfter(DateTime.now())) {
        await NotificationService.scheduleReminderNotification(
          id: reminderId.hashCode,
          title: 'Lembrete: ${reminder.title}',
          body: reminder.description ?? 'Você tem um lembrete agendado!',
          scheduledDate: combinedDateTime,
        );
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar lembrete: $e'),
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
        title: Text(widget.reminder == null ? 'Novo Lembrete' : 'Editar Lembrete'),
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
              onPressed: _saveReminder,
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
            _buildDescriptionField(),
            const SizedBox(height: 24),
            _buildCategorySelection(),
            const SizedBox(height: 24),
            _buildDateTimeSelection(),
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
            hintText: 'Digite o título do lembrete...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            prefixIcon: const Icon(Icons.title),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descrição (Opcional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Adicione uma descrição para o seu lembrete...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            prefixIcon: const Icon(Icons.description),
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

  Widget _buildDateTimeSelection() {
    final isInPast = _combinedDateTime.isBefore(DateTime.now());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Data e Hora',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isInPast) ...[
              const SizedBox(width: 8),
              const Icon(Icons.warning, color: Colors.orange, size: 20),
            ],
          ],
        ),
        if (isInPast) ...[
          const SizedBox(height: 4),
          Text(
            'Este horário já passou',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: Container(
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
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _selectTime,
                child: Container(
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
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime.format(context),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Uma notificação será enviada neste horário',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
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
}