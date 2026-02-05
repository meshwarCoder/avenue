import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repo/auth_repository.dart';
import 'auth_state.dart';
import '../../../../core/services/device_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/utils/observability.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;
  final DeviceService deviceService;
  final DatabaseService databaseService;

  AuthCubit({
    required this.repository,
    required this.deviceService,
    required this.databaseService,
  }) : super(AuthInitial()) {
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    if (repository.isAuthenticated) {
      _handleAuthSuccess();
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _handleAuthSuccess() async {
    // Sync profile and device info on every auth success (app start or login)
    try {
      // 0. Preliminary check to avoid null pointer crashes
      if (!repository.isAuthenticated) {
        emit(Unauthenticated());
        return;
      }

      final userId = repository.currentUserId;
      if (userId == null) {
        emit(Unauthenticated());
        return;
      }

      final deviceId = await deviceService.getDeviceId();
      final timezoneOffset = DateTime.now().timeZoneOffset.inHours;

      // 1. Update Profile (Timezone)
      final profileResult = await repository.createOrUpdateProfile(
        timezoneOffset,
      );
      profileResult.fold(
        (failure) => AvenueLogger.log(
          event: 'AUTH_PROFILE_FAILED',
          level: LoggerLevel.WARN,
          layer: LoggerLayer.STATE,
          payload: failure.message,
        ),
        (_) => AvenueLogger.log(
          event: 'AUTH_PROFILE_SUCCESS',
          layer: LoggerLayer.STATE,
        ),
      );

      // 2. Track Device (Add if new)
      final deviceExistsResult = await repository.deviceExists(deviceId);

      bool deviceExists = false;
      deviceExistsResult.fold(
        (failure) => AvenueLogger.log(
          event: 'AUTH_DEVICE_CHECK_FAILED',
          level: LoggerLevel.WARN,
          layer: LoggerLayer.STATE,
          payload: failure.message,
        ),
        (exists) => deviceExists = exists,
      );

      if (!deviceExists) {
        final deviceResult = await repository.createDeviceRecord(deviceId);
        deviceResult.fold(
          (failure) => AvenueLogger.log(
            event: 'AUTH_DEVICE_CREATE_FAILED',
            level: LoggerLevel.WARN,
            layer: LoggerLayer.STATE,
            payload: failure.message,
          ),
          (_) => AvenueLogger.log(
            event: 'AUTH_DEVICE_SUCCESS',
            layer: LoggerLayer.STATE,
          ),
        );
      } else {
        await repository.updateDeviceSyncTimestamp(deviceId);
      }

      emit(Authenticated(userId));
    } catch (e) {
      AvenueLogger.log(
        event: 'AUTH_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.STATE,
        payload: e.toString(),
      );
      // If we crashed but we AR authenticated, we should still emit Authenticated
      // but safely.
      final userId = repository.currentUserId;
      if (userId != null) {
        emit(Authenticated(userId));
      } else {
        emit(Unauthenticated());
      }
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    emit(AuthLoading());
    final result = await repository.signUp(email: email, password: password);
    result.fold((failure) => emit(AuthError(failure.message)), (_) {
      // Checking if we are immediately authenticated (some setups auto-login)
      if (repository.isAuthenticated) {
        _handleAuthSuccess();
      } else {
        // If not authenticated, it likely means email confirmation is required
        emit(
          const AuthError(
            'Account created! Please check your email to confirm your account.',
          ),
        );
      }
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(AuthLoading());
    final result = await repository.signIn(email: email, password: password);
    result.fold((failure) => emit(AuthError(failure.message)), (_) {
      if (repository.isAuthenticated) {
        _handleAuthSuccess();
      } else {
        emit(
          const AuthError(
            'Login failed. Please confirm your email if you haven\'t already.',
          ),
        );
      }
    });
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    final result = await repository.signOut();
    result.fold((failure) => emit(AuthError(failure.message)), (_) async {
      await databaseService.clearUserData();
      emit(Unauthenticated());
    });
  }
}
