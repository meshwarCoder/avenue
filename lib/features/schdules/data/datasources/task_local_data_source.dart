import '../../data/models/task_model.dart';
import '../../data/models/default_task_model.dart';

abstract class TaskLocalDataSource {
  /// Get all tasks for a specific date
  /// Throws [CacheException] if operation fails
  Future<List<TaskModel>> getTasksByDate(DateTime date);

  /// Get all tasks for a specific date range
  Future<List<TaskModel>> getTasksByDateRange(DateTime start, DateTime end);

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
  Future<TaskModel?> getTaskById(String id);

  /// Add a new default task
  Future<void> insertDefaultTask(DefaultTaskModel task);

  /// Get all default tasks
  Future<List<DefaultTaskModel>> getDefaultTasks();

  /// Get all one-time tasks after a specific date
  Future<List<TaskModel>> getFutureTasks(DateTime afterDate);

  /// Delete tasks older than a specific date from local cache
  Future<void> deleteTasksBefore(DateTime date);

  /// Get date bounds (min and max task dates)
  Future<Map<String, DateTime?>> getDateBounds();
}
