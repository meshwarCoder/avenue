import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/task_model.dart';
import '../../data/models/default_task_model.dart';

abstract class ScheduleRepository {
  /// Get all tasks for a specific date
  /// Returns [Right(List<TaskModel>)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, List<TaskModel>>> getTasksByDate(DateTime date);

  /// Get all tasks for a specific date range
  Future<Either<Failure, List<TaskModel>>> getTasksByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Add a new task
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> addTask(TaskModel task, {String? traceId});

  /// Update an existing task
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> updateTask(TaskModel task, {String? traceId});

  /// Delete a task by ID
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> deleteTask(String id, {String? traceId});

  /// Get a task by ID
  Future<Either<Failure, TaskModel?>> getTaskById(String id);

  /// Toggle task done status
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> toggleTaskDone(String id);

  /// Add a new default task
  Future<Either<Failure, void>> addDefaultTask(
    DefaultTaskModel task, {
    String? traceId,
  });

  /// Get all default tasks
  Future<Either<Failure, List<DefaultTaskModel>>> getDefaultTasks();

  /// Get all one-time tasks after a specific date
  Future<Either<Failure, List<TaskModel>>> getFutureTasks(DateTime afterDate);

  /// Delete tasks older than a specific date
  Future<Either<Failure, void>> deleteTasksBefore(DateTime date);

  /// Search tasks by query
  Future<Either<Failure, List<TaskModel>>> searchTasks(String query);

  /// Search default tasks by query
  Future<Either<Failure, List<DefaultTaskModel>>> searchDefaultTasks(
    String query,
  );

  /// Get date bounds (first and last task dates)
  Future<Either<Failure, Map<String, DateTime?>>> getDateBounds();

  /// Delete a default task entirely
  Future<Either<Failure, void>> deleteDefaultTask(String id);

  /// Update a default task (e.g., for hiding on specific dates)
  Future<Either<Failure, void>> updateDefaultTask(DefaultTaskModel task);

  /// Get a default task by ID
  Future<Either<Failure, DefaultTaskModel?>> getDefaultTaskById(String id);
}
