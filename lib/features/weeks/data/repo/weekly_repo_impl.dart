import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../schdules/data/datasources/task_local_data_source.dart';
import '../../../schdules/data/models/task_model.dart';
import '../../../schdules/data/models/default_task_model.dart';
import '../../domain/repo/weekly_repository.dart';

class WeeklyRepositoryImpl implements WeeklyRepository {
  final TaskLocalDataSource localDataSource;

  WeeklyRepositoryImpl({required this.localDataSource});

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
