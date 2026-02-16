import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {
  final bool isGoogle;
  const AuthLoading({this.isGoogle = false});

  @override
  List<Object?> get props => [isGoogle];
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
