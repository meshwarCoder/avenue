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
  double _hourHeight = 60.0; // Default height for 1 hour block

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
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: WeeklyHeader(
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
                        ),
                        SliverToBoxAdapter(
                          child: WeeklyDaysRow(
                            days: days,
                            currentMonday: _currentMonday,
                            currentZoom: _hourHeight,
                            onZoomChanged: (newZoom) {
                              setState(() {
                                _hourHeight = newZoom;
                              });
                            },
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
                                if (mounted) {
                                  context.read<WeeklyCubit>().loadWeeklyTasks(
                                    _currentMonday,
                                  );
                                }
                              });
                            },
                          ),
                        ),
                        SliverFillRemaining(
                          child: WeeklyGrid(
                            days: days,
                            state: state,
                            scrollController: _scrollController,
                            hourHeight: _hourHeight,
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
