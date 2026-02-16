import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  SettingsCubit(this._repository) : super(const SettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final weekStartDay = _repository.getWeekStartDay();
    final is24HourFormat = _repository.getIs24HourFormat();
    emit(
      state.copyWith(
        weekStartDay: weekStartDay,
        is24HourFormat: is24HourFormat,
      ),
    );
  }

  Future<void> updateWeekStartDay(int day) async {
    await _repository.setWeekStartDay(day);
    emit(state.copyWith(weekStartDay: day));
  }

  Future<void> updateTimeFormat(bool is24Hour) async {
    await _repository.setIs24HourFormat(is24Hour);
    emit(state.copyWith(is24HourFormat: is24Hour));
  }
}
