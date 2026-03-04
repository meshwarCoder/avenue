import 'package:flutter/material.dart';
import 'package:avenue/l10n/app_localizations.dart';

class Validation {
  static String? validateTitle(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.errTaskTitle;
    }
    return null;
  }

  static String? validateStartTime(BuildContext context, TimeOfDay? time) {
    if (time == null) {
      return AppLocalizations.of(context)!.errStartTime;
    }
    return null;
  }

  static String? validateEndTime(BuildContext context, TimeOfDay? time) {
    if (time == null) {
      return AppLocalizations.of(context)!.errEndTime;
    }
    return null;
  }

  static String? validateTimeRange(
    BuildContext context,
    TimeOfDay? start,
    TimeOfDay? end,
  ) {
    if (start == null || end == null) return null;

    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (endMinutes <= startMinutes) {
      return AppLocalizations.of(context)!.errTimeRange;
    }
    return null;
  }

  static String? validateEmail(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.errEmailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return AppLocalizations.of(context)!.errEmailInvalid;
    }
    return null;
  }

  static String? validatePassword(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.errPasswordRequired;
    }
    if (value.length < 6) {
      return AppLocalizations.of(context)!.errPasswordShort;
    }
    return null;
  }

  static String? validateConfirmPassword(
    BuildContext context,
    String? value,
    String password,
  ) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.errConfirmPasswordRequired;
    }
    if (value != password) {
      return AppLocalizations.of(context)!.errPasswordsMismatch;
    }
    return null;
  }
}
