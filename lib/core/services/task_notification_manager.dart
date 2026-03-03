import 'package:avenue/core/services/local_notification_service.dart';
import 'package:avenue/features/schdules/data/models/task_model.dart';
import 'package:avenue/features/settings/data/settings_repository.dart';
import '../utils/observability.dart';

/// Manage task-specific notification logic, separating it from the UI and core service.
class TaskNotificationManager {
  final LocalNotificationService _notificationService;
  final SettingsRepository _settingsRepository;

  TaskNotificationManager(this._notificationService, this._settingsRepository);

  /// Generate a unique integer ID for notifications from a Task UUID
  int _getNotificationId(
    String taskId, {
    bool isReminder = false,
    bool isEndTime = false,
  }) {
    // We use the hash of the taskId string and add offsets to avoid collisions.
    final hash = taskId.hashCode.abs();
    if (isReminder) return hash + 1;
    if (isEndTime) return hash + 2;
    return hash;
  }

  /// Schedules all enabled notifications for a task
  Future<void> scheduleTaskNotifications(TaskModel task) async {
    // 1. Cancel existing notifications for this task first to avoid duplicates
    await cancelTaskNotifications(task.id);

    // Global toggle check
    if (!_settingsRepository.getNotificationsEnabled()) {
      AvenueLogger.log(
        event: 'NOTIFICATION_SKIPPED_GLOBAL',
        layer: LoggerLayer.SYNC,
        payload: 'Notifications globally disabled',
      );
      return;
    }

    if (!task.notificationsEnabled || task.isDeleted) {
      AvenueLogger.log(
        event: 'NOTIFICATION_SKIPPED_DISABLED',
        layer: LoggerLayer.SYNC,
        payload: 'Notifications disabled or task deleted for task: ${task.id}',
      );
      return;
    }

    final now = DateTime.now();
    // Allow scheduling if time is up to 1 minute in the past (handling processing time)
    final schedulingWindow = now.subtract(const Duration(minutes: 1));

    AvenueLogger.log(
      event: 'TASK_NOTIFICATION_CHECK',
      layer: LoggerLayer.SYNC,
      payload: {'id': task.id, 'start': task.startTime?.toIso8601String()},
    );

    // 2. Schedule the main notification (at startTime)
    if (!task.completed &&
        task.startTime != null &&
        task.startTime!.isAfter(schedulingWindow)) {
      await _notificationService.scheduleNotification(
        id: _getNotificationId(task.id),
        title: 'Task Reminder: ${task.name} 🔔',
        body: task.desc ?? 'Time to start your task!',
        scheduledTime: task.startTime!,
        payload: 'task_${task.id}',
      );
    }

    // 3. Schedule the reminder notification (X minutes before)
    if (!task.completed &&
        task.reminderBeforeMinutes != null &&
        task.startTime != null) {
      final reminderTime = task.startTime!.subtract(
        Duration(minutes: task.reminderBeforeMinutes!),
      );

      if (reminderTime.isAfter(schedulingWindow)) {
        await _notificationService.scheduleNotification(
          id: _getNotificationId(task.id, isReminder: true),
          title: 'Upcoming Task: ${task.name} ⏳',
          body: 'Starts in ${task.reminderBeforeMinutes} minutes, get ready!',
          scheduledTime: reminderTime,
          payload: 'task_${task.id}',
        );
      }
    }

    // 4. Schedule END TIME status notification
    if (task.endTime != null &&
        task.endTime!.isAfter(schedulingWindow) &&
        task.completionNotificationEnabled) {
      final title = task.completed ? "Mission Accomplished! 🌟" : "Time's Up ⏳";
      final body = task.completed
          ? "Well done! You completed: ${task.name} ✅"
          : 'The time for "${task.name}" has passed. Try to finish it or reschedule! 🔄';

      await _notificationService.scheduleNotification(
        id: _getNotificationId(task.id, isEndTime: true),
        title: title,
        body: body,
        scheduledTime: task.endTime!,
        payload: 'task_${task.id}',
      );
    }
  }

