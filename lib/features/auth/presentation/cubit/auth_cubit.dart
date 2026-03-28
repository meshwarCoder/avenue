import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import '../../domain/repo/auth_repository.dart';
import 'auth_state.dart';
import '../../../../core/services/device_service.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/utils/observability.dart';
import '../../../../core/errors/failures.dart';

class AuthCubit extends Cubit<AuthState> with WidgetsBindingObserver {
  final AuthRepository repository;
  final DeviceService deviceService;
  final DatabaseService databaseService;

  StreamSubscription? _authSubscription;

  static const _pendingSourceKey = 'pending_auth_source';

  AuthCubit({
    required this.repository,
    required this.deviceService,
    required this.databaseService,
  }) : super(AuthInitial()) {
    WidgetsBinding.instance.addObserver(this);
    _initAuthListener();
    _checkAuthStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkOnResume();
    }
  }

  Future<void> _checkOnResume() async {
    // Give Supabase stream a moment to fire signedIn event before resetting
    await Future.delayed(const Duration(milliseconds: 500));
    if (isClosed) return;

    if (state is AuthLoading && !repository.isAuthenticated) {
      // If we are still in AuthLoading and haven't authenticated after returning,
      // the user likely cancelled the OAuth flow.
      emit(Unauthenticated());
      await databaseService.deleteSetting(_pendingSourceKey);
    }
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

  Future<void> _checkAuthStatus() async {
    // Initial check on app start
    if (repository.isAuthenticated) {
      final savedSource = await databaseService.getSetting(_pendingSourceKey);
      final source = AuthLoadingSource.values.firstWhere(
        (e) => e.name == savedSource,
        orElse: () => AuthLoadingSource.other,
      );
      emit(AuthLoading(source: source));
      _handleAuthSuccess();
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _handleAuthSuccess() async {
    // Sync profile and device info on every auth success (app start or login)
    if (state is Authenticated) return;

    final savedSource = await databaseService.getSetting(_pendingSourceKey);
    final source = state is AuthLoading
        ? (state as AuthLoading).source
        : AuthLoadingSource.values.firstWhere(
            (e) => e.name == savedSource,
            orElse: () => AuthLoadingSource.other,
          );
    emit(AuthLoading(source: source));

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
      await databaseService.deleteSetting(_pendingSourceKey);
    } catch (e) {
      AvenueLogger.log(
        event: 'AUTH_ERROR',
        level: LoggerLevel.ERROR,
        layer: LoggerLayer.STATE,
        payload: e.toString(),
      );

      await databaseService.deleteSetting(_pendingSourceKey);
      if (isClosed) return;
      if (userId != null) {
        emit(Authenticated(userId));
      } else {
        emit(Unauthenticated());
      }
    }
  }

  Future<void> signUp({
    required String email,
    required String username,
    required String password,
    required String firstName,
    String? lastName,
  }) async {
    emit(AuthLoading(source: AuthLoadingSource.email));


    final usernameResult = await repository.isUsernameAvailable(username);
    if (isClosed) return;

    bool isAvailable = false;
    usernameResult.fold(
      (failure) {
        emit(AuthError(failure.message));
      },
      (available) => isAvailable = available,
    );

    if (state is AuthError) return;

    if (!isAvailable) {
      emit(const AuthError('Username is already taken.'));
      return;
    }

    final result = await repository.signUp(
      email: email,
      username: username,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );

    if (isClosed) return;
    result.fold((failure) => emit(AuthError(failure.message)), (_) {
      if (!repository.isAuthenticated) {
        emit(
          const AuthError(
            'Account created! Please check your email to confirm your account.',
          ),
        );
      }
    });
  }

  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    emit(AuthLoading());

    String emailToUse = identifier;

    if (!identifier.contains('@')) {
      final emailResult = await repository.getEmailByUsername(identifier);
      if (isClosed) return;

      bool foundEmail = false;
      emailResult.fold(
        (failure) {
          emit(const AuthError('Invalid username or password.'));
        },
        (email) {
          emailToUse = email;
          foundEmail = true;
        },
      );

      if (!foundEmail) return;
    }

    final result = await repository.signIn(email: emailToUse, password: password);
    if (isClosed) return;
    result.fold((failure) => emit(AuthError(failure.message)), (_) {
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
    await databaseService.saveSetting(
      _pendingSourceKey,
      AuthLoadingSource.google.name,
    );
    emit(const AuthLoading(source: AuthLoadingSource.google));
    final result = await repository.signInWithGoogle();
    if (isClosed) return;
    result.fold((failure) async {
      await databaseService.deleteSetting(_pendingSourceKey);
      emit(AuthError(failure.message));
    }, (res) {});
  }

  Future<void> signInWithFacebook() async {
    await databaseService.saveSetting(
      _pendingSourceKey,
      AuthLoadingSource.facebook.name,
    );
    emit(const AuthLoading(source: AuthLoadingSource.facebook));
    final result = await repository.signInWithFacebook();
    if (isClosed) return;
    result.fold((failure) async {
      await databaseService.deleteSetting(_pendingSourceKey);
      emit(AuthError(failure.message));
    }, (res) {});
  }

  Future<void> signOut() async {
    // 1. Attempt remote sign out (Supabase SDK clears local tokens immediately)
    // We don't await this for the UI to be responsive, or we await it but proceed regardless of success
    repository.signOut().catchError((_) => const Right<Failure, void>(null));

    if (isClosed) return;

    // 2. Clear all local user data and emit Unauthenticated
    // This provides a robust "force logout" experience even when offline
    await databaseService.clearUserData();
    emit(Unauthenticated());
  }

  Future<void> sendPasswordResetOtp(String email) async {
    emit(AuthLoading());
    final result = await repository.sendPasswordResetOtp(email: email);
    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(PasswordResetOtpSent(email)),
    );
  }

  Future<void> verifyPasswordResetOtp(String email, String otp) async {
    emit(AuthLoading());
    final result = await repository.verifyPasswordResetOtp(
      email: email,
      token: otp,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(PasswordResetOtpVerified(email, otp)),
    );
  }

  Future<void> resetPassword(String password) async {
    emit(AuthLoading());
    final result = await repository.updatePassword(newPassword: password);
    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(PasswordResetSuccess()),
    );
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    return super.close();
  }
}
