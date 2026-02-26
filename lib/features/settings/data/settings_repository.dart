import 'package:avenue/core/helpers/cache_helper.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsRepository {
  final CacheHelper _cacheHelper;
  final SupabaseClient _supabase;

  SettingsRepository(this._cacheHelper, this._supabase);

  static const String _keyWeekStartDay = 'week_start_day';
  static const String _keyIs24HourFormat = 'is_24_hour_format';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyNotificationsEnabled = 'notifications_enabled';

  // Default: Monday (1)
  int getWeekStartDay() {
    return _cacheHelper.getData(key: _keyWeekStartDay) as int? ??
        1; // DateTime.monday
  }

  Future<void> setWeekStartDay(int day) async {
    await _cacheHelper.setData(key: _keyWeekStartDay, value: day);
  }

  // Default: 12-hour format (false)
  bool getIs24HourFormat() {
    return _cacheHelper.getData(key: _keyIs24HourFormat) as bool? ?? false;
  }

  Future<void> setIs24HourFormat(bool is24Hour) async {
    await _cacheHelper.setData(key: _keyIs24HourFormat, value: is24Hour);
  }

  // Default: true
  bool getNotificationsEnabled() {
    return _cacheHelper.getData(key: _keyNotificationsEnabled) as bool? ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _cacheHelper.setData(key: _keyNotificationsEnabled, value: enabled);
  }

  // Default: system
  ThemeMode getThemeMode() {
    final themeString = _cacheHelper.getData(key: _keyThemeMode) as String?;
    if (themeString == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (e) => e.name == themeString,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _cacheHelper.setData(key: _keyThemeMode, value: mode.name);
  }

  Future<void> submitFeedback({
    required String type,
    required String content,
    required String? userId,
    required String? email,
  }) async {
    await _supabase.from('user_feedback').insert({
      'type': type,
      'content': content,
      'user_id': userId,
      'email': email,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static const String _keyAiModelOverride = 'ai_model_override';
  static const String _keyAiApiKeyOverride = 'ai_api_key_override';

  String getAiModel() {
    return _cacheHelper.getData(key: _keyAiModelOverride) as String? ??
        'google/gemini-3-pro-preview';
  }

  Future<void> setAiModel(String model) async {
    await _cacheHelper.setData(key: _keyAiModelOverride, value: model);
  }

  String? getAiApiKey() {
    return _cacheHelper.getData(key: _keyAiApiKeyOverride) as String?;
  }

  Future<void> setAiApiKey(String? key) async {
    if (key == null || key.isEmpty) {
      await _cacheHelper.removeData(key: _keyAiApiKeyOverride);
    } else {
      await _cacheHelper.setData(key: _keyAiApiKeyOverride, value: key);
    }
  }
}
