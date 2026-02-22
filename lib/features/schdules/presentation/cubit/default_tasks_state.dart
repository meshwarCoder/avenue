import 'package:equatable/equatable.dart';
import '../../data/models/default_task_model.dart';

abstract class DefaultTasksState extends Equatable {
  const DefaultTasksState();

  @override
  List<Object?> get props => [];
}

class DefaultTasksInitial extends DefaultTasksState {}

class DefaultTasksLoading extends DefaultTasksState {}

class DefaultTasksLoaded extends DefaultTasksState {
  final List<DefaultTaskModel> tasks;

  const DefaultTasksLoaded(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class DefaultTasksError extends DefaultTasksState {
  final String message;

  const DefaultTasksError(this.message);

  @override
  List<Object?> get props => [message];
}
