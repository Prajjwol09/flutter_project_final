import 'package:intl/intl.dart';

class CurrencyUtils {
  // NPR as default currency
  static const String defaultCurrency = 'NPR';
  static const String defaultCurrencySymbol = 'Rs.';
  
  // Currency data for Nepal and common international currencies
  static const Map<String, CurrencyData> currencies = {
    'NPR': CurrencyData(
      code: 'NPR',
      symbol: 'Rs.',
      name: 'Nepalese Rupee',
      decimalPlaces: 2,
      symbolPosition: CurrencySymbolPosition.before,
    ),
    'USD': CurrencyData(
      code: 'USD',
      symbol: '\$',
      name: 'US Dollar',
      decimalPlaces: 2,
      symbolPosition: CurrencySymbolPosition.before,
    ),
    'EUR': CurrencyData(
      code: 'EUR',
      symbol: '€',
      name: 'Euro',
      decimalPlaces: 2,
      symbolPosition: CurrencySymbolPosition.before,
    ),
    'GBP': CurrencyData(
      code: 'GBP',
      symbol: '£',
      name: 'British Pound',
      decimalPlaces: 2,
      symbolPosition: CurrencySymbolPosition.before,
    ),
    'INR': CurrencyData(
      code: 'INR',
      symbol: '₹',
      name: 'Indian Rupee',
      decimalPlaces: 2,
      symbolPosition: CurrencySymbolPosition.before,
    ),
    'CNY': CurrencyData(
      code: 'CNY',
      symbol: '¥',
      name: 'Chinese Yuan',
      decimalPlaces: 2,
      symbolPosition: CurrencySymbolPosition.before,
    ),
    'JPY': CurrencyData(
      code: 'JPY',
      symbol: '¥',
      name: 'Japanese Yen',
      decimalPlaces: 0,
      symbolPosition: CurrencySymbolPosition.before,
    ),
  };

  static CurrencyData getCurrencyData(String currencyCode) {
    return currencies[currencyCode.toUpperCase()] ?? currencies[defaultCurrency]!;
  }

  /// Format amount with NPR currency by default
  static String formatAmount(
    double amount, {
    String? currencyCode,
    bool showSymbol = true,
    bool showCode = false,
    bool compact = false,
  }) {
    final currency = getCurrencyData(currencyCode ?? defaultCurrency);
    
    if (compact && amount >= 1000) {
      return _formatCompactAmount(amount, currency, showSymbol, showCode);
    }
    
    final formatter = NumberFormat.currency(
      locale: _getLocaleForCurrency(currency.code),
      symbol: showSymbol ? currency.symbol : '',
      decimalDigits: currency.decimalPlaces,
    );
    
    String formatted = formatter.format(amount);
    
    // Handle symbol position for NPR and other currencies
    if (showSymbol && currency.symbolPosition == CurrencySymbolPosition.after) {
      formatted = '${formatted.replaceAll(currency.symbol, '')} ${currency.symbol}';
    }
    
    if (showCode) {
      formatted = '$formatted ${currency.code}';
    }
    
    return formatted.trim();
  }

  /// Format amount in Nepali style (lakhs and crores)
  static String formatAmountNepali(double amount, {bool showSymbol = true}) {
    if (amount >= 10000000) { // 1 crore
      final crores = amount / 10000000;
      return '${showSymbol ? 'Rs.' : ''} ${crores.toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) { // 1 lakh
      final lakhs = amount / 100000;
      return '${showSymbol ? 'Rs.' : ''} ${lakhs.toStringAsFixed(2)} L';
    } else if (amount >= 1000) { // 1 thousand
      final thousands = amount / 1000;
      return '${showSymbol ? 'Rs.' : ''} ${thousands.toStringAsFixed(1)} K';
    } else {
      return formatAmount(amount, currencyCode: 'NPR', showSymbol: showSymbol);
    }
  }

