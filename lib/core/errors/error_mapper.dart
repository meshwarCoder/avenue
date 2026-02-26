import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../errors/failures.dart';

class ErrorMapper {
  static String mapFailureToMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'No internet connection try again';
    }
    return failure.message;
  }

  static String mapExceptionToMessage(dynamic e) {
    if (e is SocketException || (e.toString().contains('Failed host lookup'))) {
      return 'No internet connection try again';
    }
    if (e is TimeoutException) {
      return 'Connection timeout try again';
    }
    if (e is AuthException) {
      return _mapAuthException(e);
    }

    // Default fallback - never leak technical details
    return 'Unexpected error occurred try again';
  }

  static String _mapAuthException(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please confirm your email first.';
    }
    if (message.contains('user already exists')) {
      return 'This account already exists. Try logging in.';
    }
    if (message.contains('rate limit')) {
      return 'Too many attempts. Please try again later.';
    }
    return 'Authentication failed. Try again.';
  }
}
