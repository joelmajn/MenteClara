import 'package:mente_clara/models/category.dart';

enum ReminderStatus { pending, completed, overdue }

class Reminder {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final Category? category;
  final List<String> tags;
  final ReminderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.category,
    this.tags = const [],
    this.status = ReminderStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dateTime': dateTime.millisecondsSinceEpoch,
    'category': category?.toJson(),
    'tags': tags,
    'status': status.name,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    dateTime: DateTime.fromMillisecondsSinceEpoch(json['dateTime']),
    category: json['category'] != null 
        ? Category.fromJson(json['category'])
        : null,
    tags: List<String>.from(json['tags'] ?? []),
    status: ReminderStatus.values.byName(json['status'] ?? 'pending'),
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
  );

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    Category? category,
    List<String>? tags,
    ReminderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Reminder(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    dateTime: dateTime ?? this.dateTime,
    category: category ?? this.category,
    tags: tags ?? this.tags,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  ReminderStatus getCurrentStatus() {
    final now = DateTime.now();
    if (status == ReminderStatus.completed) return status;
    return dateTime.isBefore(now) ? ReminderStatus.overdue : ReminderStatus.pending;
  }

  bool get isOverdue => getCurrentStatus() == ReminderStatus.overdue;
  bool get isCompleted => status == ReminderStatus.completed;
  bool get isPending => getCurrentStatus() == ReminderStatus.pending;
}