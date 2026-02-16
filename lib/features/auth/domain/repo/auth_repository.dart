import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> signUp({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> signOut();

  bool get isAuthenticated;
  String? get currentUserId;

  Future<Either<Failure, void>> createDeviceRecord(String deviceId);
  Future<Either<Failure, void>> createOrUpdateProfile(int timezoneOffset);
  Future<Either<Failure, bool>> deviceExists(String deviceId);
  Future<Either<Failure, void>> updateDeviceSyncTimestamp(String deviceId);

  // Google Sign In & Reactive Auth
  Future<Either<Failure, bool>> signInWithGoogle();
  Stream<AuthEvent> get authEvents;
}

enum AuthEvent { signedIn, signedOut, unknown }
