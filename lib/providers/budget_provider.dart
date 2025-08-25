import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_model.dart';
import '../services/budget_service.dart';
import '../utils/constants.dart';
import 'auth_provider.dart';

// Budget service provider
final budgetServiceProvider = Provider<BudgetService>((ref) => BudgetService());

// Budgets provider
final budgetsProvider = StateNotifierProvider<BudgetsNotifier, AsyncValue<List<BudgetModel>>>((ref) {
  return BudgetsNotifier(ref);
});

class BudgetsNotifier extends StateNotifier<AsyncValue<List<BudgetModel>>> {
  BudgetsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadBudgets();
  }

  final Ref _ref;
  BudgetService get _budgetService => _ref.read(budgetServiceProvider);

  Future<void> _loadBudgets() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final budgets = await _budgetService.getBudgetsForUser(userId);
      state = AsyncValue.data(budgets);
    } catch (error, _) {
      // Try to load from local storage
      final localBudgets = _budgetService.getOfflineBudgets(userId);
      state = AsyncValue.data(localBudgets);
    }
  }

  Future<void> refreshBudgets() async {
    await _loadBudgets();
  }

  Future<BudgetModel> addBudget(BudgetModel budget) async {
    try {
      final addedBudget = await _budgetService.addBudget(budget);
      
      // Update the state with the new budget
      final currentBudgets = state.value ?? [];
      final updatedBudgets = [addedBudget, ...currentBudgets];
      state = AsyncValue.data(updatedBudgets);
      
      return addedBudget;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<BudgetModel> updateBudget(BudgetModel budget) async {
    try {
      final updatedBudget = await _budgetService.updateBudget(budget);
      
      // Update the state
      final currentBudgets = state.value ?? [];
      final updatedBudgets = currentBudgets.map((b) {
        return b.id == budget.id ? updatedBudget : b;
      }).toList();
      state = AsyncValue.data(updatedBudgets);
      
      return updatedBudget;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    try {
      await _budgetService.deleteBudget(budgetId);
      
      // Update the state
      final currentBudgets = state.value ?? [];
      final updatedBudgets = currentBudgets.where((b) => b.id != budgetId).toList();
      state = AsyncValue.data(updatedBudgets);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<bool> budgetExistsForCategoryAndPeriod({
    required String categoryId,
    required DateTime startDate,
    required DateTime endDate,
    String? excludeBudgetId,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return false;

    return _budgetService.budgetExistsForCategoryAndPeriod(
      userId: userId,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
      excludeBudgetId: excludeBudgetId,
    );
  }

  Future<double> getRecommendedBudgetAmount({
    required String categoryId,
    required BudgetPeriod period,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return 0.0;

    return _budgetService.getRecommendedBudgetAmount(
      userId: userId,
      categoryId: categoryId,
      period: period,
    );
  }
}

// Active budgets provider
final activeBudgetsProvider = FutureProvider<List<BudgetModel>>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return [];

  final budgetService = ref.read(budgetServiceProvider);
  return budgetService.getActiveBudgetsForUser(userId);
});

// Budget by ID provider
final budgetByIdProvider = FutureProvider.family<BudgetModel?, String>((ref, budgetId) async {
  final budgetService = ref.read(budgetServiceProvider);
  return budgetService.getBudgetById(budgetId);
});

// Budget for category provider
final budgetForCategoryProvider = FutureProvider.family<BudgetModel?, BudgetCategoryQuery>((ref, query) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return null;

  final budgetService = ref.read(budgetServiceProvider);
  return budgetService.getBudgetForCategory(
    userId: userId,
    categoryId: query.categoryId,
    date: query.date,
  );
});

// Budget spending status provider
final budgetSpendingStatusProvider = FutureProvider.family<BudgetSpendingStatus, BudgetModel>((ref, budget) async {
  final budgetService = ref.read(budgetServiceProvider);
  return budgetService.getBudgetSpendingStatus(budget);
});

// All budget statuses provider
final allBudgetStatusesProvider = FutureProvider<List<BudgetSpendingStatus>>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return [];

  final budgetService = ref.read(budgetServiceProvider);
  return budgetService.getAllBudgetStatuses(userId);
});

// Current month budgets provider
final currentMonthBudgetsProvider = Provider<List<BudgetModel>>((ref) {
  final budgets = ref.watch(budgetsProvider);
  if (budgets.value == null) return [];

  return budgets.value!.where((budget) {
    return budget.isActive && budget.isCurrentPeriod;
  }).toList();
});

// Over-budget budgets provider
final overBudgetProvider = FutureProvider<List<BudgetSpendingStatus>>((ref) async {
  final statuses = await ref.watch(allBudgetStatusesProvider.future);
  return statuses.where((status) => status.isOverBudget).toList();
});

// Near-limit budgets provider
final nearLimitBudgetsProvider = FutureProvider<List<BudgetSpendingStatus>>((ref) async {
  final statuses = await ref.watch(allBudgetStatusesProvider.future);
  return statuses.where((status) => status.isNearLimit && !status.isOverBudget).toList();
});

// Budget summary provider
final budgetSummaryProvider = FutureProvider<BudgetSummary>((ref) async {
  final statuses = await ref.watch(allBudgetStatusesProvider.future);
  
  double totalBudget = 0;
  double totalSpent = 0;
  int activeBudgets = 0;
  int overBudgetCount = 0;
  int nearLimitCount = 0;

  for (final status in statuses) {
    totalBudget += status.budget.amount;
    totalSpent += status.spentAmount;
    activeBudgets++;
    
    if (status.isOverBudget) {
      overBudgetCount++;
    } else if (status.isNearLimit) {
      nearLimitCount++;
    }
  }

  return BudgetSummary(
    totalBudget: totalBudget,
    totalSpent: totalSpent,
    activeBudgets: activeBudgets,
    overBudgetCount: overBudgetCount,
    nearLimitCount: nearLimitCount,
    remainingBudget: totalBudget - totalSpent,
  );
});

// Recommended budget amount provider
final recommendedBudgetAmountProvider = FutureProvider.family<double, BudgetRecommendationQuery>((ref, query) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return 0.0;

  final budgetService = ref.read(budgetServiceProvider);
  return budgetService.getRecommendedBudgetAmount(
    userId: userId,
    categoryId: query.categoryId,
    period: query.period,
  );
});

