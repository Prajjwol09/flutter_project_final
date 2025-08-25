import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'local_storage_service.dart';
import 'auth_service.dart';

/// ⚙️ User Settings Service
/// Manages user preferences, app settings, and configuration
class UserSettingsService {
  static final UserSettingsService _instance = UserSettingsService._internal();
  factory UserSettingsService() => _instance;
  UserSettingsService._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Settings Keys
  static const String _themeKey = 'app_theme';
  static const String _languageKey = 'app_language';
  static const String _currencyKey = 'default_currency';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _budgetAlertsKey = 'budget_alerts_enabled';
  static const String _expenseReminderKey = 'expense_reminder_enabled';
  static const String _autoBackupKey = 'auto_backup_enabled';
  static const String _dataRetentionKey = 'data_retention_months';
  static const String _privacyModeKey = 'privacy_mode_enabled';
  static const String _analyticsKey = 'analytics_enabled';
  static const String _crashReportingKey = 'crash_reporting_enabled';
  static const String _firstLaunchKey = 'first_launch_completed';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _defaultPaymentMethodKey = 'default_payment_method';
  static const String _expenseReminderTimeKey = 'expense_reminder_time';
  static const String _monthlyBudgetTargetKey = 'monthly_budget_target';

  // === Theme Settings ===

  /// Get current theme mode
  Future<String> getThemeMode() async {
    return await _secureStorage.read(key: _themeKey) ?? 'system';
  }

  /// Set theme mode (light, dark, system)
  Future<void> setThemeMode(String themeMode) async {
    await _secureStorage.write(key: _themeKey, value: themeMode);
  }

  // === Language Settings ===

  /// Get current language
  Future<String> getLanguage() async {
    return await _secureStorage.read(key: _languageKey) ?? 'en';
  }

  /// Set app language
  Future<void> setLanguage(String languageCode) async {
    await _secureStorage.write(key: _languageKey, value: languageCode);
  }

  // === Currency Settings ===

  /// Get default currency
  Future<String> getDefaultCurrency() async {
    return await _secureStorage.read(key: _currencyKey) ?? 'NPR';
  }

  /// Set default currency
  Future<void> setDefaultCurrency(String currency) async {
    await _secureStorage.write(key: _currencyKey, value: currency);
    
    // Update user profile if logged in
    try {
      final authService = AuthService();
      if (authService.currentUser != null) {
        final userData = await authService.getUserData(authService.currentUser!.uid);
        if (userData != null) {
          final updatedUser = userData.copyWith(currency: currency);
          await authService.updateUserData(updatedUser);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to update user currency: $e');
      }
    }
  }

  // === Security Settings ===

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  /// Check if privacy mode is enabled
  Future<bool> isPrivacyModeEnabled() async {
    final value = await _secureStorage.read(key: _privacyModeKey);
    return value == 'true';
  }

  /// Enable/disable privacy mode (hides amounts in app switcher)
  Future<void> setPrivacyModeEnabled(bool enabled) async {
    await _secureStorage.write(key: _privacyModeKey, value: enabled.toString());
  }

  // === Notification Settings ===

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final value = await _secureStorage.read(key: _notificationsEnabledKey);
    return value != 'false'; // Default to true
  }

