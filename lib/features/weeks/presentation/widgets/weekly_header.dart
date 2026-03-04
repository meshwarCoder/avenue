import 'package:flutter/material.dart';
import '../../../../../core/utils/calendar_utils.dart';
import '../../../../l10n/app_localizations.dart';

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
              _getMonthYearRange(context, currentMonday, curSunday),
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
        tooltip: AppLocalizations.of(context)!.backToToday,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }

  String _getMonthYearRange(
    BuildContext context,
    DateTime start,
    DateTime end,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final months = [
      l10n.january,
      l10n.february,
      l10n.march,
      l10n.april,
      l10n.mayLong,
      l10n.june,
      l10n.july,
      l10n.august,
      l10n.september,
      l10n.october,
      l10n.november,
      l10n.december,
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
