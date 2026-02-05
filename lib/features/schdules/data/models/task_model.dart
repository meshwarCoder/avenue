import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/category_utils.dart';

class TaskModel {
  final String id;
  final String name;
  final String? desc;
  final DateTime taskDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool completed;
  final String category;
  final bool oneTime;
  final bool isDeleted;
  final DateTime serverUpdatedAt;
  final String? importanceType;
  final bool isDirty;
  final List<double>? embedding;
  final String? defaultTaskId;

  TaskModel({
    String? id,
    required this.name,
    this.desc,
    required this.taskDate,
    this.startTime,
    this.endTime,
    this.completed = false,
    required this.category,
    bool? oneTime,
    bool? isDeleted,
    DateTime? serverUpdatedAt,
    this.importanceType,
    this.isDirty = false,
    this.embedding,
    this.defaultTaskId,
  }) : id = id ?? const Uuid().v4(),
       oneTime = oneTime ?? true,
       isDeleted = isDeleted ?? false,
       serverUpdatedAt = serverUpdatedAt ?? DateTime.now().toUtc();

  // SQLite Mapping
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'desc': desc,
      'task_date': taskDate.toIso8601String(),
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'completed': completed ? 1 : 0,
      'category': category,
      'one_time': oneTime ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'server_updated_at': serverUpdatedAt.toIso8601String(),
      'importance_type': importanceType,
      'is_dirty': isDirty ? 1 : 0,
      // Embedding removed locally to save space
      'default_task_id': defaultTaskId,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? const Uuid().v4(),
      name: map['name'] ?? map['title'] ?? 'Untitled Task',
      desc: map['desc'] ?? map['description'],
      taskDate: DateTime.parse(
        map['task_date'] ?? map['date'] ?? DateTime.now().toIso8601String(),
      ),
      startTime: map['start_time'] != null
          ? DateTime.parse(map['start_time'])
          : null,
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      completed: (map['completed'] ?? map['is_done']) == 1,
      category: map['category'] ?? 'Meeting',
      oneTime: (map['one_time'] ?? 1) == 1,
      isDeleted: (map['is_deleted'] ?? 0) == 1,
      serverUpdatedAt: DateTime.parse(
        map['server_updated_at'] ??
            map['updated_at'] ??
            DateTime.now().toIso8601String(),
      ),
      importanceType: map['importance_type'],
      isDirty: (map['is_dirty'] ?? 0) == 1,
      // embedding: not stored locally anymore
      defaultTaskId: map['default_task_id'],
    );
  }

  // Supabase Mapping
  Map<String, dynamic> toSupabaseJson(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'desc': desc,
      'task_date': taskDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'start_time': startTime
          ?.toIso8601String()
          .split('T')[1]
          .substring(0, 8), // HH:mm:ss
      'end_time': endTime
          ?.toIso8601String()
          .split('T')[1]
          .substring(0, 8), // HH:mm:ss
      'completed': completed,
      'category': category,
      'one_time': oneTime,
      'is_deleted': isDeleted,
      'server_updated_at': serverUpdatedAt.toIso8601String(),
      'importance_type': importanceType,
      'embedding': embedding, // Supabase handles vector/array
      'default_task_id': defaultTaskId,
    };
  }

  factory TaskModel.fromSupabaseJson(Map<String, dynamic> json) {
    // Parse time strings back to DateTime if they exist
    DateTime? parseTime(String? timeStr, DateTime date) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }

    final dateStr =
        json['task_date'] ?? json['date'] ?? DateTime.now().toIso8601String();
    final date = DateTime.parse(dateStr);

    List<double>? parsedEmbedding;
    if (json['embedding'] != null) {
      // Supabase returns vector as string like "[0.1, 0.2, ...]" or List<dynamic> depending on client
      if (json['embedding'] is List) {
        parsedEmbedding = (json['embedding'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
      } else if (json['embedding'] is String) {
        // Handle string representation if needed, though usually client decodes or returns string
        final s = json['embedding'] as String;
        if (s.startsWith('[') && s.endsWith(']')) {
          parsedEmbedding = s
              .substring(1, s.length - 1)
              .split(',')
              .map((e) => double.parse(e.trim()))
              .toList();
        }
      }
    }

    return TaskModel(
      id: json['id'] ?? const Uuid().v4(),
      name: json['name'] ?? 'Untitled Task',
      desc: json['desc'],
      taskDate: date,
      startTime: parseTime(json['start_time'], date),
      endTime: parseTime(json['end_time'], date),
      completed: json['completed'] ?? false,
      category: json['category'] ?? 'Meeting',
      oneTime: json['one_time'] ?? true,
      isDeleted: json['is_deleted'] ?? false,
      serverUpdatedAt: json['server_updated_at'] != null
          ? DateTime.parse(json['server_updated_at']).toUtc()
          : DateTime.now().toUtc(),
      importanceType: json['importance_type'],
      embedding: parsedEmbedding,
      defaultTaskId: json['default_task_id'],
    );
  }

  // Helper to get Color from CategoryUtils
  Color get color => CategoryUtils.getCategoryColor(category);

  // Helper to get duration in minutes
  int get durationInMinutes {
    if (startTime == null || endTime == null) return 0;
    final duration = endTime!.difference(startTime!).inMinutes;
    return duration < 0 ? duration + (24 * 60) : duration;
  }

  // Helper to get TimeOfDay from DateTime
  TimeOfDay? get startTimeOfDay => startTime != null
      ? TimeOfDay(hour: startTime!.hour, minute: startTime!.minute)
      : null;
  TimeOfDay? get endTimeOfDay => endTime != null
      ? TimeOfDay(hour: endTime!.hour, minute: endTime!.minute)
      : null;

  // Factory to create from UI (with TimeOfDay)
  factory TaskModel.fromTimeOfDay({
    String? id,
    required String name,
    String? desc,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required DateTime taskDate,
    bool completed = false,
    required String category,
    bool oneTime = true,
    String? importanceType,
    String? defaultTaskId,
  }) {
    final normalizedDate = DateTime(
      taskDate.year,
      taskDate.month,
      taskDate.day,
    );
    return TaskModel(
      id: id,
      name: name,
      desc: desc,
      startTime: DateTime(
        normalizedDate.year,
        normalizedDate.month,
        normalizedDate.day,
        startTime.hour,
        startTime.minute,
      ),
      endTime: DateTime(
        normalizedDate.year,
        normalizedDate.month,
        normalizedDate.day,
        endTime.hour,
        endTime.minute,
      ),
      taskDate: normalizedDate,
      completed: completed,
      category: category,
      oneTime: oneTime,
      importanceType: importanceType,
      defaultTaskId: defaultTaskId,
    );
  }

  TaskModel copyWith({
    String? name,
    String? desc,
    DateTime? taskDate,
    DateTime? startTime,
    DateTime? endTime,
    bool? completed,
    String? category,
    bool? oneTime,
    bool? isDeleted,
    DateTime? serverUpdatedAt,
    String? importanceType,
    List<double>? embedding,
    bool? isDirty,
  }) {
    return TaskModel(
      id: id,
      name: name ?? this.name,
      desc: desc ?? this.desc,
      taskDate: taskDate ?? this.taskDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      completed: completed ?? this.completed,
      category: category ?? this.category,
      oneTime: oneTime ?? this.oneTime,
      isDeleted: isDeleted ?? this.isDeleted,
      serverUpdatedAt: serverUpdatedAt ?? DateTime.now().toUtc(),
      importanceType: importanceType ?? this.importanceType,
      embedding: embedding ?? this.embedding,
      isDirty: isDirty ?? this.isDirty,
      defaultTaskId: defaultTaskId ?? this.defaultTaskId,
    );
  }

  /// Generates a deterministic UUID v5 ID for a daily instance of a default task.
  /// This ensures that the same default task on the same day always has the same ID.
  static String generatePredictableId(String defaultTaskId, DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD
    return const Uuid().v5(
      Uuid.NAMESPACE_URL,
      "default_${defaultTaskId}_$dateStr",
    );
  }
}
