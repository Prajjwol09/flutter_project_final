import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';
import '../utils/constants.dart';
import 'local_storage_service.dart';
import 'expense_service.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ExpenseService _expenseService = ExpenseService();

  // Add budget
  Future<BudgetModel> addBudget(BudgetModel budget) async {
    try {
      // Save to Firestore
      await _firestore
          .collection(AppConstants.budgetsCollection)
          .doc(budget.id)
          .set(budget.toJson());

      // Save to local storage
      await LocalStorageService.saveBudget(budget);

      return budget;
    } catch (e) {
      throw Exception('Failed to add budget: ${e.toString()}');
    }
  }

  // Update budget
  Future<BudgetModel> updateBudget(BudgetModel budget) async {
    try {
      // Update in Firestore
      await _firestore
          .collection(AppConstants.budgetsCollection)
          .doc(budget.id)
          .update(budget.toJson());

      // Update in local storage
      await LocalStorageService.saveBudget(budget);

      return budget;
    } catch (e) {
      throw Exception('Failed to update budget: ${e.toString()}');
    }
  }

  // Delete budget
  Future<void> deleteBudget(String budgetId) async {
    try {
      // Delete from Firestore
      await _firestore
          .collection(AppConstants.budgetsCollection)
          .doc(budgetId)
          .delete();

      // Delete from local storage
      await LocalStorageService.deleteBudget(budgetId);
    } catch (e) {
      throw Exception('Failed to delete budget: ${e.toString()}');
    }
  }

  // Get budgets for user
  Future<List<BudgetModel>> getBudgetsForUser(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.budgetsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final List<BudgetModel> budgets = snapshot.docs
          .map((doc) => BudgetModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Save to local storage
      await LocalStorageService.saveBudgets(budgets);

      return budgets;
    } catch (e) {
      // Return local data if network fails
      return LocalStorageService.getBudgetsByUserId(userId);
    }
  }

  // Get active budgets for user
  Future<List<BudgetModel>> getActiveBudgetsForUser(String userId) async {
    final budgets = await getBudgetsForUser(userId);
    return budgets.where((budget) => budget.isActive && budget.isCurrentPeriod).toList();
  }

  // Get budget by ID
  Future<BudgetModel?> getBudgetById(String budgetId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(AppConstants.budgetsCollection)
          .doc(budgetId)
          .get();

      if (doc.exists) {
        final budget = BudgetModel.fromJson(doc.data() as Map<String, dynamic>);
        await LocalStorageService.saveBudget(budget);
        return budget;
      }
    } catch (e) {
      // Return local data if network fails
      return LocalStorageService.getBudgetById(budgetId);
    }
    return null;
  }

  // Get budget for category and period
  Future<BudgetModel?> getBudgetForCategory({
    required String userId,
    required String categoryId,
    required DateTime date,
  }) async {
    try {
      final budgets = await getBudgetsForUser(userId);
      
      for (final budget in budgets) {
        if (budget.categoryId == categoryId &&
            budget.isActive &&
            date.isAfter(budget.startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(budget.endDate.add(const Duration(days: 1)))) {
          return budget;
        }
      }
    } catch (e) {
      // Search in local data
      final localBudgets = LocalStorageService.getBudgetsByUserId(userId);
      for (final budget in localBudgets) {
        if (budget.categoryId == categoryId &&
            budget.isActive &&
            date.isAfter(budget.startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(budget.endDate.add(const Duration(days: 1)))) {
          return budget;
        }
      }
    }
    return null;
  }

  // Get budget spending status
  Future<BudgetSpendingStatus> getBudgetSpendingStatus(BudgetModel budget) async {
    try {
      final totalSpent = await _expenseService.getTotalExpensesForPeriod(
        userId: budget.userId,
        startDate: budget.startDate,
        endDate: budget.endDate,
        categoryId: budget.categoryId,
        type: ExpenseType.expense,
      );

      final spentAmount = totalSpent.abs(); // Convert to positive value
      final remainingAmount = budget.amount - spentAmount;
      final spentPercentage = budget.amount > 0 ? (spentAmount / budget.amount) * 100 : 0.0;
      final isOverBudget = spentAmount > budget.amount;
      final isNearLimit = spentPercentage >= (budget.alertThreshold * 100);

      return BudgetSpendingStatus(
        budget: budget,
        spentAmount: spentAmount,
        remainingAmount: remainingAmount,
        spentPercentage: spentPercentage,
        isOverBudget: isOverBudget,
        isNearLimit: isNearLimit,
        daysRemaining: budget.daysRemaining,
      );
    } catch (e) {
      throw Exception('Failed to get budget spending status: ${e.toString()}');
    }
  }

  // Get all budget statuses for user
  Future<List<BudgetSpendingStatus>> getAllBudgetStatuses(String userId) async {
    try {
      final budgets = await getActiveBudgetsForUser(userId);
      final List<BudgetSpendingStatus> statuses = [];

      for (final budget in budgets) {
        final status = await getBudgetSpendingStatus(budget);
        statuses.add(status);
      }

      return statuses;
    } catch (e) {
      throw Exception('Failed to get budget statuses: ${e.toString()}');
    }
  }

  // Check if budget exists for category and period
  Future<bool> budgetExistsForCategoryAndPeriod({
    required String userId,
    required String categoryId,
    required DateTime startDate,
    required DateTime endDate,
    String? excludeBudgetId,
  }) async {
    try {
      final budgets = await getBudgetsForUser(userId);
      
      return budgets.any((budget) =>
          budget.id != excludeBudgetId &&
          budget.categoryId == categoryId &&
          budget.isActive &&
          ((startDate.isBefore(budget.endDate) && endDate.isAfter(budget.startDate))));
    } catch (e) {
      return false;
    }
  }

  // Get offline budgets
  List<BudgetModel> getOfflineBudgets(String userId) {
    return LocalStorageService.getBudgetsByUserId(userId);
  }

  // Sync local data with Firestore
  Future<void> syncLocalData(String userId) async {
    try {
      await getBudgetsForUser(userId);
      await LocalStorageService.setLastSyncTime(DateTime.now());
    } catch (e) {
      throw Exception('Failed to sync budgets: ${e.toString()}');
    }
  }

  // Calculate recommended budget amount based on historical spending
  Future<double> getRecommendedBudgetAmount({
    required String userId,
    required String categoryId,
    required BudgetPeriod period,
  }) async {
    try {
      final now = DateTime.now();
      final lookbackMonths = 3; // Look back 3 months for average
      
      double totalSpent = 0;
      int periodsWithData = 0;

      for (int i = 1; i <= lookbackMonths; i++) {
        final endDate = DateTime(now.year, now.month - i + 1, 0);
        final startDate = DateTime(now.year, now.month - i, 1);
        
        final spent = await _expenseService.getTotalExpensesForPeriod(
          userId: userId,
          startDate: startDate,
          endDate: endDate,
          categoryId: categoryId,
          type: ExpenseType.expense,
        );

        if (spent.abs() > 0) {
          totalSpent += spent.abs();
          periodsWithData++;
        }
      }

      if (periodsWithData == 0) return 0.0;

      final averageMonthlySpending = totalSpent / periodsWithData;
      
      // Adjust for different budget periods
      switch (period) {
        case BudgetPeriod.weekly:
          return averageMonthlySpending / 4;
        case BudgetPeriod.monthly:
          return averageMonthlySpending;
        case BudgetPeriod.quarterly:
          return averageMonthlySpending * 3;
        case BudgetPeriod.yearly:
          return averageMonthlySpending * 12;
      }
    } catch (e) {
      return 0.0;
    }
  }
}

// Budget spending status model
class BudgetSpendingStatus {
  final BudgetModel budget;
  final double spentAmount;
  final double remainingAmount;
  final double spentPercentage;
  final bool isOverBudget;
  final bool isNearLimit;
  final double daysRemaining;

  BudgetSpendingStatus({
    required this.budget,
    required this.spentAmount,
    required this.remainingAmount,
    required this.spentPercentage,
    required this.isOverBudget,
    required this.isNearLimit,
    required this.daysRemaining,
  });
}
