import 'dart:math';
import '../../features/schdules/data/models/task_model.dart';

class TaskConcurrencyUtils {
  /// Checks if two time ranges overlap.
  /// Ranges are [s1, e1] and [s2, e2].
  /// Overlap is defined as any shared point in time, excluding the endpoints.
  /// (e.g., 10:00-11:00 and 11:00-12:00 do NOT overlap).
  static bool isOverlapping(
    DateTime s1,
    DateTime e1,
    DateTime s2,
    DateTime e2,
  ) {
    return s1.isBefore(e2) && s2.isBefore(e1);
  }

  /// Calculates the maximum number of concurrent tasks at any single point in time.
  /// Uses a sweep-line algorithm.
  static int getMaxConcurrency(List<TaskModel> tasks) {
    if (tasks.isEmpty) return 0;

    final List<_Event> events = [];
    for (final task in tasks) {
      if (task.startTime != null && task.endTime != null) {
        events.add(_Event(task.startTime!, 1));
        events.add(_Event(task.endTime!, -1));
      }
    }

    // Sort events by time.
    // If times are equal, process end events (-1) before start events (1)
    // to treat [10:00, 11:00] and [11:00, 12:00] as non-overlapping.
    events.sort((a, b) {
      final timeComp = a.time.compareTo(b.time);
      if (timeComp != 0) return timeComp;
      return a.type.compareTo(b.type);
    });

    int maxConcurrent = 0;
    int currentConcurrent = 0;

    for (final event in events) {
      currentConcurrent += event.type;
      maxConcurrent = max(maxConcurrent, currentConcurrent);
    }

    return maxConcurrent;
  }

  /// Checks if a new task overlaps with any existing tasks.
  static bool hasAnyOverlap(List<TaskModel> existingTasks, TaskModel newTask) {
    if (newTask.startTime == null || newTask.endTime == null) return false;

    for (final task in existingTasks) {
      if (task.id == newTask.id) continue; // Skip itself if updating
      if (task.startTime != null && task.endTime != null) {
        if (isOverlapping(
          newTask.startTime!,
          newTask.endTime!,
          task.startTime!,
          task.endTime!,
        )) {
          return true;
        }
      }
    }
    return false;
  }
}

class _Event {
  final DateTime time;
  final int type; // 1 for start, -1 for end

  _Event(this.time, this.type);
}
