import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/task_model.dart';
import '../../domain/repo/schedule_repository.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final ScheduleRepository repository;
  DateTime _selectedDate = DateTime.now();

  TaskCubit({required this.repository}) : super(TaskInitial()) {
    loadTasks();
  }

  Future<void> loadTasks({DateTime? date}) async {
    emit(TaskLoading());

    if (date != null) {
      _selectedDate = date;
    }

    final result = await repository.getTasksByDate(_selectedDate);

    result.fold(
      (failure) => emit(TaskError(failure.message)),
      (tasks) => emit(TaskLoaded(tasks)),
    );
  }

  Future<void> addTask(TaskModel task) async {
    final result = await repository.addTask(task);

    result.fold(
      (failure) => emit(TaskError(failure.message)),
      (_) => loadTasks(), // Reload tasks after successful add
    );
  }

  Future<void> updateTask(TaskModel task) async {
    final result = await repository.updateTask(task);

    result.fold(
      (failure) => emit(TaskError(failure.message)),
      (_) => loadTasks(), // Reload tasks after successful update
    );
  }

  Future<void> deleteTask(String id) async {
    final result = await repository.deleteTask(id);

    result.fold(
      (failure) => emit(TaskError(failure.message)),
      (_) => loadTasks(), // Reload tasks after successful delete
    );
  }

  Future<void> toggleTaskDone(String id) async {
    final result = await repository.toggleTaskDone(id);

    result.fold(
      (failure) => emit(TaskError(failure.message)),
      (_) => loadTasks(), // Reload tasks after successful toggle
    );
  }

  DateTime get selectedDate => _selectedDate;
}
