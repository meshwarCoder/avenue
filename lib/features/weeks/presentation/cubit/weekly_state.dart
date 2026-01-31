import 'package:equatable/equatable.dart';
import '../../../schdules/data/models/task_model.dart';

abstract class WeeklyState extends Equatable {
  final DateTime? firstTaskDate;
  final DateTime? lastTaskDate;

  const WeeklyState({this.firstTaskDate, this.lastTaskDate});

  @override
  List<Object?> get props => [firstTaskDate, lastTaskDate];
}

class WeeklyInitial extends WeeklyState {
  const WeeklyInitial({super.firstTaskDate, super.lastTaskDate});
}

class WeeklyLoading extends WeeklyState {
  const WeeklyLoading({super.firstTaskDate, super.lastTaskDate});
}

class WeeklyLoaded extends WeeklyState {
  final List<TaskModel> tasks;
  final DateTime mondayDate;

  const WeeklyLoaded(
    this.tasks, {
    required this.mondayDate,
    super.firstTaskDate,
    super.lastTaskDate,
  });

  @override
  List<Object?> get props => [tasks, mondayDate, firstTaskDate, lastTaskDate];
}

class WeeklyError extends WeeklyState {
  final String message;

  const WeeklyError(this.message, {super.firstTaskDate, super.lastTaskDate});

  @override
  List<Object?> get props => [message, firstTaskDate, lastTaskDate];
}
