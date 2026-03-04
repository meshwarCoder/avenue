import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

enum AuthLoadingSource { email, google, facebook, other }

class AuthLoading extends AuthState {
  final AuthLoadingSource source;
  const AuthLoading({this.source = AuthLoadingSource.email});

  @override
  List<Object?> get props => [source];
}

class Authenticated extends AuthState {
  final String userId;
  const Authenticated(this.userId);

  @override
  List<Object?> get props => [userId];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class PasswordResetOtpSent extends AuthState {
  final String email;
  const PasswordResetOtpSent(this.email);

  @override
  List<Object?> get props => [email];
}

class PasswordResetOtpVerified extends AuthState {
  final String email;
  final String otp;
  const PasswordResetOtpVerified(this.email, this.otp);

  @override
  List<Object?> get props => [email, otp];
}

class PasswordResetSuccess extends AuthState {}
