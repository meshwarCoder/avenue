// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_action_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateTaskAction _$CreateTaskActionFromJson(Map<String, dynamic> json) =>
    CreateTaskAction(
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      importance: json['importance'] as String? ?? 'Medium',
      note: json['note'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$CreateTaskActionToJson(CreateTaskAction instance) =>
    <String, dynamic>{
      'name': instance.name,
      'date': instance.date.toIso8601String(),
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'importance': instance.importance,
      'note': instance.note,
      'type': instance.$type,
    };

UpdateTaskAction _$UpdateTaskActionFromJson(Map<String, dynamic> json) =>
    UpdateTaskAction(
      id: json['id'] as String,
      name: json['name'] as String?,
      date: json['date'] == null
          ? null
          : DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      importance: json['importance'] as String?,
      note: json['note'] as String?,
      isDone: json['isDone'] as bool?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$UpdateTaskActionToJson(UpdateTaskAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'date': instance.date?.toIso8601String(),
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'importance': instance.importance,
      'note': instance.note,
      'isDone': instance.isDone,
      'type': instance.$type,
    };

DeleteTaskAction _$DeleteTaskActionFromJson(Map<String, dynamic> json) =>
    DeleteTaskAction(id: json['id'] as String, $type: json['type'] as String?);

Map<String, dynamic> _$DeleteTaskActionToJson(DeleteTaskAction instance) =>
    <String, dynamic>{'id': instance.id, 'type': instance.$type};

ReorderDayAction _$ReorderDayActionFromJson(Map<String, dynamic> json) =>
    ReorderDayAction(
      date: DateTime.parse(json['date'] as String),
      taskIdsInOrder: (json['taskIdsInOrder'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ReorderDayActionToJson(ReorderDayAction instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'taskIdsInOrder': instance.taskIdsInOrder,
      'type': instance.$type,
    };

UpdateSettingsAction _$UpdateSettingsActionFromJson(
  Map<String, dynamic> json,
) => UpdateSettingsAction(
  theme: json['theme'] as String?,
  language: json['language'] as String?,
  notificationsEnabled: json['notificationsEnabled'] as bool?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$UpdateSettingsActionToJson(
  UpdateSettingsAction instance,
) => <String, dynamic>{
  'theme': instance.theme,
  'language': instance.language,
  'notificationsEnabled': instance.notificationsEnabled,
  'type': instance.$type,
};

UnknownAction _$UnknownActionFromJson(Map<String, dynamic> json) =>
    UnknownAction(
      rawResponse: json['rawResponse'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$UnknownActionToJson(UnknownAction instance) =>
    <String, dynamic>{
      'rawResponse': instance.rawResponse,
      'type': instance.$type,
    };
