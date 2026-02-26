import 'package:avenue/core/di/injection_container.dart';
import 'package:avenue/core/services/local_notification_service.dart';
import 'package:avenue/core/services/open_router_client.dart';
import 'package:avenue/core/services/embedding_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/settings_repository.dart';
import 'settings_state.dart';

import 'package:avenue/features/auth/domain/repo/auth_repository.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;
  final AuthRepository _authRepository;

  SettingsCubit(this._repository, this._authRepository)
    : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final weekStartDay = _repository.getWeekStartDay();
    final is24HourFormat = _repository.getIs24HourFormat();
    final notificationsEnabled = _repository.getNotificationsEnabled();
    final aiModel = _repository.getAiModel();
    final aiApiKey = _repository.getAiApiKey();

    // Apply cached model override to client immediately
    sl<OpenRouterClient>().model = aiModel;
    sl<OpenRouterClient>().apiKey =
        aiApiKey ?? dotenv.env['OPENROUTER_API_KEY'] ?? '';
    sl<EmbeddingService>().apiKey =
        aiApiKey ?? dotenv.env['OPENROUTER_API_KEY'] ?? '';

    emit(
      state.copyWith(
        weekStartDay: weekStartDay,
        is24HourFormat: is24HourFormat,
        notificationsEnabled: notificationsEnabled,
        aiModel: aiModel,
        aiApiKey: aiApiKey,
      ),
    );

    // Fetch role from Supabase (async, update UI when ready)
    final roleResult = await _authRepository.fetchUserRole();
    if (isClosed) return;
    roleResult.fold(
      (_) => null, // On failure, keep isDev = false
      (role) => emit(state.copyWith(isDev: role == 'dev')),
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

  Future<void> updateAiModel(String model) async {
    await _repository.setAiModel(model);
    sl<OpenRouterClient>().model = model;
    if (isClosed) return;
    emit(state.copyWith(aiModel: model));
  }

  Future<void> updateAiApiKey(String? key) async {
    await _repository.setAiApiKey(key);
    sl<OpenRouterClient>().apiKey =
        key ?? dotenv.env['OPENROUTER_API_KEY'] ?? '';
    sl<EmbeddingService>().apiKey =
        key ?? dotenv.env['OPENROUTER_API_KEY'] ?? '';
    if (isClosed) return;
    emit(state.copyWith(aiApiKey: key));
  }

  Future<void> submitFeedback({
    required String type,
    required String content,
  }) async {
    emit(state.copyWith(feedbackStatus: FeedbackStatus.loading));
    try {
      final userId = _authRepository.currentUserId;
      final email = _authRepository.currentUserEmail;

      await _repository.submitFeedback(
        type: type,
        content: content,
        userId: userId,
        email: email,
      );

      if (isClosed) return;
      emit(state.copyWith(feedbackStatus: FeedbackStatus.success));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          feedbackStatus: FeedbackStatus.failure,
          feedbackErrorMessage: e.toString(),
        ),
      );
    }
  }

  void resetFeedbackStatus() {
    emit(
      state.copyWith(
        feedbackStatus: FeedbackStatus.initial,
        feedbackErrorMessage: null,
      ),
    );
  }
}
