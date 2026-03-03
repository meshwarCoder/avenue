import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_connectivity_state.dart';
import '../services/network_service.dart';
import '../widgets/offline_banner.dart';

/// Monitors network connectivity globally with a debounce on the offline state.
class AppConnectivityCubit extends Cubit<AppConnectivityState> {
  final NetworkService _networkService;
  StreamSubscription<List<ConnectivityResult>>? _connectionSubscription;
  Timer? _debounceTimer;
  Timer? _backOnlineTimer;

  AppConnectivityCubit({required NetworkService networkService})
    : _networkService = networkService,
      super(const AppConnectivityState.online()) {
    _initialize();
  }

  void _initialize() async {
    // Initial check
    final isConnected = await _networkService.isConnected;
    _updateState(isConnected);

    _connectionSubscription = _networkService.connectionStream.listen((
      results,
    ) {
      final isConnected =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      _updateState(isConnected);
    });
  }

  void _updateState(bool isConnected) {
    if (isConnected) {
      // Cancel pending offline emission and go online immediately
      _debounceTimer?.cancel();
      GlobalConnectivity.setOffline(false);

      if (state.isOffline) {
        _showBackOnlineBanner();
      }
    } else {
      // If already offline or debounce is in progress, do nothing
      if (state.isOffline || (_debounceTimer?.isActive ?? false)) return;

      // Start 700ms debounce for offline emission
      _debounceTimer = Timer(const Duration(milliseconds: 700), () async {
        // Double-check connectivity after delay to confirm actual offline status
        final stillDisconnected = !(await _networkService.isConnected);
        if (stillDisconnected && !isClosed) {
          GlobalConnectivity.setOffline(true);
          emit(const AppConnectivityState.offline());
        }
      });
    }
  }

  void _showBackOnlineBanner() {
    _backOnlineTimer?.cancel();
    emit(const AppConnectivityState.backOnline());
    _backOnlineTimer = Timer(const Duration(seconds: 2), () {
      if (!isClosed && !state.isOffline) {
        emit(const AppConnectivityState.online());
      }
    });
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    _debounceTimer?.cancel();
    _backOnlineTimer?.cancel();
    return super.close();
  }
}
