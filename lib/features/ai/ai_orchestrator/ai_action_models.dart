import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_action_models.freezed.dart';
part 'ai_action_models.g.dart';

@Freezed(unionKey: 'type')
sealed class AiAction with _$AiAction {
  const factory AiAction.createTask({
    required String name,
    required DateTime date,
    String? startTime,
    String? endTime,
    @Default('Medium') String importance,
    String? note,
  }) = CreateTaskAction;

  const factory AiAction.updateTask({
    required String id,
    String? name,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? importance,
    String? note,
    bool? isDone,
  }) = UpdateTaskAction;

  const factory AiAction.deleteTask({required String id}) = DeleteTaskAction;

  const factory AiAction.reorderDay({
    required DateTime date,
    required List<String> taskIdsInOrder,
  }) = ReorderDayAction;

  const factory AiAction.updateSettings({
    String? theme,
    String? language,
    bool? notificationsEnabled,
  }) = UpdateSettingsAction;

  const factory AiAction.unknown({required String rawResponse}) = UnknownAction;

  factory AiAction.fromJson(Map<String, dynamic> json) =>
      _$AiActionFromJson(json);
}
