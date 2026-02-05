import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avenue/core/utils/constants.dart';
import 'package:avenue/features/schdules/data/models/task_model.dart';
import 'package:avenue/features/schdules/presentation/views/add_task_view.dart';
import 'package:avenue/features/schdules/presentation/views/timeline_view.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../widgets/task_card.dart';
import '../../../../core/widgets/avenue_loading.dart';
import '../../../../core/utils/task_utils.dart';
import '../../../../core/utils/calendar_utils.dart';
import '../../../../core/utils/observability.dart';

class HomeView extends StatefulWidget {
  final DateTime? selectedDate;
  const HomeView({super.key, this.selectedDate});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.selectedDate ?? DateTime.now();
    _date = DateTime(_date.year, _date.month, _date.day);

    final cubit = context.read<TaskCubit>();
    AvenueLogger.log(
      event: 'UI_INIT_STATE',
      layer: LoggerLayer.UI,
      payload: 'HomeView',
    );
    cubit.loadTasks(date: _date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _formatDate(_date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: const Icon(Icons.sync_rounded),
                onPressed: () => context.read<TaskCubit>().syncTasks(),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TimelineView(selectedDate: _date),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, state) {
          final isSameDate =
              state.selectedDate != null &&
              CalendarUtils.normalize(state.selectedDate!) == _date;

          // Show loader if:
          // 1. State is explicitly TaskLoading
          // 2. We are in TaskInitial (just started)
          // 3. The state belongs to a different date and it's NOT an error/loaded state we can use
          bool shouldShowLoader = state is TaskLoading || state is TaskInitial;
          if (!isSameDate && state is! TaskError && state is! TaskLoaded) {
            shouldShowLoader = true;
          }

          if (shouldShowLoader) {
            return const Center(child: AvenueLoadingIndicator());
          } else if (state is TaskLoaded) {
            final tasks = state.tasks;
            final completedTasks = tasks.where((t) => t.completed).length;
            final pendingTasks = tasks.length - completedTasks;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildSummaryCard(
                    tasks.length,
                    completedTasks,
                    pendingTasks,
                  ),
                ),
                if (tasks.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt_rounded,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text('No tasks for today. Relax!'),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final task = tasks[index];
                        final isPast = _isPastDate(_date);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TaskCard(
                            task: task,
                            height: 100,
                            onTap: isPast
                                ? null
                                : () async {
                                    if (!TaskUtils.canCompleteTask(task)) {
                                      TaskUtils.showBlockedActionMessage(
                                        context,
                                        "This task hasn't started yet!",
                                      );
                                      return;
                                    }

                                    final confirm = task.completed
                                        ? await TaskUtils.confirmTaskUndo(
                                            context,
                                          )
                                        : await TaskUtils.confirmTaskCompletion(
                                            context,
                                          );

                                    if (confirm && context.mounted) {
                                      context.read<TaskCubit>().toggleTaskDone(
                                        task,
                                      );
                                    }
                                  },
                            onLongPress: isPast
                                ? null
                                : () {
                                    _showTaskOptions(context, task);
                                  },
                          ),
                        );
                      }, childCount: tasks.length),
                    ),
                  ),
              ],
            );
          } else if (state is TaskError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummaryCard(int total, int completed, int pending) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem("Total", total.toString(), AppColors.slatePurple),
          _buildSummaryItem("Done", completed.toString(), Colors.green),
          _buildSummaryItem(
            "Pending",
            pending.toString(),
            AppColors.salmonPink,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  void _showTaskOptions(BuildContext context, TaskModel task) {
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
            leading: const Icon(
              Icons.edit_rounded,
              color: AppColors.slatePurple,
            ),
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
              _showDeleteConfirmation(context, task);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TaskModel task) {
    final isDefaultTask = !task.oneTime || task.defaultTaskId != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDefaultTask ? 'Delete Recurring Task' : 'Delete Task'),
        content: Text(
          isDefaultTask
              ? 'Would you like to delete this task for today only, or stop it from recurring entirely?'
              : 'Are you sure you want to delete this task?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (isDefaultTask) ...[
            TextButton(
              onPressed: () {
                context.read<TaskCubit>().hideDefaultTaskForDate(
                  task.defaultTaskId ?? task.id,
                  _date,
                  taskId: task.id,
                );
                Navigator.pop(context);
              },
              child: const Text('Only Today'),
            ),
            TextButton(
              onPressed: () {
                context.read<TaskCubit>().deleteDefaultTaskEntirely(
                  task.defaultTaskId ?? task.id,
                  taskId: task.id,
                );
                Navigator.pop(context);
              },
              child: const Text(
                'Entirely',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ] else
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

  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today);
  }

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return "Today";
    }

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}";
  }
}
