import 'package:sqflite/sqflite.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/database_service.dart';
import '../models/task_model.dart';
import '../models/default_task_model.dart';
import 'task_local_data_source.dart';

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final DatabaseService databaseService;

  TaskLocalDataSourceImpl({required this.databaseService});

  @override
  Future<List<TaskModel>> getTasksByDate(DateTime date) async {
    try {
      final db = await databaseService.database;
      final normalizedDate = DateTime(
        date.year,
        date.month,
        date.day,
      ).toIso8601String().split('T')[0];

      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: "task_date LIKE ? AND is_deleted = 0",
        whereArgs: ['$normalizedDate%'],
        orderBy: 'start_time ASC',
      );

      return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
    } catch (e) {
      throw CacheException(ErrorMessages.loadTasksFailed);
    }
  }

  @override
  Future<void> addTask(TaskModel task) async {
    try {
      final db = await databaseService.database;
      final taskToSave = task.copyWith(serverUpdatedAt: DateTime.now().toUtc());
      await db.insert(
        'tasks',
        taskToSave.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(ErrorMessages.addTaskFailed);
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      final db = await databaseService.database;
      final taskToSave = task.copyWith(serverUpdatedAt: DateTime.now().toUtc());
      final count = await db.update(
        'tasks',
        taskToSave.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
      if (count == 0) {
        throw CacheException(ErrorMessages.taskNotFound);
      }
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(ErrorMessages.updateTaskFailed);
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      final db = await databaseService.database;
      // Soft delete
      await db.update(
        'tasks',
        {
          'is_deleted': 1,
          'server_updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException(ErrorMessages.deleteTaskFailed);
    }
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    try {
      final db = await databaseService.database;
      final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);

      if (maps.isNotEmpty) {
        return TaskModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw CacheException(ErrorMessages.cacheFailure);
    }
  }

  @override
  Future<void> insertDefaultTask(DefaultTaskModel task) async {
    try {
      final db = await databaseService.database;
      await db.insert(
        'default_tasks',
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to add default task');
    }
  }

  @override
  Future<List<DefaultTaskModel>> getDefaultTasks() async {
    try {
      final db = await databaseService.database;
      final maps = await db.query('default_tasks');
      return List.generate(
        maps.length,
        (i) => DefaultTaskModel.fromMap(maps[i]),
      );
    } catch (e) {
      throw CacheException('Failed to load default tasks');
    }
  }

  @override
  Future<List<TaskModel>> getFutureTasks(DateTime afterDate) async {
    try {
      final db = await databaseService.database;
      final normalizedDate = afterDate.toIso8601String().split('T')[0];

      final maps = await db.query(
        'tasks',
        where: "task_date > ? AND one_time = 1 AND is_deleted = 0",
        whereArgs: [normalizedDate],
        orderBy: 'task_date ASC, start_time ASC',
      );

      return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
    } catch (e) {
      throw CacheException('Failed to load future tasks');
    }
  }

  @override
  Future<void> deleteTasksBefore(DateTime date) async {
    try {
      final db = await databaseService.database;
      final normalizedDate = date.toIso8601String().split('T')[0];

      await db.delete(
        'tasks',
        where: "task_date < ?",
        whereArgs: [normalizedDate],
      );
    } catch (e) {
      throw CacheException('Failed to delete old tasks');
    }
  }

  @override
  Future<List<TaskModel>> searchTasks(String query) async {
    try {
      final db = await databaseService.database;
      final maps = await db.query(
        'tasks',
        where:
            "(name LIKE ? OR desc LIKE ? OR category LIKE ?) AND is_deleted = 0",
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'task_date DESC',
      );

      return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
    } catch (e) {
      throw CacheException('Failed to search tasks');
    }
  }

  @override
  Future<Map<String, DateTime?>> getDateBounds() async {
    try {
      final db = await databaseService.database;
      final result = await db.rawQuery(
        'SELECT MIN(task_date) as first_date, MAX(task_date) as last_date FROM tasks WHERE is_deleted = 0',
      );

      DateTime? firstDate;
      DateTime? lastDate;

      if (result.isNotEmpty) {
        final firstDateStr = result.first['first_date'] as String?;
        final lastDateStr = result.first['last_date'] as String?;

        if (firstDateStr != null) {
          firstDate = DateTime.parse(firstDateStr);
        }
        if (lastDateStr != null) {
          lastDate = DateTime.parse(lastDateStr);
        }
      }

      return {'first': firstDate, 'last': lastDate};
    } catch (e) {
      throw CacheException('Failed to get date bounds');
    }
  }
}
