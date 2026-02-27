import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/request_executor.dart';
import '../../domain/repo/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabase;
  final RequestExecutor _requestExecutor;

  AuthRepositoryImpl({
    required this.supabase,
    required RequestExecutor requestExecutor,
  }) : _requestExecutor = requestExecutor;

  @override
  Future<Either<Failure, void>> signUp({
    required String email,
    required String password,
  }) async {
    return _requestExecutor.execute(
      operation: () async {
        await supabase.auth.signUp(email: email, password: password);
      },
    );
  }

  @override
  Future<Either<Failure, void>> signIn({
    required String email,
    required String password,
  }) async {
    return _requestExecutor.execute(
      operation: () async {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      },
    );
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    // For sign out, we use try-catch because we want to succeed
    // even if the network call fails (local cleanup is more important)
    try {
      await supabase.auth.signOut();
      return const Right(null);
    } catch (e) {
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
    return _requestExecutor.execute(
      operation: () async {
        await supabase.from('devices').upsert({
          'device_id': deviceId,
          'user_id': currentUserId,
          'last_sync': DateTime.now().toIso8601String(),
        });
      },
    );
  }

  @override
  Future<Either<Failure, void>> createOrUpdateProfile(
    int timezoneOffset,
  ) async {
    return _requestExecutor.execute(
      operation: () async {
        await supabase.from('profiles').upsert({
          'id': currentUserId,
          'timezone_offset': timezoneOffset,
          'updated_at': DateTime.now().toIso8601String(),
        });
      },
    );
  }

  @override
  Future<Either<Failure, bool>> deviceExists(String deviceId) async {
    return _requestExecutor.execute(
      operation: () async {
        final res = await supabase
            .from('devices')
            .select('id')
            .eq('device_id', deviceId)
            .maybeSingle();
        return res != null;
      },
    );
  }

  @override
  Future<Either<Failure, void>> updateDeviceSyncTimestamp(
    String deviceId,
  ) async {
    return _requestExecutor.execute(
      operation: () async {
        await supabase
            .from('devices')
            .update({'last_sync': DateTime.now().toIso8601String()})
            .eq('device_id', deviceId);
      },
    );
  }

  @override
  Future<Either<Failure, bool>> signInWithGoogle() async {
    return _requestExecutor.execute(
      operation: () async {
        return await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'io.supabase.flutter://login-callback/',
        );
      },
    );
  }

  @override
  Future<Either<Failure, bool>> signInWithFacebook() async {
    return _requestExecutor.execute(
      operation: () async {
        return await supabase.auth.signInWithOAuth(
          OAuthProvider.facebook,
          redirectTo: 'io.supabase.flutter://login-callback/',
          queryParams: {'auth_type': 'reauthenticate'},
        );
      },
    );
  }

  @override
  Future<Either<Failure, String>> fetchUserRole() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return const Left(ServerFailure('User not logged in'));
    }

    return _requestExecutor.execute(
      operation: () async {
        final data = await supabase
            .from('profiles')
            .select('role')
            .eq('user_id', userId)
            .maybeSingle();

        return data?['role'] as String? ?? 'user';
      },
    );
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
}
