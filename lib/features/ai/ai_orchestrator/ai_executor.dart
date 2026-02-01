import '../../schdules/data/models/task_model.dart';
import '../../schdules/domain/repo/schedule_repository.dart';
import 'ai_action_models.dart';

class AiExecutor {
  final ScheduleRepository _scheduleRepository;

  AiExecutor(this._scheduleRepository);

  Future<void> execute(AiAction action) async {
    await action.when(
      createTask: (name, date, startTime, endTime, importance, note) async {
        final task = TaskModel(
          name: name,
          taskDate: date,
          startTime: _parseTime(startTime, date),
          endTime: _parseTime(endTime, date),
          importanceType: importance,
          desc: note,
          category: 'Meeting', // Default category
          colorValue: 0xFF004D61, // Default color
        );
        await _scheduleRepository.addTask(task);
      },
      updateTask:
          (id, name, date, startTime, endTime, importance, note, isDone) async {
            final result = await _scheduleRepository.getTaskById(id);
            await result.fold(
              (failure) async => throw Exception(failure.message),
              (existingTask) async {
                if (existingTask == null) throw Exception('Task not found');

                final targetDate = date ?? existingTask.taskDate;
                final updatedTask = existingTask.copyWith(
                  name: name,
                  taskDate: targetDate,
                  startTime: startTime != null
                      ? _parseTime(startTime, targetDate)
                      : null,
                  endTime: endTime != null
                      ? _parseTime(endTime, targetDate)
                      : null,
                  importanceType: importance,
                  desc: note,
                  completed: isDone,
                );
                await _scheduleRepository.updateTask(updatedTask);
              },
            );
          },
      deleteTask: (id) async {
        await _scheduleRepository.deleteTask(id);
      },
      reorderDay: (date, taskIdsInOrder) async {
        print('Reordering tasks for $date: $taskIdsInOrder');
      },
      updateSettings: (theme, language, notificationsEnabled) async {
        print('Updating settings: $theme, $language, $notificationsEnabled');
      },
      unknown: (rawResponse) {
        print('Unknown action: $rawResponse');
      },
    );
  }

  DateTime? _parseTime(String? timeStr, DateTime date) {
    if (timeStr == null) return null;
    try {
      final parts = timeStr.split(':');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }
}
