import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final int weekStartDay;
  final bool is24HourFormat;
  final bool notificationsEnabled;

  const SettingsState({
    this.weekStartDay = 1, // Default Monday
    this.is24HourFormat = false, // Default 12h
    this.notificationsEnabled = true, // Default enabled
  });

  SettingsState copyWith({
    int? weekStartDay,
    bool? is24HourFormat,
    bool? notificationsEnabled,
  }) {
    return SettingsState(
      weekStartDay: weekStartDay ?? this.weekStartDay,
      is24HourFormat: is24HourFormat ?? this.is24HourFormat,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object> get props => [
    weekStartDay,
    is24HourFormat,
    notificationsEnabled,
  ];
}
