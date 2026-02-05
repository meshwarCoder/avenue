import 'package:avenue/features/schdules/domain/repo/schedule_repository.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/observability.dart';

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
        case 'getTasks':
          return await _handleGetTasks(args);
        case 'searchTasks':
          return await _handleSearchTasks(args);
        case 'searchDefaultTasks':
          return await _handleSearchDefaultTasks(args);
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

  Future<Map<String, dynamic>> _handleGetTasks(
    Map<String, dynamic> args,
  ) async {
    final start = DateTime.parse(args['startDate'] as String);
    final end = args['endDate'] != null
        ? DateTime.parse(args['endDate'] as String)
        : null;

    final result = end != null
        ? await _repository.getTasksByDateRange(start, end)
        : await _repository.getTasksByDate(start);

    return result.fold((f) => {'error': f.message}, (tasks) {
      AvenueLogger.log(
        event: 'AI_TOOL_RESULT',
        layer: LoggerLayer.AI,
        payload: {'tool': 'getTasks', 'count': tasks.length},
      );
      return {'tasks': tasks.map((t) => t.toMap()).toList()};
    });
  }

  Future<Map<String, dynamic>> _handleSearchTasks(
    Map<String, dynamic> args,
  ) async {
    final query = args['query'] as String;
    final result = await _repository.searchTasks(query);
    return result.fold((f) => {'error': f.message}, (tasks) {
      AvenueLogger.log(
        event: 'AI_TOOL_RESULT',
        layer: LoggerLayer.AI,
        payload: {'tool': 'searchTasks', 'count': tasks.length},
      );
      return {'tasks': tasks.map((t) => t.toMap()).toList()};
    });
  }

  Future<Map<String, dynamic>> _handleSearchDefaultTasks(
    Map<String, dynamic> args,
  ) async {
    final query = args['query'] as String;
    final result = await _repository.searchDefaultTasks(query);
    return result.fold((f) => {'error': f.message}, (tasks) {
      AvenueLogger.log(
        event: 'AI_TOOL_RESULT',
        layer: LoggerLayer.AI,
        payload: {'tool': 'searchDefaultTasks', 'count': tasks.length},
      );
      return {'tasks': tasks.map((t) => t.toMap()).toList()};
    });
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