// Helper classes
// Budget recommendation provider
final budgetRecommendationProvider = FutureProvider.family<double, BudgetRecommendationQuery>((ref, query) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return 0.0;

  final budgetService = ref.read(budgetServiceProvider);
  return budgetService.getRecommendedBudgetAmount(
    userId: userId,
    categoryId: query.categoryId,
    period: query.period,
  );
});

class BudgetCategoryQuery {
  final String categoryId;
  final DateTime date;

  BudgetCategoryQuery({required this.categoryId, required this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetCategoryQuery && 
      runtimeType == other.runtimeType && 
      categoryId == other.categoryId && 
      date == other.date;

  @override
  int get hashCode => categoryId.hashCode ^ date.hashCode;
}

class BudgetRecommendationQuery {
  final String categoryId;
  final BudgetPeriod period;

  BudgetRecommendationQuery({required this.categoryId, required this.period});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetRecommendationQuery && 
      runtimeType == other.runtimeType && 
      categoryId == other.categoryId && 
      period == other.period;

  @override
  int get hashCode => categoryId.hashCode ^ period.hashCode;
}

class BudgetSummary {
  final double totalBudget;
  final double totalSpent;
  final int activeBudgets;
  final int overBudgetCount;
  final int nearLimitCount;
  final double remainingBudget;

  BudgetSummary({
    required this.totalBudget,
    required this.totalSpent,
    required this.activeBudgets,
    required this.overBudgetCount,
    required this.nearLimitCount,
    required this.remainingBudget,
  });

  double get spentPercentage => totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;
  bool get isOverBudget => totalSpent > totalBudget;
}
