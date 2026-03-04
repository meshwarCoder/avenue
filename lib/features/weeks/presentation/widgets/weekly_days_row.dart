import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

import 'zoom_knob.dart';

class WeeklyDaysRow extends StatelessWidget {
  final List<DateTime> days;
  final DateTime currentMonday;
  final double currentZoom;
  final ValueChanged<double> onZoomChanged;
  final Function(DateTime) onDayTapped;

  const WeeklyDaysRow({
    super.key,
    required this.days,
    required this.currentMonday,
    required this.currentZoom,
    required this.onZoomChanged,
    required this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

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
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 5),
              child: Center(
                child: DragZoomRing(
                  value: currentZoom,
                  initialValue: 60.0,
                  minValue: 20.0,
                  maxValue: 150.0,
                  onChanged: onZoomChanged,
                ),
              ),
            ),
          ),
          Expanded(
            flex: days.length,
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
                          _getDayName(context, date.weekday),
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

  String _getDayName(BuildContext context, int weekday) {
    final l10n = AppLocalizations.of(context)!;
    final dayNames = [
      l10n.mon,
      l10n.tue,
      l10n.wed,
      l10n.thu,
      l10n.fri,
      l10n.sat,
      l10n.sun,
    ];
    return dayNames[weekday - 1];
  }
}
