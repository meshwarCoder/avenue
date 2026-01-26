import 'package:flutter/material.dart';
import 'package:line/features/schdules/presentation/views/days_view.dart';
import 'package:line/features/schdules/presentation/views/schedule_view.dart';
import 'package:liquid_glass_navbar/liquid_glass_navbar.dart';

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  int _index = 1; // Default to Today (HomeView)

  final items = [
    LiquidGlassNavItem(icon: Icons.calendar_month, label: "Days"),
    LiquidGlassNavItem(icon: Icons.access_time, label: "Today"),
    LiquidGlassNavItem(icon: Icons.bar_chart, label: "Stats"),
    LiquidGlassNavItem(icon: Icons.person, label: "Profile"),
  ];

  final pages = [
    const DaysView(),
    const HomeView(), // This will default to today in HomeView's initState
    const Center(child: Text("Stats")),
    const Center(child: Text("Profile")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for floating nav bars
      body: LiquidGlassNavBar(
        bubbleColor: Colors.white,
        backgroundColor: const Color(0xFF004D61), // Using app theme color
        backgroundOpacity: 0.9,
        itemColor: Colors.white,
        currentIndex: _index,
        onPageChanged: (i) => setState(() => _index = i),
        pages: pages,
        items: items,
        bottomPadding: 16,
        horizontalPadding: 16,
        bubbleBorderWidth: 1,
        bubbleOpacity: 0.4,
      ),
    );
  }
}
