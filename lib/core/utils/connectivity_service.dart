import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps connectivity_plus into a clean stream + provider.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onConnectivityChanged => _connectivity
      .onConnectivityChanged
      .map((results) => _isOnline(results));

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);
}

/// True = online, False = offline
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final svc = ConnectivityService();
  // Emit current state first
  yield await svc.isConnected;
  // Then stream changes
  yield* svc.onConnectivityChanged;
});

/// Simple bool — use this in widgets
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).maybeWhen(
        data: (v) => v,
        orElse: () => true, // assume online until proven otherwise
      );
});
