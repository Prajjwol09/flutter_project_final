import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/expense_model.dart';

class AiParsedExpenseResult {
  final double? amount;
  final String? description;
  final String? categoryName;
  final String? paymentMethod;
  final String? type; // income | expense
  final DateTime? date;
  final String? merchant;
  final String? location;
  final double? confidence;
  final List<String>? tags;
  final Map<String, dynamic>? additionalData;

  AiParsedExpenseResult({
    this.amount,
    this.description,
    this.categoryName,
    this.paymentMethod,
    this.type,
    this.date,
    this.merchant,
    this.location,
    this.confidence,
    this.tags,
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'description': description,
      'categoryName': categoryName,
      'paymentMethod': paymentMethod,
      'type': type,
      'date': date?.toIso8601String(),
      'merchant': merchant,
      'location': location,
      'confidence': confidence,
      'tags': tags,
      'additionalData': additionalData,
    };
  }
}

class AiInsight {
  final String title;
  final String description;
  final String type; // warning, info, suggestion, achievement
  final double? impact;
  final String? actionText;
  final VoidCallback? action;

  AiInsight({
    required this.title,
    required this.description,
    required this.type,
    this.impact,
    this.actionText,
    this.action,
  });
}

class SpendingPattern {
  final String category;
  final double averageAmount;
  final int frequency;
  final String trend; // increasing, decreasing, stable
  final double changePercentage;

  SpendingPattern({
    required this.category,
    required this.averageAmount,
    required this.frequency,
    required this.trend,
    required this.changePercentage,
  });
}

class AiService {
  static const String _openRouterEndpoint = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'moonshotai/kimi-k2:free';
  static final Logger _logger = Logger();
  
