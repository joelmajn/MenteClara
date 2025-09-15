import 'package:uuid/uuid.dart';
import 'package:mente_clara/models/note.dart';
import 'package:mente_clara/models/reminder.dart';
import 'package:mente_clara/models/shopping_item.dart';
import 'package:mente_clara/models/category.dart';
import 'package:mente_clara/services/storage_service.dart';
import 'package:mente_clara/services/notification_service.dart';

class DataService {
  static const Uuid _uuid = Uuid();

  // Sample data generation
  static Future<void> initializeSampleData() async {
    final notes = await StorageService.getNotes();
    final reminders = await StorageService.getReminders();
    final simpleItems = await StorageService.getSimpleShoppingItems();
    final advancedItems = await StorageService.getAdvancedShoppingItems();

    if (notes.isEmpty && reminders.isEmpty && simpleItems.isEmpty && advancedItems.isEmpty) {
      await _generateSampleData();
    }
  }

  static Future<void> _generateSampleData() async {
    final categories = await StorageService.getCategories();
    final now = DateTime.now();

    // Sample notes
    final sampleNotes = [
      Note(
        id: _uuid.v4(),
        title: 'Reunião de equipe',
        content: 'Discutir o progresso do projeto e definir próximas etapas',
        category: categories[0], // Trabalho
        tags: ['reuniao', 'projeto'],
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Note(
        id: _uuid.v4(),
        title: 'Lista de exercícios',
        content: '',
        contentType: NoteContentType.checklist,
        checklistItems: [
          NoteChecklistItem(id: _uuid.v4(), text: 'Corrida matinal', isCompleted: true),
          NoteChecklistItem(id: _uuid.v4(), text: 'Musculação'),
          NoteChecklistItem(id: _uuid.v4(), text: 'Yoga'),
        ],
        category: categories[3], // Saúde
        tags: ['exercicio', 'rotina'],
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
      Note(
        id: _uuid.v4(),
        title: 'Ideias para o fim de semana',
        content: 'Cinema novo do shopping\nPiquenique no parque\nVisitar museu de arte',
        category: categories[4], // Lazer
        tags: ['fim-de-semana', 'diversao'],
        createdAt: now.subtract(const Duration(hours: 8)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
    ];

    // Sample reminders
    final sampleReminders = [
      Reminder(
        id: _uuid.v4(),
        title: 'Consulta médica',
        description: 'Check-up anual com Dr. Silva',
        dateTime: now.add(const Duration(days: 3, hours: 10)),
        category: categories[3], // Saúde
        tags: ['medico', 'consulta'],
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Reminder(
        id: _uuid.v4(),
        title: 'Entrega do relatório',
        description: 'Relatório mensal de vendas deve ser entregue até 17h',
        dateTime: now.add(const Duration(days: 1, hours: 17)),
        category: categories[0], // Trabalho
        tags: ['relatorio', 'prazo'],
        createdAt: now.subtract(const Duration(hours: 18)),
        updatedAt: now.subtract(const Duration(hours: 18)),
      ),
      Reminder(
        id: _uuid.v4(),
        title: 'Aniversário da Maria',
        description: 'Não esquecer de parabenizar!',
        dateTime: now.add(const Duration(days: 5, hours: 9)),
        category: categories[6], // Família
        tags: ['aniversario', 'familia'],
        createdAt: now.subtract(const Duration(hours: 24)),
        updatedAt: now.subtract(const Duration(hours: 24)),
      ),
    ];

    // Simple shopping items
    final simpleShoppingItems = [
      SimpleShoppingItem(
        id: _uuid.v4(),
        name: 'Leite',
        category: categories[5], // Compras
        tags: ['alimentacao', 'urgente'],
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      SimpleShoppingItem(
        id: _uuid.v4(),
        name: 'Shampoo',
        isPurchased: true,
        category: categories[3], // Saúde
        tags: ['higiene'],
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      SimpleShoppingItem(
        id: _uuid.v4(),
        name: 'Pilhas AA',
        category: categories[1], // Pessoal
        tags: ['eletronicos'],
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now.subtract(const Duration(hours: 12)),
      ),
    ];

    // Advanced shopping items
    final advancedShoppingItems = [
      AdvancedShoppingItem(
        id: _uuid.v4(),
        name: 'Pasta de dente',
        purchaseDate: now.subtract(const Duration(days: 25)),
        estimatedEndDate: now.add(const Duration(days: 5)),
        category: categories[3], // Saúde
        tags: ['higiene', 'essencial'],
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 25)),
      ),
      AdvancedShoppingItem(
        id: _uuid.v4(),
        name: 'Detergente',
        purchaseDate: now.subtract(const Duration(days: 15)),
        estimatedEndDate: now.add(const Duration(days: 15)),
        category: categories[1], // Pessoal
        tags: ['limpeza', 'casa'],
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),
      AdvancedShoppingItem(
        id: _uuid.v4(),
        name: 'Café',
        purchaseDate: now.subtract(const Duration(days: 8)),
        estimatedEndDate: now.add(const Duration(days: 2)),
        daysToAlert: 2,
        category: categories[5], // Compras
        tags: ['bebida', 'matinal'],
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 8)),
      ),
    ];

    // Save sample data
    await StorageService.saveNotes(sampleNotes);
    await StorageService.saveReminders(sampleReminders);
    await StorageService.saveSimpleShoppingItems(simpleShoppingItems);
    await StorageService.saveAdvancedShoppingItems(advancedShoppingItems);

    // Schedule notifications for reminders
    for (final reminder in sampleReminders) {
      await NotificationService.scheduleReminderNotification(
        id: reminder.id.hashCode,
        title: 'Lembrete: ${reminder.title}',
        body: reminder.description ?? 'Você tem um lembrete agendado!',
        scheduledDate: reminder.dateTime,
      );
    }

    // Schedule notifications for advanced shopping items that are running out
    for (final item in advancedShoppingItems) {
      if (item.isRunningOut) {
        await NotificationService.scheduleShoppingNotification(
          id: item.id.hashCode,
          title: 'Item acabando: ${item.name}',
          body: 'Este item está acabando e foi adicionado à sua lista de compras!',
          scheduledDate: item.estimatedEndDate.subtract(Duration(days: item.daysToAlert)),
        );
      }
    }
  }

  // Auto-add advanced items to simple shopping list when running out
  static Future<void> checkAdvancedItemsAndAddToSimpleList() async {
    final advancedItems = await StorageService.getAdvancedShoppingItems();
    final simpleItems = await StorageService.getSimpleShoppingItems();

    final itemsToAdd = <SimpleShoppingItem>[];
    final now = DateTime.now();

    for (final advancedItem in advancedItems) {
      if (advancedItem.isRunningOut && advancedItem.isActive) {
        // Check if item already exists in simple list
        final existsInSimpleList = simpleItems.any(
          (simple) => simple.name.toLowerCase() == advancedItem.name.toLowerCase()
        );

        if (!existsInSimpleList) {
          itemsToAdd.add(
            SimpleShoppingItem(
              id: _uuid.v4(),
              name: advancedItem.name,
              category: advancedItem.category,
              tags: [...advancedItem.tags, 'auto-adicionado'],
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      }
    }

    if (itemsToAdd.isNotEmpty) {
      final updatedSimpleItems = [...simpleItems, ...itemsToAdd];
      await StorageService.saveSimpleShoppingItems(updatedSimpleItems);

      // Schedule notifications for auto-added items
      for (final item in itemsToAdd) {
        await NotificationService.scheduleShoppingNotification(
          id: item.id.hashCode,
          title: 'Item adicionado automaticamente: ${item.name}',
          body: 'Este item está acabando e foi adicionado à sua lista de compras!',
          scheduledDate: now,
        );
      }
    }
  }
}