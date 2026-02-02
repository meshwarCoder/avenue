import 'package:flutter/material.dart';

class WeeklyDaysRow extends StatelessWidget {
  final List<DateTime> days;
  final DateTime currentMonday;
  final Function(DateTime) onDayTapped;

  const WeeklyDaysRow({
    super.key,
    required this.days,
    required this.currentMonday,
    required this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onBackground;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 60.0), // Spacer for time column
          Expanded(
            child: Row(
              children: days.map((date) {
                final isToday = _isSameDay(date, DateTime.now());
                return Expanded(
                  child: InkWell(
                    onTap: () => onDayTapped(date),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getDayName(date.weekday),
                          style: TextStyle(
                            color: isToday
                                ? theme.colorScheme.primary
                                : onSurface.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: isToday
                              ? BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: isToday ? Colors.white : onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  String _getDayName(int weekday) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return dayNames[weekday - 1];
  }
}
