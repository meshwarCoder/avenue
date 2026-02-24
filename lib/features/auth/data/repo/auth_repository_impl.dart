import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repo/auth_repository.dart';
import '../models/device_model.dart';
import '../models/profile_model.dart';

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
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } on SocketException {
      return const Left(
        ServerFailure('No internet connection. Please check your network.'),
      );
    } on HandshakeException {
      return const Left(
        ServerFailure(
          'Network security error (Handshake). Please check your VPN or firewall.',
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } on SocketException {
      return const Left(
        ServerFailure('No internet connection. Please check your network.'),
      );
    } on HandshakeException {
      return const Left(
        ServerFailure(
          'Network security error (Handshake). Please check your VPN or firewall.',
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await supabase.auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        return const Left(ServerFailure('User not logged in'));
      }

      // Generate a stable UUID from the hardware deviceId
      final stableId = const Uuid().v5(Namespace.url.value, deviceId);

      final device = DeviceModel(
        id: stableId,
        userId: userId,
        deviceId: deviceId,
      );
      await supabase.from('devices').upsert(device.toSupabaseJson());

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createOrUpdateProfile(
    int timezoneOffset,
  ) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        return const Left(ServerFailure('User not logged in'));
      }

      final profile = ProfileModel(
        id: userId,
        userId: userId,
        timezoneOffset: timezoneOffset,
      );

      await supabase.from('profiles').upsert(profile.toSupabaseJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deviceExists(String deviceId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        return const Left(ServerFailure('User not logged in'));
      }

      final data = await supabase
          .from('devices')
          .select()
          .eq('user_id', userId)
          .eq('device_id', deviceId)
          .maybeSingle();

      return Right(data != null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateDeviceSyncTimestamp(
    String deviceId,
  ) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        return const Left(ServerFailure('User not logged in'));
      }

      await supabase
          .from('devices')
          .update({
            'server_updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('device_id', deviceId);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> signInWithGoogle() async {
    try {
      final res = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.line://login-callback',
      );
      return Right(res);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> signInWithFacebook() async {
    try {
      final res = await supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'com.example.line://login-callback',
      );
      return Right(res);
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
