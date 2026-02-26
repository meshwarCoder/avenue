import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkService {
  Future<bool> get isConnected;
  Stream<List<ConnectivityResult>> get connectionStream;
}

class NetworkServiceImpl implements NetworkService {
  final Connectivity connectivity;

  NetworkServiceImpl({required this.connectivity});

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  @override
  Stream<List<ConnectivityResult>> get connectionStream =>
      connectivity.onConnectivityChanged;
}
