import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True = online, False = offline
/// Streams real-time connectivity changes using connectivity_plus.
class ConnectivityNotifier extends AsyncNotifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  Future<bool> build() async {
    // Listen to stream and update state on change
    _subscription?.cancel();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      state = AsyncData(isOnline);
    });

    ref.onDispose(() => _subscription?.cancel());

    // Initial check
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}

final connectivityProvider = AsyncNotifierProvider<ConnectivityNotifier, bool>(
  ConnectivityNotifier.new,
);
