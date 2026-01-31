import 'package:flutter/material.dart';

class WeeklyHeader extends StatelessWidget {
  final DateTime currentMonday;
  final DateTime? firstTaskDate;
  final DateTime? lastTaskDate;
  final Function(DateTime) onWeekChanged;

  const WeeklyHeader({
    super.key,
    required this.currentMonday,
    required this.onWeekChanged,
    this.firstTaskDate,
    this.lastTaskDate,
  });

  // Color Palette matches WeeklyCalendarView
  static const Color _textColor = Colors.white;
  static const Color _secondaryTextColor = Colors.white70;

  @override
  Widget build(BuildContext context) {
    final curSunday = currentMonday.add(const Duration(days: 6));
    final canGoPrev =
        firstTaskDate == null ||
        currentMonday
            .subtract(const Duration(days: 7))
            .isAfter(firstTaskDate!.subtract(const Duration(days: 1)));
    final canGoNext =
        lastTaskDate == null ||
        curSunday
            .add(const Duration(days: 1))
            .isBefore(lastTaskDate!.add(const Duration(days: 1)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                _getMonthYearRange(currentMonday, curSunday),
                style: const TextStyle(
                  color: _textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: canGoPrev
                      ? _textColor
                      : _secondaryTextColor.withOpacity(0.3),
                ),
                onPressed: canGoPrev
                    ? () => onWeekChanged(
                        currentMonday.subtract(const Duration(days: 7)),
                      )
                    : null,
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: canGoNext
                      ? _textColor
                      : _secondaryTextColor.withOpacity(0.3),
                ),
                onPressed: canGoNext
                    ? () => onWeekChanged(
                        currentMonday.add(const Duration(days: 7)),
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthYearRange(DateTime start, DateTime end) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (start.month == end.month) {
      return "${months[start.month - 1]} ${start.year}";
    } else if (start.year == end.year) {
      return "${months[start.month - 1]} - ${months[end.month - 1]} ${start.year}";
    } else {
      return "${months[start.month - 1]} ${start.year} - ${months[end.month - 1]} ${end.year}";
    }
  }
}
