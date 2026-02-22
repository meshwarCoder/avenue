import 'package:flutter/material.dart';
import '../../../schdules/data/models/task_model.dart';
import '../../../schdules/presentation/widgets/task_detail_sheet.dart';

class WeeklyTaskItem extends StatelessWidget {
  final TaskModel task;
  final int columnIndex;
  final int maxColumns;
  final double dayWidth;
  final double hourHeight;

  const WeeklyTaskItem({
    super.key,
    required this.task,
    required this.columnIndex,
    required this.maxColumns,
    required this.dayWidth,
    required this.hourHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (task.startTime == null || task.endTime == null)
      return const SizedBox.shrink();

    // Ensure we use local time for positioning
    final localStart = task.startTime!.toLocal();
    final localEnd = task.endTime!.toLocal();

    final startHour = localStart.hour + (localStart.minute / 60.0);
    var endHour = localEnd.hour + (localEnd.minute / 60.0);

    // Handle spanning to next day (e.g., 23:00 -> 00:00 becomes 23.0 -> 24.0)
    if (endHour < startHour) {
      endHour += 24.0;
    }

    // Calc positioning based on 0-24 grid
    final top = (startHour) * hourHeight;
    double height = (endHour - startHour) * hourHeight;

    // Minimum visual height + clipping
    if (height < 20) height = 20;

    // Boundary check to prevent bleeding out of 24h
    final bottomBoundary = 24.0 * hourHeight;
    final finalHeight = (top + height > bottomBoundary)
        ? (bottomBoundary - top)
        : height;
    if (finalHeight <= 0) return const SizedBox.shrink();

    return Positioned(
      top: top,
      left: 2 + (columnIndex * (1.0 / maxColumns) * dayWidth),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) =>
                TaskDetailSheet(task: task, selectedDate: task.taskDate),
          );
        },
        child: Container(
          width: (dayWidth / maxColumns) - 4,
          height: finalHeight,
          clipBehavior: Clip.hardEdge, // Prevent anything from overflowing
          decoration: BoxDecoration(
            color: task.completed
                ? Colors.green.withOpacity(0.15)
                : (_isMissed(task)
                      ? Colors.red.withOpacity(0.15)
                      : task.color.withOpacity(0.8)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: task.completed
                  ? Colors.green.withOpacity(0.5)
                  : (_isMissed(task)
                        ? Colors.red.withOpacity(0.5)
                        : task.color),
              width: 1.0,
            ),
          ),
          child: finalHeight < 18
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              task.name,
                              style: TextStyle(
                                color: task.completed
                                    ? Colors.green[900]
                                    : (_isMissed(task)
                                          ? Colors.red[900]
                                          : Colors.white),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                decoration: task.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (height > 45) ...[
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 2,
                          left: 3,
                          right: 3,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildImportanceDot(task.importanceType ?? 'Low'),
                            const SizedBox(width: 4),
                            if (task.completed)
                              const Flexible(
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                  size: 10,
                                ),
                              )
                            else if (_isMissed(task))
                              const Flexible(
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.red,
                                  size: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildImportanceDot(String importance) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: _getImportanceColor(importance),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getImportanceColor(String importance) {
    switch (importance.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  bool _isMissed(TaskModel task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return task.taskDate.isBefore(today) && !task.completed;
  }
}
