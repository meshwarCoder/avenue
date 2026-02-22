import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static const String _keyWeekStartDay = 'week_start_day';
  static const String _keyIs24HourFormat = 'is_24_hour_format';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyNotificationsEnabled = 'notifications_enabled';

  // Default: Monday (1)
  int getWeekStartDay() {
    return _prefs.getInt(_keyWeekStartDay) ?? 1; // DateTime.monday
  }

  Future<void> setWeekStartDay(int day) async {
    await _prefs.setInt(_keyWeekStartDay, day);
  }

  // Default: 12-hour format (false)
  bool getIs24HourFormat() {
    return _prefs.getBool(_keyIs24HourFormat) ?? false;
  }

  Future<void> setIs24HourFormat(bool is24Hour) async {
    await _prefs.setBool(_keyIs24HourFormat, is24Hour);
  }

  // Default: true
  bool getNotificationsEnabled() {
    return _prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  // Default: system
  ThemeMode getThemeMode() {
    final themeString = _prefs.getString(_keyThemeMode);
    if (themeString == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (e) => e.name == themeString,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_keyThemeMode, mode.name);
  }
}
