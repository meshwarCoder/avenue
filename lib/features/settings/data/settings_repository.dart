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

  String getAiModel() {
    return _cacheHelper.getData(key: _keyAiModelOverride) as String? ??
        'google/gemini-3-pro-preview';
  }

  Future<void> setAiModel(String model) async {
    await _cacheHelper.setData(key: _keyAiModelOverride, value: model);
    // Sync with Supabase app_settings for Edge Function
    await _supabase.from('app_settings').upsert({
      'key': 'openrouter_model',
      'value': model,
    });
  }

  Future<void> setAiApiKey(String key) async {
    if (key.isNotEmpty) {
      // Sync with Supabase app_settings for Edge Function (Write-Only)
      await _supabase.from('app_settings').upsert({
        'key': 'openrouter_api_key',
        'value': key,
      });
    }
  }

  /// Fetches AI configuration from Supabase and updates the local cache.
  /// Fetches AI configuration from Supabase and updates the local cache.
  /// Note: Only fetches the model; the API Key is sensitive and stays on the server.
  Future<void> fetchServerAiSettings() async {
    try {
      final res = await _supabase
          .from('app_settings')
          .select('key, value')
          .eq('key', 'openrouter_model')
          .maybeSingle();

      if (res != null) {
        await _cacheHelper.setData(
          key: _keyAiModelOverride,
          value: res['value'],
        );
      }
    } catch (e) {
      // Fail silently, use local cache as backup
    }
  }
}
