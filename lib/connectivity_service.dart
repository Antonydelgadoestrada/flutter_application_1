import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _hasInternet = false;
  late StreamSubscription<ConnectivityResult> _subscription;

  bool get hasInternet => _hasInternet;

  ConnectivityService() {
    _initConnectivity();
    _listenForConnectivity();
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _hasInternet = false;
    }
  }

  void _listenForConnectivity() {
    _subscription = _connectivity.onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      _updateConnectionStatus(result);
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final previousStatus = _hasInternet;
    _hasInternet = result != ConnectivityResult.none;

    if (previousStatus != _hasInternet) {
      debugPrint(
        '🌐 Conectividad cambió: ${_hasInternet ? "CONECTADO" : "DESCONECTADO"}',
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
