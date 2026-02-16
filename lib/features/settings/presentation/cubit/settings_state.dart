import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final int weekStartDay;
  final bool is24HourFormat;

  const SettingsState({
    this.weekStartDay = 1, // Default Monday
    this.is24HourFormat = false, // Default 12h
  });

  SettingsState copyWith({int? weekStartDay, bool? is24HourFormat}) {
    return SettingsState(
      weekStartDay: weekStartDay ?? this.weekStartDay,
      is24HourFormat: is24HourFormat ?? this.is24HourFormat,
    );
  }

  @override
  List<Object> get props => [weekStartDay, is24HourFormat];
}
