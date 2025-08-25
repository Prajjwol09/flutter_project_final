import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/goal_model.dart';
import 'local_storage_service.dart';
import 'expense_service.dart';
import 'budget_service.dart';
import 'category_service.dart';
import 'goal_service.dart';
import 'connectivity_service.dart';
import 'error_handling_service.dart';

// Offline sync service provider
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(ref);
});

// Sync status provider
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier();
});

enum SyncOperation {
  create,
  update,
  delete,
}

enum SyncItemType {
  expense,
  budget,
  category,
  goal,
}

enum SyncStatusState {
  idle,
  syncing,
  success,
  error,
  partial,
}

class SyncStatus {
  final SyncStatusState state;
  final String? message;
  final int totalItems;
  final int syncedItems;
  final int failedItems;
  final DateTime? lastSyncTime;
  final List<SyncError> errors;

  const SyncStatus({
    required this.state,
    this.message,
    this.totalItems = 0,
    this.syncedItems = 0,
    this.failedItems = 0,
    this.lastSyncTime,
    this.errors = const [],
  });

  SyncStatus copyWith({
    SyncStatusState? state,
    String? message,
    int? totalItems,
    int? syncedItems,
    int? failedItems,
    DateTime? lastSyncTime,
    List<SyncError>? errors,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      message: message ?? this.message,
      totalItems: totalItems ?? this.totalItems,
      syncedItems: syncedItems ?? this.syncedItems,
      failedItems: failedItems ?? this.failedItems,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errors: errors ?? this.errors,
    );
  }

  double get progress {
    if (totalItems == 0) return 0.0;
    return syncedItems / totalItems;
  }

  bool get hasErrors => errors.isNotEmpty;
  bool get isComplete => syncedItems + failedItems >= totalItems;
}

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier() : super(const SyncStatus(state: SyncStatusState.idle));

  void updateState(SyncStatus newState) {
    state = newState;
  }

  void reset() {
    state = const SyncStatus(state: SyncStatusState.idle);
  }
}

class SyncError {
  final SyncItemType itemType;
  final String itemId;
  final SyncOperation operation;
  final String error;
  final DateTime timestamp;

