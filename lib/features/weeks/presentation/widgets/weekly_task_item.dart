import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../schdules/data/models/task_model.dart';
import '../../../schdules/presentation/views/add_task_view.dart';
import '../../../schdules/presentation/cubit/task_cubit.dart';
import '../../../../core/utils/task_utils.dart';

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
      child: GestureDetector(
        onTap: () => _showTaskOptions(context),
        child: Container(
          width: (dayWidth / maxColumns) - 4,
          height: finalHeight,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
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
                      maxLines: height < 40 ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (height > 45) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildImportanceDot(task.importanceType ?? 'Low'),
                    if (task.completed)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 10,
                      )
                    else if (_isMissed(task))
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 10,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(
              task.completed
                  ? Icons.undo_rounded
                  : Icons.check_circle_outline_rounded,
              color: !TaskUtils.canCompleteTask(task)
                  ? Colors.grey.withOpacity(0.5)
                  : (task.completed ? Colors.grey : Colors.green),
            ),
            title: Text(
              task.completed
                  ? 'Mark as Pending'
                  : (!TaskUtils.canCompleteTask(task)
                        ? 'Cannot Complete Yet'
                        : 'Mark as Completed'),
              style: TextStyle(
                color: !TaskUtils.canCompleteTask(task) ? Colors.grey : null,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);
              if (!TaskUtils.canCompleteTask(task)) {
                TaskUtils.showBlockedActionMessage(
                  context,
                  "This task hasn't started yet!",
                );
                return;
              }

              final confirm = task.completed
                  ? await TaskUtils.confirmTaskUndo(context)
                  : await TaskUtils.confirmTaskCompletion(context);

              if (confirm && context.mounted) {
                context.read<TaskCubit>().toggleTaskDone(task);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: Colors.blue),
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
            leading: const Icon(Icons.delete_rounded, color: Colors.redAccent),
            title: const Text('Delete Task'),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
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
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
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
