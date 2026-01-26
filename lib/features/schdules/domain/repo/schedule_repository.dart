import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/task_model.dart';

abstract class ScheduleRepository {
  /// Get all tasks for a specific date
  /// Returns [Right(List<TaskModel>)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, List<TaskModel>>> getTasksByDate(DateTime date);

  /// Add a new task
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> addTask(TaskModel task);

  /// Update an existing task
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> updateTask(TaskModel task);

  /// Delete a task by ID
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> deleteTask(String id);

  /// Toggle task done status
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error
  Future<Either<Failure, void>> toggleTaskDone(String id);
}
