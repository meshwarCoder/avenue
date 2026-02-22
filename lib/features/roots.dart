import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avenue/features/schdules/presentation/views/schedule_view.dart';
import 'package:avenue/features/weeks/presentation/cubit/weekly_cubit.dart';
import 'package:avenue/features/weeks/presentation/pages/weekly_calendar_page.dart';
import 'package:avenue/features/ai/presentation/widgets/animated_ai_button.dart';
import 'package:avenue/features/settings/presentation/views/settings_view.dart';
import 'package:go_router/go_router.dart';
import '../core/di/injection_container.dart';
import 'package:avenue/features/schdules/presentation/views/add_task_view.dart';
import '../core/widgets/animated_task_button.dart';
import '../core/widgets/avenue_nav_bar.dart';

import 'package:avenue/core/services/local_notification_service.dart';

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> with SingleTickerProviderStateMixin {
  int _index = 0; // Default to Today (HomeView)
  bool _isNavVisible = true;

  @override
  void initState() {
    super.initState();
    // Request notification permission on Android 13+
    sl<LocalNotificationService>().requestPermissionIfNeeded();
  }

  late final PageController _pageController = PageController(
    initialPage: _index,
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final items = [
    AvenueNavBarItem(icon: Icons.calendar_today_rounded, label: "Today"),
    AvenueNavBarItem(icon: Icons.calendar_view_week_rounded, label: "Week"),
    AvenueNavBarItem(icon: Icons.settings_rounded, label: "Settings"),
  ];

  late final List<Widget> pages = [
    const HomeView(),
    BlocProvider(
      create: (context) => sl<WeeklyCubit>(),
      child: const WeeklyCalendarPage(),
    ),
    const SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            if (_isNavVisible) setState(() => _isNavVisible = false);
          } else if (notification.direction == ScrollDirection.forward) {
            if (!_isNavVisible) setState(() => _isNavVisible = true);
          }
          return false;
        },
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _index = index);
              },
              children: pages,
            ),

            // AI Chat Button (Middle)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              right: _isNavVisible ? 0 : -120,
              bottom: 186, // 110 (task) + 60 (task height) + 16 (spacing)
              child: AnimatedAIChatButton(
                visible: true,
                onTap: () => context.push('/ai-chat'),
              ),
            ),

            // New Task Button (Bottom)
            AnimatedPositioned(
              duration: _isNavVisible
                  ? const Duration(milliseconds: 600) // Slower slide in
                  : const Duration(milliseconds: 250), // Faster slide out
              curve: Curves.easeOutCubic,
              right: _isNavVisible ? 0 : -120,
              bottom: 110,
              child: AnimatedTaskButton(
                visible: true,
                onTap: () => _showAddTask(context),
              ),
            ),

            // Navigation Bar with Slide Down Animation
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: _isNavVisible ? 0 : -200, // Slide down out of screen
              child: AvenueNavBar(
                currentIndex: _index,
                items: items,
                onTap: (i) {
                  _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTaskView(),
    );
  }
}
