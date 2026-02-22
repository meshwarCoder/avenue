import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/task_model.dart';
import '../cubit/task_cubit.dart';
import 'package:avenue/core/utils/constants.dart';
import 'package:avenue/core/utils/calendar_utils.dart';
import 'package:avenue/core/utils/task_utils.dart';
import 'package:avenue/features/schdules/presentation/views/add_task_view.dart';

class TaskDetailSheet extends StatelessWidget {
  final TaskModel task;
  final DateTime selectedDate;

  const TaskDetailSheet({
    super.key,
    required this.task,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPast = selectedDate.isBefore(
      CalendarUtils.normalize(DateTime.now()),
    );
    final isMissed = isPast && !task.completed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category & Importance Badges
          Row(
            children: [
              _buildBadge(context, task.category, task.color),
              if (task.importanceType != null) ...[
                const SizedBox(width: 8),
                _buildImportanceBadge(context, task.importanceType!),
              ],
              const Spacer(),
              if (task.completed)
                _buildStatusChip(context, "Completed", Colors.green)
              else if (isMissed)
                _buildStatusChip(context, "Missed", Colors.redAccent),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            task.name,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Time & Frequency info
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_filled_rounded,
                    size: 18,
                    color: theme.primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    task.startTimeOfDay != null && task.endTimeOfDay != null
                        ? "${task.startTimeOfDay!.format(context)} - ${task.endTimeOfDay!.format(context)}"
                        : task.startTimeOfDay != null
                        ? "From ${task.startTimeOfDay!.format(context)}"
                        : "All Day",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    task.oneTime
                        ? Icons.calendar_today_rounded
                        : Icons.repeat_rounded,
                    size: 18,
                    color: theme.primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    task.oneTime ? "One-time" : "Recurring",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Description
          if (task.desc != null && task.desc!.isNotEmpty) ...[
            Text(
              "NOTES",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Text(
                  task.desc!,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Actions Row
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 10,
            ),
            child: Row(
              children: [
                // Delete Button
                _buildActionButton(
                  context,
                  icon: Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  onTap: () {
                    final navigator = Navigator.of(context);
                    // Open the dialog first, pass the navigator so we can pop the sheet later.
                    _showDeleteConfirmation(context, navigator);
                  },
                ),
                const SizedBox(width: 12),
                // Edit Button
                _buildActionButton(
                  context,
                  icon: Icons.edit_outlined,
                  color: AppColors.slatePurple,
                  onTap: () {
                    final navigator = Navigator.of(context);
                    navigator.pop(); // Close detail sheet
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddTaskView(task: task),
                    );
                  },
                ),
                const SizedBox(width: 16),
                // Toggle Done Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: isPast
                        ? null
                        : () {
                            if (!TaskUtils.canCompleteTask(task)) {
                              TaskUtils.showBlockedActionMessage(
                                context,
                                "Task hasn't started yet!",
                              );
                              return;
                            }
                            final cubit = context.read<TaskCubit>();
                            Navigator.pop(context); // Close detail sheet
                            cubit.toggleTaskDone(task);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: task.completed
                          ? Colors.amber
                          : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          task.completed
                              ? Icons.undo_rounded
                              : Icons.check_rounded,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          task.completed ? "Mark as Pending" : "Mark as Done",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildImportanceBadge(BuildContext context, String importance) {
    Color color;
    switch (importance.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            importance.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, NavigatorState navigator) {
    // Capture the cubit BEFORE showing the dialog to avoid deactivated context errors later
    final cubit = context.read<TaskCubit>();
    final isDefaultTask = !task.oneTime || task.defaultTaskId != null;

    showDialog(
      // Important: Use the navigator's context to show the dialog
      // so it's tied to the root navigator, not the bottom sheet.
      context: navigator.context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isDefaultTask ? 'Delete Recurring Task' : 'Delete Task'),
        content: Text(
          isDefaultTask
              ? 'Would you like to delete this task for today only, or stop it from recurring entirely?'
              : 'Are you sure you want to delete this task?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // Close dialog only
            child: const Text('Cancel'),
          ),
          if (isDefaultTask) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                navigator.pop(); // Close the bottom sheet
                cubit.hideDefaultTaskForDate(
                  task.defaultTaskId ?? task.id,
                  selectedDate,
                  taskId: task.id,
                );
              },
              child: const Text('Only Today'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                navigator.pop(); // Close the bottom sheet
                cubit.deleteDefaultTaskEntirely(
                  task.defaultTaskId ?? task.id,
                  taskId: task.id,
                );
              },
              child: const Text(
                'Entirely',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ] else
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                navigator.pop(); // Close the bottom sheet
                cubit.deleteTask(task.id);
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
}