  // Provide API key via secrets or environment; empty key means offline fallback parsing
  static String get _apiKey => const String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: '');

  static bool get isEnabled => _apiKey.isNotEmpty;

  // Enhanced system prompts for different tasks
  static const String _expenseParsingPrompt = '''
You are an expert financial AI assistant. Extract expense/income data from text with high accuracy.

OUTPUT ONLY VALID JSON with these exact keys:
{
  "amount": number or null,
  "description": "string or null",
  "categoryName": "string or null", 
  "paymentMethod": "string or null",
  "type": "expense" or "income" or null,
  "date": "ISO-8601 string or null",
  "merchant": "string or null",
  "location": "string or null",
  "confidence": number 0-1,
  "tags": ["array", "of", "strings"] or null
}

Categories: Food & Dining, Transportation, Shopping, Entertainment, Healthcare, Education, Bills & Utilities, Income, Other
Payment Methods: Cash, Credit Card, Debit Card, Digital Wallet, Bank Transfer, Other

Analyze context for merchant names, locations, and confidence scores.
''';

  static const String _insightsPrompt = '''
You are a financial advisor AI. Analyze spending patterns and provide actionable insights.

Provide insights in this JSON format:
{
  "insights": [
    {
      "title": "insight title",
      "description": "detailed description",
      "type": "warning|info|suggestion|achievement",
      "impact": 0-1 score,
      "actionText": "action button text or null"
    }
  ]
}

Focus on: spending patterns, budget optimization, saving opportunities, unusual transactions.
''';

  static const String _categorizationPrompt = '''
You are a smart categorization AI. Suggest the best category for expenses based on description and context.

OUTPUT ONLY JSON:
{
  "category": "exact category name",
  "confidence": 0-1 score,
  "alternatives": ["category1", "category2"],
  "reasoning": "brief explanation"
}

Available categories: Food & Dining, Transportation, Shopping, Entertainment, Healthcare, Education, Bills & Utilities, Income, Other
''';

  // Enhanced expense parsing with better AI integration
  static Future<AiParsedExpenseResult> parseExpenseFromText(String text) async {
    if (_apiKey.isEmpty) {
      _logger.w('No OpenRouter API key found, using fallback parsing');
      return _fallbackParse(text);
    }

    return _makeAiRequest(_expenseParsingPrompt, text, _parseExpenseResponse);
  }

  // Smart categorization for expenses
  static Future<Map<String, dynamic>> suggestCategory(String description, String? context) async {
    if (_apiKey.isEmpty) {
      return _fallbackCategorization(description);
    }

    final fullText = context != null ? '$description $context' : description;
    return _makeAiRequest(_categorizationPrompt, fullText, _parseCategoryResponse);
  }

  // Generate financial insights from spending data
  static Future<List<AiInsight>> generateInsights(List<ExpenseModel> expenses, {
    List<Map<String, dynamic>>? budgets,
    Map<String, double>? categoryTotals,
  }) async {
    if (_apiKey.isEmpty) {
      return _generateFallbackInsights(expenses);
    }

    final spendingData = _formatSpendingData(expenses, budgets, categoryTotals);
    final insights = await _makeAiRequest(_insightsPrompt, spendingData, _parseInsightsResponse);
    return insights;
  }

  // Enhanced receipt parsing for detailed line items
  static Future<Map<String, dynamic>> parseReceipt(String ocrText) async {
    if (_apiKey.isEmpty) {
      return _fallbackReceiptParse(ocrText);
    }

    const receiptPrompt = '''
Parse this receipt text and extract detailed information. OUTPUT ONLY JSON:
{
  "merchant": "merchant name",
  "total": number,
  "date": "ISO-8601 date",
  "items": [
    {"name": "item name", "price": number, "quantity": number}
  ],
  "paymentMethod": "method",
  "location": "address/location",
  "confidence": 0-1 score
}
''';

    return _makeAiRequest(receiptPrompt, ocrText, _parseReceiptResponse);
  }

  // Generic AI request handler
  static Future<T> _makeAiRequest<T>(
    String systemPrompt, 
    String userInput, 
    T Function(Map<String, dynamic>) responseParser,
  ) async {
    try {
    final body = {
        'model': _model,
      'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userInput},
      ],
        'temperature': 0.1,
        'max_tokens': 1000,
    };

      _logger.d('Making AI request to OpenRouter');
      
      final resp = await http.post(
        Uri.parse(_openRouterEndpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'finlytic.app',
          'X-Title': 'Finlytic',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final content = data['choices']?[0]?['message']?['content']?.toString() ?? '';
        
        _logger.d('AI Response: $content');
        
        // Extract JSON from response
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0)!;
          final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
          return responseParser(parsed);
        }
      } else {
        _logger.e('AI request failed: ${resp.statusCode} - ${resp.body}');
      }
    } catch (e) {
      _logger.e('AI request error: $e');
    }
    
    // Return appropriate fallback
    if (T == AiParsedExpenseResult) {
      return _fallbackParse(userInput) as T;
    } else if (T == Map<String, dynamic>) {
      return <String, dynamic>{} as T;
    } else if (T == List<AiInsight>) {
      return <AiInsight>[] as T;
    }
    
    // Default fallback
    return _fallbackParse(userInput) as T;
  }

  // Response parsers
  static AiParsedExpenseResult _parseExpenseResponse(Map<String, dynamic> data) {
          return AiParsedExpenseResult(
      amount: (data['amount'] is num) ? (data['amount'] as num).toDouble() : double.tryParse('${data['amount']}'),
      description: data['description']?.toString(),
      categoryName: data['categoryName']?.toString(),
      paymentMethod: data['paymentMethod']?.toString(),
      type: data['type']?.toString(),
      date: data['date'] != null ? DateTime.tryParse(data['date'].toString()) : null,
      merchant: data['merchant']?.toString(),
      location: data['location']?.toString(),
      confidence: (data['confidence'] is num) ? (data['confidence'] as num).toDouble() : null,
      tags: data['tags'] is List ? (data['tags'] as List).map((e) => e.toString()).toList() : null,
      additionalData: data['additionalData'] as Map<String, dynamic>?,
    );
  }

  static Map<String, dynamic> _parseCategoryResponse(Map<String, dynamic> data) {
    return {
      'category': data['category']?.toString(),
      'confidence': (data['confidence'] is num) ? (data['confidence'] as num).toDouble() : 0.5,
      'alternatives': data['alternatives'] is List ? (data['alternatives'] as List).map((e) => e.toString()).toList() : [],
      'reasoning': data['reasoning']?.toString(),
    };
  }

  static List<AiInsight> _parseInsightsResponse(Map<String, dynamic> data) {
    final insights = <AiInsight>[];
    if (data['insights'] is List) {
      for (final insight in data['insights'] as List) {
        if (insight is Map<String, dynamic>) {
          insights.add(AiInsight(
            title: insight['title']?.toString() ?? '',
            description: insight['description']?.toString() ?? '',
            type: insight['type']?.toString() ?? 'info',
            impact: (insight['impact'] is num) ? (insight['impact'] as num).toDouble() : null,
            actionText: insight['actionText']?.toString(),
          ));
        }
      }
    }
    return insights;
  }

  static Map<String, dynamic> _parseReceiptResponse(Map<String, dynamic> data) {
    return {
      'merchant': data['merchant']?.toString(),
      'total': (data['total'] is num) ? (data['total'] as num).toDouble() : null,
      'date': data['date'] != null ? DateTime.tryParse(data['date'].toString()) : null,
      'items': data['items'] is List ? data['items'] as List : [],
      'paymentMethod': data['paymentMethod']?.toString(),
      'location': data['location']?.toString(),
      'confidence': (data['confidence'] is num) ? (data['confidence'] as num).toDouble() : 0.5,
    };
  }

  // Helper methods
  static String _formatSpendingData(
    List<ExpenseModel> expenses, 
    List<Map<String, dynamic>>? budgets,
    Map<String, double>? categoryTotals,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Recent Spending Data:');
    
    // Add recent expenses summary
    final recentExpenses = expenses.take(20).toList();
    for (final expense in recentExpenses) {
      buffer.writeln('${expense.description}: \$${expense.amount.toStringAsFixed(2)} (${expense.type.name})');
    }
    
    if (categoryTotals != null) {
      buffer.writeln('\nCategory Totals:');
      categoryTotals.forEach((category, total) {
        buffer.writeln('$category: \$${total.toStringAsFixed(2)}');
      });
    }
    
    if (budgets != null) {
      buffer.writeln('\nBudget Information:');
      for (final budget in budgets) {
        buffer.writeln('${budget['category']}: \$${budget['amount']} budget');
      }
    }
    
    return buffer.toString();
  }

  // Fallback methods
  static AiParsedExpenseResult _fallbackParse(String text) {
    final amountMatch = RegExp(r'(?:rs\.?|usd|inr|npr|\$|€|£)?\s*([0-9]+(?:\.[0-9]{1,2})?)', caseSensitive: false).firstMatch(text);
    final amount = amountMatch != null ? double.tryParse(amountMatch.group(1)!) : null;

    final dateMatch = RegExp(r'(\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4}|\d{1,2}\s\w+\s\d{4})').firstMatch(text);
    DateTime? when;
    if (dateMatch != null) {
      when = DateTime.tryParse(dateMatch.group(0)!);
    }

    final isIncome = RegExp(r'\b(received|income|credit|earned|salary)\b', caseSensitive: false).hasMatch(text);
    final isExpense = RegExp(r'\b(spent|paid|debit|purchase|bought)\b', caseSensitive: false).hasMatch(text);

    String? category;
    String? merchant;
    if (RegExp(r'food|restaurant|coffee|dining|mcdonald|kfc|pizza', caseSensitive: false).hasMatch(text)) {
      category = 'Food & Dining';
      merchant = RegExp(r'(mcdonald|kfc|pizza hut|starbucks|subway)', caseSensitive: false).stringMatch(text);
    } else if (RegExp(r'uber|taxi|bus|train|fuel|gas|lyft', caseSensitive: false).hasMatch(text)) {
      category = 'Transportation';
      merchant = RegExp(r'(uber|lyft|taxi)', caseSensitive: false).stringMatch(text);
    } else if (RegExp(r'shopping|store|mall|clothes|amazon|walmart', caseSensitive: false).hasMatch(text)) {
      category = 'Shopping';
      merchant = RegExp(r'(amazon|walmart|target|costco)', caseSensitive: false).stringMatch(text);
    }

    return AiParsedExpenseResult(
      amount: amount,
      description: _firstSentence(text),
      categoryName: category,
      paymentMethod: RegExp(r'card|cash|wallet|upi|bank', caseSensitive: false).stringMatch(text)?.toString(),
      type: isIncome && !isExpense ? 'income' : 'expense',
      date: when,
      merchant: merchant,
      confidence: amount != null ? 0.7 : 0.3,
      tags: _extractTags(text),
    );
  }

  static Map<String, dynamic> _fallbackCategorization(String description) {
    String category = 'Other';
    double confidence = 0.5;
    final alternatives = <String>[];

    if (RegExp(r'food|restaurant|coffee|dining', caseSensitive: false).hasMatch(description)) {
      category = 'Food & Dining';
      confidence = 0.8;
      alternatives.addAll(['Entertainment']);
    } else if (RegExp(r'uber|taxi|bus|train|fuel|gas', caseSensitive: false).hasMatch(description)) {
      category = 'Transportation';
      confidence = 0.8;
    } else if (RegExp(r'shopping|store|mall|clothes', caseSensitive: false).hasMatch(description)) {
      category = 'Shopping';
      confidence = 0.7;
      alternatives.addAll(['Entertainment']);
    }

    return {
      'category': category,
      'confidence': confidence,
      'alternatives': alternatives,
      'reasoning': 'Based on keyword matching'
    };
  }

  static List<AiInsight> _generateFallbackInsights(List<ExpenseModel> expenses) {
    final insights = <AiInsight>[];
    
    if (expenses.isEmpty) return insights;

    // Calculate basic statistics
    final totalSpent = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final avgDaily = totalSpent / 30; // Assuming 30 days
    
    if (avgDaily > 50) {
      insights.add(AiInsight(
        title: 'High Daily Spending',
        description: 'Your average daily spending is \$${avgDaily.toStringAsFixed(2)}. Consider reviewing your expenses.',
        type: 'warning',
        impact: 0.7,
        actionText: 'Review Budget',
      ));
    }

    // Find most expensive category
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      categoryTotals[expense.categoryId] = (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
    }
    
    if (categoryTotals.isNotEmpty) {
      final topCategory = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add(AiInsight(
        title: 'Top Spending Category',
        description: 'Most of your spending (\$${topCategory.value.toStringAsFixed(2)}) goes to ${topCategory.key}.',
        type: 'info',
        impact: 0.5,
      ));
    }

    return insights;
  }

  static Map<String, dynamic> _fallbackReceiptParse(String ocrText) {
    // Simple regex-based receipt parsing
    final totalMatch = RegExp(r'total[:\s]*\$?([0-9]+\.?[0-9]*)', caseSensitive: false).firstMatch(ocrText);
    final dateMatch = RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})').firstMatch(ocrText);
    
    return {
      'merchant': _extractMerchantName(ocrText),
      'total': totalMatch != null ? double.tryParse(totalMatch.group(1)!) : null,
      'date': dateMatch != null ? DateTime.tryParse(dateMatch.group(1)!) : null,
      'items': <Map<String, dynamic>>[],
      'confidence': 0.4,
    };
  }

  static String? _extractMerchantName(String text) {
    // Common merchant patterns
    final merchants = ['walmart', 'target', 'amazon', 'starbucks', 'mcdonald', 'kfc'];
    for (final merchant in merchants) {
      if (RegExp(merchant, caseSensitive: false).hasMatch(text)) {
        return merchant.toUpperCase();
      }
    }
    return null;
  }

  static List<String> _extractTags(String text) {
    final tags = <String>[];
    if (RegExp(r'urgent|emergency', caseSensitive: false).hasMatch(text)) tags.add('urgent');
    if (RegExp(r'business|work', caseSensitive: false).hasMatch(text)) tags.add('business');
    if (RegExp(r'personal|family', caseSensitive: false).hasMatch(text)) tags.add('personal');
    return tags;
  }

  static String _firstSentence(String text) {
    final idx = text.indexOf('.');
    return (idx > 0 ? text.substring(0, idx) : text).trim();
  }
}
