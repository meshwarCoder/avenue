import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/utils/calendar_utils.dart';
import '../../../schdules/presentation/views/schedule_view.dart';
import '../cubit/weekly_cubit.dart';
import '../cubit/weekly_state.dart';
import '../../../schdules/presentation/cubit/task_cubit.dart';
import '../../../schdules/presentation/cubit/task_state.dart';
import '../../../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../../../features/settings/presentation/cubit/settings_state.dart';
import '../widgets/weekly_header.dart';
import '../widgets/weekly_days_row.dart';
import '../widgets/weekly_grid.dart';

class WeeklyCalendarPage extends StatefulWidget {
  const WeeklyCalendarPage({super.key});

  @override
  State<WeeklyCalendarPage> createState() => _WeeklyCalendarPageState();
}

class _WeeklyCalendarPageState extends State<WeeklyCalendarPage> {
  final ScrollController _scrollController = ScrollController();
  late DateTime _currentMonday;

  @override
  void initState() {
    super.initState();
    // Week start is now dynamic, will be handled in build/listener
    final weekStart = context.read<SettingsCubit>().state.weekStartDay;
    _currentMonday = CalendarUtils.getStartOfWeek(
      DateTime.now(),
      startOfWeek: weekStart,
    );

    // Use the new WeeklyCubit
    context.read<WeeklyCubit>().loadDateBounds();
    context.read<WeeklyCubit>().loadWeeklyTasks(_currentMonday);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Keep theme as it's used

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        // Prepare days based on current start of week
        final days = List.generate(
          7,
          (i) => _currentMonday.add(Duration(days: i)),
        );

        return BlocListener<SettingsCubit, SettingsState>(
          listener: (context, state) {
            // If week start changes, reset view to current week with new start
            final newStart = CalendarUtils.getStartOfWeek(
              DateTime.now(),
              startOfWeek: state.weekStartDay,
            );
            setState(() {
              _currentMonday = newStart;
            });
            context.read<WeeklyCubit>().loadWeeklyTasks(newStart);
          },
          child: BlocBuilder<WeeklyCubit, WeeklyState>(
            builder: (context, state) {
              return Scaffold(
                backgroundColor: theme.scaffoldBackgroundColor,
                body: SafeArea(
                  bottom: false,
                  child: BlocListener<TaskCubit, TaskState>(
                    listener: (context, taskState) {
                      // If a task was added, updated, or deleted, reload the week
                      if (taskState is TaskLoaded) {
                        context.read<WeeklyCubit>().loadWeeklyTasks(
                          _currentMonday,
                        );
                      }
                    },
                    child: Column(
                      children: [
                        // Header: Navigation and Month/Year range
                        WeeklyHeader(
                          currentMonday: _currentMonday,
                          firstTaskDate: state.firstTaskDate,
                          lastTaskDate: state.lastTaskDate,
                          weekStartDay: settingsState.weekStartDay,
                          onWeekChanged: (newMonday) {
                            setState(() {
                              _currentMonday = newMonday;
                            });
                            context.read<WeeklyCubit>().loadWeeklyTasks(
                              newMonday,
                            );
                          },
                        ),

                        // Days Row: Clickable day labels (Mon, Tue, etc.)
                        WeeklyDaysRow(
                          days: days,
                          currentMonday: _currentMonday,
                          onDayTapped: (date) async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlocProvider.value(
                                  value: context.read<TaskCubit>(),
                                  child: HomeView(selectedDate: date),
                                ),
                              ),
                            ).then((_) {
                              // Reload weekly tasks upon return to ensure UI is in sync
                              if (mounted) {
                                context.read<WeeklyCubit>().loadWeeklyTasks(
                                  _currentMonday,
                                );
                              }
                            });
                          },
                        ),

                        // Main Grid: Scrollable area with time sidebar and tasks
                        Expanded(
                          child: WeeklyGrid(
                            days: days,
                            state: state,
                            scrollController: _scrollController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
