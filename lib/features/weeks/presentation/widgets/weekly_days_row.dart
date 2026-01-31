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

  // Color Palette matches WeeklyCalendarView
  static const Color _textColor = Colors.white;
  static const Color _secondaryTextColor = Colors.white70;
  static const Color _gridLineColor = Colors.white12;
  static const Color _currentDayIndicatorColor = Color(0xFF02D7FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withOpacity(0.8),
        border: const Border(
          bottom: BorderSide(color: _gridLineColor, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
                                ? _currentDayIndicatorColor
                                : _secondaryTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: isToday
                              ? const BoxDecoration(
                                  color: _currentDayIndicatorColor,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: isToday ? Colors.black : _textColor,
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
