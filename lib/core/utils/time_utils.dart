import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeUtils {
  static String formatTime(TimeOfDay time, bool is24HourFormat) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (is24HourFormat) {
      return DateFormat('HH:mm').format(dt);
    } else {
      return DateFormat('h:mm a').format(dt);
    }
  }

  static String formatDateTime(DateTime date, bool is24HourFormat) {
    if (is24HourFormat) {
      return DateFormat('HH:mm').format(date);
    } else {
      return DateFormat('h:mm a').format(date);
    }
  }
}
