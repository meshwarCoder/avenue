import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repo/schedule_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final TaskLocalDataSource localDataSource;

  ScheduleRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<TaskModel>>> getTasksByDate(DateTime date) async {
    try {
      final tasks = localDataSource.getTasksByDate(date);
      return Right(tasks);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('حدث خطأ غير متوقع'));
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
      return Left(CacheFailure('حدث خطأ غير متوقع'));
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
      return Left(CacheFailure('حدث خطأ غير متوقع'));
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
      return Left(CacheFailure('حدث خطأ غير متوقع'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleTaskDone(String id) async {
    try {
      final task = localDataSource.getTaskById(id);
      if (task == null) {
        return const Left(CacheFailure('المهمة غير موجودة'));
      }

      final updatedTask = task.copyWith(isDone: !task.isDone);
      await localDataSource.updateTask(updatedTask);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('حدث خطأ غير متوقع'));
    }
  }
}
