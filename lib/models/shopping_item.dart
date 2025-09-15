import 'package:mente_clara/models/category.dart';

enum ShoppingItemType { simple, advanced }

class SimpleShoppingItem {
  final String id;
  final String name;
  final bool isPurchased;
  final Category? category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  SimpleShoppingItem({
    required this.id,
    required this.name,
    this.isPurchased = false,
    this.category,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isPurchased': isPurchased,
    'category': category?.toJson(),
    'tags': tags,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory SimpleShoppingItem.fromJson(Map<String, dynamic> json) => SimpleShoppingItem(
    id: json['id'],
    name: json['name'],
    isPurchased: json['isPurchased'] ?? false,
    category: json['category'] != null 
        ? Category.fromJson(json['category'])
        : null,
    tags: List<String>.from(json['tags'] ?? []),
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
  );

  SimpleShoppingItem copyWith({
    String? id,
    String? name,
    bool? isPurchased,
    Category? category,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SimpleShoppingItem(
    id: id ?? this.id,
    name: name ?? this.name,
    isPurchased: isPurchased ?? this.isPurchased,
    category: category ?? this.category,
    tags: tags ?? this.tags,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class AdvancedShoppingItem {
  final String id;
  final String name;
  final DateTime? purchaseDate;
  final DateTime estimatedEndDate;
  final int daysToAlert;
  final Category? category;
  final List<String> tags;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdvancedShoppingItem({
    required this.id,
    required this.name,
    this.purchaseDate,
    required this.estimatedEndDate,
    this.daysToAlert = 3,
    this.category,
    this.tags = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'purchaseDate': purchaseDate?.millisecondsSinceEpoch,
    'estimatedEndDate': estimatedEndDate.millisecondsSinceEpoch,
    'daysToAlert': daysToAlert,
    'category': category?.toJson(),
    'tags': tags,
    'isActive': isActive,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory AdvancedShoppingItem.fromJson(Map<String, dynamic> json) => AdvancedShoppingItem(
    id: json['id'],
    name: json['name'],
    purchaseDate: json['purchaseDate'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['purchaseDate'])
        : null,
    estimatedEndDate: DateTime.fromMillisecondsSinceEpoch(json['estimatedEndDate']),
    daysToAlert: json['daysToAlert'] ?? 3,
    category: json['category'] != null 
        ? Category.fromJson(json['category'])
        : null,
    tags: List<String>.from(json['tags'] ?? []),
    isActive: json['isActive'] ?? true,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
  );

  AdvancedShoppingItem copyWith({
    String? id,
    String? name,
    DateTime? purchaseDate,
    DateTime? estimatedEndDate,
    int? daysToAlert,
    Category? category,
    List<String>? tags,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AdvancedShoppingItem(
    id: id ?? this.id,
    name: name ?? this.name,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    estimatedEndDate: estimatedEndDate ?? this.estimatedEndDate,
    daysToAlert: daysToAlert ?? this.daysToAlert,
    category: category ?? this.category,
    tags: tags ?? this.tags,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  bool get isRunningOut {
    final now = DateTime.now();
    final alertDate = estimatedEndDate.subtract(Duration(days: daysToAlert));
    return now.isAfter(alertDate) && isActive;
  }

  int get daysRemaining {
    final now = DateTime.now();
    return estimatedEndDate.difference(now).inDays;
  }
}