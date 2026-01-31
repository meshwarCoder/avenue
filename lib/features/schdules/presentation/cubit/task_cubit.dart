import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/task_model.dart';
import '../../data/models/default_task_model.dart';
import '../../domain/repo/schedule_repository.dart';
import 'task_state.dart';

import '../../../../core/services/sync_service.dart';

class TaskCubit extends Cubit<TaskState> {
  final ScheduleRepository repository;
  final SyncService syncService;
  DateTime _selectedDate = DateTime.now();
  StreamSubscription? _connectivitySubscription;

  TaskCubit({required this.repository, required this.syncService})
    : super(TaskInitial()) {
    loadTasks();
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

  Future<void> loadTasks({DateTime? date, bool shouldSync = false}) async {
    if (date != null) {
      _selectedDate = date;
    }
    emit(
      TaskLoading(
        selectedDate: _selectedDate,
        firstTaskDate: state.firstTaskDate,
        lastTaskDate: state.lastTaskDate,
      ),
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Check if the selected date is in the past (before today)
    final isPastDate =
        _selectedDate.day != today.day ||
            _selectedDate.month != today.month ||
            _selectedDate.year != today.year
        ? _selectedDate.isBefore(today)
        : false;

    // Smart Fetching: If date is older than 7 days, fetch from backend
    // We only preserve 1 week locally.
    final retentionLimit = today.subtract(const Duration(days: 7));
    if (_selectedDate.isBefore(retentionLimit)) {
      try {
        // Fetch the specific week containing this date
        // E.g., fetch from selectedDate to selectedDate + 7 days or similar chunk
        // For simplicity, let's fetch the whole week context
        final startOfWeek = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        await syncService.fetchTasksForDateRange(startOfWeek, endOfWeek);
      } catch (e) {
        print("TaskCubit: Error fetching historical data: $e");
        // Continue to try loading from local DB even if fetch fails
      }
    } else if (shouldSync) {
      try {
        await syncService.sync();
      } catch (e) {
        print("Sync failed during load: $e");
      }
    }

    // 1. Get specific tasks
    final result = await repository.getTasksByDate(_selectedDate);

    // 2. Get default tasks
    // ONLY fetch/merge default tasks if we are NOT in the past.
    // For past dates, we only show crystallized records (real TaskModels).
    final Either<Failure, List<DefaultTaskModel>> defaultTasksResult =
        isPastDate
        ? const Right<Failure, List<DefaultTaskModel>>(
            [],
          ) // Return empty list for past dates
        : await repository.getDefaultTasks(); // Fetch for Today/Future

    result.fold(
      (failure) => emit(
        TaskError(
          failure.message,
          selectedDate: _selectedDate,
          firstTaskDate: state.firstTaskDate,
          lastTaskDate: state.lastTaskDate,
        ),
      ),
      (tasks) {
        // Merge default tasks
        final List<TaskModel> allTasks = List.from(tasks);

        defaultTasksResult.fold(
          (l) => null, // Ignore default tasks error or if skipped
          (defaultTasks) {
            // will be empty list if isPastDate is true
            for (var dt in defaultTasks) {
              // Check if default task runs on this weekday
              if (dt.weekdays.contains(_selectedDate.weekday)) {
                // Generate predictable ID for this instance
                final predictableId = TaskModel.generatePredictableId(
                  dt.id,
                  _selectedDate,
                );

                // Check if this instance is already "crystallized" in the DB
                if (tasks.any((t) => t.id == predictableId)) {
                  continue; // Skip adding template, use the one from DB
                }

                allTasks.add(
                  TaskModel.fromTimeOfDay(
                    id: predictableId,
                    name: dt.name,
                    desc: dt.desc,
                    startTime: dt.startTime,
                    endTime: dt.endTime,
                    taskDate: _selectedDate,
                    category: dt.category,
                    color: dt.color,
                    completed: false, // Default tasks start as not completed
                    oneTime: false,
                    importanceType: dt.importanceType,
                  ),
                );
              }
            }
          },
        );

        // Sort by start time
        allTasks.sort((a, b) {
          if (a.startTime == null) return 1;
          if (b.startTime == null) return -1;
          return a.startTime!.compareTo(b.startTime!);
        });

        emit(
          TaskLoaded(
            allTasks,
            selectedDate: _selectedDate,
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
          loadTasks();
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
          loadTasks(); // Reload locally first
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
          loadTasks(); // Reload locally first
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
          loadTasks(); // Reload locally first
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
          loadTasks(); // Reload locally first
          syncTasks(); // Then sync in background
        }
      },
    );
  }

  DateTime get selectedDate => _selectedDate;
}
