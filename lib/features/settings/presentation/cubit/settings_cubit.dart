import 'package:avenue/core/di/injection_container.dart';
import 'package:avenue/core/services/local_notification_service.dart';
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
    final notificationsEnabled = _repository.getNotificationsEnabled();
    emit(
      state.copyWith(
        weekStartDay: weekStartDay,
        is24HourFormat: is24HourFormat,
        notificationsEnabled: notificationsEnabled,
      ),
    );
  }

  Future<void> updateWeekStartDay(int day) async {
    await _repository.setWeekStartDay(day);
    if (isClosed) return;
    emit(state.copyWith(weekStartDay: day));
  }

  Future<void> updateTimeFormat(bool is24Hour) async {
    await _repository.setIs24HourFormat(is24Hour);
    if (isClosed) return;
    emit(state.copyWith(is24HourFormat: is24Hour));
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    await _repository.setNotificationsEnabled(enabled);
    if (!enabled) {
      await sl<LocalNotificationService>().cancelAllNotifications();
    }
    if (isClosed) return;
    emit(state.copyWith(notificationsEnabled: enabled));
  }
}
