import 'dart:async';
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

  StreamSubscription? _authSubscription;
  bool _isClosed = false;

  AuthCubit({
    required this.repository,
    required this.deviceService,
    required this.databaseService,
  }) : super(AuthInitial()) {
    _initAuthListener();
    _checkAuthStatus();
  }

  void _initAuthListener() {
    _authSubscription = repository.authEvents.listen((event) {
      if (_isClosed) return;
      if (event == AuthEvent.signedIn) {
        _handleAuthSuccess();
      } else if (event == AuthEvent.signedOut) {
        emit(Unauthenticated());
      }
    });
  }

  void _checkAuthStatus() {
    // Initial check on app start
    if (repository.isAuthenticated) {
      _handleAuthSuccess();
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _handleAuthSuccess() async {
    // Sync profile and device info on every auth success (app start or login)
    if (state is Authenticated) return;

    try {
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
      // Success! We rely on _authSubscription to handle the rest.
      // However, if email confirmation is required, the listener might NOT fire 'signedIn' yet.
      if (!repository.isAuthenticated) {
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
      // Success! We rely on _authSubscription.
      if (!repository.isAuthenticated) {
        emit(
          const AuthError(
            'Login failed. Please confirm your email if you haven\'t already.',
          ),
        );
      }
    });
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading(isGoogle: true));
    final result = await repository.signInWithGoogle();
    result.fold((failure) => emit(AuthError(failure.message)), (_) {
      // Success means the browser flow started.
      // We rely on _authSubscription.
    });
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    final result = await repository.signOut();
    result.fold((failure) => emit(AuthError(failure.message)), (_) async {
      await databaseService.clearUserData();
      // Unauthenticated state will be emitted by listener
    });
  }

  @override
  Future<void> close() {
    _isClosed = true;
    _authSubscription?.cancel();
    return super.close();
  }
}