  static String _formatCompactAmount(
    double amount,
    CurrencyData currency,
    bool showSymbol,
    bool showCode,
  ) {
    String suffix;
    double value;
    
    if (amount >= 1000000000) {
      suffix = 'B';
      value = amount / 1000000000;
    } else if (amount >= 1000000) {
      suffix = 'M';
      value = amount / 1000000;
    } else if (amount >= 1000) {
      suffix = 'K';
      value = amount / 1000;
    } else {
      return formatAmount(amount, currencyCode: currency.code, showSymbol: showSymbol, showCode: showCode);
    }
    
    final symbol = showSymbol ? currency.symbol : '';
    final code = showCode ? ' ${currency.code}' : '';
    
    return '$symbol${value.toStringAsFixed(1)}$suffix$code';
  }

  static String _getLocaleForCurrency(String currencyCode) {
    switch (currencyCode) {
      case 'NPR':
        return 'ne_NP'; // Nepali locale
      case 'INR':
        return 'hi_IN'; // Hindi locale for Indian Rupee
      case 'USD':
        return 'en_US';
      case 'EUR':
        return 'de_DE';
      case 'GBP':
        return 'en_GB';
      case 'CNY':
        return 'zh_CN';
      case 'JPY':
        return 'ja_JP';
      default:
        return 'en_US';
    }
  }

  /// Parse amount from formatted string
  static double parseAmount(String formattedAmount) {
    // Remove currency symbols and codes
    String cleaned = formattedAmount
        .replaceAll(RegExp(r'[^\d.,\-]'), '')
        .replaceAll(',', '');
    
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Get exchange rate (mock implementation - in real app, fetch from API)
  static double getExchangeRate(String fromCurrency, String toCurrency) {
    // Mock exchange rates - in real app, fetch from API
    const Map<String, double> nprRates = {
      'USD': 132.50, // 1 USD = 132.50 NPR
      'EUR': 144.20, // 1 EUR = 144.20 NPR
      'GBP': 165.80, // 1 GBP = 165.80 NPR
      'INR': 1.60,   // 1 INR = 1.60 NPR
      'CNY': 18.45,  // 1 CNY = 18.45 NPR
      'JPY': 0.89,   // 1 JPY = 0.89 NPR
    };
    
    if (fromCurrency == 'NPR' && toCurrency == 'NPR') return 1.0;
    if (fromCurrency == 'NPR') return 1.0 / (nprRates[toCurrency] ?? 1.0);
    if (toCurrency == 'NPR') return nprRates[fromCurrency] ?? 1.0;
    
    // Convert through NPR
    final fromToNpr = nprRates[fromCurrency] ?? 1.0;
    final toToNpr = nprRates[toCurrency] ?? 1.0;
    return fromToNpr / toToNpr;
  }

  /// Convert amount between currencies
  static double convertAmount(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) {
    if (fromCurrency == toCurrency) return amount;
    final rate = getExchangeRate(fromCurrency, toCurrency);
    return amount * rate;
  }

  /// Format amount with conversion info
  static String formatWithConversion(
    double amount,
    String baseCurrency,
    String displayCurrency, {
    bool showSymbol = true,
  }) {
    if (baseCurrency == displayCurrency) {
      return formatAmount(amount, currencyCode: baseCurrency, showSymbol: showSymbol);
    }
    
    final convertedAmount = convertAmount(amount, baseCurrency, displayCurrency);
    final originalFormatted = formatAmount(amount, currencyCode: baseCurrency, showSymbol: showSymbol);
    final convertedFormatted = formatAmount(convertedAmount, currencyCode: displayCurrency, showSymbol: showSymbol);
    
    return '$convertedFormatted (~$originalFormatted)';
  }
}

class CurrencyData {
  final String code;
  final String symbol;
  final String name;
  final int decimalPlaces;
  final CurrencySymbolPosition symbolPosition;

  const CurrencyData({
    required this.code,
    required this.symbol,
    required this.name,
    required this.decimalPlaces,
    required this.symbolPosition,
  });
}

enum CurrencySymbolPosition {
  before,
  after,
}
