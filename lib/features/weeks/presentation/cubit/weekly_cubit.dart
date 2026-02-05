import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../schdules/data/models/task_model.dart';
import '../../domain/repo/weekly_repository.dart';
import 'weekly_state.dart';

class WeeklyCubit extends Cubit<WeeklyState> {
  final WeeklyRepository repository;

  WeeklyCubit({required this.repository}) : super(const WeeklyInitial());

  Future<void> loadDateBounds() async {
    final result = await repository.getDateBounds();
    result.fold(
      (failure) => print(
        "Failed to load date bounds in WeeklyCubit: ${failure.message}",
      ),
      (bounds) {
        final first = bounds['first'];
        final last = bounds['last'];
        final currentState = state;

        if (currentState is WeeklyLoaded) {
          emit(
            WeeklyLoaded(
              currentState.tasks,
              mondayDate: currentState.mondayDate,
              firstTaskDate: first,
              lastTaskDate: last,
            ),
          );
        } else if (currentState is WeeklyLoading) {
          emit(WeeklyLoading(firstTaskDate: first, lastTaskDate: last));
        } else if (currentState is WeeklyError) {
          emit(
            WeeklyError(
              currentState.message,
              firstTaskDate: first,
              lastTaskDate: last,
            ),
          );
        } else {
          emit(WeeklyInitial(firstTaskDate: first, lastTaskDate: last));
        }
      },
    );
  }

  Future<void> loadWeeklyTasks(DateTime monday) async {
    emit(
      WeeklyLoading(
        firstTaskDate: state.firstTaskDate,
        lastTaskDate: state.lastTaskDate,
      ),
    );

    final sunday = monday.add(const Duration(days: 6));

    // Smart Skip: If the entire week is before the first recorded task,
    // we skip the range fetch but still allow recurring tasks logic if needed.
    // However, usually recurring tasks don't exist in the far past either.
    if (state.firstTaskDate != null && sunday.isBefore(state.firstTaskDate!)) {
      emit(
        WeeklyLoaded(
          [],
          mondayDate: monday,
          firstTaskDate: state.firstTaskDate,
          lastTaskDate: state.lastTaskDate,
        ),
      );
      return;
    }

    // 1. Get real tasks for the week
    final result = await repository.getTasksByDateRange(monday, sunday);

    // 2. Get default tasks
    final defaultTasksResult = await repository.getDefaultTasks();

    result.fold(
      (failure) => emit(
        WeeklyError(
          failure.message,
          firstTaskDate: state.firstTaskDate,
          lastTaskDate: state.lastTaskDate,
        ),
      ),
      (tasks) {
        final List<TaskModel> allTasks = List.from(tasks);

        defaultTasksResult.fold((l) => null, (defaultTasks) {
          // Generate instances for each day of the week
          for (int i = 0; i < 7; i++) {
            final date = monday.add(Duration(days: i));
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            // Only add default tasks for Today onwards
            if (date.isBefore(today)) continue;

            for (var dt in defaultTasks) {
              if (dt.weekdays.contains(date.weekday)) {
                final predictableId = TaskModel.generatePredictableId(
                  dt.id,
                  date,
                );

                // Check if already crystallized
                if (tasks.any((t) => t.id == predictableId)) continue;

                allTasks.add(
                  TaskModel.fromTimeOfDay(
                    id: predictableId,
                    name: dt.name,
                    desc: dt.desc,
                    startTime: dt.startTime,
                    endTime: dt.endTime,
                    taskDate: date,
                    category: dt.category,
                    completed: false,
                    oneTime: false,
                    importanceType: dt.importanceType,
                  ),
                );
              }
            }
          }
        });

        emit(
          WeeklyLoaded(
            allTasks,
            mondayDate: monday,
            firstTaskDate: state.firstTaskDate,
            lastTaskDate: state.lastTaskDate,
          ),
        );
      },
    );
  }
}
