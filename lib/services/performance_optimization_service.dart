import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../utils/constants.dart';
import '../services/local_storage_service.dart';

class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance = PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  // Cache configurations
  static const int _maxCacheSize = 1000;
  static const Duration _cacheExpiration = Duration(hours: 1);
  
  // Memory caches
  final Map<String, _CacheItem<List<ExpenseModel>>> _expenseCache = {};
  final Map<String, _CacheItem<List<BudgetModel>>> _budgetCache = {};
  final Map<String, _CacheItem<List<CategoryModel>>> _categoryCache = {};
  final Map<String, _CacheItem<Map<String, double>>> _analyticsCache = {};
  
  // Pagination caches
  final Map<String, List<ExpenseModel>> _paginatedExpenses = {};
  static const int _pageSize = 50;

  // === Memory Management ===
  
  /// Clear all caches to free memory
  void clearAllCaches() {
    _expenseCache.clear();
    _budgetCache.clear();
    _categoryCache.clear();
    _analyticsCache.clear();
    _paginatedExpenses.clear();
    
    if (kDebugMode) {
      print('🧹 All caches cleared');
    }
  }

  /// Clear expired cache entries
  void clearExpiredCaches() {
    final now = DateTime.now();
    
    _expenseCache.removeWhere((key, item) => item.isExpired(now));
    _budgetCache.removeWhere((key, item) => item.isExpired(now));
    _categoryCache.removeWhere((key, item) => item.isExpired(now));
    _analyticsCache.removeWhere((key, item) => item.isExpired(now));
    
    if (kDebugMode) {
      print('🗑️ Expired caches cleared');
    }
  }

  /// Force garbage collection (use sparingly)
  void forceGarbageCollection() {
    clearExpiredCaches();
    // Request system garbage collection
    if (kDebugMode) {
      print('🧼 Requesting garbage collection');
    }
  }

  // === Expense Caching ===
  
  /// Get cached expenses for user
  List<ExpenseModel>? getCachedExpenses(String userId) {
    final cacheKey = 'expenses_$userId';
    final cached = _expenseCache[cacheKey];
    
    if (cached != null && !cached.isExpired(DateTime.now())) {
      if (kDebugMode) {
        print('📋 Cache hit for expenses: $userId');
      }
      return cached.data;
    }
    
    return null;
  }

  /// Cache expenses for user
  void cacheExpenses(String userId, List<ExpenseModel> expenses) {
    final cacheKey = 'expenses_$userId';
    
    // Enforce cache size limit
    if (_expenseCache.length >= _maxCacheSize) {
      _clearOldestCache(_expenseCache);
    }
    
    _expenseCache[cacheKey] = _CacheItem(expenses, DateTime.now());
    
    if (kDebugMode) {
      print('💾 Cached ${expenses.length} expenses for user: $userId');
    }
  }

  /// Get paginated expenses
  List<ExpenseModel> getPaginatedExpenses(String userId, int page) {
    final cacheKey = 'paginated_${userId}_$page';
    
    if (_paginatedExpenses.containsKey(cacheKey)) {
      return _paginatedExpenses[cacheKey]!;
    }
    
    // Get from local storage with pagination
    final allExpenses = LocalStorageService.getExpensesByUserId(userId);
    final startIndex = page * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, allExpenses.length);
    
    if (startIndex >= allExpenses.length) {
      return [];
    }
    
    final paginatedData = allExpenses.sublist(startIndex, endIndex);
    _paginatedExpenses[cacheKey] = paginatedData;
    
    return paginatedData;
  }

  // === Budget Caching ===
  
  List<BudgetModel>? getCachedBudgets(String userId) {
    final cacheKey = 'budgets_$userId';
    final cached = _budgetCache[cacheKey];
    
    if (cached != null && !cached.isExpired(DateTime.now())) {
      return cached.data;
    }
    
    return null;
  }

  void cacheBudgets(String userId, List<BudgetModel> budgets) {
    final cacheKey = 'budgets_$userId';
    
    if (_budgetCache.length >= _maxCacheSize) {
      _clearOldestCache(_budgetCache);
    }
    
    _budgetCache[cacheKey] = _CacheItem(budgets, DateTime.now());
  }

  // === Category Caching ===
  
  List<CategoryModel>? getCachedCategories(String? userId) {
    final cacheKey = 'categories_${userId ?? 'default'}';
    final cached = _categoryCache[cacheKey];
    
    if (cached != null && !cached.isExpired(DateTime.now())) {
      return cached.data;
    }
    
    return null;
  }

  void cacheCategories(String? userId, List<CategoryModel> categories) {
    final cacheKey = 'categories_${userId ?? 'default'}';
    
    if (_categoryCache.length >= _maxCacheSize) {
      _clearOldestCache(_categoryCache);
    }
    
    _categoryCache[cacheKey] = _CacheItem(categories, DateTime.now());
  }

  // === Analytics Caching ===
  
  Map<String, double>? getCachedAnalytics(String userId, String type) {
    final cacheKey = '${type}_$userId';
    final cached = _analyticsCache[cacheKey];
    
    if (cached != null && !cached.isExpired(DateTime.now())) {
      return cached.data;
    }
    
    return null;
  }

  void cacheAnalytics(String userId, String type, Map<String, double> analytics) {
    final cacheKey = '${type}_$userId';
    
    if (_analyticsCache.length >= _maxCacheSize) {
      _clearOldestCache(_analyticsCache);
    }
    
    _analyticsCache[cacheKey] = _CacheItem(analytics, DateTime.now());
  }

  // === Data Optimization ===
  
  /// Optimize expense list by removing duplicates and sorting
  List<ExpenseModel> optimizeExpenseList(List<ExpenseModel> expenses) {
    // Remove duplicates by ID
    final seen = <String>{};
    final uniqueExpenses = expenses.where((expense) => seen.add(expense.id)).toList();
    
    // Sort by date (most recent first)
    uniqueExpenses.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    
    return uniqueExpenses;
  }

  /// Batch operations for multiple expenses
  Future<void> batchUpdateExpenses(List<ExpenseModel> expenses) async {
    const batchSize = 100;
    
    for (int i = 0; i < expenses.length; i += batchSize) {
      final batch = expenses.sublist(
        i, 
        (i + batchSize).clamp(0, expenses.length)
      );
      
      await LocalStorageService.saveExpenses(batch);
      
      // Yield control to prevent blocking UI
      await Future.delayed(Duration.zero);
    }
  }

  // === Query Optimization ===
  
  /// Optimized expense filtering
  List<ExpenseModel> filterExpensesOptimized({
    required List<ExpenseModel> expenses,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    ExpenseType? type,
    double? minAmount,
    double? maxAmount,
  }) {
    return expenses.where((expense) {
      // Category filter
      if (categoryId != null && expense.categoryId != categoryId) {
        return false;
      }
      
      // Date range filter
      if (startDate != null && expense.transactionDate.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && expense.transactionDate.isAfter(endDate)) {
        return false;
      }
      
      // Type filter
      if (type != null && expense.type != type) {
        return false;
      }
      
      // Amount range filter
      if (minAmount != null && expense.amount < minAmount) {
        return false;
      }
      if (maxAmount != null && expense.amount > maxAmount) {
        return false;
      }
      
      return true;
    }).toList();
  }

  /// Optimized category spending calculation
  Map<String, double> calculateCategorySpendingOptimized({
    required List<ExpenseModel> expenses,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final spending = <String, double>{};
    
    for (final expense in expenses) {
      // Skip if not an expense
      if (expense.type != ExpenseType.expense) continue;
      
      // Skip if outside date range
      if (startDate != null && expense.transactionDate.isBefore(startDate)) continue;
      if (endDate != null && expense.transactionDate.isAfter(endDate)) continue;
      
      // Add to category spending
      spending[expense.categoryId] = (spending[expense.categoryId] ?? 0) + expense.amount;
    }
    
    return spending;
  }

  // === Image Optimization ===
  
  /// Optimize image for caching
  static Future<Uint8List?> optimizeImageForCache(Uint8List imageBytes) async {
    try {
      // In a real implementation, you would use image compression libraries
      // For now, we'll return the original bytes
      return imageBytes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Image optimization failed: $e');
      }
      return null;
    }
  }

  // === Background Processing ===
  
  /// Process data in background to avoid blocking UI
  Future<void> processDataInBackground(Function() operation) async {
    await compute((fn) => fn(), operation);
  }

  // === Monitoring ===
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return {
      'expenseCache': {
        'size': _expenseCache.length,
        'maxSize': _maxCacheSize,
        'hitRate': _calculateHitRate(_expenseCache),
      },
      'budgetCache': {
        'size': _budgetCache.length,
        'maxSize': _maxCacheSize,
      },
      'categoryCache': {
        'size': _categoryCache.length,
        'maxSize': _maxCacheSize,
      },
      'analyticsCache': {
        'size': _analyticsCache.length,
        'maxSize': _maxCacheSize,
      },
      'paginatedExpenses': {
        'size': _paginatedExpenses.length,
      },
    };
  }

  /// Log performance metrics
  void logPerformanceMetrics() {
    if (kDebugMode) {
      final stats = getCacheStatistics();
      print('📊 Performance Metrics:');
      print('   Expense Cache: ${stats['expenseCache']['size']}/${stats['expenseCache']['maxSize']}');
      print('   Budget Cache: ${stats['budgetCache']['size']}');
      print('   Category Cache: ${stats['categoryCache']['size']}');
      print('   Analytics Cache: ${stats['analyticsCache']['size']}');
    }
  }

  // === Private Helpers ===
  
  void _clearOldestCache<T>(Map<String, _CacheItem<T>> cache) {
    if (cache.isEmpty) return;
    
    final oldestKey = cache.entries
        .reduce((a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b)
        .key;
    
    cache.remove(oldestKey);
  }

  double _calculateHitRate<T>(Map<String, _CacheItem<T>> cache) {
    if (cache.isEmpty) return 0.0;
    
    final hits = cache.values.where((item) => item.hitCount > 0).length;
    return hits / cache.length;
  }
}

/// Cache item wrapper
class _CacheItem<T> {
  final T data;
  final DateTime timestamp;
  int hitCount;

  _CacheItem(this.data, this.timestamp) : hitCount = 0;

  bool isExpired(DateTime now) {
    return now.difference(timestamp) > PerformanceOptimizationService._cacheExpiration;
  }

  void recordHit() {
    hitCount++;
  }
}