import 'package:equatable/equatable.dart';
import '../../data/models/task_model.dart';

abstract class TaskState extends Equatable {
  final DateTime? selectedDate;
  final DateTime? firstTaskDate;
  final DateTime? lastTaskDate;

  const TaskState({this.selectedDate, this.firstTaskDate, this.lastTaskDate});

  @override
  List<Object?> get props => [selectedDate, firstTaskDate, lastTaskDate];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {
  const TaskLoading({
    super.selectedDate,
    super.firstTaskDate,
    super.lastTaskDate,
  });
}

class TaskLoaded extends TaskState {
  final List<TaskModel> tasks;
  final DateTime? updatedAt;

  const TaskLoaded(
    this.tasks, {
    required DateTime super.selectedDate,
    super.firstTaskDate,
    super.lastTaskDate,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    tasks,
    selectedDate,
    firstTaskDate,
    lastTaskDate,
    updatedAt,
  ];
}

class TaskError extends TaskState {
  final String message;

  const TaskError(
    this.message, {
    super.selectedDate,
    super.firstTaskDate,
    super.lastTaskDate,
  });

  @override
  List<Object?> get props => [
    message,
    selectedDate,
    firstTaskDate,
    lastTaskDate,
  ];
}

class FutureTasksLoaded extends TaskState {
  final List<TaskModel> tasks;

  const FutureTasksLoaded(
    this.tasks, {
    super.firstTaskDate,
    super.lastTaskDate,
  });

  @override
  List<Object?> get props => [tasks, firstTaskDate, lastTaskDate];
}
