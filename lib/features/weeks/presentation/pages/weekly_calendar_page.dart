import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/utils/calendar_utils.dart';
import '../../../schdules/presentation/views/schedule_view.dart';
import '../cubit/weekly_cubit.dart';
import '../cubit/weekly_state.dart';
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
    _currentMonday = CalendarUtils.getStartOfWeek(DateTime.now());

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
    final days = List.generate(7, (i) => _currentMonday.add(Duration(days: i)));

    return BlocBuilder<WeeklyCubit, WeeklyState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF001A20),
          body: SafeArea(
            child: Column(
              children: [
                // Header: Navigation and Month/Year range
                WeeklyHeader(
                  currentMonday: _currentMonday,
                  firstTaskDate: state.firstTaskDate,
                  lastTaskDate: state.lastTaskDate,
                  onWeekChanged: (newMonday) {
                    setState(() {
                      _currentMonday = newMonday;
                    });
                    context.read<WeeklyCubit>().loadWeeklyTasks(newMonday);
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
                        builder: (context) => HomeView(selectedDate: date),
                      ),
                    );
                    // Reload weekly tasks upon return to ensure UI is in sync
                    if (mounted) {
                      context.read<WeeklyCubit>().loadWeeklyTasks(
                        _currentMonday,
                      );
                    }
                  },
                ),

                // Main Grid: Scrollable area with time sidebar and tasks
                WeeklyGrid(
                  days: days,
                  state: state,
                  scrollController: _scrollController,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
