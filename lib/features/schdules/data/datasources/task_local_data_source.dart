import '../../data/models/task_model.dart';

abstract class TaskLocalDataSource {
  /// Get all tasks for a specific date
  /// Throws [CacheException] if operation fails
  List<TaskModel> getTasksByDate(DateTime date);

  /// Add a new task
  /// Throws [CacheException] if operation fails
  Future<void> addTask(TaskModel task);

  /// Update an existing task
  /// Throws [CacheException] if operation fails
  Future<void> updateTask(TaskModel task);

  /// Delete a task by ID
  /// Throws [CacheException] if operation fails
  Future<void> deleteTask(String id);

  /// Get a task by ID
  /// Returns null if task not found
  /// Throws [CacheException] if operation fails
  TaskModel? getTaskById(String id);
}
