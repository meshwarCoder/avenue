import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../schdules/data/models/task_model.dart';
import '../../../schdules/presentation/views/add_task_view.dart';
import '../cubit/weekly_state.dart';
import 'weekly_task_item.dart';
import '../../../../core/utils/task_utils.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';

class WeeklyGrid extends StatelessWidget {
  final List<DateTime> days;
  final WeeklyState state;
  final ScrollController scrollController;
  final double hourHeight;

  const WeeklyGrid({
    super.key,
    required this.days,
    required this.state,
    required this.scrollController,
    required this.hourHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Total flex layout perfectly matches header: 1 (time column) + 7 (days grid) = 8
    final screenWidth = MediaQuery.of(context).size.width;
    final dayWidth = screenWidth / (1 + days.length);

    return SingleChildScrollView(
      controller: scrollController,

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: _buildTimeColumn(context)),
          Expanded(
            flex: days.length,
            child: _buildDaysGrid(context, days, state, dayWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(BuildContext context) {
    final is24Hour = context.read<SettingsCubit>().state.is24HourFormat;
    final textStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    return Column(
      children: List.generate(24, (index) {
        final hour = index;
        final timeText = TimeUtils.formatTime(
          TimeOfDay(hour: hour, minute: 0),
          is24Hour,
          locale: Localizations.localeOf(context).languageCode,
        );

        return SizedBox(
          height: hourHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Current Hour Label
              Align(
                alignment: Alignment.topCenter,
                child: FractionalTranslation(
                  translation: Offset(0.0, index == 0 ? 0.0 : -0.5),
                  child: Text(timeText, style: textStyle),
                ),
              ),
              // Midnight label for the very end of the day (bottom of last cell)
              if (index == 23)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    TimeUtils.formatTime(
                      const TimeOfDay(hour: 0, minute: 0),
                      is24Hour,
                      locale: Localizations.localeOf(context).languageCode,
                    ),
                    style: textStyle,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDaysGrid(
    BuildContext context,
    List<DateTime> weekDays,
    WeeklyState state,
    double dayWidth,
  ) {
    final List<TaskModel> allTasks = (state is WeeklyLoaded) ? state.tasks : [];

    return Row(
      children: List.generate(7, (dayIndex) {
        final date = weekDays[dayIndex];
        final dayTasks = allTasks.where((task) {
          final localTaskDate = task.taskDate.toLocal();
          return localTaskDate.year == date.year &&
              localTaskDate.month == date.month &&
              localTaskDate.day == date.day &&
              task.startTime != null &&
              task.endTime != null;
        }).toList();

        if (dayTasks.isEmpty) {
          return Expanded(
            child: Stack(children: [_buildGridLines(context, date)]),
          );
        }

        final groups = _groupOverlappingTasks(dayTasks);

        return Expanded(
          child: Stack(
            children: [
              // Grid Lines Column
              _buildGridLines(context, date),
              // Tasks
              ...groups.expand((group) {
                final columns = _assignColumns(group);
                final maxCols = columns.values.isEmpty
                    ? 1
                    : columns.values.reduce((a, b) => a > b ? a : b) + 1;
                return group.map(
                  (task) => WeeklyTaskItem(
                    task: task,
                    columnIndex: columns[task] ?? 0,
                    maxColumns: maxCols,
                    dayWidth: dayWidth,
                    hourHeight: hourHeight,
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildGridLines(BuildContext context, DateTime date) {
    return Column(
      children: List.generate(
        24,
        (hour) => GestureDetector(
          onTap: () {
            if (TaskUtils.isPast(date, TimeOfDay(hour: hour, minute: 0))) {
              TaskUtils.showBlockedActionMessage(
                context,
                AppLocalizations.of(context)!.errPastTask,
              );
              return;
            }
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddTaskView(
                initialDate: date,
                initialStartTime: TimeOfDay(hour: hour, minute: 0),
                initialEndTime: TimeOfDay(hour: (hour + 1) % 24, minute: 0),
                disableRecurring: true,
              ),
            );
          },
          child: Container(
            height: hourHeight,
            decoration: BoxDecoration(
              border: BorderDirectional(
                end: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  width: 0.5,
                ),
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<List<TaskModel>> _groupOverlappingTasks(List<TaskModel> tasks) {
    if (tasks.isEmpty) return [];

    final sortedTasks = List<TaskModel>.from(tasks)
      ..sort(
        (a, b) => _timeToDouble(
          a.startTime!.toLocal(),
        ).compareTo(_timeToDouble(b.startTime!.toLocal())),
      );

    List<List<TaskModel>> groups = [];
    List<TaskModel> currentGroup = [sortedTasks[0]];
    double currentEnd = _timeToDouble(sortedTasks[0].endTime!.toLocal());

    for (int i = 1; i < sortedTasks.length; i++) {
      final task = sortedTasks[i];
      if (_timeToDouble(task.startTime!.toLocal()) < currentEnd) {
        currentGroup.add(task);
        currentEnd = currentEnd > _timeToDouble(task.endTime!.toLocal())
            ? currentEnd
            : _timeToDouble(task.endTime!.toLocal());
      } else {
        groups.add(currentGroup);
        currentGroup = [task];
        currentEnd = _timeToDouble(task.endTime!.toLocal());
      }
    }
    groups.add(currentGroup);
    return groups;
  }

  Map<TaskModel, int> _assignColumns(List<TaskModel> group) {
    Map<TaskModel, int> columns = {};
    List<double> columnEnds = [];

    for (var task in group) {
      bool assigned = false;
      for (int i = 0; i < columnEnds.length; i++) {
        if (_timeToDouble(task.startTime!.toLocal()) >= columnEnds[i]) {
          columns[task] = i;
          columnEnds[i] = _timeToDouble(task.endTime!.toLocal());
          assigned = true;
          break;
        }
      }
      if (!assigned) {
        columns[task] = columnEnds.length;
        columnEnds.add(_timeToDouble(task.endTime!.toLocal()));
      }
    }
    return columns;
  }

  double _timeToDouble(DateTime time) => time.hour + (time.minute / 60.0);
}
