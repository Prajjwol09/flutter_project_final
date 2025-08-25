import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_storage_service.dart';

// Connectivity service provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

// Connectivity state provider
final connectivityProvider = StreamProvider<ConnectivityState>((ref) {
  return ref.read(connectivityServiceProvider).connectivityStream;
});

enum NetworkStatus {
  connected,
  disconnected,
  unknown,
}

class ConnectivityState {
  final NetworkStatus status;
  final List<ConnectivityResult> connections;
  final DateTime lastUpdated;
  final bool isOnline;

  const ConnectivityState({
    required this.status,
    required this.connections,
    required this.lastUpdated,
    required this.isOnline,
  });

  ConnectivityState copyWith({
    NetworkStatus? status,
    List<ConnectivityResult>? connections,
    DateTime? lastUpdated,
    bool? isOnline,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      connections: connections ?? this.connections,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  String toString() {
    return 'ConnectivityState(status: $status, isOnline: $isOnline, connections: $connections)';
  }
}

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityState> _connectivityController = 
      StreamController<ConnectivityState>.broadcast();

  StreamSubscription? _connectivitySubscription;
  ConnectivityState _currentState = ConnectivityState(
    status: NetworkStatus.unknown,
    connections: [],
    lastUpdated: DateTime.now(),
    isOnline: false,
  );

  bool _isInitialized = false;
  Timer? _connectivityCheckTimer;

  /// Get the connectivity stream
  Stream<ConnectivityState> get connectivityStream => _connectivityController.stream;

  /// Get current connectivity state
  ConnectivityState get currentState => _currentState;

  /// Check if device is currently online
  bool get isOnline => _currentState.isOnline;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get initial connectivity state
      final results = await _connectivity.checkConnectivity();
      await _updateConnectivityState(results);

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectivityState,
        onError: (error) {
          if (kDebugMode) {
            print('❌ Connectivity stream error: $error');
          }
          _updateConnectivityState([ConnectivityResult.none]);
        },
      );

      // Start periodic connectivity checks
      _startPeriodicConnectivityCheck();

      _isInitialized = true;
      if (kDebugMode) {
        print('✅ Connectivity service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize connectivity service: $e');
      }
      // Continue with unknown state
      _currentState = _currentState.copyWith(
        status: NetworkStatus.unknown,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Update connectivity state
  Future<void> _updateConnectivityState(List<ConnectivityResult> results) async {
    try {
      final isOnline = await _isConnectedToInternet(results);
      final status = _determineNetworkStatus(results, isOnline);

      _currentState = ConnectivityState(
        status: status,
        connections: results,
        lastUpdated: DateTime.now(),
        isOnline: isOnline,
      );

      _connectivityController.add(_currentState);

      if (kDebugMode) {
        print('📶 Connectivity updated: ${_currentState.toString()}');
      }

      // Handle connectivity changes
      await _handleConnectivityChange(isOnline);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating connectivity state: $e');
      }
    }
  }

  /// Determine network status from connectivity results
  NetworkStatus _determineNetworkStatus(List<ConnectivityResult> results, bool isOnline) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return NetworkStatus.disconnected;
    }

    if (isOnline) {
      return NetworkStatus.connected;
    }

    return NetworkStatus.disconnected;
  }

  /// Check if device is actually connected to the internet
  Future<bool> _isConnectedToInternet(List<ConnectivityResult> results) async {
    // If no connectivity at all, definitely offline
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return false;
    }

    // For other connection types, try to perform a quick internet check
    try {
      // Simple internet connectivity check
      // You could implement a more sophisticated check here
      return true; // For now, assume connected if we have network interface
    } catch (e) {
      return false;
    }
  }

  /// Handle connectivity changes
  Future<void> _handleConnectivityChange(bool isOnline) async {
    if (isOnline) {
      await _onConnectedToInternet();
    } else {
      await _onDisconnectedFromInternet();
    }
  }

  /// Handle when device comes online
  Future<void> _onConnectedToInternet() async {
    try {
      if (kDebugMode) {
        print('🌐 Device is now online - triggering sync');
      }

      // Trigger data sync when coming online
      await _triggerDataSync();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling online state: $e');
      }
    }
  }

  /// Handle when device goes offline
  Future<void> _onDisconnectedFromInternet() async {
    try {
      if (kDebugMode) {
        print('📵 Device is now offline - saving offline indicators');
      }

      // Save offline state
      await _saveOfflineState();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling offline state: $e');
      }
    }
  }

  /// Trigger data synchronization
  Future<void> _triggerDataSync() async {
    // This would be called by other services that need to sync
    // For now, just update the last sync attempt time
    try {
      await LocalStorageService.setLastSyncTime(DateTime.now());
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not update sync time: $e');
      }
    }
  }

  /// Save offline state
  Future<void> _saveOfflineState() async {
    // Save any pending offline operations
    // This would be implemented by services that need offline support
  }

  /// Start periodic connectivity checks
  void _startPeriodicConnectivityCheck() {
    _connectivityCheckTimer?.cancel();
    _connectivityCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) async {
        try {
          final results = await _connectivity.checkConnectivity();
          await _updateConnectivityState(results);
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Periodic connectivity check failed: $e');
          }
        }
      },
    );
  }

  /// Force check connectivity
  Future<ConnectivityState> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateConnectivityState(results);
      return _currentState;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Manual connectivity check failed: $e');
      }
      return _currentState;
    }
  }

  /// Wait for internet connection
  Future<void> waitForConnection({Duration? timeout}) async {
    if (isOnline) return;

    final completer = Completer<void>();
    late StreamSubscription subscription;

    subscription = connectivityStream.listen((state) {
      if (state.isOnline) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    if (timeout != null) {
      Timer(timeout, () {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Connection timeout', timeout));
        }
      });
    }

    return completer.future;
  }

  /// Check if we have been offline for a long time
  bool hasBeenOfflineTooLong() {
    if (_currentState.isOnline) return false;
    
    const offlineThreshold = Duration(hours: 24);
    return DateTime.now().difference(_currentState.lastUpdated) > offlineThreshold;
  }

  /// Get connectivity statistics
  Map<String, dynamic> getConnectivityStats() {
    return {
      'current_status': _currentState.status.name,
      'is_online': _currentState.isOnline,
      'connections': _currentState.connections.map((c) => c.name).toList(),
      'last_updated': _currentState.lastUpdated.toIso8601String(),
      'has_been_offline_too_long': hasBeenOfflineTooLong(),
    };
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityCheckTimer?.cancel();
    _connectivityController.close();
    _isInitialized = false;
  }
}

/// Exception for connectivity-related errors
class ConnectivityException implements Exception {
  final String message;
  final String? details;

  const ConnectivityException(this.message, [this.details]);

  @override
  String toString() {
    return details != null 
        ? 'ConnectivityException: $message ($details)'
        : 'ConnectivityException: $message';
  }
}