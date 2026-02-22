import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repo/schedule_repository.dart';
import '../../data/models/default_task_model.dart';
import 'default_tasks_state.dart';

class DefaultTasksCubit extends Cubit<DefaultTasksState> {
  final ScheduleRepository _repository;

  DefaultTasksCubit(this._repository) : super(DefaultTasksInitial());

  Future<void> loadDefaultTasks() async {
    emit(DefaultTasksLoading());
    final result = await _repository.getDefaultTasks();
    result.fold(
      (failure) => emit(DefaultTasksError(failure.message)),
      (tasks) =>
          emit(DefaultTasksLoaded(tasks.where((t) => !t.isDeleted).toList())),
    );
  }

  Future<void> deleteDefaultTask(String id) async {
    final result = await _repository.deleteDefaultTask(id);
    result.fold(
      (failure) => emit(DefaultTasksError(failure.message)),
      (_) => loadDefaultTasks(),
    );
  }

  Future<void> updateDefaultTask(DefaultTaskModel task) async {
    final result = await _repository.updateDefaultTask(task);
    result.fold(
      (failure) => emit(DefaultTasksError(failure.message)),
      (_) => loadDefaultTasks(),
    );
  }
}
