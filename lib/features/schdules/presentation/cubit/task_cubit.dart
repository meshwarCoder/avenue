import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/task_model.dart';
import '../../data/models/default_task_model.dart';
import '../../domain/repo/schedule_repository.dart';
import 'task_state.dart';

import '../../../../core/services/sync_service.dart';
import '../../../../core/utils/calendar_utils.dart';
import '../../../../core/utils/observability.dart';

class TaskCubit extends Cubit<TaskState> {
  final ScheduleRepository repository;
  final SyncService syncService;
  DateTime _selectedDate = DateTime.now();
  StreamSubscription? _connectivitySubscription;

  TaskCubit({required this.repository, required this.syncService})
    : super(TaskInitial()) {
    AvenueLogger.log(event: 'STATE_TASK_INITIALIZED', layer: LoggerLayer.STATE);
    _selectedDate = CalendarUtils.normalize(_selectedDate);
    // Removed loadTasks(); Views will trigger it with their specific dates
    syncTasks(); // Sync once on app start

    // Listen for connectivity changes to auto-sync when back online
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      // connectivity_plus 6.x returns a List<ConnectivityResult>
      if (results.any((result) => result != ConnectivityResult.none)) {
        AvenueLogger.log(
          event: 'CONNECTIVITY_RESTORED',
          layer: LoggerLayer.SYNC,
        );
        syncTasks();
      }
    });
  }

  void _logState(TaskState state, {String? traceId}) {
    AvenueLogger.log(
      event: 'STATE_TASKS_UPDATED',
      layer: LoggerLayer.STATE,
      traceId: traceId,
      payload: {'state': state.runtimeType.toString()},
    );
    emit(state);
  }

  Future<void> loadDateBounds() async {
    final result = await repository.getDateBounds();
    result.fold(
      (failure) => AvenueLogger.log(
        event: 'DB_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.DB,
        payload: 'Failed to load date bounds: ${failure.message}',
      ),
      (bounds) {
        final currentState = state;
        final first = bounds['first'];
        final last = bounds['last'];

        if (currentState is TaskLoaded) {
          _logState(
            TaskLoaded(
              currentState.tasks,
              selectedDate: currentState.selectedDate!,
              firstTaskDate: first,
              lastTaskDate: last,
            ),
          );
        } else if (currentState is TaskLoading) {
          _logState(
            TaskLoading(
              selectedDate: currentState.selectedDate,
              firstTaskDate: first,
              lastTaskDate: last,
            ),
          );
        } else if (currentState is TaskError) {
          _logState(
            TaskError(
              currentState.message,
              selectedDate: currentState.selectedDate,
              firstTaskDate: first,
              lastTaskDate: last,
            ),
          );
        }
      },
    );
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }

  Future<void> syncTasks() async {
    try {
      await syncService.sync();
      // Only reload if we are not in a loading state to avoid flicker
      // And only if we are viewing a specific date (not Future Tasks)
      if (state is! TaskLoading && state is! FutureTasksLoaded) {
        await loadTasks(date: _selectedDate);
      }
    } catch (e) {
      AvenueLogger.log(
        event: 'SYNC_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.SYNC,
        payload: 'Background sync failed: $e',
      );
    }
  }

  Future<void> loadTasks({DateTime? date, bool force = false}) async {
    final targetDate = CalendarUtils.normalize(date ?? _selectedDate);

    // Prevent redundant loads if already on this date
    if (!force && state is TaskLoaded && _selectedDate == targetDate) {
      AvenueLogger.log(
        event: 'STATE_LOAD_SKIPPED',
        layer: LoggerLayer.STATE,
        payload: targetDate.toIso8601String(),
      );
      return;
    }

    _selectedDate = targetDate;
    AvenueLogger.log(
      event: 'STATE_LOAD_STARTED',
      layer: LoggerLayer.STATE,
      payload: targetDate.toIso8601String(),
    );

    emit(
      TaskLoading(
        selectedDate: targetDate,
        firstTaskDate: state.firstTaskDate,
        lastTaskDate: state.lastTaskDate,
      ),
    );

    final now = DateTime.now();
    final today = CalendarUtils.normalize(now);
    final isPastDate = targetDate.isBefore(today);

    // 1. Get specific tasks
    final result = await repository.getTasksByDate(targetDate);

    // 2. Get default tasks
    final Either<Failure, List<DefaultTaskModel>> defaultTasksResult =
        isPastDate
        ? const Right<Failure, List<DefaultTaskModel>>([])
        : await repository.getDefaultTasks();

    result.fold(
      (failure) {
        AvenueLogger.log(
          event: 'STATE_LOAD_FAILED',
          level: LoggerLevel.ERROR,
          layer: LoggerLayer.STATE,
          payload: 'Load failed for $targetDate: ${failure.message}',
        );
        _logState(
          TaskError(
            failure.message,
            selectedDate: targetDate,
            firstTaskDate: state.firstTaskDate,
            lastTaskDate: state.lastTaskDate,
          ),
        );
      },
      (tasks) {
        AvenueLogger.log(
          event: 'STATE_LOAD_COMPLETED',
          layer: LoggerLayer.STATE,
          payload: {
            'count': tasks.length,
            'date': targetDate.toIso8601String(),
          },
        );
        final List<TaskModel> allTasks = List.from(tasks);

        defaultTasksResult.fold((l) => null, (defaultTasks) {
          for (var dt in defaultTasks) {
            if (dt.weekdays.contains(targetDate.weekday)) {
              final predictableId = TaskModel.generatePredictableId(
                dt.id,
                targetDate,
              );

              // Filter out default tasks that are hidden for this specific date
              final dateStr = targetDate.toIso8601String().split('T')[0];
              if (dt.hideOn.any(
                (d) => d.toIso8601String().split('T')[0] == dateStr,
              )) {
                continue;
              }

              if (tasks.any((t) => t.id == predictableId)) {
                continue;
              }

              allTasks.add(
                TaskModel.fromTimeOfDay(
                  id: predictableId,
                  name: dt.name,
                  desc: dt.desc,
                  startTime: dt.startTime,
                  endTime: dt.endTime,
                  taskDate: targetDate,
                  category: dt.category,
                  completed: false,
                  oneTime: false,
                  importanceType: dt.importanceType,
                  defaultTaskId: dt.id,
                ),
              );
            }
          }
        });

        allTasks.sort((a, b) {
          if (a.startTime == null) return 1;
          if (b.startTime == null) return -1;
          return a.startTime!.compareTo(b.startTime!);
        });

        _logState(
          TaskLoaded(
            allTasks,
            selectedDate: targetDate,
            firstTaskDate: state.firstTaskDate,
            lastTaskDate: state.lastTaskDate,
            updatedAt: DateTime.now(),
          ),
        );
      },
    );
  }

  Future<void> loadFutureTasks() async {
    _logState(
      TaskLoading(
        firstTaskDate: state.firstTaskDate,
        lastTaskDate: state.lastTaskDate,
      ),
    );
    // Only show tasks that are beyond the next 7 days
    final futureThreshold = DateTime.now().add(const Duration(days: 7));
    final result = await repository.getFutureTasks(futureThreshold);
    result.fold(
      (failure) => _logState(
        TaskError(
          failure.message,
          firstTaskDate: state.firstTaskDate,
          lastTaskDate: state.lastTaskDate,
        ),
      ),
      (tasks) => _logState(
        FutureTasksLoaded(
          tasks,
          firstTaskDate: state.firstTaskDate,
          lastTaskDate: state.lastTaskDate,
        ),
      ),
    );
  }

  Future<void> addDefaultTask(DefaultTaskModel task, {String? traceId}) async {
    final result = await repository.addDefaultTask(task, traceId: traceId);
    result.fold(
      (failure) => _logState(
        TaskError(
          failure.message,
          selectedDate: _selectedDate,
          firstTaskDate: state.firstTaskDate,
          lastTaskDate: state.lastTaskDate,
        ),
        traceId: traceId,
      ),
      (_) {
        if (state is FutureTasksLoaded) {
          loadFutureTasks();
        } else {
          loadTasks(force: true);
        }
      },
    );
  }

  Future<void> addTask(TaskModel task, {String? traceId}) async {
    // 1. Emit loading immediately to signal the UI that work has started
    _logState(
      TaskLoading(
        selectedDate: _selectedDate,
        firstTaskDate: state.firstTaskDate,
        lastTaskDate: state.lastTaskDate,
      ),
      traceId: traceId,
    );

    final result = await repository.addTask(task, traceId: traceId);

    result.fold(
      (failure) => _logState(
        TaskError(
          failure.message,
          selectedDate: _selectedDate,
          firstTaskDate: state.firstTaskDate,
          lastTaskDate: state.lastTaskDate,
        ),
        traceId: traceId,
      ),
      (_) {
        if (state is FutureTasksLoaded) {
          loadFutureTasks();
        } else {
          loadTasks(force: true); // Reload locally first
          syncTasks(); // Then sync in background
        }
      },
    );
  }

  Future<void> updateTask(TaskModel task, {String? traceId}) async {
    final result = await repository.updateTask(task, traceId: traceId);

    result.fold(
      (failure) => _logState(
        TaskError(
          failure.message,
          selectedDate: _selectedDate,
          firstTaskDate: state.firstTaskDate,
          lastTaskDate: state.lastTaskDate,
        ),
        traceId: traceId,
      ),
      (_) {
        if (state is FutureTasksLoaded) {
          loadFutureTasks();
        } else {
          loadTasks(force: true); // Reload locally first
          syncTasks(); // Then sync in background
        }
      },
    );
  }

  Future<void> deleteTask(String id, {String? traceId}) async {
    final result = await repository.deleteTask(id, traceId: traceId);

    result.fold(
      (failure) => _logState(
        TaskError(failure.message, selectedDate: _selectedDate),
        traceId: traceId,
      ),
      (_) {
        if (state is FutureTasksLoaded) {
          loadFutureTasks();
        } else {
          loadTasks(force: true); // Reload locally first
          syncTasks(); // Then sync in background
        }
      },
    );
  }

  Future<void> toggleTaskDone(TaskModel task) async {
    // Check if task exists in DB first
    // Note: Default tasks have random IDs generated on the fly in loadTasks,
    // so getTaskById might return null even if we pass that ID.
    // However, for "real" tasks, they are in the DB.

    // We try to toggle it using the repo.
    // If it fails with "Not Found", we assume it's a default task and we "Crystallize" it.

    final result = await repository.toggleTaskDone(task.id);

    await result.fold(
      (failure) async {
        // If failed because not found, create it as a new task (Crystallization)
        if (failure.message.toLowerCase().contains('not found')) {
          AvenueLogger.log(
            event: 'STATE_CRYSTALLIZE_TASK',
            layer: LoggerLayer.STATE,
            payload: task.name,
          );
          await addTask(task.copyWith(completed: true));
        } else {
          _logState(
            TaskError(
              failure.message,
              selectedDate: _selectedDate,
              firstTaskDate: state.firstTaskDate,
              lastTaskDate: state.lastTaskDate,
            ),
          );
        }
      },
      (_) {
        if (state is FutureTasksLoaded) {
          loadFutureTasks();
        } else {
          loadTasks(force: true); // Reload locally first
          syncTasks(); // Then sync in background
        }
      },
    );
  }

  DateTime get selectedDate => _selectedDate;

  Future<void> deleteDefaultTaskEntirely(
    String defaultTaskId, {
    String? taskId,
  }) async {
    // 1. Delete the specific instance if provided
    if (taskId != null) {
      await repository.deleteTask(taskId);
    }

    // 2. Delete the template
    final result = await repository.deleteDefaultTask(defaultTaskId);
    result.fold(
      (failure) =>
          _logState(TaskError(failure.message, selectedDate: _selectedDate)),
      (_) {
        loadTasks(force: true);
        syncTasks();
      },
    );
  }

  Future<void> hideDefaultTaskForDate(
    String defaultTaskId,
    DateTime date, {
    String? taskId,
  }) async {
    // 1. Delete the specific instance if it exists (crystallized)
    if (taskId != null) {
      await repository.deleteTask(taskId);
    }

    // 2. Add date to hideOn in the template
    final defaultTasksResult = await repository.getDefaultTasks();
    await defaultTasksResult.fold(
      (failure) async =>
          _logState(TaskError(failure.message, selectedDate: _selectedDate)),
      (defaultTasks) async {
        final task = defaultTasks.firstWhereOrNull(
          (t) => t.id == defaultTaskId,
        );
        if (task == null) {
          // If template is missing, just reload (it's essentially gone anyway)
          loadTasks(force: true);
          return;
        }

        final dateStr = date.toIso8601String().split('T')[0];
        // Only add if not already present
        if (!task.hideOn.any(
          (d) => d.toIso8601String().split('T')[0] == dateStr,
        )) {
          final updatedHideOn = List<DateTime>.from(task.hideOn)..add(date);
          final updatedTask = task.copyWith(hideOn: updatedHideOn);
          final result = await repository.updateDefaultTask(updatedTask);
          result.fold(
            (failure) => _logState(
              TaskError(failure.message, selectedDate: _selectedDate),
            ),
            (_) {
              loadTasks(force: true);
              syncTasks();
            },
          );
        } else {
          loadTasks();
        }
      },
    );
  }

  Future<void> updateDefaultTask(DefaultTaskModel task) async {
    final result = await repository.updateDefaultTask(task);
    result.fold(
      (failure) =>
          _logState(TaskError(failure.message, selectedDate: _selectedDate)),
      (_) {
        loadTasks(force: true);
        syncTasks();
      },
    );
  }

  Future<void> deleteDefaultTask(String id) async {
    final result = await repository.deleteDefaultTask(id);
    result.fold(
      (failure) =>
          _logState(TaskError(failure.message, selectedDate: _selectedDate)),
      (_) {
        loadTasks(force: true);
        syncTasks();
      },
    );
  }
}
