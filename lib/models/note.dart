import 'package:mente_clara/models/category.dart';

enum NoteContentType { text, checklist, date }

class NoteChecklistItem {
  final String id;
  final String text;
  final bool isCompleted;

  NoteChecklistItem({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isCompleted': isCompleted,
  };

  factory NoteChecklistItem.fromJson(Map<String, dynamic> json) => NoteChecklistItem(
    id: json['id'],
    text: json['text'],
    isCompleted: json['isCompleted'] ?? false,
  );

  NoteChecklistItem copyWith({
    String? id,
    String? text,
    bool? isCompleted,
  }) => NoteChecklistItem(
    id: id ?? this.id,
    text: text ?? this.text,
    isCompleted: isCompleted ?? this.isCompleted,
  );
}

class Note {
  final String id;
  final String title;
  final String content;
  final NoteContentType contentType;
  final List<NoteChecklistItem> checklistItems;
  final DateTime? noteDate;
  final Category? category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.contentType = NoteContentType.text,
    this.checklistItems = const [],
    this.noteDate,
    this.category,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'contentType': contentType.name,
    'checklistItems': checklistItems.map((item) => item.toJson()).toList(),
    'noteDate': noteDate?.millisecondsSinceEpoch,
    'category': category?.toJson(),
    'tags': tags,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    contentType: NoteContentType.values.byName(json['contentType'] ?? 'text'),
    checklistItems: (json['checklistItems'] as List?)
        ?.map((item) => NoteChecklistItem.fromJson(item))
        .toList() ?? [],
    noteDate: json['noteDate'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['noteDate'])
        : null,
    category: json['category'] != null 
        ? Category.fromJson(json['category'])
        : null,
    tags: List<String>.from(json['tags'] ?? []),
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
  );

  Note copyWith({
    String? id,
    String? title,
    String? content,
    NoteContentType? contentType,
    List<NoteChecklistItem>? checklistItems,
    DateTime? noteDate,
    Category? category,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Note(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    contentType: contentType ?? this.contentType,
    checklistItems: checklistItems ?? this.checklistItems,
    noteDate: noteDate ?? this.noteDate,
    category: category ?? this.category,
    tags: tags ?? this.tags,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}