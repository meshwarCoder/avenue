import 'package:intl/intl.dart';

class CalendarUtils {
  /// Returns the Monday of the week for the given [date].
  /// Week starts on Monday (1).
  static DateTime getStartOfWeek(DateTime date) {
    return normalize(date).subtract(Duration(days: date.weekday - 1));
  }

  /// Returns the date at 00:00:00 local time.
  static DateTime normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime getNextWeek(DateTime currentMonday) {
    return currentMonday.add(const Duration(days: 7));
  }

  static DateTime getPrevWeek(DateTime currentMonday) {
    return currentMonday.subtract(const Duration(days: 7));
  }

  /// Returns true if [date]'s week is strictly before [bound]'s week.
  static bool isBeforeWeek(DateTime date, DateTime bound) {
    final startOfDateWeek = getStartOfWeek(date);
    final startOfBoundWeek = getStartOfWeek(bound);
    return startOfDateWeek.isBefore(startOfBoundWeek);
  }

  /// Returns true if [date]'s week is strictly after [bound]'s week.
  static bool isAfterWeek(DateTime date, DateTime bound) {
    final startOfDateWeek = getStartOfWeek(date);
    final startOfBoundWeek = getStartOfWeek(bound);
    return startOfDateWeek.isAfter(startOfBoundWeek);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatRange(DateTime start) {
    final end = start.add(const Duration(days: 6));
    if (start.month == end.month) {
      return "${start.day} - ${end.day} ${DateFormat('MMM').format(start)}";
    }
    return "${start.day} ${DateFormat('MMM').format(start)} - ${end.day} ${DateFormat('MMM').format(end)}";
  }
}
