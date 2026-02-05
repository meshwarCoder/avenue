import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      return Left(ServerFailure(e.message));
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
      return Left(ServerFailure(e.message));
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
  Future<Either<Failure, void>> createDeviceRecord(String deviceId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        return const Left(ServerFailure('User not logged in'));
      }

      final device = DeviceModel(
        id: deviceId,
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
}
