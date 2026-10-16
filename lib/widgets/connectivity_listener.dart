import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../utils/toast_helper.dart';

/// App-wide widget that monitors internet connectivity changes
/// and triggers toast notifications when the device goes offline or comes back online.
class ConnectivityListener extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const ConnectivityListener({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<ConnectivityListener> createState() => _ConnectivityListenerState();
}

class _ConnectivityListenerState extends State<ConnectivityListener> {
  bool? _lastKnownOnline;
  bool _initialToastTriggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleConnectivityUpdate();
  }

  void _handleConnectivityUpdate() {
    final provider = context.watch<ConnectivityProvider>();
    if (!provider.hasInitialCheck) return;

    final isOnline = provider.isOnline;

    // First time we know the connectivity state
    if (_lastKnownOnline == null) {
      _lastKnownOnline = isOnline;
      // If offline on app launch, alert the user once the frame is ready
      if (!isOnline && !_initialToastTriggered) {
        _initialToastTriggered = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _triggerToast(false);
        });
      }
      return;
    }

    // State transition detected
    if (_lastKnownOnline != isOnline) {
      _lastKnownOnline = isOnline;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerToast(isOnline);
      });
    }
  }

  void _triggerToast(bool isOnline) {
    final navState = widget.navigatorKey.currentState;
    final navContext = widget.navigatorKey.currentContext;
    if (navState == null && navContext == null) return;
    if (!mounted) return;

    final targetOverlay = navState?.overlay;
    final targetContext = navContext ?? context;

    if (isOnline) {
      showOnlineToast(targetContext, overlay: targetOverlay);
    } else {
      showOfflineToast(targetContext, overlay: targetOverlay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

