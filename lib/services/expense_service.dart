import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import '../utils/constants.dart';
import 'local_storage_service.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add expense
  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    try {
      // Save to Firestore
      await _firestore
          .collection(AppConstants.expensesCollection)
          .doc(expense.id)
          .set(expense.toJson());

      // Save to local storage
      await LocalStorageService.saveExpense(expense);

      return expense;
    } catch (e) {
      throw Exception('Failed to add expense: ${e.toString()}');
    }
  }

  // Update expense
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    try {
      // Update in Firestore
      await _firestore
          .collection(AppConstants.expensesCollection)
          .doc(expense.id)
          .update(expense.toJson());

      // Update in local storage
      await LocalStorageService.saveExpense(expense);

      return expense;
    } catch (e) {
      throw Exception('Failed to update expense: ${e.toString()}');
    }
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      // Delete from Firestore
      await _firestore
          .collection(AppConstants.expensesCollection)
          .doc(expenseId)
          .delete();

      // Delete from local storage
      await LocalStorageService.deleteExpense(expenseId);
    } catch (e) {
      throw Exception('Failed to delete expense: ${e.toString()}');
    }
  }

  // Get expenses for user
  Future<List<ExpenseModel>> getExpensesForUser(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.expensesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('transactionDate', descending: true)
          .get();

      final List<ExpenseModel> expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Save to local storage
      await LocalStorageService.saveExpenses(expenses);

      return expenses;
    } catch (e) {
      // Return local data if network fails
      return LocalStorageService.getExpensesByUserId(userId);
    }
  }

  // Get expenses for date range
  Future<List<ExpenseModel>> getExpensesForDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.expensesCollection)
          .where('userId', isEqualTo: userId)
          .where('transactionDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('transactionDate', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('transactionDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return local data filtered by date range
      final localExpenses = LocalStorageService.getExpensesByUserId(userId);
      return localExpenses.where((expense) {
        return expense.transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               expense.transactionDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }
  }

  // Get expenses for category
  Future<List<ExpenseModel>> getExpensesForCategory({
    required String userId,
    required String categoryId,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.expensesCollection)
          .where('userId', isEqualTo: userId)
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('transactionDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return local data filtered by category
      final localExpenses = LocalStorageService.getExpensesByUserId(userId);
      return localExpenses.where((expense) => expense.categoryId == categoryId).toList();
    }
  }

  // Get monthly expenses
  Future<List<ExpenseModel>> getMonthlyExpenses({
    required String userId,
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return getExpensesForDateRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Get total expenses for period
  Future<double> getTotalExpensesForPeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? categoryId,
    ExpenseType? type,
  }) async {
    final expenses = await getExpensesForDateRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    double total = 0.0;
    for (final expense in expenses) {
      if (categoryId != null && expense.categoryId != categoryId) continue;
      if (type != null && expense.type != type) continue;
      
      if (expense.type == ExpenseType.income) {
        total += expense.amount;
      } else {
        total -= expense.amount;
      }
    }

    return total;
  }

  // Get category spending for period
  Future<Map<String, double>> getCategorySpendingForPeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final expenses = await getExpensesForDateRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    final Map<String, double> categorySpending = {};

    for (final expense in expenses) {
      if (expense.type == ExpenseType.expense) {
        categorySpending[expense.categoryId] = 
            (categorySpending[expense.categoryId] ?? 0.0) + expense.amount;
      }
    }

    return categorySpending;
  }

  // Sync local data with Firestore
  Future<void> syncLocalData(String userId) async {
    try {
      // Get all expenses from Firestore
      await getExpensesForUser(userId);
      
      // Update last sync time
      await LocalStorageService.setLastSyncTime(DateTime.now());
    } catch (e) {
      throw Exception('Failed to sync data: ${e.toString()}');
    }
  }

  // Get offline expenses
  List<ExpenseModel> getOfflineExpenses(String userId) {
    return LocalStorageService.getExpensesByUserId(userId);
  }

  // Bulk delete expenses
  Future<void> bulkDeleteExpenses(List<String> expenseIds) async {
    try {
      final WriteBatch batch = _firestore.batch();

      for (final id in expenseIds) {
        batch.delete(_firestore.collection(AppConstants.expensesCollection).doc(id));
      }

      await batch.commit();

      // Delete from local storage
      for (final id in expenseIds) {
        await LocalStorageService.deleteExpense(id);
      }
    } catch (e) {
      throw Exception('Failed to bulk delete expenses: ${e.toString()}');
    }
  }
}
