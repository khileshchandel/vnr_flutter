import 'package:connectivity_plus/connectivity_plus.dart';

/// Cross-cutting view of the device's network reachability.
///
/// Kept as an interface so sync tests can drive reconnects without a plugin.
abstract interface class ConnectivityService {
  /// Emits the current reachability whenever the network changes.
  Stream<bool> get onConnectivityChanged;

  /// One-shot reachability check used when the observer starts.
  Future<bool> isOnline();
}

final class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// The plugin emits a list; no connectivity is a single `none` entry.
  static bool _reachable(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  @override
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_reachable);

  @override
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _reachable(results);
  }
}