  const SyncError({
    required this.itemType,
    required this.itemId,
    required this.operation,
    required this.error,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemType': itemType.name,
      'itemId': itemId,
      'operation': operation.name,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SyncError.fromJson(Map<String, dynamic> json) {
    return SyncError(
      itemType: SyncItemType.values.firstWhere((e) => e.name == json['itemType']),
      itemId: json['itemId'],
      operation: SyncOperation.values.firstWhere((e) => e.name == json['operation']),
      error: json['error'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class PendingSyncItem {
  final String id;
  final SyncItemType type;
  final SyncOperation operation;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  const PendingSyncItem({
    required this.id,
    required this.type,
    required this.operation,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  PendingSyncItem copyWith({
    int? retryCount,
  }) {
    return PendingSyncItem(
      id: id,
      type: type,
      operation: operation,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'operation': operation.name,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory PendingSyncItem.fromJson(Map<String, dynamic> json) {
    return PendingSyncItem(
      id: json['id'],
      type: SyncItemType.values.firstWhere((e) => e.name == json['type']),
      operation: SyncOperation.values.firstWhere((e) => e.name == json['operation']),
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

class OfflineSyncService {
  final Ref _ref;
  final List<PendingSyncItem> _pendingItems = [];
  final StreamController<SyncStatus> _syncStatusController = StreamController<SyncStatus>.broadcast();
  
  static const int _maxRetries = 3;
  static const Duration _syncInterval = Duration(minutes: 5);
  Timer? _syncTimer;
  bool _isSyncing = false;

  OfflineSyncService(this._ref) {
    _initializeSync();
  }

  /// Initialize synchronization
  void _initializeSync() {
    // Load pending items from storage
    _loadPendingItems();

    // Listen to connectivity changes
    _ref.read(connectivityServiceProvider).connectivityStream.listen((state) {
      if (state.isOnline && _pendingItems.isNotEmpty) {
        _scheduleSyncWhenOnline();
      }
    });

    // Start periodic sync timer
    _startPeriodicSync();
  }

  /// Load pending sync items from local storage
  void _loadPendingItems() {
    try {
      // This would load from a dedicated sync queue in local storage
      // For now, we'll manage it in memory
      if (kDebugMode) {
        print('📦 Loading pending sync items...');
      }
    } catch (e) {
      ErrorHandlingService().handleBusinessError(
        'Failed to load pending sync items: $e',
        context: 'OfflineSyncService._loadPendingItems',
      );
    }
  }

  /// Add item to sync queue
  Future<void> addToSyncQueue({
    required String id,
    required SyncItemType type,
    required SyncOperation operation,
    required Map<String, dynamic> data,
  }) async {
    try {
      final item = PendingSyncItem(
        id: id,
        type: type,
        operation: operation,
        data: data,
        timestamp: DateTime.now(),
      );

      _pendingItems.add(item);

      if (kDebugMode) {
        print('➕ Added to sync queue: ${type.name} ${operation.name} $id');
      }

      // Try to sync immediately if online
      final connectivityService = _ref.read(connectivityServiceProvider);
      if (connectivityService.isOnline) {
        _scheduleSyncWhenOnline();
      }
    } catch (e) {
      ErrorHandlingService().handleBusinessError(
        'Failed to add item to sync queue: $e',
        context: 'OfflineSyncService.addToSyncQueue',
        metadata: {
          'id': id,
          'type': type.name,
          'operation': operation.name,
        },
      );
    }
  }

  /// Schedule sync when online
  void _scheduleSyncWhenOnline() {
    if (_isSyncing) return;

    // Small delay to batch multiple operations
    Future.delayed(const Duration(seconds: 2), () {
      if (!_isSyncing) {
        syncPendingItems();
      }
    });
  }

  /// Start periodic sync
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      final connectivityService = _ref.read(connectivityServiceProvider);
      if (connectivityService.isOnline && _pendingItems.isNotEmpty) {
        syncPendingItems();
      }
    });
  }

  /// Sync all pending items
  Future<void> syncPendingItems() async {
    if (_isSyncing || _pendingItems.isEmpty) return;

    _isSyncing = true;
    final syncStatusNotifier = _ref.read(syncStatusProvider.notifier);

    try {
      if (kDebugMode) {
        print('🔄 Starting sync: ${_pendingItems.length} items');
      }

      syncStatusNotifier.updateState(SyncStatus(
        state: SyncStatusState.syncing,
        message: 'Syncing ${_pendingItems.length} items...',
        totalItems: _pendingItems.length,
      ));

      final errors = <SyncError>[];
      int syncedCount = 0;
      int failedCount = 0;

      final itemsToProcess = List<PendingSyncItem>.from(_pendingItems);

      for (final item in itemsToProcess) {
        try {
          await _syncSingleItem(item);
          _pendingItems.remove(item);
          syncedCount++;

          // Update progress
          syncStatusNotifier.updateState(SyncStatus(
            state: SyncStatusState.syncing,
            message: 'Syncing... ${syncedCount}/${itemsToProcess.length}',
            totalItems: itemsToProcess.length,
            syncedItems: syncedCount,
            failedItems: failedCount,
          ));
        } catch (e) {
          failedCount++;
          final syncError = SyncError(
            itemType: item.type,
            itemId: item.id,
            operation: item.operation,
            error: e.toString(),
            timestamp: DateTime.now(),
          );
          errors.add(syncError);

          // Retry logic
          if (item.retryCount < _maxRetries) {
            final updatedItem = item.copyWith(retryCount: item.retryCount + 1);
            final index = _pendingItems.indexOf(item);
            if (index >= 0) {
              _pendingItems[index] = updatedItem;
            }
          } else {
            // Max retries reached, remove from queue
            _pendingItems.remove(item);
            if (kDebugMode) {
              print('❌ Max retries reached for ${item.type.name} ${item.id}');
            }
          }
        }
      }

      // Update final status
      final finalState = errors.isEmpty 
          ? SyncStatusState.success 
          : (syncedCount > 0 ? SyncStatusState.partial : SyncStatusState.error);

      syncStatusNotifier.updateState(SyncStatus(
        state: finalState,
        message: _getSyncResultMessage(syncedCount, failedCount),
        totalItems: itemsToProcess.length,
        syncedItems: syncedCount,
        failedItems: failedCount,
        lastSyncTime: DateTime.now(),
        errors: errors,
      ));

      if (kDebugMode) {
        print('✅ Sync completed: $syncedCount synced, $failedCount failed');
      }
    } catch (e) {
      syncStatusNotifier.updateState(SyncStatus(
        state: SyncStatusState.error,
        message: 'Sync failed: $e',
        lastSyncTime: DateTime.now(),
      ));

      ErrorHandlingService().handleBusinessError(
        'Sync process failed: $e',
        context: 'OfflineSyncService.syncPendingItems',
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single item
  Future<void> _syncSingleItem(PendingSyncItem item) async {
    switch (item.type) {
      case SyncItemType.expense:
        await _syncExpenseItem(item);
        break;
      case SyncItemType.budget:
        await _syncBudgetItem(item);
        break;
      case SyncItemType.category:
        await _syncCategoryItem(item);
        break;
      case SyncItemType.goal:
        await _syncGoalItem(item);
        break;
    }
  }

  /// Sync expense item
  Future<void> _syncExpenseItem(PendingSyncItem item) async {
    final expenseService = ExpenseService();
    
    switch (item.operation) {
      case SyncOperation.create:
        final expense = ExpenseModel.fromJson(item.data);
        await expenseService.addExpense(expense);
        break;
      case SyncOperation.update:
        final expense = ExpenseModel.fromJson(item.data);
        await expenseService.updateExpense(expense);
        break;
      case SyncOperation.delete:
        await expenseService.deleteExpense(item.id);
        break;
    }
  }

  /// Sync budget item
  Future<void> _syncBudgetItem(PendingSyncItem item) async {
    final budgetService = BudgetService();
    
    switch (item.operation) {
      case SyncOperation.create:
        final budget = BudgetModel.fromJson(item.data);
        await budgetService.addBudget(budget);
        break;
      case SyncOperation.update:
        final budget = BudgetModel.fromJson(item.data);
        await budgetService.updateBudget(budget);
        break;
      case SyncOperation.delete:
        await budgetService.deleteBudget(item.id);
        break;
    }
  }

  /// Sync category item
  Future<void> _syncCategoryItem(PendingSyncItem item) async {
    final categoryService = CategoryService();
    
    switch (item.operation) {
      case SyncOperation.create:
        final category = CategoryModel.fromJson(item.data);
        await categoryService.addCategory(category);
        break;
      case SyncOperation.update:
        final category = CategoryModel.fromJson(item.data);
        await categoryService.updateCategory(category);
        break;
      case SyncOperation.delete:
        await categoryService.deleteCategory(item.id);
        break;
    }
  }

  /// Sync goal item
  Future<void> _syncGoalItem(PendingSyncItem item) async {
    final goalService = GoalService();
    
    switch (item.operation) {
      case SyncOperation.create:
        final goal = GoalModel.fromJson(item.data);
        await goalService.addGoal(goal);
        break;
      case SyncOperation.update:
        final goal = GoalModel.fromJson(item.data);
        await goalService.updateGoal(goal);
        break;
      case SyncOperation.delete:
        await goalService.deleteGoal(item.id);
        break;
    }
  }

  /// Get sync result message
  String _getSyncResultMessage(int synced, int failed) {
    if (failed == 0) {
      return 'All $synced items synced successfully';
    } else if (synced == 0) {
      return 'Failed to sync $failed items';
    } else {
      return '$synced items synced, $failed failed';
    }
  }

  /// Force sync all data
  Future<void> forceSyncAll(String userId) async {
    try {
      if (kDebugMode) {
        print('🔄 Force syncing all data for user: $userId');
      }

      // Sync all services
      await Future.wait([
        ExpenseService().syncLocalData(userId),
        BudgetService().syncLocalData(userId),
        CategoryService().syncLocalData(userId),
        GoalService().syncLocalData(userId),
      ]);

      // Update last sync time
      await LocalStorageService.setLastSyncTime(DateTime.now());
      
      if (kDebugMode) {
        print('✅ Force sync completed');
      }
    } catch (e) {
      ErrorHandlingService().handleBusinessError(
        'Force sync failed: $e',
        context: 'OfflineSyncService.forceSyncAll',
        metadata: {'userId': userId},
      );
      rethrow;
    }
  }

  /// Check if sync is needed
  bool isSyncNeeded() {
    return _pendingItems.isNotEmpty;
  }

  /// Get pending items count
  int getPendingItemsCount() {
    return _pendingItems.length;
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    final typeStats = <String, int>{};
    final operationStats = <String, int>{};

    for (final item in _pendingItems) {
      typeStats[item.type.name] = (typeStats[item.type.name] ?? 0) + 1;
      operationStats[item.operation.name] = (operationStats[item.operation.name] ?? 0) + 1;
    }

    return {
      'totalPendingItems': _pendingItems.length,
      'isSyncing': _isSyncing,
      'pendingByType': typeStats,
      'pendingByOperation': operationStats,
      'lastSyncTime': LocalStorageService.getLastSyncTime()?.toIso8601String(),
    };
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
  }
}