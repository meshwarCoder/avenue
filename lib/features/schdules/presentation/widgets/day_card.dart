import 'package:flutter/material.dart';

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
