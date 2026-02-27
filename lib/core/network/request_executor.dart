import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../errors/failures.dart';
import '../services/network_service.dart';

/// Executes async operations with network check and timeout handling.
class RequestExecutor {
  final NetworkService _networkService;

  const RequestExecutor({required NetworkService networkService})
    : _networkService = networkService;

  Future<Either<Failure, T>> execute<T>({
    required Future<T> Function() operation,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final isConnected = await _networkService.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final result = await operation().timeout(timeout);
      return Right(result);
    } on TimeoutException {
      return const Left(TimeoutFailure());
    } on AuthException catch (e) {
      return Left(_mapAuthExceptionToFailure(e));
    } on Exception catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  Failure _mapAuthExceptionToFailure(AuthException e) {
    final code = e.code?.toLowerCase() ?? '';
    final message = e.message.toLowerCase();

    if (code.contains('invalid_credentials') ||
        message.contains('invalid login credentials')) {
      return const ServerFailure('Invalid email or password');
    }

    if (code.contains('email_not_confirmed') ||
        message.contains('email not confirmed')) {
      return const ServerFailure('Please confirm your email first');
    }

    if (code.contains('user_not_found') ||
        message.contains('user not found') ||
        message.contains('no user found') ||
        message.contains('not found')) {
      return const ServerFailure('No account found with this email');
    }

    if (code.contains('user_already_exists') ||
        message.contains('user already exists')) {
      return const ServerFailure('This account already exists. Try signing in');
    }

    if (code.contains('rate_limit') || message.contains('rate limit')) {
      return const ServerFailure('Too many attempts. Please try again later');
    }

    return const ServerFailure('Something went wrong. Please try again');
  }

  Failure _mapExceptionToFailure(Exception e) {
    final errorString = e.toString().toLowerCase();

    if (errorString.contains('socket') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network') ||
        errorString.contains('connection refused')) {
      return const NetworkFailure();
    }

    if (errorString.contains('timeout')) {
      return const TimeoutFailure();
    }

    return const ServerFailure('Something went wrong. Please try again');
  }
}
