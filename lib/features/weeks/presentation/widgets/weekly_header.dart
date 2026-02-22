import 'package:flutter/material.dart';
import '../../../../../core/utils/calendar_utils.dart';

class WeeklyHeader extends StatelessWidget {
  final DateTime currentMonday;
  final DateTime? firstTaskDate;
  final DateTime? lastTaskDate;
  final Function(DateTime) onWeekChanged;
  final int weekStartDay;

  const WeeklyHeader({
    super.key,
    required this.currentMonday,
    required this.onWeekChanged,
    required this.weekStartDay,
    this.firstTaskDate,
    this.lastTaskDate,
  });

  @override
  Widget build(BuildContext context) {
    final curSunday = currentMonday.add(const Duration(days: 6));
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final today = CalendarUtils.getStartOfWeek(
      DateTime.now(),
      startOfWeek: weekStartDay,
    );

    final isPast = currentMonday.isBefore(today);
    final isFuture = currentMonday.isAfter(today);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          // Month Range
          Expanded(
            child: Text(
              _getMonthYearRange(currentMonday, curSunday),
              style: TextStyle(
                color: onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Navigation Row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Future Today Button (Left of arrows) — zero-width when hidden
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: isFuture
                    ? _buildTodayButton(context, today)
                    : const SizedBox.shrink(),
              ),
              if (isFuture) const SizedBox(width: 4),

              // Arrows Container
              Container(
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: onSurface,
                      ),
                      onPressed: () => onWeekChanged(
                        currentMonday.subtract(const Duration(days: 7)),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: theme.dividerColor.withOpacity(0.1),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: onSurface,
                      ),
                      onPressed: () => onWeekChanged(
                        currentMonday.add(const Duration(days: 7)),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

              if (isPast) const SizedBox(width: 4),
              // Past Today Button (Right of arrows) — zero-width when hidden
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: isPast
                    ? _buildTodayButton(context, today)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayButton(BuildContext context, DateTime today) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(Icons.today, size: 18, color: theme.colorScheme.primary),
        onPressed: () => onWeekChanged(today),
        tooltip: 'Back to Today',
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
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
