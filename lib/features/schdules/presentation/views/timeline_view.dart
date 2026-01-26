import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:line/features/schdules/presentation/views/add_task_view.dart';
import 'package:line/features/schdules/presentation/widgets/task_card.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../../data/models/task_model.dart';

class TimelineView extends StatefulWidget {
  final DateTime selectedDate;
  const TimelineView({super.key, required this.selectedDate});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final double hourHeight = 120.0;
  final double timeColumnWidth = 60.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskCubit>().loadTasks(date: widget.selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
          if (state is TaskLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TaskLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: TimelineLayout(
                tasks: state.tasks,
                hourHeight: hourHeight,
                timeColumnWidth: timeColumnWidth,
              ),
            );
          } else if (state is TaskError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: _isPastDate(widget.selectedDate)
          ? null
          : FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      AddTaskView(initialDate: widget.selectedDate),
                );
              },
              backgroundColor: const Color(0xFF004D61),
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today);
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
              ),
            ),
          ),
          // Task start/end times
          ...tasks.expand((task) {
            final startTop = _calculateTopOffset(
              task.startTimeOfDay,
              startHour,
            );
            final endTop = startTop + _calculateHeight(task.durationInMinutes);

            return [
              // Start dot
              Positioned(
                left: timeColumnWidth - 13,
                top: startTop - 3,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: task.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // End dot
              Positioned(
                left: timeColumnWidth - 13,
                top: endTop - 3,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: task.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: timeColumnWidth - 5,
                top: startTop - 10,
                child: Text(
                  _formatTime(task.startTimeOfDay),
                  style: TextStyle(
                    color: task.color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    backgroundColor: const Color(0xFFF5F7FA),
                  ),
                ),
              ),
              Positioned(
                left: timeColumnWidth - 5,
                top: endTop - 10,
                child: Text(
                  _formatTime(task.endTimeOfDay),
                  style: TextStyle(
                    color: task.color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    backgroundColor: const Color(0xFFF5F7FA),
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
                task.startTimeOfDay,
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
                  onTap: _isPastDate(task.date)
                      ? null
                      : () {
                          context.read<TaskCubit>().toggleTaskDone(task.id);
                        },
                  onLongPress: _isPastDate(task.date)
                      ? null
                      : () {
                          _showTaskOptions(context, task);
                        },
                ),
              );
            });
          }),
        ],
      ),
    );
  }

  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today);
  }

  void _showTaskOptions(BuildContext context, TaskModel task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Edit Task'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => AddTaskView(task: task),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Task'),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, task);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskCubit>().deleteTask(task.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<List<TaskModel>> _groupOverlappingTasks(List<TaskModel> tasks) {
    if (tasks.isEmpty) return [];

    final sortedTasks = List<TaskModel>.from(tasks)
      ..sort(
        (a, b) => _timeToDouble(
          a.startTimeOfDay,
        ).compareTo(_timeToDouble(b.startTimeOfDay)),
      );

    List<List<TaskModel>> groups = [];
    List<TaskModel> currentGroup = [sortedTasks[0]];
    double currentEnd = _timeToDouble(sortedTasks[0].endTimeOfDay);

    for (int i = 1; i < sortedTasks.length; i++) {
      final task = sortedTasks[i];
      if (_timeToDouble(task.startTimeOfDay) < currentEnd) {
        currentGroup.add(task);
        currentEnd = currentEnd > _timeToDouble(task.endTimeOfDay)
            ? currentEnd
            : _timeToDouble(task.endTimeOfDay);
      } else {
        groups.add(currentGroup);
        currentGroup = [task];
        currentEnd = _timeToDouble(task.endTimeOfDay);
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
        if (_timeToDouble(task.startTimeOfDay) >= columnEnds[i]) {
          columns[task] = i;
          columnEnds[i] = _timeToDouble(task.endTimeOfDay);
          assigned = true;
          break;
        }
      }
      if (!assigned) {
        columns[task] = columnEnds.length;
        columnEnds.add(_timeToDouble(task.endTimeOfDay));
      }
    }
    return columns;
  }

  double _timeToDouble(TimeOfDay time) => time.hour + (time.minute / 60.0);

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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

  TimeColumnPainter({
    required this.startHour,
    required this.endHour,
    required this.hourHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.blue.shade100
      ..strokeWidth = 2;

    final dotPaint = Paint()
      ..color = Colors.blue
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

      canvas.drawCircle(Offset(size.width - 10, y), 4, dotPaint);

      final timeText = '${hour.toString().padLeft(2, '0')}:00';
      textPainter.text = TextSpan(
        text: timeText,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
