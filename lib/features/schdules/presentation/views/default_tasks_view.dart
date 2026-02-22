import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avenue/features/schdules/data/models/default_task_model.dart';
import 'package:avenue/features/schdules/presentation/views/add_task_view.dart';
import 'package:avenue/features/schdules/presentation/cubit/default_tasks_cubit.dart';
import 'package:avenue/features/schdules/presentation/cubit/default_tasks_state.dart';
import 'package:avenue/core/widgets/avenue_loading.dart';

class DefaultTasksView extends StatefulWidget {
  const DefaultTasksView({super.key});

  @override
  State<DefaultTasksView> createState() => _DefaultTasksViewState();
}

class _DefaultTasksViewState extends State<DefaultTasksView> {
  @override
  void initState() {
    super.initState();
    context.read<DefaultTasksCubit>().loadDefaultTasks();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Master Routine',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: BlocBuilder<DefaultTasksCubit, DefaultTasksState>(
        builder: (context, state) {
          if (state is DefaultTasksLoading) {
            return const Center(child: AvenueLoadingIndicator());
          } else if (state is DefaultTasksError) {
            return Center(child: Text(state.message));
          } else if (state is DefaultTasksLoaded) {
            if (state.tasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.repeat_on_rounded,
                      size: 64,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No recurring tasks yet.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.tasks.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DefaultTaskCard(task: state.tasks[index]),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DefaultTaskCard extends StatelessWidget {
  final DefaultTaskModel task;

  const _DefaultTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = task.color;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar
              Container(width: 6, color: color),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Wrap left side in Expanded to handle overflow
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: _buildBadge(
                                      context,
                                      task.category,
                                      color,
                                    ),
                                  ),
                                  if (task.importanceType != null) ...[
                                    const SizedBox(width: 8),
                                    _buildImportanceDot(task.importanceType!),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Actions Row
                            _buildActionButton(
                              context,
                              icon: Icons.edit_outlined,
                              color: theme.colorScheme.primary,
                              onTap: () => _handleEdit(context),
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              context,
                              icon: Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                              onTap: () => _confirmDelete(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          task.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.desc != null && task.desc!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.desc!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_filled_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_formatTime(task.startTime)} - ${_formatTime(task.endTime)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildWeekdaysRow(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
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

  Widget _buildImportanceDot(String importance) {
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
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _handleEdit(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTaskView(defaultTask: task),
    );
    if (context.mounted) {
      context.read<DefaultTasksCubit>().loadDefaultTasks();
    }
  }

  Widget _buildWeekdaysRow(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(7, (index) {
          final dayIndex = index + 1;
          final isActive = task.weekdays.contains(dayIndex);
          return Container(
            margin: const EdgeInsets.only(right: 6),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive ? task.color : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? task.color : Colors.grey.withOpacity(0.3),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              days[index],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey,
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: Text(
          'Are you sure you want to delete "${task.name}"? This will stop generating future tasks for this routine.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      context.read<DefaultTasksCubit>().deleteDefaultTask(task.id);
    }
  }
}
