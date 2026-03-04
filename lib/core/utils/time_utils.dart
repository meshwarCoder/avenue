import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeUtils {
  static String formatTime(
    TimeOfDay time,
    bool is24HourFormat, {
    String? locale,
  }) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (is24HourFormat) {
      return DateFormat('HH:mm', locale).format(dt);
    } else {
      return DateFormat.jm(locale).format(dt);
    }
  }

  static String formatDateTime(
    DateTime date,
    bool is24HourFormat, {
    String? locale,
  }) {
    if (is24HourFormat) {
      return DateFormat('HH:mm', locale).format(date);
    } else {
      return DateFormat.jm(locale).format(date);
    }
  }
}
