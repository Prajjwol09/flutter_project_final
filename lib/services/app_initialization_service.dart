import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';
import 'error_handling_service.dart';
import 'offline_sync_service.dart';
import 'local_storage_service.dart';
import '../config/environment_config.dart';

// App initialization service provider
final appInitializationServiceProvider = Provider<AppInitializationService>((ref) {
  return AppInitializationService(ref);
});

// App initialization status provider
final appInitializationProvider = StateNotifierProvider<AppInitializationNotifier, AppInitializationStatus>((ref) {
  return AppInitializationNotifier(ref);
});

enum InitializationStage {
  starting,
  loadingEnvironment,
  initializingErrorHandling,
  initializingLocalStorage,
  initializingConnectivity,
  initializingOfflineSync,
  loadingUserData,
  ready,
  failed,
}

class AppInitializationStatus {
  final InitializationStage stage;
  final String? message;
  final double progress;
  final String? error;
  final bool isComplete;
  final Map<String, dynamic>? metadata;

  const AppInitializationStatus({
    required this.stage,
    this.message,
    this.progress = 0.0,
    this.error,
    this.isComplete = false,
    this.metadata,
  });

  AppInitializationStatus copyWith({
    InitializationStage? stage,
    String? message,
    double? progress,
    String? error,
    bool? isComplete,
    Map<String, dynamic>? metadata,
  }) {
    return AppInitializationStatus(
      stage: stage ?? this.stage,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      isComplete: isComplete ?? this.isComplete,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isFailed => stage == InitializationStage.failed;
  bool get isReady => stage == InitializationStage.ready;
}

class AppInitializationNotifier extends StateNotifier<AppInitializationStatus> {
  final Ref _ref;

  AppInitializationNotifier(this._ref) : super(const AppInitializationStatus(stage: InitializationStage.starting));

  void updateStatus(AppInitializationStatus status) {
    state = status;
  }

  Future<void> initialize() async {
    final service = _ref.read(appInitializationServiceProvider);
    await service.initializeApp();
  }
}

class AppInitializationService {
  final Ref _ref;
  static const int _totalStages = 7;

  AppInitializationService(this._ref);

  /// Initialize the entire app
  Future<void> initializeApp() async {
    final notifier = _ref.read(appInitializationProvider.notifier);
    
    try {
      if (kDebugMode) {
        print('🚀 Starting app initialization...');
      }

      // Stage 1: Load Environment
      notifier.updateStatus(AppInitializationStatus(
        stage: InitializationStage.loadingEnvironment,
        message: 'Loading environment configuration...',
        progress: 1 / _totalStages,
      ));
      await _initializeEnvironment();

      // Stage 2: Initialize Error Handling
      notifier.updateStatus(AppInitializationStatus(
        stage: InitializationStage.initializingErrorHandling,
        message: 'Setting up error handling...',
        progress: 2 / _totalStages,
      ));
      await _initializeErrorHandling();

      // Stage 3: Initialize Local Storage
      notifier.updateStatus(AppInitializationStatus(
        stage: InitializationStage.initializingLocalStorage,
        message: 'Initializing local storage...',
        progress: 3 / _totalStages,
      ));
      await _initializeLocalStorage();

      // Stage 4: Initialize Connectivity
      notifier.updateStatus(AppInitializationStatus(
        stage: InitializationStage.initializingConnectivity,
        message: 'Setting up connectivity monitoring...',
        progress: 4 / _totalStages,
      ));
      await _initializeConnectivity();

      // Stage 5: Initialize Offline Sync
      notifier.updateStatus(AppInitializationStatus(
        stage: InitializationStage.initializingOfflineSync,
        message: 'Setting up offline synchronization...',
        progress: 5 / _totalStages,
      ));
      await _initializeOfflineSync();

      // Stage 6: Load User Data
      notifier.updateStatus(AppInitializationStatus(
        stage: InitializationStage.loadingUserData,
        message: 'Loading user data...',
        progress: 6 / _totalStages,
      ));
      await _loadUserData();

      // Stage 7: Ready
      notifier.updateStatus(AppInitializationStatus(
        stage: InitializationStage.ready,
        message: 'App ready!',
        progress: 1.0,
        isComplete: true,
        metadata: await _getInitializationMetadata(),
      ));

      if (kDebugMode) {
        print('✅ App initialization completed successfully');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ App initialization failed: $e');
      }

      notifier.updateStatus(AppInitializationStatus(
        stage: InitializationStage.failed,
        message: 'Initialization failed',
        error: e.toString(),
        metadata: {
          'error': e.toString(),
          'stackTrace': stack.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));

      // Still log the error even if error handling isn't fully initialized
      try {
        ErrorHandlingService().handleBusinessError(
          'App initialization failed: $e',
          context: 'AppInitializationService.initializeApp',
          stackTrace: stack,
        );
      } catch (_) {
        // Error handling not available yet
      }

      rethrow;
    }
  }

  /// Initialize environment configuration
  Future<void> _initializeEnvironment() async {
    try {
      await EnvironmentConfig.init();
      if (kDebugMode) {
        print('✅ Environment configuration loaded');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Environment configuration failed, using defaults: $e');
      }
      // Continue with defaults - not critical for app functionality
    }
  }

  /// Initialize error handling
  Future<void> _initializeErrorHandling() async {
    try {
      ErrorHandlingService.initialize();
      if (kDebugMode) {
        print('✅ Error handling initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Initialize local storage
  Future<void> _initializeLocalStorage() async {
    try {
      await LocalStorageService.init();
      if (kDebugMode) {
        final stats = LocalStorageService.getDataCounts();
        print('✅ Local storage initialized: $stats');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Local storage initialization failed, continuing without it: $e');
      }
      // Continue without local storage - app can still work with Firebase only
      ErrorHandlingService().handleBusinessError(
        'Local storage initialization failed: $e',
        context: 'AppInitializationService._initializeLocalStorage',
      );
    }
  }

  /// Initialize connectivity monitoring
  Future<void> _initializeConnectivity() async {
    try {
      final connectivityService = _ref.read(connectivityServiceProvider);
      await connectivityService.initialize();
      
      if (kDebugMode) {
        final stats = connectivityService.getConnectivityStats();
        print('✅ Connectivity service initialized: $stats');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Connectivity service initialization failed: $e');
      }
      ErrorHandlingService().handleBusinessError(
        'Connectivity service initialization failed: $e',
        context: 'AppInitializationService._initializeConnectivity',
      );
      // Continue without connectivity monitoring
    }
  }

  /// Initialize offline sync
  Future<void> _initializeOfflineSync() async {
    try {
      // Offline sync service is initialized automatically when accessed
      final syncService = _ref.read(offlineSyncServiceProvider);
      
      if (kDebugMode) {
        final stats = syncService.getSyncStatistics();
        print('✅ Offline sync service initialized: $stats');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Offline sync service initialization failed: $e');
      }
      ErrorHandlingService().handleBusinessError(
        'Offline sync service initialization failed: $e',
        context: 'AppInitializationService._initializeOfflineSync',
      );
      // Continue without offline sync
    }
  }

  /// Load user data
  Future<void> _loadUserData() async {
    try {
      // Check if we have local user data
      final hasLocalData = LocalStorageService.hasLocalData();
      
      if (kDebugMode) {
        print('📊 Local data available: $hasLocalData');
      }

      // If we have connectivity, try to sync
      final connectivityService = _ref.read(connectivityServiceProvider);
      if (connectivityService.isOnline && hasLocalData) {
        if (kDebugMode) {
          print('🔄 Triggering data sync...');
        }
        // Sync will happen in the background via offline sync service
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ User data loading encountered issues: $e');
      }
      ErrorHandlingService().handleBusinessError(
        'User data loading failed: $e',
        context: 'AppInitializationService._loadUserData',
      );
      // Continue - user can still use the app
    }
  }

  /// Get initialization metadata
  Future<Map<String, dynamic>> _getInitializationMetadata() async {
    try {
      final connectivityService = _ref.read(connectivityServiceProvider);
      final syncService = _ref.read(offlineSyncServiceProvider);
      
      return {
        'initializationTime': DateTime.now().toIso8601String(),
        'environment': 'production', // EnvironmentConfig.environment.name,
        'hasLocalData': LocalStorageService.hasLocalData(),
        'localDataCounts': LocalStorageService.getDataCounts(),
        'connectivity': connectivityService.getConnectivityStats(),
        'syncStats': syncService.getSyncStatistics(),
        'lastSyncTime': LocalStorageService.getLastSyncTime()?.toIso8601String(),
        'version': '1.0.0', // You can get this from package_info_plus
      };
    } catch (e) {
      return {
        'initializationTime': DateTime.now().toIso8601String(),
        'error': 'Failed to collect metadata: $e',
      };
    }
  }

  /// Perform health check
  Future<Map<String, dynamic>> performHealthCheck() async {
    final results = <String, dynamic>{};

    try {
      // Check error handling
      results['errorHandling'] = {
        'status': 'healthy',
        'errorCount': ErrorHandlingService().errorHistory.length,
      };
    } catch (e) {
      results['errorHandling'] = {
        'status': 'error',
        'error': e.toString(),
      };
    }

    try {
      // Check local storage
      results['localStorage'] = {
        'status': LocalStorageService.hasLocalData() ? 'healthy' : 'empty',
        'dataCounts': LocalStorageService.getDataCounts(),
      };
    } catch (e) {
      results['localStorage'] = {
        'status': 'error',
        'error': e.toString(),
      };
    }

    try {
      // Check connectivity
      final connectivityService = _ref.read(connectivityServiceProvider);
      results['connectivity'] = {
        'status': connectivityService.isOnline ? 'online' : 'offline',
        'stats': connectivityService.getConnectivityStats(),
      };
    } catch (e) {
      results['connectivity'] = {
        'status': 'error',
        'error': e.toString(),
      };
    }

    try {
      // Check sync service
      final syncService = _ref.read(offlineSyncServiceProvider);
      results['syncService'] = {
        'status': syncService.isSyncNeeded() ? 'pending' : 'up-to-date',
        'stats': syncService.getSyncStatistics(),
      };
    } catch (e) {
      results['syncService'] = {
        'status': 'error',
        'error': e.toString(),
      };
    }

    results['overall'] = {
      'status': results.values.any((r) => r['status'] == 'error') ? 'degraded' : 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
    };

    return results;
  }

  /// Restart app components
  Future<void> restartComponents() async {
    try {
      if (kDebugMode) {
        print('🔄 Restarting app components...');
      }

      // Restart connectivity service
      final connectivityService = _ref.read(connectivityServiceProvider);
      await connectivityService.initialize();

      // Clear error history
      ErrorHandlingService().clearErrorHistory();

      if (kDebugMode) {
        print('✅ App components restarted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Component restart failed: $e');
      }
      ErrorHandlingService().handleBusinessError(
        'Component restart failed: $e',
        context: 'AppInitializationService.restartComponents',
      );
      rethrow;
    }
  }
}