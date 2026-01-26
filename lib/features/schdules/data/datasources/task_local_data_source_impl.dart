import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/constants.dart';
import '../models/task_model.dart';
import 'task_local_data_source.dart';

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final Box<TaskModel> tasksBox;

  TaskLocalDataSourceImpl({required this.tasksBox});

  @override
  List<TaskModel> getTasksByDate(DateTime date) {
    try {
      // Normalize the date to midnight
      final normalizedDate = DateTime(date.year, date.month, date.day);

      // Filter tasks by date
      final allTasks = tasksBox.values.toList();
      final filteredTasks = allTasks.where((task) {
        final taskDate = DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
        );
        return taskDate == normalizedDate;
      }).toList();

      // Sort by start time
      filteredTasks.sort((a, b) => a.startTime.compareTo(b.startTime));

      return filteredTasks;
    } catch (e) {
      throw CacheException(ErrorMessages.loadTasksFailed);
    }
  }

  @override
  Future<void> addTask(TaskModel task) async {
    try {
      await tasksBox.put(task.id, task);
    } catch (e) {
      throw CacheException(ErrorMessages.addTaskFailed);
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      if (!tasksBox.containsKey(task.id)) {
        throw CacheException(ErrorMessages.taskNotFound);
      }
      await tasksBox.put(task.id, task);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(ErrorMessages.updateTaskFailed);
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      if (!tasksBox.containsKey(id)) {
        throw CacheException(ErrorMessages.taskNotFound);
      }
      await tasksBox.delete(id);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(ErrorMessages.deleteTaskFailed);
    }
  }

  @override
  TaskModel? getTaskById(String id) {
    try {
      return tasksBox.get(id);
    } catch (e) {
      throw CacheException(ErrorMessages.cacheFailure);
    }
  }
}
