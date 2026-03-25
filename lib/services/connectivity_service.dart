import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late ConnectivityResult _connectionStatus = ConnectivityResult.none;
  bool _isOnline = false;

  bool get isOnline => _isOnline;
  ConnectivityResult get connectionStatus => _connectionStatus;

  ConnectivityService() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      _connectionStatus = await _connectivity.checkConnectivity();
      _isOnline = _connectionStatus != ConnectivityResult.none;
      debugPrint('Initial connectivity: ${_connectionStatus.toString()}');
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = false;
    }
    notifyListeners();
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _connectionStatus = result;
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    // Log connection state changes
    if (wasOnline != _isOnline) {
      debugPrint('Connectivity changed: Online=$_isOnline');
    }

    notifyListeners();
  }
}
