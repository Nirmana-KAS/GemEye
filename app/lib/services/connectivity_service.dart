import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Live network state for the offline banner. connectivity_plus reports the
/// network interface only, so "online" means a Wi-Fi, mobile or ethernet
/// link exists, not that the grading server is reachable.
class ConnectivityService {
  ConnectivityService._();

  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _sub;

  /// True while a network link is available. Starts optimistic.
  static final ValueNotifier<bool> online = ValueNotifier(true);

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  static Future<void> init() async {
    await check();
    _sub ??= _connectivity.onConnectivityChanged.listen(
      (results) => online.value = _isOnline(results),
      onError: (Object e) {
        if (kDebugMode) debugPrint('Connectivity stream failed: $e');
      },
    );
  }

  /// Re-checks the connection now (the offline banner's Retry).
  static Future<bool> check() async {
    try {
      online.value = _isOnline(await _connectivity.checkConnectivity());
    } catch (e) {
      if (kDebugMode) debugPrint('Connectivity check failed: $e');
    }
    return online.value;
  }
}