  /// Updates notifications only if essential fields have changed.
  Future<void> updateTaskNotificationIfNeeded(
    TaskModel? oldTask,
    TaskModel newTask,
  ) async {
    if (oldTask == null) return scheduleTaskNotifications(newTask);

    final bool timeChanged =
        oldTask.startTime != newTask.startTime ||
        oldTask.endTime != newTask.endTime;
    final bool statusChanged = oldTask.completed != newTask.completed;
    final bool settingsChanged =
        oldTask.notificationsEnabled != newTask.notificationsEnabled ||
        oldTask.reminderBeforeMinutes != newTask.reminderBeforeMinutes;
    final bool deletionChanged = oldTask.isDeleted != newTask.isDeleted;

    if (timeChanged || statusChanged || settingsChanged || deletionChanged) {
      AvenueLogger.log(
        event: 'NOTIFICATION_UPDATE_NEEDED',
        layer: LoggerLayer.SYNC,
        payload: newTask.id,
      );
      return scheduleTaskNotifications(newTask);
    }
  }

  /// Safely handles boot-time scheduling.
  /// Only schedules notifications for tasks that don't have pending notifications.
  Future<void> scheduleFutureTasksIfMissing(List<TaskModel> tasks) async {
    try {
      if (!_settingsRepository.getNotificationsEnabled()) return;

      final pendingRequests = await _notificationService
          .getPendingNotificationRequests();
      final pendingIds = pendingRequests.map((r) => r.id).toSet();

      int scheduledCount = 0;
      for (final task in tasks) {
        // Only consider future tasks that are enabled and not completed
        if (!task.notificationsEnabled || task.completed || task.isDeleted) {
          continue;
        }

        final mainId = _getNotificationId(task.id);
        if (!pendingIds.contains(mainId)) {
          // If the main notification is missing, re-evaluate and schedule all for this task
          // We use scheduleTaskNotifications because we know at least one is missing
          await scheduleTaskNotifications(task);
          scheduledCount++;
        }
      }

      if (scheduledCount > 0) {
        AvenueLogger.log(
          event: 'NOTIFICATION_BOOT_REPAIR',
          layer: LoggerLayer.SYNC,
          payload: 'Scheduled $scheduledCount missing notifications on boot',
        );
      }
    } catch (e) {
      AvenueLogger.log(
        event: 'NOTIFICATION_BOOT_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.SYNC,
        payload: 'Failed to repair notifications on boot: $e',
      );
    }
  }

  /// Schedules a summary of the day's progress at midnight (00:00 AM) of the next day
  Future<void> scheduleDailySummary(
    DateTime date,
    List<TaskModel> tasks,
  ) async {
    if (!_settingsRepository.getNotificationsEnabled()) return;

    // Normalizing the date to ensure we are talking about a specific 24h period
    final targetDate = DateTime(date.year, date.month, date.day);
    // Midnight of the next day
    final summaryTime = targetDate.add(const Duration(days: 1));

    if (summaryTime.isBefore(DateTime.now())) return;

    // Filter tasks specifically for the targetDate
    final dayTasks = tasks
        .where(
          (t) =>
              !t.isDeleted &&
              t.taskDate.year == targetDate.year &&
              t.taskDate.month == targetDate.month &&
              t.taskDate.day == targetDate.day,
        )
        .toList();

    if (dayTasks.isEmpty) return;

    final totalCount = dayTasks.length;
    final completedCount = dayTasks.where((t) => t.completed).length;
    final percentage = (completedCount / totalCount * 100).round();

    String title;
    String body;

    if (percentage == 100) {
      title = "Perfect Day Finished! 🏆";
      body =
          "Amazing! You completed all $totalCount tasks yesterday. What a streak!";
    } else if (percentage >= 70) {
      title = "Great Results! 📈";
      body =
          "You finished $completedCount/$totalCount tasks ($percentage%) yesterday. Keep up the momentum!";
    } else {
      title = "Day Summary 📊";
      body =
          "You finished $completedCount/$totalCount tasks ($percentage%) yesterday. Ready to beat that today?";
    }

    await _notificationService.scheduleNotification(
      id: 999999, // Unique ID for summary - replaces any existing one
      title: title,
      body: body,
      scheduledTime: summaryTime,
      payload: 'daily_summary',
    );
  }

  /// Cancels all notifications (main, reminder, end-time) for a specific task
  Future<void> cancelTaskNotifications(String taskId) async {
    await _notificationService.cancelNotification(_getNotificationId(taskId));
    await _notificationService.cancelNotification(
      _getNotificationId(taskId, isReminder: true),
    );
    await _notificationService.cancelNotification(
      _getNotificationId(taskId, isEndTime: true),
    );

    AvenueLogger.log(
      event: 'TASK_NOTIFICATIONS_CANCELLED',
      layer: LoggerLayer.SYNC,
      payload: taskId,
    );
  }
}
