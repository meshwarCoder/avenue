import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../schdules/data/models/task_model.dart';
import '../../../schdules/data/models/default_task_model.dart';

abstract class WeeklyRepository {
  /// Get all tasks for a specific date range
  Future<Either<Failure, List<TaskModel>>> getTasksByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Get all default tasks
  Future<Either<Failure, List<DefaultTaskModel>>> getDefaultTasks();

  /// Get date bounds (first and last task dates)
  Future<Either<Failure, Map<String, DateTime?>>> getDateBounds();
}
