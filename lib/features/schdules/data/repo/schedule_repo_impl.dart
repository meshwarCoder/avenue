import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repo/schedule_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';
import '../models/default_task_model.dart';
import '../../../../core/utils/observability.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final TaskLocalDataSource localDataSource;
  final SupabaseClient supabase;

  ScheduleRepositoryImpl({
    required this.localDataSource,
    required this.supabase,
  });

  @override
  Future<Either<Failure, List<TaskModel>>> getTasksByDate(
    DateTime taskDate, {
    String? traceId,
  }) async {
    try {
      AvenueLogger.log(
        event: 'DB_READ',
        layer: LoggerLayer.DB,
        traceId: traceId,
        payload: {'source': 'LOCAL_CACHE', 'entity': 'tasks', 'date': taskDate},
      );
      final tasks = await localDataSource.getTasksByDate(taskDate);
      AvenueLogger.log(
        event: 'DB_RESULT',
        layer: LoggerLayer.DB,
        traceId: traceId,
        payload: {'count': tasks.length},
      );
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
  Future<Either<Failure, void>> addTask(
    TaskModel task, {
    String? traceId,
  }) async {
    try {
      AvenueLogger.log(
        event: 'DB_INSERT',
        layer: LoggerLayer.DB,
        traceId: traceId,
        payload: {'source': 'LOCAL_CACHE', 'entity': 'task', 'id': task.id},
      );
      // Generate embedding for "Name: ... Desc: ..."
      // Embedding generation moved to SyncService to save time and local space
      final taskWithEmbedding = task.copyWith(embedding: null);
      await localDataSource.addTask(taskWithEmbedding);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> updateTask(
    TaskModel task, {
    String? traceId,
  }) async {
    try {
      AvenueLogger.log(
        event: 'DB_UPDATE',
        layer: LoggerLayer.DB,
        traceId: traceId,
        payload: {'source': 'LOCAL_CACHE', 'entity': 'task', 'id': task.id},
      );
      // Generate embedding for "Name: ... Desc: ..."
      // Embedding generation moved to SyncService
      await localDataSource.updateTask(task);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id, {String? traceId}) async {
    try {
      AvenueLogger.log(
        event: 'DB_DELETE',
        layer: LoggerLayer.DB,
        traceId: traceId,
        payload: {'source': 'LOCAL_CACHE', 'entity': 'task', 'id': id},
      );
      await localDataSource.deleteTask(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, TaskModel?>> getTaskById(String id) async {
    try {
      final task = await localDataSource.getTaskById(id);
      return Right(task);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get task'));
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
  Future<Either<Failure, void>> addDefaultTask(
    DefaultTaskModel task, {
    String? traceId,
  }) async {
    try {
      AvenueLogger.log(
        event: 'DB_INSERT',
        layer: LoggerLayer.DB,
        traceId: traceId,
        payload: {
          'source': 'LOCAL_CACHE',
          'entity': 'default_task',
          'id': task.id,
        },
      );
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
      AvenueLogger.log(
        event: 'DB_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.DB,
        payload: 'Repository Error (getDateBounds): ${e.message}',
      );
      return Left(CacheFailure(e.message));
    } catch (e) {
      AvenueLogger.log(
        event: 'DB_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.DB,
        payload: 'Unexpected Repository Error (getDateBounds): $e',
      );
      return Left(CacheFailure('Failed to get date bounds'));
    }
  }

  @override
  Future<Either<Failure, List<TaskModel>>> searchTasks(String query) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return const Left(CacheFailure('User not logged in'));
      final token = supabase.auth.currentSession?.accessToken;
      if (token == null) return const Left(CacheFailure('token not logged in'));

      final response = await supabase.functions.invoke(
        'embed-search',
        body: {'query': query, 'user_id': user.id, 'limit': 10},
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.status != 200) {
        throw Exception('Edge function search failed: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>;

      final tasks = results
          .where((json) => json['source_table'] == 'tasks')
          .map((json) => TaskModel.fromSupabaseJson(json))
          .toList();

      return Right(tasks);
    } catch (e) {
      AvenueLogger.log(
        event: 'SEARCH_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.DB,
        payload: {
          'query': query,
          'error': e.toString(),
          'source': 'EDGE_FUNCTION',
          'action': 'FALLBACK_LOCAL',
        },
      );
      try {
        final tasks = await localDataSource.searchTasks(query);
        return Right(tasks);
      } catch (e2) {
        return Left(CacheFailure('Failed to search tasks: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, List<DefaultTaskModel>>> searchDefaultTasks(
    String query,
  ) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return const Left(CacheFailure('User not logged in'));

      final response = await supabase.functions.invoke(
        'embed-search',
        body: {'query': query, 'user_id': user.id, 'limit': 10},
        headers: {
          'Authorization':
              'Bearer ${supabase.auth.currentSession?.accessToken}',
        },
      );

      if (response.status != 200) {
        throw Exception('Edge function search failed: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>;

      final tasks = results
          .where((json) => json['source_table'] == 'default_tasks')
          .map((json) => DefaultTaskModel.fromSupabaseJson(json))
          .toList();

      return Right(tasks);
    } catch (e) {
      AvenueLogger.log(
        event: 'SEARCH_DEFAULT_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.DB,
        payload: {
          'query': query,
          'error': e.toString(),
          'source': 'EDGE_FUNCTION',
          'action': 'FALLBACK_LOCAL',
        },
      );
      try {
        final allDefaults = await localDataSource.getDefaultTasks();
        final filtered = allDefaults
            .where(
              (t) =>
                  t.name.toLowerCase().contains(query.toLowerCase()) ||
                  (t.desc?.toLowerCase().contains(query.toLowerCase()) ??
                      false),
            )
            .toList();
        return Right(filtered);
      } catch (e2) {
        return Left(CacheFailure('Failed to search default tasks: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, void>> deleteDefaultTask(String id) async {
    try {
      await localDataSource.deleteDefaultTask(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> updateDefaultTask(DefaultTaskModel task) async {
    try {
      await localDataSource.updateDefaultTask(task);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, DefaultTaskModel?>> getDefaultTaskById(
    String id,
  ) async {
    try {
      final task = await localDataSource.getDefaultTaskById(id);
      return Right(task);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get default task'));
    }
  }
}
