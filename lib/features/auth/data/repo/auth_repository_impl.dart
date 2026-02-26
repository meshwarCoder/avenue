import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../domain/repo/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabase;

  AuthRepositoryImpl({required this.supabase});

  @override
  Future<Either<Failure, void>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signUp(email: email, password: password);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ErrorMapper.mapExceptionToMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ErrorMapper.mapExceptionToMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await supabase.auth.signOut();
      return const Right(null);
    } catch (e) {
      // Return success anyway for local cleanup robustness
      return const Right(null);
    }
  }

  @override
  bool get isAuthenticated => supabase.auth.currentUser != null;

  @override
  String? get currentUserId => supabase.auth.currentUser?.id;

  @override
  String? get currentUserEmail => supabase.auth.currentUser?.email;

  @override
  Future<Either<Failure, void>> createDeviceRecord(String deviceId) async {
    try {
      await supabase.from('devices').upsert({
        'device_id': deviceId,
        'user_id': currentUserId,
        'last_sync': DateTime.now().toIso8601String(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ErrorMapper.mapExceptionToMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> createOrUpdateProfile(
    int timezoneOffset,
  ) async {
    try {
      await supabase.from('profiles').upsert({
        'id': currentUserId,
        'timezone_offset': timezoneOffset,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ErrorMapper.mapExceptionToMessage(e)));
    }
  }

  @override
  Future<Either<Failure, bool>> deviceExists(String deviceId) async {
    try {
      final res = await supabase
          .from('devices')
          .select('id')
          .eq('device_id', deviceId)
          .maybeSingle();
      return Right(res != null);
    } catch (e) {
      return Left(ServerFailure(ErrorMapper.mapExceptionToMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> updateDeviceSyncTimestamp(
    String deviceId,
  ) async {
    try {
      await supabase
          .from('devices')
          .update({'last_sync': DateTime.now().toIso8601String()})
          .eq('device_id', deviceId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ErrorMapper.mapExceptionToMessage(e)));
    }
  }

  @override
  Future<Either<Failure, bool>> signInWithGoogle() async {
    try {
      final res = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback/',
      );
      return Right(res);
    } catch (e) {
      return Left(ServerFailure(ErrorMapper.mapExceptionToMessage(e)));
    }
  }

  @override
  Future<Either<Failure, bool>> signInWithFacebook() async {
    try {
      final res = await supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.flutter://login-callback/',
        queryParams: {'auth_type': 'reauthenticate'},
      );
      return Right(res);
    } catch (e) {
      return Left(ServerFailure(ErrorMapper.mapExceptionToMessage(e)));
    }
  }

  @override
  Future<Either<Failure, String>> fetchUserRole() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        return const Left(ServerFailure('User not logged in'));
      }

      final data = await supabase
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      final role = data?['role'] as String? ?? 'user';
      return Right(role);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<AuthEvent> get authEvents {
    return supabase.auth.onAuthStateChange.map((data) {
      switch (data.event) {
        case AuthChangeEvent.signedIn:
          return AuthEvent.signedIn;
        case AuthChangeEvent.signedOut:
          return AuthEvent.signedOut;
        default:
          return AuthEvent.unknown;
      }
    });
  }

  Failure _mapAuthException(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return const ServerFailure('Invalid email or password.');
    } else if (message.contains('email not confirmed')) {
      return const ServerFailure('Email not confirmed.');
    } else if (message.contains('user already exists')) {
      return const ServerFailure(
        'An account with this email already exists. Try signing in instead.',
      );
    } else if (message.contains('not found') ||
        message.contains('no user found')) {
      return const ServerFailure(
        'No account found with this email. Please sign up first.',
      );
    } else if (message.contains('rate limit')) {
      return const ServerFailure('Too many attempts. Please try again later.');
    }
    return ServerFailure(e.message);
  }
}
