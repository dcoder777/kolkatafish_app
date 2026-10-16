import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitors device connectivity and validates real internet reachability.
class ConnectivityService {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _pollingTimer;

  bool _isOnline = true;
  bool _initialized = false;
  final _statusController = StreamController<bool>.broadcast();

  final bool enablePolling;

  ConnectivityService({
    Connectivity? connectivity,
    this.enablePolling = true,
  }) : _connectivity = connectivity ?? Connectivity();

  bool get isOnline => _isOnline;
  Stream<bool> get onStatusChanged => _statusController.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Initial check
    await _checkStatus();

    // Listen to OS network interface changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityResult(results);
    });

    // Periodic heartbeat check to detect WAN drops on active WiFi
    if (enablePolling) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _checkStatus();
      });
    }
  }

  Future<void> _handleConnectivityResult(List<ConnectivityResult> results) async {
    final hasInterface = results.any((r) => r != ConnectivityResult.none);
    if (!hasInterface) {
      _updateStatus(false);
      return;
    }
    await _checkStatus();
  }

  Future<void> _checkStatus() async {
    final online = await checkRealInternet();
    _updateStatus(online);
  }

  /// Verifies active internet reachability using direct IP socket check (bypasses DNS cache)
  /// with host lookup fallback.
  Future<bool> checkRealInternet() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) return false;

      // 1. Direct TCP socket to Google Public DNS (port 53) - fails immediately if offline
      // and bypasses OS libc DNS cache completely.
      try {
        final socket = await Socket.connect(
          '8.8.8.8',
          53,
          timeout: const Duration(milliseconds: 1500),
        );
        socket.destroy();
        return true;
      } catch (_) {}

      // 2. Direct TCP socket to Cloudflare DNS (1.1.1.1:53) fallback
      try {
        final socket = await Socket.connect(
          '1.1.1.1',
          53,
          timeout: const Duration(milliseconds: 1500),
        );
        socket.destroy();
        return true;
      } catch (_) {}

      // 3. Fallback DNS lookup to kolkatafish.com
      try {
        final addresses = await InternetAddress.lookup('kolkatafish.com')
            .timeout(const Duration(milliseconds: 2000));
        if (addresses.isNotEmpty && addresses[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {}

      return false;
    } catch (_) {
      return false;
    }
  }

  void _updateStatus(bool online) {
    if (online != _isOnline) {
      _isOnline = online;
      _statusController.add(online);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _pollingTimer?.cancel();
    _statusController.close();
  }
}
