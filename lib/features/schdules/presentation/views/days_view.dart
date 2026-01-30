import 'package:flutter/material.dart';
import 'package:line/features/schdules/presentation/views/schedule_view.dart';
import 'package:line/features/schdules/presentation/views/add_task_view.dart';
import 'package:line/features/schdules/presentation/views/future_tasks_view.dart';
import 'package:line/features/schdules/presentation/views/past_tasks_view.dart';
import 'package:go_router/go_router.dart';
import 'package:line/core/utils/routes.dart';

class DaysView extends StatelessWidget {
  const DaysView({super.key});

  @override
  Widget build(BuildContext context) {
    // Key to anchor the "Today" sliver
    const Key centerKey = ValueKey('today-sliver');

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text(
              "Days",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            Text(
              "Scroll down for future, up for past",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF004D61)),
            onPressed: () {
              context.push(AppRoutes.aiChat);
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              // Initial scroll handled by CustomScrollView center architecture
            },
          ),
        ],
      ),
      body: CustomScrollView(
        center: centerKey,
        slivers: [
          // 1. PAST DAYS (Top/Upwards)
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              // Determine item count: 7 days + 1 button
              final itemCount = 8;
              if (index >= itemCount) return null;

              // Index 0 = Yesterday (closest to center)
              // Index 6 = 7 days ago
              // Index 7 = Past Tasks Button (furthest top)

              if (index == itemCount - 1) {
                // The "View Past Tasks" button (at the very top of content)
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 16,
                    top: 40,
                    left: 20,
                    right: 20,
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PastTasksView(initialOffset: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history, color: Colors.blueGrey),
                    label: const Text("View Older Weeks"),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blueGrey.withOpacity(0.1),
                      foregroundColor: Colors.blueGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                );
              }

              // Days (Yesterday backwards)
              final dayOffset = index + 1; // 1 to 7
              final day = normalizedToday.subtract(Duration(days: dayOffset));

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DayCard(
                  day: day,
                  isToday: false,
                  isPast: true,
                  isFuture: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeView(selectedDate: day),
                      ),
                    );
                  },
                ),
              );
            }),
          ),

          // 2. TODAY & FUTURE DAYS (Bottom/Downwards)
          SliverList(
            key: centerKey,
            delegate: SliverChildBuilderDelegate((context, index) {
              // Determine item count: Today + 6 future days + Future Button
              // Total 1 + 6 = 7 days visible initially + button = 8 items
              final itemCount = 8;
              if (index >= itemCount) return null;

              if (index == itemCount - 1) {
                // Future Tasks Button
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 80,
                    left: 20,
                    right: 20,
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FutureTasksView(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text("View Further Future"),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF004D61),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );
              }

              final day = normalizedToday.add(Duration(days: index));
              final isToday = index == 0;
              final isFuture = index > 0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DayCard(
                  day: day,
                  isToday: isToday,
                  isPast: false,
                  isFuture: isFuture,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeView(selectedDate: day),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddTaskView(),
          );
        },
        backgroundColor: const Color(0xFF004D61),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class DayCard extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isPast;
  final bool isFuture;
  final VoidCallback onTap;

  const DayCard({
    super.key,
    required this.day,
    required this.isToday,
    required this.isPast,
    required this.isFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.transparent;
    Color textColor;
    Color subTextColor;
    List<Color>? gradient;

    if (isToday) {
      gradient = [
        const Color(0xFF1A237E), // Dark Blue
        const Color(0xFF006064), // Dark Teal
      ];
      textColor = Colors.white;
      subTextColor = Colors.white70;
    } else if (isPast) {
      backgroundColor = const Color(0xFFF0F2F5);
      textColor = Colors.grey[600]!;
      subTextColor = Colors.grey[500]!;
    } else {
      backgroundColor = Colors.white;
      textColor = const Color(0xFF2D3142);
      subTextColor = Colors.grey[600]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient != null
            ? LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: const Color(0xFF1A237E).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday ? "Today" : _getDayName(day.weekday),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_getMonthName(day.month)} ${day.day}",
                        style: TextStyle(fontSize: 16, color: subTextColor),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 18, color: subTextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}
