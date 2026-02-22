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

  AuthCubit({
    required this.repository,
    required this.deviceService,
    required this.databaseService,
  }) : super(AuthInitial()) {
    _initAuthListener();
    _checkAuthStatus();
  }

  void _initAuthListener() {
    _authSubscription = repository.authEvents.listen(
      (event) {
        if (isClosed) return;
        if (event == AuthEvent.signedIn) {
          _handleAuthSuccess();
        } else if (event == AuthEvent.signedOut) {
          emit(Unauthenticated());
        }
      },
      onError: (error) {
        if (isClosed) return;
        AvenueLogger.log(
          event: 'AUTH_STREAM_ERROR',
          level: LoggerLevel.WARN,
          layer: LoggerLayer.STATE,
          payload: error.toString(),
        );
        if (!repository.isAuthenticated) {
          emit(Unauthenticated());
        }
      },
    );
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

    String? userId;
    try {
      if (!repository.isAuthenticated) {
        emit(Unauthenticated());
        return;
      }

      userId = repository.currentUserId;
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

      if (isClosed) return;
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
    if (isClosed) return;
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
    if (isClosed) return;
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
    emit(const AuthLoading(source: AuthLoadingSource.google));
    final result = await repository.signInWithGoogle();
    if (isClosed) return;
    result.fold((failure) => emit(AuthError(failure.message)), (_) {
      // Success means the browser flow started.
      // We rely on _authSubscription.
      // Fallback: If no auth event received in 5s, reset to Unauthenticated
      Future.delayed(const Duration(seconds: 5), () {
        if (isClosed) return;
        if (state is AuthLoading && !repository.isAuthenticated) {
          emit(Unauthenticated());
        }
      });
    });
  }

  Future<void> signInWithFacebook() async {
    emit(const AuthLoading(source: AuthLoadingSource.facebook));
    final result = await repository.signInWithFacebook();
    if (isClosed) return;
    result.fold((failure) => emit(AuthError(failure.message)), (_) {
      // Success means the browser flow started.
      // We rely on _authSubscription.
      // Fallback: If no auth event received in 5s, reset to Unauthenticated
      Future.delayed(const Duration(seconds: 5), () {
        if (isClosed) return;
        if (state is AuthLoading && !repository.isAuthenticated) {
          emit(Unauthenticated());
        }
      });
    });
  }

  Future<void> signOut() async {
    emit(const AuthLoading(source: AuthLoadingSource.other));
    final result = await repository.signOut();
    if (isClosed) return;
    result.fold((failure) => emit(AuthError(failure.message)), (_) async {
      await databaseService.clearUserData();
      // Unauthenticated state will be emitted by listener
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
