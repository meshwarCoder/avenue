import 'dart:async';
import 'dart:io';
import 'package:avenue/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../errors/failures.dart';

class ErrorMapper {
  static String mapFailureToMessage(AppLocalizations l10n, Failure failure) {
    if (failure is NetworkFailure) {
      return l10n.errNoInternet;
    }
    if (failure is TimeoutFailure) {
      return l10n.errTimeout;
    }
    if (failure.message == 'Unexpected error occurred') {
      return l10n.errUnexpected;
    }
    if (failure.message == 'Task not found') {
      return l10n.errTaskNotFound;
    }
    return failure.message;
  }

  static String mapExceptionToMessage(AppLocalizations l10n, dynamic e) {
    if (e is SocketException || (e.toString().contains('Failed host lookup'))) {
      return l10n.errNoInternet;
    }
    if (e is TimeoutException) {
      return l10n.errTimeout;
    }
    if (e is AuthException) {
      return _mapAuthException(l10n, e);
    }

    // Default fallback - never leak technical details
    return l10n.errUnexpected;
  }

  static String _mapAuthException(AppLocalizations l10n, AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return l10n.errInvalidCredentials;
    }
    if (message.contains('email not confirmed')) {
      return l10n.errEmailNotConfirmed;
    }
    if (message.contains('user already exists')) {
      return l10n.errUserAlreadyExists;
    }
    if (message.contains('rate limit')) {
      return l10n.errRateLimit;
    }
    return l10n.errAuthFailed;
  }
}
