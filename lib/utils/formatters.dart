import 'package:intl/intl.dart';
import 'constants.dart';

/// 💰 Comprehensive formatting utilities for Finlytic
/// Handles currency, dates, numbers, and text formatting
class Formatters {
  // 💱 CURRENCY FORMATTING
  
  /// Format currency amount with proper symbol and locale
  static String formatCurrency(double amount, {String currency = 'NPR'}) {
    final symbol = AppConstants.currencies[currency] ?? currency;
    
    // Use appropriate number formatting based on currency
    if (currency == 'NPR' || currency == 'INR') {
      // Indian numbering system (lakhs, crores)
      return '$symbol${_formatIndianNumber(amount)}';
    } else {
      // Standard international formatting
      final formatter = NumberFormat.currency(
        symbol: symbol,
        decimalDigits: _getDecimalDigits(currency),
      );
      return formatter.format(amount);
    }
  }
  
  /// Format currency without symbol
  static String formatAmount(double amount, {String currency = 'NPR'}) {
    if (currency == 'NPR' || currency == 'INR') {
      return _formatIndianNumber(amount);
    } else {
      final formatter = NumberFormat('#,##0.00');
      return formatter.format(amount);
    }
  }
  
  /// Format compact currency (e.g., 1.2K, 15M)
  static String formatCompactCurrency(double amount, {String currency = 'NPR'}) {
    final symbol = AppConstants.currencies[currency] ?? currency;
    return '$symbol${formatCompactNumber(amount)}';
  }
  
  /// Indian number system formatting (lakhs, crores)
  static String _formatIndianNumber(double amount) {
    if (amount < 1000) {
      return amount.toStringAsFixed(2);
    } else if (amount < 100000) {
      // Thousands
      return NumberFormat('#,##0.00').format(amount);
    } else if (amount < 10000000) {
      // Lakhs
      final lakhs = amount / 100000;
      return '${lakhs.toStringAsFixed(lakhs < 10 ? 2 : 1)}L';
    } else {
      // Crores
      final crores = amount / 10000000;
      return '${crores.toStringAsFixed(crores < 10 ? 2 : 1)}Cr';
    }
  }
  
  /// Get decimal digits for currency
  static int _getDecimalDigits(String currency) {
    // Some currencies don't use decimal places
    const noDecimalCurrencies = ['JPY', 'KRW', 'VND', 'CLP', 'PYG', 'RWF'];
    return noDecimalCurrencies.contains(currency) ? 0 : 2;
  }
  
  // 📅 DATE & TIME FORMATTING
  
  /// Format date for display (e.g., "Mar 15, 2024")
  static String formatDisplayDate(DateTime date) {
    return DateFormat(AppConstants.displayDateFormat).format(date);
  }
  
