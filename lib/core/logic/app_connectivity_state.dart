import 'package:equatable/equatable.dart';

/// Represents the global connectivity state of the application.
class AppConnectivityState extends Equatable {
  final bool isOffline;
  final bool justCameOnline; // Flag to show "back online" banner

  const AppConnectivityState._({
    required this.isOffline,
    this.justCameOnline = false,
  });

  /// Creates an online state.
  const AppConnectivityState.online() : this._(isOffline: false);

  /// Creates an offline state.
  const AppConnectivityState.offline() : this._(isOffline: true);

  /// Creates a state indicating we just came back online.
  const AppConnectivityState.backOnline()
    : this._(isOffline: false, justCameOnline: true);

  @override
  List<Object?> get props => [isOffline, justCameOnline];
}
