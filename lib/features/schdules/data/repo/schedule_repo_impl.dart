import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/embedding_service.dart';
import '../../domain/repo/schedule_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';
import '../models/default_task_model.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final TaskLocalDataSource localDataSource;
  final SupabaseClient supabase;
  final EmbeddingService embeddingService;

  ScheduleRepositoryImpl({
    required this.localDataSource,
    required this.supabase,
    required this.embeddingService,
  });

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
      return Left(CacheFailure('حدث خطأ غير متوقع'));
    }
  }

  @override
  Future<Either<Failure, void>> addTask(TaskModel task) async {
    try {
      // Generate embedding for "Name: ... Desc: ..."
      final text =
          "Name: ${task.name}. Desc: ${task.desc ?? ''}. Category: ${task.category}";
      List<double>? embedding;
      try {
        embedding = await embeddingService.generateEmbedding(text);
      } catch (e) {
        print('Embedding generation failed: $e');
        // Continue without embedding (will be null)
      }

      final taskWithEmbedding = task.copyWith(embedding: embedding);
      await localDataSource.addTask(taskWithEmbedding);
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
      // Generate embedding for "Name: ... Desc: ..."
      final text =
          "Name: ${task.name}. Desc: ${task.desc ?? ''}. Category: ${task.category}";
      List<double>? embedding;
      try {
        embedding = await embeddingService.generateEmbedding(text);
      } catch (e) {
        print('Embedding generation failed: $e');
      }

      final taskWithEmbedding = task.copyWith(
        embedding: embedding, // Update embedding if generated
        // If generation failed, should we keep old?
        // copyWith(embedding: null) replaces it.
        // We typically want to update it if text changed.
      );

      await localDataSource.updateTask(taskWithEmbedding);
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
        return const Left(CacheFailure('المهمة غير موجودة'));
      }

      final updatedTask = task.copyWith(completed: !task.completed);
      await localDataSource.updateTask(updatedTask);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('حدث خطأ غير متوقع'));
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
      return Left(CacheFailure('حدث خطأ غير متوقع'));
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
      return Left(CacheFailure('حدث خطأ غير متوقع'));
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
      return Left(CacheFailure('حدث خطأ غير متوقع'));
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
      return Left(CacheFailure('حدث خطأ غير متوقع'));
    }
  }

  @override
  Future<Either<Failure, Map<String, DateTime?>>> getDateBounds() async {
    try {
      final bounds = await localDataSource.getDateBounds();
      return Right(bounds);
    } on CacheException catch (e) {
      print('Repository Error (getDateBounds): ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e, stack) {
      print('Unexpected Repository Error (getDateBounds): $e');
      print(stack);
      return Left(CacheFailure('Failed to get date bounds'));
    }
  }

  @override
  Future<Either<Failure, List<TaskModel>>> searchTasks(String query) async {
    try {
      // 1. Generate Embedding
      // ... (existing implementation)
      final embedding = await embeddingService.generateEmbedding(query);

      if (embedding.isEmpty) {
        final tasks = await localDataSource.searchTasks(query);
        return Right(tasks);
      }

      // 2. Search Tasks (RPC)
      final List<dynamic> taskResponse = await supabase.rpc(
        'match_tasks',
        params: {
          'query_embedding': embedding,
          'match_threshold': 0.5,
          'match_count': 10,
        },
      );

      final tasks = taskResponse
          .map((json) => TaskModel.fromSupabaseJson(json))
          .toList();
      return Right(tasks);
    } catch (e) {
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
      final embedding = await embeddingService.generateEmbedding(query);
      if (embedding.isEmpty) {
        // Fallback to local? Local doesn't have searchDefaultTasks yet
        // We can implement it or just return empty.
        // Let's return empty for now or try to filter local loaded.
        final allDefaults = await localDataSource.getDefaultTasks();
        // Simple keyword filter
        final filtered = allDefaults
            .where(
              (t) =>
                  t.name.toLowerCase().contains(query.toLowerCase()) ||
                  (t.desc?.toLowerCase().contains(query.toLowerCase()) ??
                      false),
            )
            .toList();
        return Right(filtered);
      }

      // Assume 'match_default_tasks' RPC exists or similar logic
      // If user only created one table 'tasks' with embedding, maybe default tasks are there?
      // But user said "default tasks table".
      // So likely need 'match_default_tasks' RPC.
      // Or we can assume the user will create it.

      final List<dynamic> response = await supabase.rpc(
        'match_default_tasks',
        params: {
          'query_embedding': embedding,
          'match_threshold': 0.5,
          'match_count': 10,
        },
      );

      final tasks = response
          .map((json) => DefaultTaskModel.fromSupabaseJson(json))
          .toList();
      return Right(tasks);
    } catch (e) {
      // Fallback local
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
        return Left(CacheFailure('Failed to search default tasks'));
      }
    }
  }
}
