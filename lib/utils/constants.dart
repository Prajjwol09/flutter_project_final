import 'package:hive/hive.dart';

part 'constants.g.dart';

class AppConstants {
  // App info
  static const String appName = 'Finlytic';
  static const String appVersion = '1.0.0';
  
  // Default categories
  static const List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Food & Dining', 'icon': '🍕', 'color': 0xFFE57373},
    {'name': 'Transportation', 'icon': '🚗', 'color': 0xFF81C784},
    {'name': 'Entertainment', 'icon': '🎬', 'color': 0xFF64B5F6},
    {'name': 'Shopping', 'icon': '🛍️', 'color': 0xFFBA68C8},
    {'name': 'Healthcare', 'icon': '🏥', 'color': 0xFFFF8A65},
    {'name': 'Education', 'icon': '📚', 'color': 0xFFFFB74D},
    {'name': 'Bills & Utilities', 'icon': '💡', 'color': 0xFFA1887F},
    {'name': 'Income', 'icon': '💰', 'color': 0xFF4CAF50},
    {'name': 'Other', 'icon': '📦', 'color': 0xFF90A4AE},
  ];
  
  // Payment methods
  static const List<String> paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Digital Wallet',
    'Bank Transfer',
    'Other'
  ];
  
  // Budget periods
  static const List<String> budgetPeriods = [
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly'
  ];
  
  // Currency symbols
  static const Map<String, String> currencies = {
    'NPR': 'Rs.',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'INR': '₹',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'CHF': 'CHF',
    'CNY': '¥',
    'SGD': 'S\$',
    'NZD': 'NZ\$',
    'HKD': 'HK\$',
    'SEK': 'kr',
    'NOK': 'kr',
    'DKK': 'kr',
    'PLN': 'zł',
    'CZK': 'Kč',
    'HUF': 'Ft',
    'RON': 'lei',
    'BGN': 'лв',
    'HRK': 'kn',
    'RUB': '₽',
    'TRY': '₺',
    'BRL': 'R\$',
    'MXN': '\$',
    'ARS': '\$',
    'CLP': '\$',
    'COP': '\$',
    'PEN': 'S/',
    'UYU': '\$U',
    'ZAR': 'R',
    'EGP': 'E£',
    'MAD': 'DH',
    'TND': 'د.ت',
    'KES': 'KSh',
    'NGN': '₦',
    'GHS': 'GH₵',
    'TZS': 'TSh',
    'UGX': 'USh',
    'BWP': 'P',
    'ZMW': 'ZK',
    'MWK': 'MK',
    'ZWL': 'Z\$',
    'THB': '฿',
    'VND': '₫',
    'IDR': 'Rp',
    'MYR': 'RM',
    'PHP': '₱',
    'KRW': '₩',
    'PKR': 'Rs',
    'LKR': 'Rs',
    'BDT': '৳',
    'AFN': '؋',
    'IRR': '﷼',
    'IQD': 'ع.د',
    'JOD': 'د.ا',
    'KWD': 'د.ك',
    'LBP': 'ل.ل',
    'OMR': 'ر.ع.',
    'QAR': 'ر.ق',
    'SAR': 'ر.س',
    'AED': 'د.إ',
    'YER': '﷼',
    'BHD': '.د.ب',
  };
  
  // Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'MMM dd, yyyy';
  static const String displayTimeFormat = 'HH:mm';
  
  // Validation constants
  static const int maxDescriptionLength = 100;
  static const double maxExpenseAmount = 999999.99;
  static const double minExpenseAmount = 0.01;
  
  // Firebase collections
  static const String usersCollection = 'users';
  static const String expensesCollection = 'expenses';
  static const String categoriesCollection = 'categories';
  static const String budgetsCollection = 'budgets';
  
  // Hive box names
  static const String userBoxName = 'user_box';
  static const String expenseBoxName = 'expense_box';
  static const String categoryBoxName = 'category_box';
  static const String budgetBoxName = 'budget_box';
}

@HiveType(typeId: 10)
enum ExpenseType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}

@HiveType(typeId: 11)
enum BudgetPeriod {
  @HiveField(0)
  weekly,
  @HiveField(1)
  monthly,
  @HiveField(2)
  quarterly,
  @HiveField(3)
  yearly,
}

@HiveType(typeId: 12)
enum PaymentMethod {
  @HiveField(0)
  cash,
  @HiveField(1)
  creditCard,
  @HiveField(2)
  debitCard,
  @HiveField(3)
  digitalWallet,
  @HiveField(4)
  bankTransfer,
  @HiveField(5)
  other,
}
