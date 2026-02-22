import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:avenue/features/schdules/presentation/views/add_task_view.dart';
import 'package:avenue/features/schdules/presentation/widgets/task_card.dart';
import 'package:avenue/features/schdules/presentation/widgets/task_detail_sheet.dart';
import 'package:avenue/features/ai/presentation/widgets/animated_ai_button.dart';
import 'package:avenue/core/widgets/animated_task_button.dart';
import '../../../../core/widgets/avenue_loading.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../../data/models/task_model.dart';
import 'package:avenue/core/utils/constants.dart';
import 'package:avenue/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:avenue/core/utils/time_utils.dart';

class TimelineView extends StatefulWidget {
  final DateTime selectedDate;
  const TimelineView({super.key, required this.selectedDate});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final double hourHeight = 140.0;
  final double timeColumnWidth = 72.0;

  @override
  void initState() {
    super.initState();
    context.read<TaskCubit>().loadTasks(date: widget.selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Timeline",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, state) {
          Widget content;
          if (state is TaskLoading ||
              (state.selectedDate != null &&
                  state.selectedDate != widget.selectedDate)) {
            content = const Center(child: AvenueLoadingIndicator());
          } else if (state is TaskLoaded) {
            content = SingleChildScrollView(
              padding: const EdgeInsets.only(top: 20, bottom: 100),
              child: TimelineLayout(
                tasks: state.tasks,
                hourHeight: hourHeight,
                timeColumnWidth: timeColumnWidth,
              ),
            );
          } else if (state is TaskError) {
            content = Center(child: Text(state.message));
          } else {
            content = const SizedBox.shrink();
          }

          return Stack(
            children: [
              content,

              // AI Chat Button
              Positioned(
                right: 0,
                bottom: 100, // Adjusted for being inside body
                child: AnimatedAIChatButton(
                  visible: true,
                  onTap: () => context.push('/ai-chat'),
                ),
              ),

              // New Task Button
              Positioned(
                right: 0,
                bottom: 24,
                child: AnimatedTaskButton(
                  visible: true,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddTaskView(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class TimelineLayout extends StatelessWidget {
  final List<TaskModel> tasks;
  final double hourHeight;
  final double timeColumnWidth;

  const TimelineLayout({
    super.key,
    required this.tasks,
    required this.hourHeight,
    required this.timeColumnWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double startHour = 0.0;
    const double endHour = 24.0;
    final totalHours = endHour - startHour;
    final totalHeight = totalHours * hourHeight;
    final List<List<TaskModel>> groups = _groupOverlappingTasks(tasks);

    return SizedBox(
      height: totalHeight + 100,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: timeColumnWidth,
            child: CustomPaint(
              painter: TimeColumnPainter(
                startHour: startHour,
                endHour: endHour,
                hourHeight: hourHeight,
                theme: theme,
                is24HourFormat: context
                    .read<SettingsCubit>()
                    .state
                    .is24HourFormat,
              ),
            ),
          ),
          // Task start/end times
          ...tasks.expand((task) {
            final startTop = _calculateTopOffset(
              task.startTimeOfDay!,
              startHour,
            );
            final endTop = startTop + _calculateHeight(task.durationInMinutes);

            return [
              // Start dot
              Positioned(
                left: timeColumnWidth - 13,
                top: startTop - 3,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: task.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // End dot
              Positioned(
                left: timeColumnWidth - 13,
                top: endTop - 3,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: task.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: timeColumnWidth - 5,
                top: startTop - 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatTime(context, task.startTimeOfDay!),
                    style: TextStyle(
                      color: task.color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: timeColumnWidth - 5,
                top: endTop - 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatTime(context, task.endTimeOfDay!),
                    style: TextStyle(
                      color: task.color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ];
          }),
          // Tasks side-by-side
          ...groups.expand((group) {
            final columns = _assignColumns(group);
            final maxColumns =
                columns.values.fold(0, (max, col) => col > max ? col : max) + 1;

            return group.map((task) {
              final topOffset = _calculateTopOffset(
                task.startTimeOfDay!,
                startHour,
              );
              final height = _calculateHeight(task.durationInMinutes);
              final columnIndex = columns[task]!;

              return Positioned(
                top: topOffset,
                left:
                    timeColumnWidth +
                    40 +
                    (columnIndex *
                        (MediaQuery.of(context).size.width -
                            timeColumnWidth -
                            56) /
                        maxColumns),
                width:
                    (MediaQuery.of(context).size.width - timeColumnWidth - 56) /
                    maxColumns,
                height: height,
                child: TaskCard(
                  task: task,
                  height: height,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => TaskDetailSheet(
                        task: task,
                        selectedDate: task.taskDate,
                      ),
                    );
                  },
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => TaskDetailSheet(
                        task: task,
                        selectedDate: task.taskDate,
                      ),
                    );
                  },
                ),
              );
            });
          }),
        ],
      ),
    );
  }

  List<List<TaskModel>> _groupOverlappingTasks(List<TaskModel> tasks) {
    if (tasks.isEmpty) return [];

    final sortedTasks = List<TaskModel>.from(tasks)
      ..sort(
        (a, b) => _timeToDouble(
          a.startTimeOfDay!,
        ).compareTo(_timeToDouble(b.startTimeOfDay!)),
      );

    List<List<TaskModel>> groups = [];
    List<TaskModel> currentGroup = [sortedTasks[0]];
    double currentEnd = _timeToDouble(sortedTasks[0].endTimeOfDay!);

    for (int i = 1; i < sortedTasks.length; i++) {
      final task = sortedTasks[i];
      if (_timeToDouble(task.startTimeOfDay!) < currentEnd) {
        currentGroup.add(task);
        currentEnd = currentEnd > _timeToDouble(task.endTimeOfDay!)
            ? currentEnd
            : _timeToDouble(task.endTimeOfDay!);
      } else {
        groups.add(currentGroup);
        currentGroup = [task];
        currentEnd = _timeToDouble(task.endTimeOfDay!);
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
        if (_timeToDouble(task.startTimeOfDay!) >= columnEnds[i]) {
          columns[task] = i;
          columnEnds[i] = _timeToDouble(task.endTimeOfDay!);
          assigned = true;
          break;
        }
      }
      if (!assigned) {
        columns[task] = columnEnds.length;
        columnEnds.add(_timeToDouble(task.endTimeOfDay!));
      }
    }
    return columns;
  }

  double _timeToDouble(TimeOfDay time) => time.hour + (time.minute / 60.0);

  String _formatTime(BuildContext context, TimeOfDay time) {
    final is24Hour = context.read<SettingsCubit>().state.is24HourFormat;
    return TimeUtils.formatTime(time, is24Hour);
  }

  double _calculateTopOffset(TimeOfDay time, double startHour) {
    final double timeInHours = time.hour + (time.minute / 60.0);
    return (timeInHours - startHour) * hourHeight;
  }

  double _calculateHeight(int durationMinutes) {
    return (durationMinutes / 60.0) * hourHeight;
  }
}

class TimeColumnPainter extends CustomPainter {
  final double startHour;
  final double endHour;
  final double hourHeight;
  final ThemeData theme;
  final bool is24HourFormat;

  TimeColumnPainter({
    required this.startHour,
    required this.endHour,
    required this.hourHeight,
    required this.theme,
    required this.is24HourFormat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = theme.brightness == Brightness.dark;
    final linePaint = Paint()
      ..color = (isDark ? Colors.white : AppColors.slatePurple).withOpacity(0.1)
      ..strokeWidth = 1.5;

    final dotPaint = Paint()
      ..color = AppColors.salmonPink.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    canvas.drawLine(
      Offset(size.width - 10, 0),
      Offset(size.width - 10, size.height),
      linePaint,
    );

    for (int i = 0; i <= (endHour - startHour); i++) {
      final double y = i * hourHeight;
      final int hour = (startHour + i).toInt();

      canvas.drawCircle(Offset(size.width - 10, y), 3, dotPaint);

      final timeOfDay = TimeOfDay(hour: hour, minute: 0);
      final timeText = TimeUtils.formatTime(timeOfDay, is24HourFormat);
      textPainter.text = TextSpan(
        text: timeText,
        style: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.4),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
