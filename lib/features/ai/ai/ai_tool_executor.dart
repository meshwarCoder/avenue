import 'package:uuid/uuid.dart';
import '../../../../core/utils/observability.dart';
import '../../schdules/data/models/task_model.dart';
import '../../schdules/domain/repo/schedule_repository.dart';

class AiToolExecutor {
  final ScheduleRepository _repository;

  AiToolExecutor(this._repository);

  Future<Map<String, dynamic>> execute(
    String name,
    Map<String, dynamic> args,
  ) async {
    AvenueLogger.log(
      event: 'AI_TOOL_CALL',
      layer: LoggerLayer.AI,
      payload: {'tool': name, 'args': args},
    );

    try {
      switch (name) {
        case 'getSchedule':
          return await _handleGetSchedule(args);
        case 'searchSchedule':
          return await _handleSearchSchedule(args);
        case 'addTask':
          return await _handleAddTask(args);
        case 'addDefaultTask':
          return await _handleAddDefaultTask(args);
        case 'updateTask':
          return await _handleUpdateTask(args);
        case 'updateDefaultTask':
          return await _handleUpdateDefaultTask(args);
        case 'deleteTask':
          return await _handleDeleteTask(args);
        case 'deleteDefaultTask':
          return await _handleDeleteDefaultTask(args);
        default:
          return {'error': 'Tool not found: $name'};
      }
    } catch (e) {
      AvenueLogger.log(
        event: 'AI_TOOL_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.AI,
        payload: {'tool': name, 'error': e.toString()},
      );
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _handleGetSchedule(
    Map<String, dynamic> args,
  ) async {
    final start = DateTime.parse(args['startDate'] as String);
    final end = args['endDate'] != null
        ? DateTime.parse(args['endDate'] as String)
        : null;
    final type = args['type'] as String? ?? 'all';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<Map<String, dynamic>> allResults = [];

    // 1. Fetch One-Time/Instantiated Tasks
    if (type == 'all' || type == 'task') {
      final taskResult = end != null
          ? await _repository.getTasksByDateRange(start, end)
          : await _repository.getTasksByDate(start);

      taskResult.fold((f) => null, (tasks) {
        allResults.addAll(
          tasks.map((t) {
            final map = t.toMap();
            map['source'] = 'task';
            // Format for AI
            map['date'] = t.taskDate.toIso8601String().split('T')[0];
            map['startTime'] = t.startTime != null
                ? '${t.startTime!.hour.toString().padLeft(2, '0')}:${t.startTime!.minute.toString().padLeft(2, '0')}'
                : null;
            map['endTime'] = t.endTime != null
                ? '${t.endTime!.hour.toString().padLeft(2, '0')}:${t.endTime!.minute.toString().padLeft(2, '0')}'
                : null;
            return map;
          }),
        );
      });
    }

    // 2. Fetch Recurring Habits (Only for Today or Future)
    if (type == 'all' || type == 'default') {
      final effectiveStart = start.isBefore(today) ? today : start;
      final effectiveEnd = end ?? start;

      if (!effectiveEnd.isBefore(today)) {
        final defaultResult = await _repository.getDefaultTasks();
        defaultResult.fold((f) => null, (defaults) {
          // Iterate through range
          for (
            int i = 0;
            i <= effectiveEnd.difference(effectiveStart).inDays;
            i++
          ) {
            final currentDate = effectiveStart.add(Duration(days: i));
            final weekday = currentDate.weekday;
            final dateStr = currentDate.toIso8601String().split('T')[0];

            for (final habit in defaults) {
              if (habit.weekdays.contains(weekday)) {
                final predictableId = TaskModel.generatePredictableId(
                  habit.id,
                  currentDate,
                );

                // Suppression Logic: If already exists in one-time tasks (crystallized), skip.
                if (allResults.any((t) => t['id'] == predictableId)) {
                  continue;
                }

                // Check if hidden on this date
                final isHidden = habit.hideOn.any(
                  (h) =>
                      h.year == currentDate.year &&
                      h.month == currentDate.month &&
                      h.day == currentDate.day,
                );

                if (!isHidden) {
                  allResults.add({
                    'id': predictableId,
                    'name': habit.name,
                    'desc': habit.desc,
                    'date': dateStr,
                    'startTime':
                        '${habit.startTime.hour.toString().padLeft(2, '0')}:${habit.startTime.minute.toString().padLeft(2, '0')}',
                    'endTime':
                        '${habit.endTime.hour.toString().padLeft(2, '0')}:${habit.endTime.minute.toString().padLeft(2, '0')}',
                    'source': 'default',
                    'category': habit.category,
                    'importance_type': habit.importanceType,
                    'default_task_id': habit.id,
                  });
                }
              }
            }
          }
        });
      }
    }

    // Sort by Date and then by StartTime
    allResults.sort((a, b) {
      final dateComp = (a['date'] as String).compareTo(b['date'] as String);
      if (dateComp != 0) return dateComp;
      return (a['startTime'] as String? ?? '00:00').compareTo(
        b['startTime'] as String? ?? '00:00',
      );
    });

    AvenueLogger.log(
      event: 'AI_TOOL_RESULT',
      layer: LoggerLayer.AI,
      payload: {'tool': 'getSchedule', 'count': allResults.length},
    );

    return {'tasks': allResults};
  }

  Future<Map<String, dynamic>> _handleSearchSchedule(
    Map<String, dynamic> args,
  ) async {
    final query = args['query'] as String;
    final type = args['type'] as String? ?? 'all';
    final List<Map<String, dynamic>> allResults = [];

    if (type == 'all' || type == 'task') {
      final result = await _repository.searchTasks(query);
      result.fold((f) => null, (tasks) {
        allResults.addAll(
          tasks.map((t) {
            final map = t.toMap();
            map['source'] = 'task';
            map['date'] = t.taskDate.toIso8601String().split('T')[0];
            map['startTime'] = t.startTime != null
                ? '${t.startTime!.hour.toString().padLeft(2, '0')}:${t.startTime!.minute.toString().padLeft(2, '0')}'
                : null;
            map['endTime'] = t.endTime != null
                ? '${t.endTime!.hour.toString().padLeft(2, '0')}:${t.endTime!.minute.toString().padLeft(2, '0')}'
                : null;
            return map;
          }),
        );
      });
    }

    if (type == 'all' || type == 'default') {
      final result = await _repository.searchDefaultTasks(query);
      result.fold((f) => null, (defaults) {
        allResults.addAll(
          defaults.map((d) {
            final map = d.toMap();
            map['source'] = 'default';
            map['date'] = 'Recurring'; // Stabilize sorting
            map['startTime'] =
                '${d.startTime.hour.toString().padLeft(2, '0')}:${d.startTime.minute.toString().padLeft(2, '0')}';
            map['endTime'] =
                '${d.endTime.hour.toString().padLeft(2, '0')}:${d.endTime.minute.toString().padLeft(2, '0')}';
            return map;
          }),
        );
      });
    }

    // Sort by Date and then by StartTime
    allResults.sort((a, b) {
      final dateA = a['date'] as String? ?? '';
      final dateB = b['date'] as String? ?? '';
      final dateComp = dateA.compareTo(dateB);
      if (dateComp != 0) return dateComp;
      return (a['startTime'] as String? ?? '00:00').compareTo(
        b['startTime'] as String? ?? '00:00',
      );
    });

    AvenueLogger.log(
      event: 'AI_TOOL_RESULT',
      layer: LoggerLayer.AI,
      payload: {'tool': 'searchSchedule', 'count': allResults.length},
    );

    return {'tasks': allResults};
  }

  Future<Map<String, dynamic>> _handleAddTask(Map<String, dynamic> args) async {
    // [Draft Mode] Generate ID but do not save to DB yet.
    // The UI will confirm and execute.
    final id = const Uuid().v4();
    AvenueLogger.log(
      event: 'AI_DRAFT_ACTION',
      layer: LoggerLayer.AI,
      payload: {'action': 'addTask', 'id': id},
    );
    return {
      'success': true,
      'taskId': id,
      'status': 'success_draft_waiting_confirmation',
      'message': 'Draft created. Ask user to confirm.',
    };
  }

  Future<Map<String, dynamic>> _handleAddDefaultTask(
    Map<String, dynamic> args,
  ) async {
    // [Draft Mode]
    final id = const Uuid().v4();
    AvenueLogger.log(
      event: 'AI_DRAFT_ACTION',
      layer: LoggerLayer.AI,
      payload: {'action': 'addDefaultTask', 'id': id},
    );
    return {
      'success': true,
      'defaultTaskId': id,
      'status': 'success_draft_waiting_confirmation',
      'message': 'Draft created. Ask user to confirm.',
    };
  }

  Future<Map<String, dynamic>> _handleUpdateTask(
    Map<String, dynamic> args,
  ) async {
    // [Draft Mode] We still check if it exists to be nice, but act as if updated
    // Optional: Check existence?
    // final existingResult = await _repository.getTaskById(id);
    // if (existingResult.isLeft()) return {'error': 'Task not found'};

    // Validate we can parse the inputs at least?
    // For now, assume success to let user confirm.
    return {
      'success': true,
      'status': 'success_draft_waiting_confirmation',
      'message': 'Update draft ready. Ask user to confirm.',
    };
  }

  Future<Map<String, dynamic>> _handleUpdateDefaultTask(
    Map<String, dynamic> args,
  ) async {
    return {
      'success': true,
      'status': 'success_draft_waiting_confirmation',
      'message': 'Update draft ready. Ask user to confirm.',
    };
  }

  Future<Map<String, dynamic>> _handleDeleteTask(
    Map<String, dynamic> args,
  ) async {
    // [Draft Mode]
    return {
      'success': true,
      'status': 'success_draft_waiting_confirmation',
      'message': 'Delete draft ready. Ask user to confirm.',
    };
  }

  Future<Map<String, dynamic>> _handleDeleteDefaultTask(
    Map<String, dynamic> args,
  ) async {
    // [Draft Mode]
    return {
      'success': true,
      'status': 'success_draft_waiting_confirmation',
      'message': 'Delete draft ready. Ask user to confirm.',
    };
  }
}
