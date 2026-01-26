import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late DateTime startTime;

  @HiveField(4)
  late DateTime endTime;

  @HiveField(5)
  late DateTime date; // Normalized to day (00:00:00)

  @HiveField(6)
  late bool isDone;

  @HiveField(7)
  late String category;

  @HiveField(8)
  late int colorValue;

  TaskModel({
    String? id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.date,
    this.isDone = false,
    required this.category,
    int? colorValue,
  }) {
    this.id = id ?? const Uuid().v4();
    this.colorValue = colorValue ?? Colors.blue.value;
  }

  // Helper to get Color from colorValue
  Color get color => Color(colorValue);

  // Helper to get duration in minutes
  int get durationInMinutes {
    final duration = endTime.difference(startTime).inMinutes;
    return duration < 0 ? duration + (24 * 60) : duration;
  }

  // Helper to get TimeOfDay from DateTime
  TimeOfDay get startTimeOfDay =>
      TimeOfDay(hour: startTime.hour, minute: startTime.minute);
  TimeOfDay get endTimeOfDay =>
      TimeOfDay(hour: endTime.hour, minute: endTime.minute);

  // Factory to create from UI (with TimeOfDay)
  factory TaskModel.fromTimeOfDay({
    String? id,
    required String title,
    required String description,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required DateTime date,
    bool isDone = false,
    required String category,
    required Color color,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return TaskModel(
      id: id,
      title: title,
      description: description,
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
      date: normalizedDate,
      isDone: isDone,
      category: category,
      colorValue: color.value,
    );
  }

  // Copy with method
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? date,
    bool? isDone,
    String? category,
    Color? color,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      date: date ?? this.date,
      isDone: isDone ?? this.isDone,
      category: category ?? this.category,
      colorValue: color?.value ?? colorValue,
    );
  }
}
