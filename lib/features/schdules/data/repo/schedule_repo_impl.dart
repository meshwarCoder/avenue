import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repo/schedule_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';
import '../models/default_task_model.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final TaskLocalDataSource localDataSource;

  ScheduleRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<TaskModel>>> getTasksByDate(
    DateTime taskDate,
  ) async {
    try {
      final tasks = await localDataSource.getTasksByDate(taskDate);
      return Right(tasks);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<TaskModel>>> getTasksByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final tasks = await localDataSource.getTasksByDateRange(start, end);
      return Right(tasks);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> addTask(TaskModel task) async {
    try {
      await localDataSource.addTask(task);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTask(TaskModel task) async {
    try {
      await localDataSource.updateTask(task);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id) async {
    try {
      await localDataSource.deleteTask(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleTaskDone(String id) async {
    try {
      final task = await localDataSource.getTaskById(id);
      if (task == null) {
        return const Left(CacheFailure('Task not found'));
      }

      final updatedTask = task.copyWith(completed: !task.completed);
      await localDataSource.updateTask(updatedTask);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> addDefaultTask(DefaultTaskModel task) async {
    try {
      await localDataSource.insertDefaultTask(task);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<DefaultTaskModel>>> getDefaultTasks() async {
    try {
      final tasks = await localDataSource.getDefaultTasks();
      return Right(tasks);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<TaskModel>>> getFutureTasks(
    DateTime afterDate,
  ) async {
    try {
      final tasks = await localDataSource.getFutureTasks(afterDate);
      return Right(tasks);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTasksBefore(DateTime date) async {
    try {
      await localDataSource.deleteTasksBefore(date);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, Map<String, DateTime?>>> getDateBounds() async {
    try {
      final bounds = await localDataSource.getDateBounds();
      return Right(bounds);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get date bounds'));
    }
  }
}
