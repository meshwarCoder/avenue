import 'package:flutter/material.dart';
import '../../../schdules/data/models/task_model.dart';

class WeeklyTaskItem extends StatelessWidget {
  final TaskModel task;
  final int columnIndex;
  final int maxColumns;
  final double dayWidth;

  const WeeklyTaskItem({
    super.key,
    required this.task,
    required this.columnIndex,
    required this.maxColumns,
    required this.dayWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (task.startTime == null || task.endTime == null)
      return const SizedBox.shrink();

    // Ensure we use local time for positioning
    final localStart = task.startTime!.toLocal();
    final localEnd = task.endTime!.toLocal();

    final startHour = localStart.hour + (localStart.minute / 60.0);
    final endHour = localEnd.hour + (localEnd.minute / 60.0);

    // Calc positioning based on 0-24 grid
    final top = (startHour) * 60.0;
    double height = (endHour - startHour) * 60.0;

    // Minimum visual height + clipping
    if (height < 20) height = 20;

    // Boundary check to prevent bleeding out of 24h
    const bottomBoundary = 24.0 * 60.0;
    final finalHeight = (top + height > bottomBoundary)
        ? (bottomBoundary - top)
        : height;
    if (finalHeight <= 0) return const SizedBox.shrink();

    return Positioned(
      top: top,
      left: 2 + (columnIndex * (1.0 / maxColumns) * dayWidth),
      child: Container(
        width: (dayWidth / maxColumns) - 4,
        height: finalHeight,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: task.color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: task.color, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              task.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (finalHeight > 25)
              Text(
                '${localStart.hour.toString().padLeft(2, '0')}:${localStart.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 8,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
