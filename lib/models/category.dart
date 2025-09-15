import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String emoji;
  final Color color;

  Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'color': color.value,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    emoji: json['emoji'],
    color: Color(json['color']),
  );
}

class CategoryHelper {
  static List<Category> getDefaultCategories() => [
    Category(id: '1', name: 'Trabalho', emoji: '💼', color: const Color(0xFF3B82F6)),
    Category(id: '2', name: 'Pessoal', emoji: '🏠', color: const Color(0xFFEF4444)),
    Category(id: '3', name: 'Estudos', emoji: '📚', color: const Color(0xFF10B981)),
    Category(id: '4', name: 'Saúde', emoji: '💊', color: const Color(0xFFF59E0B)),
    Category(id: '5', name: 'Lazer', emoji: '🎮', color: const Color(0xFF8B5CF6)),
    Category(id: '6', name: 'Compras', emoji: '🛒', color: const Color(0xFFEC4899)),
    Category(id: '7', name: 'Família', emoji: '👨‍👩‍👧‍👦', color: const Color(0xFF06B6D4)),
    Category(id: '8', name: 'Financeiro', emoji: '💰', color: const Color(0xFF84CC16)),
  ];
}