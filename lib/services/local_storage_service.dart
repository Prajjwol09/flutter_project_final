import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../utils/constants.dart';
import '../config/environment_config.dart';

class LocalStorageService {
  static Box<UserModel>? _userBox;
  static Box<ExpenseModel>? _expenseBox;
  static Box<CategoryModel>? _categoryBox;
  static Box<BudgetModel>? _budgetBox;
  static Box<GoalModel>? _goalBox;
  static Box<dynamic>? _settingsBox;
  static bool _isInitialized = false;
  
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> init() async {
    try {
      if (_isInitialized) return;
      
      await Hive.initFlutter();

      // Use simple encryption only if explicitly enabled for production
      List<int>? encryptionKey;
      if (EnvironmentConfig.enableEncryption && EnvironmentConfig.isProduction) {
        encryptionKey = await _getOrCreateEncryptionKey();
      }

      // Register adapters safely (avoid duplicate registration crash)
      _registerAdapters();

      // Open boxes with minimal encryption for better performance
      await _openBoxesSafely(encryptionKey);
      
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Local storage initialization failed: $e');
      }
      // Don't rethrow - allow app to continue without local storage
      _isInitialized = false;
    }
  }

  static void _registerAdapters() {
    try {
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserModelAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryModelAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ExpenseModelAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(BudgetModelAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(GoalModelAdapter());
      if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(GoalMilestoneAdapter());
      if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(ExpenseTypeAdapter());
      if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(BudgetPeriodAdapter());
      if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(PaymentMethodAdapter());
      if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(GoalCategoryAdapter());
      if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(GoalTypeAdapter());
      
      if (kDebugMode) {
        print('✅ Hive adapters registered successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error registering Hive adapters: $e');
      }
      // Continue anyway - some adapters might already be registered
    }
  }

  static Future<void> _openBoxesSafely(List<int>? encryptionKey) async {
    // Open boxes with error handling for corruption
    _userBox = await _openBoxSafely<UserModel>(
      AppConstants.userBoxName,
      encryptionKey,
    );
    _expenseBox = await _openBoxSafely<ExpenseModel>(
      AppConstants.expenseBoxName,
      encryptionKey,
    );
    _categoryBox = await _openBoxSafely<CategoryModel>(
      AppConstants.categoryBoxName,
      encryptionKey,
    );
    _budgetBox = await _openBoxSafely<BudgetModel>(
      AppConstants.budgetBoxName,
      encryptionKey,
    );
    _goalBox = await _openBoxSafely<GoalModel>(
      'goal_box',
      encryptionKey,
    );
    _settingsBox = await _openBoxSafely(
      'settings',
      encryptionKey,
    );
  }

  /// Safely open Hive box with corruption recovery
  static Future<Box<T>?> _openBoxSafely<T>(
    String boxName,
    List<int>? encryptionKey,
  ) async {
    try {
      final box = await Hive.openBox<T>(
        boxName,
        encryptionCipher: encryptionKey != null ? HiveAesCipher(encryptionKey) : null,
      );
      if (kDebugMode) {
        print('✅ Opened Hive box: $boxName');
      }
      return box;
    } catch (e) {
      // Handle corrupted box by deleting and recreating
      if (kDebugMode) {
        print('🔄 Recovering corrupted box: $boxName - $e');
      }
      
      try {
        // Delete corrupted box
        await Hive.deleteBoxFromDisk(boxName);
      } catch (deleteError) {
        if (kDebugMode) {
          print('⚠️ Error deleting corrupted box $boxName: $deleteError');
        }
      }
      
      try {
        // Create new box
        final box = await Hive.openBox<T>(
          boxName,
          encryptionCipher: encryptionKey != null ? HiveAesCipher(encryptionKey) : null,
        );
        if (kDebugMode) {
          print('✅ Recreated Hive box: $boxName');
        }
        return box;
      } catch (recreateError) {
        if (kDebugMode) {
          print('❌ Failed to recreate box $boxName: $recreateError');
        }
        return null;
      }
    }
  }

  // User operations
  static Future<void> saveUser(UserModel user) async {
    if (!_isInitialized || _userBox == null) return;
    await _userBox!.put('current_user', user);
  }

  static UserModel? getCurrentUser() {
    if (!_isInitialized || _userBox == null) return null;
    return _userBox!.get('current_user');
  }

  static Future<void> clearUser() async {
    if (!_isInitialized || _userBox == null) return;
    await _userBox!.delete('current_user');
  }

  // Expense operations
  static Future<void> saveExpense(ExpenseModel expense) async {
    if (!_isInitialized || _expenseBox == null) return;
    await _expenseBox!.put(expense.id, expense);
  }

  static Future<void> saveExpenses(List<ExpenseModel> expenses) async {
    if (!_isInitialized || _expenseBox == null) return;
    final Map<String, ExpenseModel> expenseMap = {
      for (ExpenseModel expense in expenses) expense.id: expense
    };
    await _expenseBox!.putAll(expenseMap);
  }

  static List<ExpenseModel> getAllExpenses() {
    if (!_isInitialized || _expenseBox == null) return [];
    return _expenseBox!.values.toList();
  }

  static List<ExpenseModel> getExpensesByUserId(String userId) {
    if (!_isInitialized || _expenseBox == null) return [];
    return _expenseBox!.values.where((expense) => expense.userId == userId).toList();
  }

  static ExpenseModel? getExpenseById(String id) {
    if (!_isInitialized || _expenseBox == null) return null;
    return _expenseBox!.get(id);
  }

  static Future<void> deleteExpense(String id) async {
    if (!_isInitialized || _expenseBox == null) return;
    await _expenseBox!.delete(id);
  }

  static Future<void> clearExpenses() async {
    if (!_isInitialized || _expenseBox == null) return;
    await _expenseBox!.clear();
  }

  // Category operations
  static Future<void> saveCategory(CategoryModel category) async {
    if (!_isInitialized || _categoryBox == null) return;
    await _categoryBox!.put(category.id, category);
  }

  static Future<void> saveCategories(List<CategoryModel> categories) async {
    if (!_isInitialized || _categoryBox == null) return;
    final Map<String, CategoryModel> categoryMap = {
      for (CategoryModel category in categories) category.id: category
    };
    await _categoryBox!.putAll(categoryMap);
  }

  static List<CategoryModel> getAllCategories() {
    if (!_isInitialized || _categoryBox == null) return [];
    return _categoryBox!.values.toList();
  }

  static List<CategoryModel> getCategoriesByUserId(String? userId) {
    if (!_isInitialized || _categoryBox == null) return [];
    return _categoryBox!.values
        .where((category) => category.isDefault || category.userId == userId)
        .toList();
  }

  static CategoryModel? getCategoryById(String id) {
    if (!_isInitialized || _categoryBox == null) return null;
    return _categoryBox!.get(id);
  }

  static Future<void> deleteCategory(String id) async {
    if (!_isInitialized || _categoryBox == null) return;
    await _categoryBox!.delete(id);
  }

  static Future<void> clearCategories() async {
    if (!_isInitialized || _categoryBox == null) return;
    await _categoryBox!.clear();
  }

  // Budget operations
  static Future<void> saveBudget(BudgetModel budget) async {
    if (!_isInitialized || _budgetBox == null) return;
    await _budgetBox!.put(budget.id, budget);
  }

  static Future<void> saveBudgets(List<BudgetModel> budgets) async {
    if (!_isInitialized || _budgetBox == null) return;
    final Map<String, BudgetModel> budgetMap = {
      for (BudgetModel budget in budgets) budget.id: budget
    };
    await _budgetBox!.putAll(budgetMap);
  }

  static List<BudgetModel> getAllBudgets() {
    if (!_isInitialized || _budgetBox == null) return [];
    return _budgetBox!.values.toList();
  }

  static List<BudgetModel> getBudgetsByUserId(String userId) {
    if (!_isInitialized || _budgetBox == null) return [];
    return _budgetBox!.values.where((budget) => budget.userId == userId).toList();
  }

  static BudgetModel? getBudgetById(String id) {
    if (!_isInitialized || _budgetBox == null) return null;
    return _budgetBox!.get(id);
  }

  static Future<void> deleteBudget(String id) async {
    if (!_isInitialized || _budgetBox == null) return;
    await _budgetBox!.delete(id);
  }

  static Future<void> clearBudgets() async {
    if (!_isInitialized || _budgetBox == null) return;
    await _budgetBox!.clear();
  }

  // Goal operations
  static Future<void> saveGoal(GoalModel goal) async {
    if (!_isInitialized || _goalBox == null) return;
    await _goalBox!.put(goal.id, goal);
  }

  static Future<void> saveGoals(List<GoalModel> goals) async {
    if (!_isInitialized || _goalBox == null) return;
    final Map<String, GoalModel> goalMap = {
      for (GoalModel goal in goals) goal.id: goal
    };
    await _goalBox!.putAll(goalMap);
  }

  static List<GoalModel> getAllGoals() {
    if (!_isInitialized || _goalBox == null) return [];
    return _goalBox!.values.toList();
  }

  static List<GoalModel> getGoalsByUserId(String userId) {
    if (!_isInitialized || _goalBox == null) return [];
    return _goalBox!.values.where((goal) => goal.userId == userId).toList();
  }

  static GoalModel? getGoalById(String id) {
    if (!_isInitialized || _goalBox == null) return null;
    return _goalBox!.get(id);
  }

  static Future<void> deleteGoal(String id) async {
    if (!_isInitialized || _goalBox == null) return;
    await _goalBox!.delete(id);
  }

  static Future<void> clearGoals() async {
    if (!_isInitialized || _goalBox == null) return;
    await _goalBox!.clear();
  }

  // Sync operations
  static Future<void> setLastSyncTime(DateTime time) async {
    if (!_isInitialized || _settingsBox == null) return;
    await _settingsBox!.put('last_sync_time', time.toIso8601String());
  }

  static DateTime? getLastSyncTime() {
    if (!_isInitialized || _settingsBox == null) return null;
    final timeString = _settingsBox!.get('last_sync_time');
    return timeString != null ? DateTime.tryParse(timeString) : null;
  }


  // Check if data exists locally
  static bool hasLocalData() {
    if (!_isInitialized || _expenseBox == null || _categoryBox == null || _budgetBox == null || _goalBox == null) return false;
    return _expenseBox!.isNotEmpty || _categoryBox!.isNotEmpty || _budgetBox!.isNotEmpty || _goalBox!.isNotEmpty;
  }

  // Get data count
  static Map<String, int> getDataCounts() {
    if (!_isInitialized || _expenseBox == null || _categoryBox == null || _budgetBox == null || _goalBox == null) {
      return {'expenses': 0, 'categories': 0, 'budgets': 0, 'goals': 0};
    }
    return {
      'expenses': _expenseBox!.length,
      'categories': _categoryBox!.length,
      'budgets': _budgetBox!.length,
      'goals': _goalBox!.length,
    };
  }

  // Encryption key management
  static Future<List<int>> _getOrCreateEncryptionKey() async {
    const keyName = 'hive_encryption_key';
    
    try {
      final keyString = await _secureStorage.read(key: keyName);
      if (keyString != null) {
        return base64Decode(keyString);
      }
    } catch (e) {
      // If key retrieval fails, generate a new one
    }
    
    // Generate new encryption key
    final key = _generateEncryptionKey();
    await _secureStorage.write(key: keyName, value: base64Encode(key));
    return key;
  }
  
  static List<int> _generateEncryptionKey() {
    final keyString = EnvironmentConfig.encryptionKey + DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(keyString);
    final digest = sha256.convert(bytes);
    return digest.bytes;
  }
  
  // Secure storage for sensitive data
  static Future<void> storeSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  static Future<String?> getSecureData(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  static Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  static Future<void> clearAllSecureData() async {
    await _secureStorage.deleteAll();
  }
}
