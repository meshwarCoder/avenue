import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/settings/data/settings_repository.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SettingsRepository _repository;

  ThemeCubit(this._repository) : super(_repository.getThemeMode());

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repository.setThemeMode(mode);
    emit(mode);
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  bool get isDark => state == ThemeMode.dark;
}
