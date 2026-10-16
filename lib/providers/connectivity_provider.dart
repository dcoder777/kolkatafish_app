import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Provider for app-wide internet connectivity status.
class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _service;
  StreamSubscription<bool>? _sub;

  bool _isOnline = true;
  bool _hasInitialCheck = false;
  bool _wasOffline = false;

  ConnectivityProvider({ConnectivityService? service})
      : _service = service ?? ConnectivityService() {
    _init();
  }

  bool get isOnline => _isOnline;
  bool get hasInitialCheck => _hasInitialCheck;
  bool get wasOffline => _wasOffline;

  Future<void> _init() async {
    await _service.initialize();
    _isOnline = _service.isOnline;
    _hasInitialCheck = true;
    if (!_isOnline) {
      _wasOffline = true;
    }
    notifyListeners();

    _sub = _service.onStatusChanged.listen((online) {
      if (online != _isOnline) {
        if (!online) {
          _wasOffline = true;
        }
        _isOnline = online;
        notifyListeners();
      }
    });
  }

  Future<bool> checkNow() async {
    final online = await _service.checkRealInternet();
    if (online != _isOnline) {
      if (!online) _wasOffline = true;
      _isOnline = online;
      notifyListeners();
    }
    return online;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }
}

