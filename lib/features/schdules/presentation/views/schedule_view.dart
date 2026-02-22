import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avenue/core/utils/constants.dart';
import 'package:avenue/features/schdules/presentation/views/timeline_view.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../widgets/task_card.dart';
import '../../../../core/widgets/avenue_loading.dart';
import '../../../../core/utils/calendar_utils.dart';
import '../../../../core/utils/observability.dart';
import '../widgets/task_detail_sheet.dart';

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
            : null,
        actions: const [],
      ),
      body: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, state) {
          final isSameDate =
              state.selectedDate != null &&
              CalendarUtils.normalize(state.selectedDate!) == _date;

          // loader if we are loading OR if the state belongs to a different date
          if (state is TaskLoading || !isSameDate) {
            return const Center(child: AvenueLoadingIndicator());
          } else if (state is TaskLoaded) {
            final tasks = state.tasks;
            final completedTasks = tasks.where((t) => t.completed).length;
            final pendingTasks = tasks.length - completedTasks;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildSummaryCard(
                        tasks.length,
                        completedTasks,
                        pendingTasks,
                      ),
                      _buildTimelineButton(),
                    ],
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
                            height: 125,
                            onTap: isPast
                                ? null
                                : () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => TaskDetailSheet(
                                        task: task,
                                        selectedDate: _date,
                                      ),
                                    );
                                  },
                            onLongPress: isPast
                                ? null
                                : () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => TaskDetailSheet(
                                        task: task,
                                        selectedDate: _date,
                                      ),
                                    );
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
    final progress = total == 0 ? 0.0 : completed / total;
    final percentage = (progress * 100).toInt();
    final isPast = _isPastDate(_date);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmall = screenWidth < 360;
        final padding = isSmall ? 16.0 : 28.0;
        final chartSize = isSmall ? 70.0 : 85.0;
        final spacing = isSmall ? 16.0 : 28.0;

        return Container(
          margin: EdgeInsets.fromLTRB(20, 10, 20, isSmall ? 10 : 20),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [theme.cardColor, theme.cardColor.withOpacity(0.8)]
                  : [Colors.white, Colors.white.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : theme.primaryColor).withOpacity(
                  0.08,
                ),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              // Circular Progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: chartSize,
                    height: chartSize,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: isSmall ? 8 : 10,
                      backgroundColor: (isDark
                          ? Colors.white10
                          : Colors.grey[100])!,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completed == total && total > 0
                            ? Colors.green
                            : theme.primaryColor,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$percentage%",
                        style: TextStyle(
                          fontSize: isSmall ? 16 : 20,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(width: spacing),
              // Text Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getMotivationalMessage(progress, total, isPast),
                      style: TextStyle(
                        fontSize: isSmall ? 15 : 17,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmall ? 8 : 12),
                    Wrap(
                      spacing: isSmall ? 8 : 12,
                      runSpacing: 4,
                      children: [
                        _buildStatusDot("Total", total, theme.primaryColor),
                        _buildStatusDot("Done", completed, Colors.green),
                        _buildStatusDot(
                          isPast ? "Missed" : "Left",
                          pending,
                          isPast ? Colors.redAccent : AppColors.salmonPink,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusDot(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            "$count $label",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getMotivationalMessage(double progress, int total, bool isPast) {
    if (total == 0)
      return isPast ? "No history here. 🌫️" : "No tasks today! ☕";

    if (isPast) {
      if (progress == 1.0) return "Perfect score! You nailed it! 🏆";
      if (progress >= 0.7) return "Excellent performance! 🌟";
      if (progress >= 0.4) return "Good effort on this day! 👍";
      if (progress > 0) return "Managed to get some done. 📈";
      return "This day passed by. ⌛";
    }

    if (progress == 0) return "Let's get started! 💪";
    if (progress < 0.4) return "Great start, keep it up! ✨";
    if (progress < 0.7) return "You're doing great! 🌟";
    if (progress < 1.0) return "Almost there! 🎯";
    return "All done! Enjoy your day 🎉";
  }

  Widget _buildTimelineButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark ? theme.colorScheme.primary : AppColors.deepPurple;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TimelineView(selectedDate: _date),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.15 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(isDark ? 0.3 : 0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timeline_rounded,
                color: isDark ? Colors.white : color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "View Timeline",
                  style: TextStyle(
                    color: isDark ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: (isDark ? Colors.white : color).withOpacity(0.5),
                size: 14,
              ),
            ],
          ),
        ),
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
