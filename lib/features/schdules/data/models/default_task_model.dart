import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class DefaultTaskModel {
  final String id;
  final String name;
  final String? desc;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String category;
  final int colorValue;
  final List<int> weekdays; // 1 = Monday, 7 = Sunday
  final String? importanceType;

  final DateTime serverUpdatedAt;
  final bool isDeleted;
  final bool isDirty;
  final List<double>? embedding;
  final List<DateTime> hideOn;

  DefaultTaskModel({
    String? id,
    required this.name,
    this.desc,
    required this.startTime,
    required this.endTime,
    required this.category,
    required this.colorValue,
    required this.weekdays,
    this.importanceType,
    DateTime? serverUpdatedAt,
    this.isDeleted = false,
    this.isDirty = false,
    this.embedding,
    List<DateTime>? hideOn,
  }) : id = id ?? const Uuid().v4(),
       serverUpdatedAt = serverUpdatedAt ?? DateTime.now().toUtc(),
       hideOn = hideOn ?? [];

  DefaultTaskModel copyWith({
    String? name,
    String? desc,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? category,
    int? colorValue,
    List<int>? weekdays,
    String? importanceType,
    DateTime? serverUpdatedAt,
    bool? isDeleted,
    bool? isDirty,
    List<double>? embedding,
    List<DateTime>? hideOn,
  }) {
    return DefaultTaskModel(
      id: id,
      name: name ?? this.name,
      desc: desc ?? this.desc,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      colorValue: colorValue ?? this.colorValue,
      weekdays: weekdays ?? this.weekdays,
      importanceType: importanceType ?? this.importanceType,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isDirty: isDirty ?? this.isDirty,
      embedding: embedding ?? this.embedding,
      hideOn: hideOn ?? this.hideOn,
    );
  }

  // SQLite Mapping
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'desc': desc,
      'start_time': '${startTime.hour}:${startTime.minute}',
      'end_time': '${endTime.hour}:${endTime.minute}',
      'category': category,
      'color_value': colorValue,
      'weekdays': weekdays.join(','), // Store as comma-separated string
      'importance_type': importanceType,
      'server_updated_at': serverUpdatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
      'is_dirty': isDirty ? 1 : 0,
      'embedding': embedding != null ? embedding!.join(',') : null,
      'hide_on': hideOn.map((d) => d.toIso8601String().split('T')[0]).join(','),
    };
  }

  factory DefaultTaskModel.fromMap(Map<String, dynamic> map) {
    TimeOfDay parseTime(String timeStr) {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return DefaultTaskModel(
      id: map['id'],
      name: map['name'],
      desc: map['desc'],
      startTime: parseTime(map['start_time']),
      endTime: parseTime(map['end_time']),
      category: map['category'],
      colorValue: map['color_value'],
      weekdays: (map['weekdays'] as String)
          .split(',')
          .map((e) => int.parse(e))
          .toList(),
      importanceType: map['importance_type'],
      serverUpdatedAt: DateTime.parse(map['server_updated_at']),
      isDeleted: map['is_deleted'] == 1,
      isDirty: (map['is_dirty'] ?? 0) == 1,
      embedding: map['embedding'] != null
          ? (map['embedding'] as String)
                .split(',')
                .map((e) => double.parse(e))
                .toList()
          : null,
      hideOn: map['hide_on'] != null && (map['hide_on'] as String).isNotEmpty
          ? (map['hide_on'] as String)
                .split(',')
                .map((e) => DateTime.parse(e))
                .toList()
          : [],
    );
  }

  // Supabase Mapping
  Map<String, dynamic> toSupabaseJson(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'desc': desc,
      'start_time': '${startTime.hour}:${startTime.minute}',
      'end_time': '${endTime.hour}:${endTime.minute}',
      'category': category,
      'color_value': colorValue,
      'weekdays': weekdays.join(','),
      'importance_type': importanceType,
      'server_updated_at': serverUpdatedAt.toIso8601String(),
      'is_deleted': isDeleted,
      'embedding': embedding,
      'hide_on': hideOn.map((d) => d.toIso8601String().split('T')[0]).toList(),
    };
  }

  factory DefaultTaskModel.fromSupabaseJson(Map<String, dynamic> json) {
    TimeOfDay parseTime(String timeStr) {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    List<double>? parsedEmbedding;
    if (json['embedding'] != null) {
      if (json['embedding'] is List) {
        parsedEmbedding = (json['embedding'] as List)
            .map((e) => (e as num).toDouble())
            .toList();
      } else if (json['embedding'] is String) {
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

    return DefaultTaskModel(
      id: json['id'],
      name: json['name'],
      desc: json['desc'],
      startTime: parseTime(json['start_time']),
      endTime: parseTime(json['end_time']),
      category: json['category'],
      colorValue: json['color_value'],
      weekdays: (json['weekdays'] as String)
          .split(',')
          .map((e) => int.parse(e))
          .toList(),
      importanceType: json['importance_type'],
      serverUpdatedAt: DateTime.parse(json['server_updated_at']),
      isDeleted: json['is_deleted'] ?? false,
      embedding: parsedEmbedding,
      hideOn: json['hide_on'] != null
          ? (json['hide_on'] as List).map((e) => DateTime.parse(e)).toList()
          : [],
    );
  }

  Color get color => Color(colorValue);
}