  /// Format date for storage (e.g., "2024-03-15")
  static String formatStorageDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }
  
  /// Format time for display (e.g., "14:30")
  static String formatDisplayTime(DateTime time) {
    return DateFormat(AppConstants.displayTimeFormat).format(time);
  }
  
  /// Format relative time (e.g., "2 hours ago", "Yesterday")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }
  
  /// Format month year (e.g., "March 2024")
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
  
  /// Format short month year (e.g., "Mar 2024")
  static String formatShortMonthYear(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }
  
  /// Format day month (e.g., "15 Mar")
  static String formatDayMonth(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }
  
  /// Format date (alias for display date)
  static String formatDate(DateTime date) {
    return formatDisplayDate(date);
  }
  
  // 🔢 NUMBER FORMATTING
  
  /// Format number with commas (e.g., "1,234,567")
  static String formatNumber(double number) {
    return NumberFormat('#,##0.##').format(number);
  }
  
  /// Format compact number (e.g., "1.2K", "15M", "3.4B")
  static String formatCompactNumber(double number) {
    if (number < 1000) {
      return number.toStringAsFixed(number == number.roundToDouble() ? 0 : 1);
    } else if (number < 1000000) {
      final thousands = number / 1000;
      return '${thousands.toStringAsFixed(thousands < 10 ? 1 : 0)}K';
    } else if (number < 1000000000) {
      final millions = number / 1000000;
      return '${millions.toStringAsFixed(millions < 10 ? 1 : 0)}M';
    } else {
      final billions = number / 1000000000;
      return '${billions.toStringAsFixed(billions < 10 ? 1 : 0)}B';
    }
  }
  
  /// Format percentage (e.g., "25.5%")
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }
  
  /// Format decimal places
  static String formatDecimal(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }
  
  // 📝 TEXT FORMATTING
  
  /// Capitalize first letter of each word
  static String toTitleCase(String text) {
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
  
  /// Capitalize first letter only
  static String toSentenceCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  /// Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  /// Remove special characters and spaces for IDs
  static String toId(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
  
  /// Format file size (e.g., "1.5 MB")
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
  
  // 📊 FINANCIAL CALCULATIONS
  
  /// Calculate percentage change
  static double calculatePercentageChange(double oldValue, double newValue) {
    if (oldValue == 0) return newValue > 0 ? 100 : 0;
    return ((newValue - oldValue) / oldValue) * 100;
  }
  
  /// Format percentage change with + or - sign
  static String formatPercentageChange(double change) {
    final sign = change >= 0 ? '+' : '';
    return '$sign${formatPercentage(change)}';
  }
  
  /// Calculate monthly average
  static double calculateMonthlyAverage(List<double> amounts, int months) {
    if (amounts.isEmpty || months == 0) return 0;
    final total = amounts.reduce((a, b) => a + b);
    return total / months;
  }
  
  /// Format budget progress
  static String formatBudgetProgress(double spent, double budget) {
    if (budget == 0) return '0%';
    final percentage = (spent / budget) * 100;
    return formatPercentage(percentage.clamp(0, 100));
  }
  
  // 🎯 CATEGORY & LABELS
  
  /// Format expense type
  static String formatExpenseType(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return 'Income';
      case 'expense':
        return 'Expense';
      default:
        return toTitleCase(type);
    }
  }
  
  /// Format payment method
  static String formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'creditcard':
      case 'credit_card':
        return 'Credit Card';
      case 'debitcard':
      case 'debit_card':
        return 'Debit Card';
      case 'digitalwallet':
      case 'digital_wallet':
        return 'Digital Wallet';
      case 'banktransfer':
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return toTitleCase(method.replaceAll('_', ' '));
    }
  }
  
  /// Format budget period
  static String formatBudgetPeriod(String period) {
    switch (period.toLowerCase()) {
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'yearly':
        return 'Yearly';
      default:
        return toTitleCase(period);
    }
  }
  
  // 🔐 PRIVACY & SECURITY
  
  /// Mask sensitive information (e.g., card numbers)
  static String maskCardNumber(String cardNumber) {
    if (cardNumber.length < 4) return cardNumber;
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }
  
  /// Mask email address
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 2) return email;
    
    final maskedUsername = '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}';
    return '$maskedUsername@$domain';
  }
  
  /// Mask phone number
  static String maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length < 4) return phoneNumber;
    return '${'*' * (phoneNumber.length - 4)}${phoneNumber.substring(phoneNumber.length - 4)}';
  }
}

/// Extension methods for easier formatting
extension DoubleFormatting on double {
  String toCurrency({String currency = 'NPR'}) => Formatters.formatCurrency(this, currency: currency);
  String toCompactCurrency({String currency = 'NPR'}) => Formatters.formatCompactCurrency(this, currency: currency);
  String toCompact() => Formatters.formatCompactNumber(this);
  String toPercentage({int decimals = 1}) => Formatters.formatPercentage(this, decimals: decimals);
  String toDecimal({int decimals = 2}) => Formatters.formatDecimal(this, decimals: decimals);
}

extension DateTimeFormatting on DateTime {
  String toDisplayDate() => Formatters.formatDisplayDate(this);
  String toStorageDate() => Formatters.formatStorageDate(this);
  String toDisplayTime() => Formatters.formatDisplayTime(this);
  String toRelativeTime() => Formatters.formatRelativeTime(this);
  String toMonthYear() => Formatters.formatMonthYear(this);
  String toShortMonthYear() => Formatters.formatShortMonthYear(this);
  String toDayMonth() => Formatters.formatDayMonth(this);
}

extension StringFormatting on String {
  String toTitleCase() => Formatters.toTitleCase(this);
  String toSentenceCase() => Formatters.toSentenceCase(this);
  String truncate(int maxLength) => Formatters.truncateText(this, maxLength);
  String toId() => Formatters.toId(this);
  String maskCard() => Formatters.maskCardNumber(this);
  String maskEmail() => Formatters.maskEmail(this);
  String maskPhone() => Formatters.maskPhoneNumber(this);
}