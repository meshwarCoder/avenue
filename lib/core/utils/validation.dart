import 'package:flutter/material.dart';

class Validation {
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a task title';
    }
    return null;
  }

  static String? validateStartTime(TimeOfDay? time) {
    if (time == null) {
      return 'Please select a start time';
    }
    return null;
  }

  static String? validateEndTime(TimeOfDay? time) {
    if (time == null) {
      return 'Please select an end time';
    }
    return null;
  }

  static String? validateTimeRange(TimeOfDay? start, TimeOfDay? end) {
    if (start == null || end == null) return null;

    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (endMinutes <= startMinutes) {
      return 'End time must be after start time';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
