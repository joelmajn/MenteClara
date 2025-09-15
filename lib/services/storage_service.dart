import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mente_clara/models/note.dart';
import 'package:mente_clara/models/reminder.dart';
import 'package:mente_clara/models/shopping_item.dart';
import 'package:mente_clara/models/category.dart';

class StorageService {
  static const String _notesKey = 'notes';
  static const String _remindersKey = 'reminders';
  static const String _simpleShoppingKey = 'simple_shopping_items';
  static const String _advancedShoppingKey = 'advanced_shopping_items';
  static const String _categoriesKey = 'categories';

  static Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // Notes
  static Future<List<Note>> getNotes() async {
    final prefs = await _prefs;
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    return notesJson.map((json) => Note.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> saveNotes(List<Note> notes) async {
    final prefs = await _prefs;
    final notesJson = notes.map((note) => jsonEncode(note.toJson())).toList();
    await prefs.setStringList(_notesKey, notesJson);
  }

  // Reminders
  static Future<List<Reminder>> getReminders() async {
    final prefs = await _prefs;
    final remindersJson = prefs.getStringList(_remindersKey) ?? [];
    return remindersJson.map((json) => Reminder.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> saveReminders(List<Reminder> reminders) async {
    final prefs = await _prefs;
    final remindersJson = reminders.map((reminder) => jsonEncode(reminder.toJson())).toList();
    await prefs.setStringList(_remindersKey, remindersJson);
  }

  // Simple Shopping Items
  static Future<List<SimpleShoppingItem>> getSimpleShoppingItems() async {
    final prefs = await _prefs;
    final itemsJson = prefs.getStringList(_simpleShoppingKey) ?? [];
    return itemsJson.map((json) => SimpleShoppingItem.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> saveSimpleShoppingItems(List<SimpleShoppingItem> items) async {
    final prefs = await _prefs;
    final itemsJson = items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_simpleShoppingKey, itemsJson);
  }

  // Advanced Shopping Items
  static Future<List<AdvancedShoppingItem>> getAdvancedShoppingItems() async {
    final prefs = await _prefs;
    final itemsJson = prefs.getStringList(_advancedShoppingKey) ?? [];
    return itemsJson.map((json) => AdvancedShoppingItem.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> saveAdvancedShoppingItems(List<AdvancedShoppingItem> items) async {
    final prefs = await _prefs;
    final itemsJson = items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_advancedShoppingKey, itemsJson);
  }

  // Categories
  static Future<List<Category>> getCategories() async {
    final prefs = await _prefs;
    final categoriesJson = prefs.getStringList(_categoriesKey);
    if (categoriesJson == null || categoriesJson.isEmpty) {
      final defaultCategories = CategoryHelper.getDefaultCategories();
      await saveCategories(defaultCategories);
      return defaultCategories;
    }
    return categoriesJson.map((json) => Category.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> saveCategories(List<Category> categories) async {
    final prefs = await _prefs;
    final categoriesJson = categories.map((category) => jsonEncode(category.toJson())).toList();
    await prefs.setStringList(_categoriesKey, categoriesJson);
  }

  // Clear all data
  static Future<void> clearAllData() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}