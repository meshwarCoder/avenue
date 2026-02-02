import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.height,
    this.onTap,
    this.onLongPress,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final secondaryText = onSurface.withOpacity(0.6);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: task.completed ? 0.7 : 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          height: height,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: task.completed
                  ? Colors.green.withOpacity(0.3)
                  : theme.dividerColor.withOpacity(0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Left accent bar
                  Container(
                    width: 4,
                    color: task.completed ? Colors.grey : task.color,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxHeight < 110;

                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Category and Importance
                              Row(
                                children: [
                                  _buildBadge(
                                    context,
                                    task.category,
                                    task.color,
                                  ),
                                  if (task.importanceType != null &&
                                      !isCompact) ...[
                                    const SizedBox(width: 6),
                                    _buildBadge(
                                      context,
                                      task.importanceType!,
                                      _getImportanceColor(task.importanceType!),
                                      isOutline: true,
                                    ),
                                  ],
                                  const Spacer(),
                                  if (task.completed)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Title
                              Text(
                                task.name,
                                style: TextStyle(
                                  fontSize: isCompact ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: onSurface,
                                  decoration: task.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Description (if not compact)
                              if (!isCompact &&
                                  task.desc != null &&
                                  task.desc!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  task.desc!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryText,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const Spacer(),
                              // Footer: Time and Type
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: secondaryText,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${_formatTime(task.startTimeOfDay)} - ${_formatTime(task.endTimeOfDay)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: secondaryText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildTypeIndicator(context, task.oneTime),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context,
    String label,
    Color color, {
    bool isOutline = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: isOutline
            ? Border.all(color: color.withOpacity(0.5), width: 1)
            : null,
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTypeIndicator(BuildContext context, bool isOneTime) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOneTime ? Icons.calendar_today : Icons.repeat,
          size: 10,
          color: theme.colorScheme.primary.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Text(
          isOneTime ? "ONE-TIME" : "RECURRING",
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary.withOpacity(0.6),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Color _getImportanceColor(String importance) {
    switch (importance.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