  /// Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _secureStorage.write(key: _notificationsEnabledKey, value: enabled.toString());
  }

  /// Check if budget alerts are enabled
  Future<bool> areBudgetAlertsEnabled() async {
    final value = await _secureStorage.read(key: _budgetAlertsKey);
    return value != 'false'; // Default to true
  }

  /// Enable/disable budget alerts
  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    await _secureStorage.write(key: _budgetAlertsKey, value: enabled.toString());
  }

  /// Check if expense reminders are enabled
  Future<bool> areExpenseRemindersEnabled() async {
    final value = await _secureStorage.read(key: _expenseReminderKey);
    return value == 'true';
  }

  /// Enable/disable expense reminders
  Future<void> setExpenseRemindersEnabled(bool enabled) async {
    await _secureStorage.write(key: _expenseReminderKey, value: enabled.toString());
  }

  /// Get expense reminder time (hour of day)
  Future<int> getExpenseReminderTime() async {
    final value = await _secureStorage.read(key: _expenseReminderTimeKey);
    return int.tryParse(value ?? '20') ?? 20; // Default to 8 PM
  }

  /// Set expense reminder time
  Future<void> setExpenseReminderTime(int hour) async {
    await _secureStorage.write(key: _expenseReminderTimeKey, value: hour.toString());
  }

  // === Data Settings ===

  /// Check if auto backup is enabled
  Future<bool> isAutoBackupEnabled() async {
    final value = await _secureStorage.read(key: _autoBackupKey);
    return value != 'false'; // Default to true
  }

  /// Enable/disable auto backup
  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _secureStorage.write(key: _autoBackupKey, value: enabled.toString());
  }

  /// Get data retention period in months
  Future<int> getDataRetentionMonths() async {
    final value = await _secureStorage.read(key: _dataRetentionKey);
    return int.tryParse(value ?? '24') ?? 24; // Default to 24 months
  }

  /// Set data retention period
  Future<void> setDataRetentionMonths(int months) async {
    await _secureStorage.write(key: _dataRetentionKey, value: months.toString());
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final value = await _secureStorage.read(key: _lastSyncTimeKey);
    return value != null ? DateTime.tryParse(value) : null;
  }

  /// Set last sync time
  Future<void> setLastSyncTime(DateTime time) async {
    await _secureStorage.write(key: _lastSyncTimeKey, value: time.toIso8601String());
  }

  // === Privacy Settings ===
  
  /// Check if analytics are enabled
  Future<bool> areAnalyticsEnabled() async {
    final value = await _secureStorage.read(key: _analyticsKey);
    return value != 'false'; // Default to true
  }

  /// Enable/disable analytics
  Future<void> setAnalyticsEnabled(bool enabled) async {
    await _secureStorage.write(key: _analyticsKey, value: enabled.toString());
  }

  /// Check if crash reporting is enabled
  Future<bool> isCrashReportingEnabled() async {
    final value = await _secureStorage.read(key: _crashReportingKey);
    return value != 'false'; // Default to true
  }

  /// Enable/disable crash reporting
  Future<void> setCrashReportingEnabled(bool enabled) async {
    await _secureStorage.write(key: _crashReportingKey, value: enabled.toString());
  }

  // === App State Settings ===

  /// Check if this is the first app launch
  Future<bool> isFirstLaunch() async {
    final value = await _secureStorage.read(key: _firstLaunchKey);
    return value != 'true';
  }

  /// Mark first launch as completed
  Future<void> setFirstLaunchCompleted() async {
    await _secureStorage.write(key: _firstLaunchKey, value: 'true');
  }

  /// Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    final value = await _secureStorage.read(key: _onboardingCompletedKey);
    return value == 'true';
  }

  /// Mark onboarding as completed
  Future<void> setOnboardingCompleted() async {
    await _secureStorage.write(key: _onboardingCompletedKey, value: 'true');
  }

  // === Financial Settings ===

  /// Get default payment method
  Future<String> getDefaultPaymentMethod() async {
    return await _secureStorage.read(key: _defaultPaymentMethodKey) ?? 'Cash';
  }

  /// Set default payment method
  Future<void> setDefaultPaymentMethod(String method) async {
    await _secureStorage.write(key: _defaultPaymentMethodKey, value: method);
  }

  /// Get monthly budget target
  Future<double> getMonthlyBudgetTarget() async {
    final value = await _secureStorage.read(key: _monthlyBudgetTargetKey);
    return double.tryParse(value ?? '0') ?? 0.0;
  }

  /// Set monthly budget target
  Future<void> setMonthlyBudgetTarget(double target) async {
    await _secureStorage.write(key: _monthlyBudgetTargetKey, value: target.toString());
    
    // Update user profile
    try {
      final authService = AuthService();
      if (authService.currentUser != null) {
        final userData = await authService.getUserData(authService.currentUser!.uid);
        if (userData != null) {
          final updatedUser = userData.copyWith(monthlyBudgetTarget: target);
          await authService.updateUserData(updatedUser);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to update user budget target: $e');
      }
    }
  }

  // === Bulk Operations ===
  
  /// Get all settings as a map
  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'theme': await getThemeMode(),
      'language': await getLanguage(),
      'currency': await getDefaultCurrency(),
      'biometricEnabled': await isBiometricEnabled(),
      'notificationsEnabled': await areNotificationsEnabled(),
      'budgetAlertsEnabled': await areBudgetAlertsEnabled(),
      'expenseRemindersEnabled': await areExpenseRemindersEnabled(),
      'expenseReminderTime': await getExpenseReminderTime(),
      'autoBackupEnabled': await isAutoBackupEnabled(),
      'dataRetentionMonths': await getDataRetentionMonths(),
      'privacyModeEnabled': await isPrivacyModeEnabled(),
      'analyticsEnabled': await areAnalyticsEnabled(),
      'crashReportingEnabled': await isCrashReportingEnabled(),
      'firstLaunchCompleted': !await isFirstLaunch(),
      'onboardingCompleted': await isOnboardingCompleted(),
      'defaultPaymentMethod': await getDefaultPaymentMethod(),
      'monthlyBudgetTarget': await getMonthlyBudgetTarget(),
      'lastSyncTime': (await getLastSyncTime())?.toIso8601String(),
    };
  }

  /// Reset all settings to defaults
  Future<void> resetAllSettings() async {
    try {
      await _secureStorage.deleteAll();
      if (kDebugMode) {
        debugPrint('✅ All settings reset to defaults');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to reset settings: $e');
      }
      rethrow;
    }
  }

  /// Import settings from map
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      if (settings['theme'] != null) {
        await setThemeMode(settings['theme']);
      }
      if (settings['language'] != null) {
        await setLanguage(settings['language']);
      }
      if (settings['currency'] != null) {
        await setDefaultCurrency(settings['currency']);
      }
      if (settings['biometricEnabled'] != null) {
        await setBiometricEnabled(settings['biometricEnabled']);
      }
      if (settings['notificationsEnabled'] != null) {
        await setNotificationsEnabled(settings['notificationsEnabled']);
      }
      if (settings['budgetAlertsEnabled'] != null) {
        await setBudgetAlertsEnabled(settings['budgetAlertsEnabled']);
      }
      if (settings['expenseRemindersEnabled'] != null) {
        await setExpenseRemindersEnabled(settings['expenseRemindersEnabled']);
      }
      if (settings['expenseReminderTime'] != null) {
        await setExpenseReminderTime(settings['expenseReminderTime']);
      }
      if (settings['autoBackupEnabled'] != null) {
        await setAutoBackupEnabled(settings['autoBackupEnabled']);
      }
      if (settings['dataRetentionMonths'] != null) {
        await setDataRetentionMonths(settings['dataRetentionMonths']);
      }
      if (settings['privacyModeEnabled'] != null) {
        await setPrivacyModeEnabled(settings['privacyModeEnabled']);
      }
      if (settings['analyticsEnabled'] != null) {
        await setAnalyticsEnabled(settings['analyticsEnabled']);
      }
      if (settings['crashReportingEnabled'] != null) {
        await setCrashReportingEnabled(settings['crashReportingEnabled']);
      }
      if (settings['defaultPaymentMethod'] != null) {
        await setDefaultPaymentMethod(settings['defaultPaymentMethod']);
      }
      if (settings['monthlyBudgetTarget'] != null) {
        await setMonthlyBudgetTarget(settings['monthlyBudgetTarget'].toDouble());
      }
      
      if (kDebugMode) {
        debugPrint('✅ Settings imported successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to import settings: $e');
      }
      rethrow;
    }
  }

  /// Get settings that should sync across devices
  Future<Map<String, dynamic>> getSyncableSettings() async {
    return {
      'theme': await getThemeMode(),
      'language': await getLanguage(),
      'currency': await getDefaultCurrency(),
      'notificationsEnabled': await areNotificationsEnabled(),
      'budgetAlertsEnabled': await areBudgetAlertsEnabled(),
      'expenseRemindersEnabled': await areExpenseRemindersEnabled(),
      'expenseReminderTime': await getExpenseReminderTime(),
      'autoBackupEnabled': await isAutoBackupEnabled(),
      'dataRetentionMonths': await getDataRetentionMonths(),
      'defaultPaymentMethod': await getDefaultPaymentMethod(),
      'monthlyBudgetTarget': await getMonthlyBudgetTarget(),
    };
  }

  /// Check if settings need to be synced
  Future<bool> needsSync() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;
    
    // Sync if more than 24 hours since last sync
    return DateTime.now().difference(lastSync).inHours > 24;
  }

  // === Development/Debug Settings ===

  /// Get debug info for troubleshooting
  Future<Map<String, dynamic>> getDebugInfo() async {
    if (!kDebugMode) return {};
    
    final allSettings = await getAllSettings();
    return {
      'settings': allSettings,
      'secureStorageKeys': await _getAllSecureStorageKeys(),
      'localStorageStats': await _getLocalStorageStats(),
    };
  }

  /// Get all secure storage keys (debug only)
  Future<Map<String, String>> _getAllSecureStorageKeys() async {
    if (!kDebugMode) return {};
    
    try {
      return await _secureStorage.readAll();
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Get local storage statistics (debug only)
  Future<Map<String, dynamic>> _getLocalStorageStats() async {
    if (!kDebugMode) return {};
    
    try {
      return {
        'expenses': LocalStorageService.getAllExpenses().length,
        'categories': LocalStorageService.getAllCategories().length,
        'budgets': LocalStorageService.getAllBudgets().length,
        'currentUser': LocalStorageService.getCurrentUser() != null,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Get supported currencies
  static List<String> get supportedCurrencies => [
    'NPR', // Nepali Rupee
    'USD', // US Dollar
    'EUR', // Euro
    'GBP', // British Pound
    'JPY', // Japanese Yen
    'INR', // Indian Rupee
    'AUD', // Australian Dollar
    'CAD', // Canadian Dollar
    'CNY', // Chinese Yuan
  ];

  /// Set currency preference (alias for setDefaultCurrency)
  Future<void> setCurrency(String currency) async {
    if (!supportedCurrencies.contains(currency)) {
      throw ArgumentError('Unsupported currency: $currency');
    }
    
    await setDefaultCurrency(currency);
  }
}