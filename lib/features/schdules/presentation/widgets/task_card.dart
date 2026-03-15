import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import 'package:avenue/core/utils/time_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avenue/l10n/app_localizations.dart';
import 'package:avenue/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:avenue/core/widgets/base_avenue_card.dart';

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
    final isPast = _isPastDate(task.taskDate);
    final isMissed = isPast && !task.completed;
    final onSurface = theme.colorScheme.onSurface;
    final secondaryText = onSurface.withValues(alpha: 0.6);

    final accentColor = task.completed
        ? Colors.green
        : (isMissed ? Colors.redAccent : task.color);

    final backgroundColor = task.completed
        ? Colors.green.withValues(alpha: 0.08)
        : (isMissed ? Colors.red.withValues(alpha: 0.08) : theme.cardColor);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: task.completed ? 0.9 : 1.0,
      child: BaseAvenueCard(
        onTap: onTap,
        onLongPress: onLongPress,
        accentColor: accentColor,
        backgroundColor: backgroundColor,
        height: height,
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 110;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Category, Importance Dot, and Status Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            fit: FlexFit.loose,
                            child: _buildBadge(
                              context,
                              task.category,
                              accentColor,
                            ),
                          ),
                          if (task.importanceType != null) ...[
                            const SizedBox(width: 8),
                            _buildImportanceDot(
                              task.importanceType!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (task.completed)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 18,
                      )
                    else if (isMissed)
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Content: Title and Description (Flexible)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        task.name,
                        style: TextStyle(
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          decoration:
                              task.completed ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.desc != null && task.desc!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            task.desc!,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Footer: Time and Type
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 11,
                      color: secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      flex: 3,
                      child: Text(
                        '${_formatTime(context, task.startTimeOfDay)} - ${_formatTime(context, task.endTimeOfDay)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: _buildTypeIndicator(
                        context,
                        task.oneTime && task.defaultTaskId == null,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
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
        color: isOutline ? Colors.transparent : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: isOutline
            ? Border.all(color: color.withValues(alpha: 0.5), width: 1)
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTypeIndicator(BuildContext context, bool isOneTime) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : theme.colorScheme.primary.withValues(alpha: 0.7);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOneTime ? Icons.calendar_today : Icons.repeat,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isOneTime
                ? AppLocalizations.of(context)!.oneTimeUpper
                : AppLocalizations.of(context)!.recurringUpper,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildImportanceDot(String importance) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getImportanceColor(importance),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getImportanceColor(importance).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today);
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

  String _formatTime(BuildContext context, TimeOfDay? time) {
    if (time == null) return '--:--';
    final is24Hour = context.read<SettingsCubit>().state.is24HourFormat;
    return TimeUtils.formatTime(time, is24Hour);
  }
}
