import 'package:uuid/uuid.dart';

enum InboxItemType {
  task,
  idea,
  note,
  brainDump;

  String get displayName {
    switch (this) {
      case InboxItemType.task:
        return 'Task';
      case InboxItemType.idea:
        return 'Idea';
      case InboxItemType.note:
        return 'Note';
      case InboxItemType.brainDump:
        return 'Brain Dump';
    }
  }

  /// Converts enum to the string stored in SQLite / Supabase.
  String toStorageString() {
    switch (this) {
      case InboxItemType.task:
        return 'task';
      case InboxItemType.idea:
        return 'idea';
      case InboxItemType.note:
        return 'note';
      case InboxItemType.brainDump:
        return 'brain_dump';
    }
  }

  /// Parses the storage string back to an enum value.
  static InboxItemType fromStorageString(String? value) {
    switch (value) {
      case 'task':
        return InboxItemType.task;
      case 'idea':
        return InboxItemType.idea;
      case 'note':
        return InboxItemType.note;
      case 'brain_dump':
        return InboxItemType.brainDump;
      default:
        return InboxItemType.note;
    }
  }
}

class InboxItemModel {
  final String id;
  final String title;
  final String? content;
  final InboxItemType type;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool isDirty;
  final DateTime? serverUpdatedAt;
  final List<double>? embedding;

  InboxItemModel({
    String? id,
    required this.title,
    this.content,
    required this.type,
    this.deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    this.isDirty = false,
    this.serverUpdatedAt,
    this.embedding,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc(),
        isDeleted = isDeleted ?? false;

  // SQLite Mapping
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.toStorageString(),
      'deadline': deadline?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'is_dirty': isDirty ? 1 : 0,
      'server_updated_at': serverUpdatedAt?.toIso8601String(),
      // Embedding removed locally to save space
    };
  }

  factory InboxItemModel.fromMap(Map<String, dynamic> map) {
    List<double>? parsedEmbedding;
    if (map['embedding'] is List) {
      parsedEmbedding = (map['embedding'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    return InboxItemModel(
      id: map['id'] ?? const Uuid().v4(),
      title: map['title'] ?? 'Untitled',
      content: map['content'],
      type: InboxItemType.fromStorageString(map['type']),
      deadline:
          map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      isDeleted: (map['is_deleted'] ?? 0) == 1,
      isDirty: (map['is_dirty'] ?? 0) == 1,
      serverUpdatedAt: map['server_updated_at'] != null
          ? DateTime.parse(map['server_updated_at'])
          : null,
      embedding: parsedEmbedding,
    );
  }

  // Supabase Mapping
  Map<String, dynamic> toSupabaseJson(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'type': type.toStorageString(),
      'deadline': deadline?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
      'is_dirty': isDirty,
      'server_updated_at': serverUpdatedAt?.toIso8601String(),
      // 'embedding': embedding, // Removed: Supabase now handles embedding generation
    };
  }

  factory InboxItemModel.fromSupabaseJson(Map<String, dynamic> json) {
    List<double>? parsedEmbedding;
    if (json['embedding'] is List) {
      parsedEmbedding = (json['embedding'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    return InboxItemModel(
      id: json['id'] ?? const Uuid().v4(),
      title: json['title'] ?? 'Untitled',
      content: json['content'],
      type: InboxItemType.fromStorageString(json['type']),
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toUtc()
          : DateTime.now().toUtc(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at']).toUtc()
          : DateTime.now().toUtc(),
      isDeleted: json['is_deleted'] ?? false,
      isDirty: json['is_dirty'] ?? false,
      serverUpdatedAt: json['server_updated_at'] != null
          ? DateTime.parse(json['server_updated_at']).toUtc()
          : null,
      embedding: parsedEmbedding,
    );
  }

  InboxItemModel copyWith({
    String? title,
    String? content,
    InboxItemType? type,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isDirty,
    DateTime? serverUpdatedAt,
    List<double>? embedding,
  }) {
    return InboxItemModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isDirty: isDirty ?? this.isDirty,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      embedding: embedding ?? this.embedding,
    );
  }
}
