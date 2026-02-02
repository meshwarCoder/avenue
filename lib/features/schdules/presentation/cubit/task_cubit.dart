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

class TaskCubit extends Cubit<TaskState> {
  final ScheduleRepository repository;
  final SyncService syncService;
  DateTime _selectedDate = DateTime.now();
  StreamSubscription? _connectivitySubscription;

  TaskCubit({required this.repository, required this.syncService})
    : super(TaskInitial()) {
    _selectedDate = CalendarUtils.normalize(_selectedDate);
    // Removed loadTasks(); Views will trigger it with their specific dates
    syncTasks(); // Sync once on app start

    // Listen for connectivity changes to auto-sync when back online
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      // connectivity_plus 6.x returns a List<ConnectivityResult>
      if (results.any((result) => result != ConnectivityResult.none)) {
        print("TaskCubit: Internet restored. Triggering auto-sync.");
        syncTasks();
      }
    });
  }

  Future<void> loadDateBounds() async {
    final result = await repository.getDateBounds();
    result.fold(
      (failure) => print("Failed to load date bounds: ${failure.message}"),
      (bounds) {
        final currentState = state;
        final first = bounds['first'];
        final last = bounds['last'];

        if (currentState is TaskLoaded) {
          emit(
            TaskLoaded(
              currentState.tasks,
              selectedDate: currentState.selectedDate!,
              firstTaskDate: first,
              lastTaskDate: last,
            ),
          );
        } else if (currentState is TaskLoading) {
          emit(
            TaskLoading(
              selectedDate: currentState.selectedDate,
              firstTaskDate: first,
              lastTaskDate: last,
            ),
          );
        } else if (currentState is TaskError) {
          emit(
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
      print("TaskCubit: Background sync failed: $e");
    }
  }

  Future<void> loadTasks({DateTime? date, bool force = false}) async {
    final targetDate = CalendarUtils.normalize(date ?? _selectedDate);

    // Prevent redundant loads if already on this date
    if (!force && state is TaskLoaded && _selectedDate == targetDate) {
      print("TaskCubit: Already loaded for $targetDate, skipping.");
      return;
    }

    _selectedDate = targetDate;
    print("TaskCubit: Loading tasks for $targetDate");

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
        print("TaskCubit: Load failed for $targetDate: ${failure.message}");
        emit(
          TaskError(
            failure.message,
            selectedDate: targetDate,
            firstTaskDate: state.firstTaskDate,
            lastTaskDate: state.lastTaskDate,
          ),
        );
      },
      (tasks) {
        print(
          "TaskCubit: Successfully loaded ${tasks.length} tasks for $targetDate",
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
                  color: dt.color,
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

        emit(
          TaskLoaded(
            allTasks,
            selectedDate: targetDate,
            firstTaskDate: state.firstTaskDate,
            lastTaskDate: state.lastTaskDate,
          ),
        );
      },
    );
  }

  Future<void> loadFutureTasks() async {
    emit(
      TaskLoading(
        firstTaskDate: state.firstTaskDate,
        lastTaskDate: state.lastTaskDate,
      ),
    );
    // Only show tasks that are beyond the next 7 days
    final futureThreshold = DateTime.now().add(const Duration(days: 7));
    final result = await repository.getFutureTasks(futureThreshold);
    result.fold(
      (failure) => emit(
        TaskError(
          failure.message,
          firstTaskDate: state.firstTaskDate,
          lastTaskDate: state.lastTaskDate,
        ),
      ),
      (tasks) => emit(
        FutureTasksLoaded(
          tasks,
          firstTaskDate: state.firstTaskDate,
          lastTaskDate: state.lastTaskDate,
        ),
      ),
    );
  }

  Future<void> addDefaultTask(DefaultTaskModel task) async {
    final result = await repository.addDefaultTask(task);
    result.fold(
      (failure) => emit(
        TaskError(
          failure.message,
          selectedDate: _selectedDate,
          firstTaskDate: state.firstTaskDate,
          lastTaskDate: state.lastTaskDate,
        ),
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

  Future<void> addTask(TaskModel task) async {
    final result = await repository.addTask(task);

    result.fold(
      (failure) => emit(
        TaskError(
          failure.message,
          selectedDate: _selectedDate,
          firstTaskDate: state.firstTaskDate,
          lastTaskDate: state.lastTaskDate,
        ),
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

  Future<void> updateTask(TaskModel task) async {
    final result = await repository.updateTask(task);

    result.fold(
      (failure) => emit(
        TaskError(
          failure.message,
          selectedDate: _selectedDate,
          firstTaskDate: state.firstTaskDate,
          lastTaskDate: state.lastTaskDate,
        ),
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

  Future<void> deleteTask(String id) async {
    final result = await repository.deleteTask(id);

    result.fold(
      (failure) =>
          emit(TaskError(failure.message, selectedDate: _selectedDate)),
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
          print("Crystallizing default task: ${task.name}");
          await addTask(task.copyWith(completed: true));
        } else {
          emit(
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
          emit(TaskError(failure.message, selectedDate: _selectedDate)),
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
          emit(TaskError(failure.message, selectedDate: _selectedDate)),
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
            (failure) =>
                emit(TaskError(failure.message, selectedDate: _selectedDate)),
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
}
