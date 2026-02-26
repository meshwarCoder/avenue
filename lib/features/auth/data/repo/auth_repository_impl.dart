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
  Stream<AuthEvent> get authEvents =>
      supabase.auth.onAuthStateChange.map((data) {
        if (data.event == AuthChangeEvent.signedIn) return AuthEvent.signedIn;
        if (data.event == AuthChangeEvent.signedOut) return AuthEvent.signedOut;
        return AuthEvent.unknown;
      });
}
