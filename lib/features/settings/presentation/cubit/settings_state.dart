import 'package:equatable/equatable.dart';

enum FeedbackStatus { initial, loading, success, failure }

class SettingsState extends Equatable {
  final int weekStartDay;
  final bool is24HourFormat;
  final bool notificationsEnabled;
  final FeedbackStatus feedbackStatus;
  final String? feedbackErrorMessage;
  final bool isDev;
  final String aiModel;
  final String? aiApiKey;

  const SettingsState({
    this.weekStartDay = 1, // Default Monday
    this.is24HourFormat = false, // Default 12h
    this.notificationsEnabled = true, // Default enabled
    this.feedbackStatus = FeedbackStatus.initial,
    this.feedbackErrorMessage,
    this.isDev = false,
    this.aiModel = 'google/gemini-3-pro-preview',
    this.aiApiKey,
  });

  SettingsState copyWith({
    int? weekStartDay,
    bool? is24HourFormat,
    bool? notificationsEnabled,
    FeedbackStatus? feedbackStatus,
    String? feedbackErrorMessage,
    bool? isDev,
    String? aiModel,
    String? aiApiKey,
  }) {
    return SettingsState(
      weekStartDay: weekStartDay ?? this.weekStartDay,
      is24HourFormat: is24HourFormat ?? this.is24HourFormat,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      feedbackStatus: feedbackStatus ?? this.feedbackStatus,
      feedbackErrorMessage: feedbackErrorMessage ?? this.feedbackErrorMessage,
      isDev: isDev ?? this.isDev,
      aiModel: aiModel ?? this.aiModel,
      aiApiKey: aiApiKey ?? this.aiApiKey,
    );
  }

  @override
  List<Object?> get props => [
    weekStartDay,
    is24HourFormat,
    notificationsEnabled,
    feedbackStatus,
    feedbackErrorMessage,
    isDev,
    aiModel,
    aiApiKey,
  ];
}
