import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_connectivity_state.dart';
import '../services/network_service.dart';
import '../widgets/offline_banner.dart';

/// Monitors network connectivity globally.
class AppConnectivityCubit extends Cubit<AppConnectivityState> {
  final NetworkService _networkService;
  StreamSubscription<List<ConnectivityResult>>? _connectionSubscription;
  Timer? _periodicCheckTimer;
  Timer? _backOnlineTimer;

  AppConnectivityCubit({required NetworkService networkService})
    : _networkService = networkService,
      super(const AppConnectivityState.online()) {
    _initialize();
  }

  void _initialize() async {
    await _checkAndUpdateConnectivity();

    _connectionSubscription = _networkService.connectionStream.listen(
      (results) => _handleConnectivityResults(results),
      onError: (error) {
        GlobalConnectivity.setOffline(true);
        if (!state.isOffline) {
          emit(const AppConnectivityState.offline());
        }
      },
    );

    _periodicCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkAndUpdateConnectivity(),
    );
  }

  Future<void> _checkAndUpdateConnectivity() async {
    try {
      final isConnected = await _networkService.isConnected;
      final isOffline = !isConnected;

      GlobalConnectivity.setOffline(isOffline);

      if (isOffline && !state.isOffline) {
        emit(const AppConnectivityState.offline());
      } else if (!isOffline && state.isOffline) {
        _showBackOnlineBanner();
      }
    } catch (e) {
      GlobalConnectivity.setOffline(true);
      emit(const AppConnectivityState.offline());
    }
  }

  void _handleConnectivityResults(List<ConnectivityResult> results) {
    final isOffline =
        results.isEmpty || results.contains(ConnectivityResult.none);

    GlobalConnectivity.setOffline(isOffline);

    if (isOffline && !state.isOffline) {
      emit(const AppConnectivityState.offline());
    } else if (!isOffline && state.isOffline) {
      _showBackOnlineBanner();
    }
  }

  void _showBackOnlineBanner() {
    _backOnlineTimer?.cancel();
    emit(const AppConnectivityState.backOnline());
    _backOnlineTimer = Timer(const Duration(seconds: 2), () {
      if (!state.isOffline) {
        emit(const AppConnectivityState.online());
      }
    });
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    _periodicCheckTimer?.cancel();
    _backOnlineTimer?.cancel();
    return super.close();
  }
}
