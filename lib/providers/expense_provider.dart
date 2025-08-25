import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../services/performance_optimization_service.dart';
import '../utils/constants.dart';
import 'auth_provider.dart';

// Expense service provider
final expenseServiceProvider = Provider<ExpenseService>((ref) => ExpenseService());

// Expenses provider - simplified
final expensesProvider = StateNotifierProvider<ExpensesNotifier, AsyncValue<List<ExpenseModel>>>((ref) {
  return ExpensesNotifier(ref);
});

class ExpensesNotifier extends StateNotifier<AsyncValue<List<ExpenseModel>>> {
  ExpensesNotifier(this._ref) : super(const AsyncValue.data([])) {
    _loadExpenses();
  }

  final Ref _ref;
  ExpenseService get _expenseService => _ref.read(expenseServiceProvider);
  final _performanceService = PerformanceOptimizationService();

  Future<void> _loadExpenses() async {
    try {
      state = const AsyncValue.loading();
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      // Try to get from cache first
      final cachedExpenses = _performanceService.getCachedExpenses(userId);
      if (cachedExpenses != null) {
        state = AsyncValue.data(cachedExpenses);
        // Still load fresh data in background
        _loadFreshData(userId);
        return;
      }

      // Load fresh data
      await _loadFreshData(userId);
    } catch (error, stack) {
      // Try to load from local storage as fallback
      final userId = _ref.read(currentUserIdProvider);
      if (userId != null) {
        final offlineExpenses = _expenseService.getOfflineExpenses(userId);
        final optimizedExpenses = _performanceService.optimizeExpenseList(offlineExpenses);
        state = AsyncValue.data(optimizedExpenses);
      } else {
        state = AsyncValue.error(error, stack);
      }
    }
  }

  Future<void> _loadFreshData(String userId) async {
    final expenses = await _expenseService.getExpensesForUser(userId);
    final optimizedExpenses = _performanceService.optimizeExpenseList(expenses);
    
    // Cache the data
    _performanceService.cacheExpenses(userId, optimizedExpenses);
    
    state = AsyncValue.data(optimizedExpenses);
  }

  Future<void> refreshExpenses() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId != null) {
      // Clear cache to force fresh data
      _performanceService.clearExpiredCaches();
      await _loadFreshData(userId);
    }
  }

  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    try {
      final addedExpense = await _expenseService.addExpense(expense);
      
      // Optimistically update the state
      final currentExpenses = state.value ?? [];
      final updatedExpenses = [addedExpense, ...currentExpenses];
      final optimizedExpenses = _performanceService.optimizeExpenseList(updatedExpenses);
      state = AsyncValue.data(optimizedExpenses);
      
      // Update cache
      final userId = _ref.read(currentUserIdProvider);
      if (userId != null) {
        _performanceService.cacheExpenses(userId, optimizedExpenses);
      }
      
      return addedExpense;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      rethrow;
    }
  }

  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    try {
      final updatedExpense = await _expenseService.updateExpense(expense);
      
      // Update the state optimistically
      final currentExpenses = state.value ?? [];
      final updatedExpenses = currentExpenses.map((e) {
        return e.id == expense.id ? updatedExpense : e;
      }).toList();
      final optimizedExpenses = _performanceService.optimizeExpenseList(updatedExpenses);
      state = AsyncValue.data(optimizedExpenses);
      
      // Update cache
      final userId = _ref.read(currentUserIdProvider);
      if (userId != null) {
        _performanceService.cacheExpenses(userId, optimizedExpenses);
      }
      
      return updatedExpense;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await _expenseService.deleteExpense(expenseId);
      
      // Update the state optimistically
      final currentExpenses = state.value ?? [];
      final updatedExpenses = currentExpenses.where((e) => e.id != expenseId).toList();
      state = AsyncValue.data(updatedExpenses);
      
      // Update cache
      final userId = _ref.read(currentUserIdProvider);
      if (userId != null) {
        _performanceService.cacheExpenses(userId, updatedExpenses);
      }
    } catch (error, stack) {
      state = AsyncError(error, stack);
      rethrow;
    }
  }

  /// Get paginated expenses for better performance with large datasets
  List<ExpenseModel> getPaginatedExpenses(int page) {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return [];
    
    return _performanceService.getPaginatedExpenses(userId, page);
  }

  /// Filter expenses efficiently
  List<ExpenseModel> filterExpenses({
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    ExpenseType? type,
    double? minAmount,
    double? maxAmount,
  }) {
    final currentExpenses = state.value ?? [];
    
    return _performanceService.filterExpensesOptimized(
      expenses: currentExpenses,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
      type: type,
      minAmount: minAmount,
      maxAmount: maxAmount,
    );
  }

  /// Get cache statistics for monitoring
  Map<String, dynamic> getCacheStatistics() {
    return _performanceService.getCacheStatistics();
  }
}

// Recent expenses provider (last 10) - simplified
final recentExpensesProvider = Provider<AsyncValue<List<ExpenseModel>>>((ref) {
  final allExpenses = ref.watch(expensesProvider);
  return allExpenses.when(
    data: (expenses) => AsyncValue.data(expenses.take(10).toList()),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Current month expenses provider - simplified
final currentMonthExpensesProvider = Provider<AsyncValue<List<ExpenseModel>>>((ref) {
  final allExpenses = ref.watch(expensesProvider);
  
  return allExpenses.when(
    data: (expenses) {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      
      final filteredExpenses = expenses
          .where((expense) =>
              expense.transactionDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
              expense.transactionDate.isBefore(endOfMonth.add(const Duration(days: 1))))
          .toList();
      
      return AsyncValue.data(filteredExpenses);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Current month total spending provider - simplified
final currentMonthSpendingProvider = Provider<AsyncValue<double>>((ref) {
  final monthlyExpenses = ref.watch(currentMonthExpensesProvider);
  
  return monthlyExpenses.when(
    data: (expenses) {
      double total = 0.0;
      for (final expense in expenses) {
        if (expense.type == ExpenseType.expense) {
          total += expense.amount;
        }
      }
      return AsyncValue.data(total);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Current month income provider - simplified
final currentMonthIncomeProvider = Provider<AsyncValue<double>>((ref) {
  final monthlyExpenses = ref.watch(currentMonthExpensesProvider);
  
  return monthlyExpenses.when(
    data: (expenses) {
      double total = 0.0;
      for (final expense in expenses) {
        if (expense.type == ExpenseType.income) {
          total += expense.amount;
        }
      }
      return AsyncValue.data(total);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Helper classes
class MonthYear {
  final int month;
  final int year;

  MonthYear({required this.month, required this.year});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthYear && runtimeType == other.runtimeType && month == other.month && year == other.year;

  @override
  int get hashCode => month.hashCode ^ year.hashCode;
}

class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange({required this.startDate, required this.endDate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange && runtimeType == other.runtimeType && startDate == other.startDate && endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}

class ExpensePeriodQuery {
  final DateTime startDate;
  final DateTime endDate;
  final String? categoryId;
  final ExpenseType? type;

  ExpensePeriodQuery({
    required this.startDate,
    required this.endDate,
    this.categoryId,
    this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpensePeriodQuery &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          categoryId == other.categoryId &&
          type == other.type;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode ^ categoryId.hashCode ^ type.hashCode;
}
