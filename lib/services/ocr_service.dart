import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import '../models/expense_model.dart';
import '../models/category_model.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'package:uuid/uuid.dart';

/// 🔍 OCR Service for Receipt Text Recognition
/// Powered by Google ML Kit for offline text recognition
class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  late final TextRecognizer _textRecognizer;
  bool _isInitialized = false;

  /// Initialize the OCR service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('✅ OCR Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize OCR Service: $e');
      }
      rethrow;
    }
  }

  /// Dispose the OCR service
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    try {
      await _textRecognizer.close();
      _isInitialized = false;
      
      if (kDebugMode) {
        debugPrint('🗑️ OCR Service disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error disposing OCR Service: $e');
      }
    }
  }

  /// Process image and extract text
  Future<OCRResult> processImage(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        return OCRResult(
          success: false,
          message: 'No text found in the image',
          rawText: '',
        );
      }

      // Parse the text to extract expense information
      final expenseData = _parseReceiptText(recognizedText.text);
      
      return OCRResult(
        success: true,
        message: 'Text extracted successfully',
        rawText: recognizedText.text,
        extractedAmount: expenseData.amount,
        extractedMerchant: expenseData.merchant,
        extractedDate: expenseData.date,
        extractedItems: expenseData.items,
        confidence: _calculateConfidence(recognizedText),
        suggestedCategory: expenseData.suggestedCategory,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ OCR processing failed: $e');
      }
      
      return OCRResult(
        success: false,
        message: 'Failed to process image: ${e.toString()}',
        rawText: '',
      );
    }
  }

  /// Process image from bytes
  Future<OCRResult> processImageBytes(Uint8List imageBytes) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(800, 600), // Default size, adjust as needed
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.yuv420,
          bytesPerRow: 800,
        ),
      );
      
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        return OCRResult(
          success: false,
          message: 'No text found in the image',
          rawText: '',
        );
      }

      final expenseData = _parseReceiptText(recognizedText.text);
      
      return OCRResult(
        success: true,
        message: 'Text extracted successfully',
        rawText: recognizedText.text,
        extractedAmount: expenseData.amount,
        extractedMerchant: expenseData.merchant,
        extractedDate: expenseData.date,
        extractedItems: expenseData.items,
        confidence: _calculateConfidence(recognizedText),
        suggestedCategory: expenseData.suggestedCategory,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ OCR processing from bytes failed: $e');
      }
      
      return OCRResult(
        success: false,
        message: 'Failed to process image: ${e.toString()}',
        rawText: '',
      );
    }
  }

  /// Parse receipt text to extract expense information
  ReceiptData _parseReceiptText(String text) {
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    double? amount;
    String? merchant;
    DateTime? date;
    List<String> items = [];
    String? suggestedCategory;

    // Extract amount (look for patterns like $10.50, Rs. 1,500, 10.50)
    amount = _extractAmount(lines);
    
    // Extract merchant name (usually one of the first few lines)
    merchant = _extractMerchant(lines);
    
    // Extract date
    date = _extractDate(lines);
    
    // Extract items
    items = _extractItems(lines);
    
    // Suggest category based on merchant and items
    suggestedCategory = _suggestCategory(merchant, items);

    return ReceiptData(
      amount: amount,
      merchant: merchant,
      date: date,
      items: items,
      suggestedCategory: suggestedCategory,
    );
  }

  /// Extract amount from text lines
  double? _extractAmount(List<String> lines) {
    final amountPatterns = [
      // Nepali Rupees: Rs. 1,500.50, NPR 1500, Rs 1500
      RegExp(r'(?:Rs\.?|NPR|रु)\s*([0-9,]+\.?[0-9]*)', caseSensitive: false),
      // USD/Generic: $10.50, 10.50
      RegExp(r'\$\s*([0-9,]+\.[0-9]{2})', caseSensitive: false),
      // Total patterns: Total: 1500, Total 1500.50
      RegExp(r'(?:total|amount|sum|grand total)[\s:]*(?:Rs\.?|NPR|रु|\$)?\s*([0-9,]+\.?[0-9]*)', caseSensitive: false),
      // Generic number patterns (last resort)
      RegExp(r'([0-9,]+\.[0-9]{2})', caseSensitive: false),
      RegExp(r'([0-9,]+)', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in amountPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final amountStr = match.group(1)?.replaceAll(',', '');
          final amount = double.tryParse(amountStr ?? '');
          if (amount != null && amount > 0 && amount < 1000000) {
            return amount;
          }
        }
      }
    }
    return null;
  }

  /// Extract merchant name from text lines
  String? _extractMerchant(List<String> lines) {
    if (lines.isEmpty) return null;
    
    // Skip common receipt headers and look for actual merchant names
    final skipPatterns = [
      RegExp(r'^(receipt|bill|invoice|tax invoice)$', caseSensitive: false),
      RegExp(r'^[0-9\-/\s]+$'), // Date-only lines
      RegExp(r'^[\*\-\=\s]+$'), // Decoration lines
    ];
    
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      
      // Skip if matches skip patterns
      if (skipPatterns.any((pattern) => pattern.hasMatch(line))) {
        continue;
      }
      
      // Check if line contains letters (potential merchant name)
      if (line.length > 2 && RegExp(r'[a-zA-Z]').hasMatch(line)) {
        // Clean up the line
        final cleaned = line.replaceAll(RegExp(r'[^\w\s]'), '').trim();
        if (cleaned.length > 2) {
          return Formatters.toTitleCase(cleaned);
        }
      }
    }
    
    return null;
  }

  /// Extract date from text lines
  DateTime? _extractDate(List<String> lines) {
    final datePatterns = [
      // DD/MM/YYYY, DD-MM-YYYY
      RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})'),
      // MM/DD/YYYY
      RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})'),
      // YYYY-MM-DD
      RegExp(r'(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})'),
      // DD MMM YYYY (e.g., 15 Mar 2024)
      RegExp(r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          try {
            // Try to parse the date (this is simplified, could be more robust)
            final now = DateTime.now();
            // For now, return current date - in real implementation, parse the matched groups
            return now;
          } catch (e) {
            continue;
          }
        }
      }
    }
    
    return null;
  }

  /// Extract items from receipt text
  List<String> _extractItems(List<String> lines) {
    final items = <String>[];
    
    for (final line in lines) {
      // Skip lines that look like headers, totals, or merchant info
      if (_isItemLine(line)) {
        final cleanedItem = _cleanItemName(line);
        if (cleanedItem.isNotEmpty && cleanedItem.length > 2) {
          items.add(cleanedItem);
        }
      }
    }
    
    return items.take(10).toList(); // Limit to 10 items
  }

  /// Check if a line represents an item
  bool _isItemLine(String line) {
    // Skip if line is too short
    if (line.length < 3) return false;
    
    // Skip common non-item patterns
    final skipPatterns = [
      RegExp(r'^(total|subtotal|tax|discount|amount|grand total|receipt|bill)', caseSensitive: false),
      RegExp(r'^[\*\-\=\s]+$'), // Decoration lines
      RegExp(r'^\d+[\/\-]\d+[\/\-]\d+'), // Date lines
      RegExp(r'^thank you|please come again', caseSensitive: false),
    ];
    
    if (skipPatterns.any((pattern) => pattern.hasMatch(line))) {
      return false;
    }
    
    // Likely an item if it contains letters and possibly numbers/prices
    return RegExp(r'[a-zA-Z]').hasMatch(line);
  }

  /// Clean item name by removing prices and extra characters
  String _cleanItemName(String line) {
    // Remove common price patterns
    String cleaned = line.replaceAll(RegExp(r'(?:Rs\.?|NPR|রু|\$)\s*[0-9,]+\.?[0-9]*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\b[0-9,]+\.[0-9]{2}\b'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\b[0-9,]+\b'), '');
    
    // Remove extra whitespace and special characters
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\s]'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return Formatters.toTitleCase(cleaned);
  }

  /// Suggest category based on merchant and items
  String? _suggestCategory(String? merchant, List<String> items) {
    final merchantLower = merchant?.toLowerCase() ?? '';
    final allText = '$merchantLower ${items.join(' ').toLowerCase()}';
    
    // Food & Dining
    if (_containsAny(allText, ['restaurant', 'cafe', 'pizza', 'burger', 'food', 'kitchen', 'dining', 'meal', 'lunch', 'dinner', 'coffee', 'tea'])) {
      return 'Food & Dining';
    }
    
    // Transportation
    if (_containsAny(allText, ['gas', 'fuel', 'taxi', 'uber', 'lyft', 'bus', 'metro', 'transport', 'parking', 'toll'])) {
      return 'Transportation';
    }
    
    // Shopping
    if (_containsAny(allText, ['store', 'shop', 'mart', 'mall', 'supermarket', 'grocery', 'clothes', 'fashion', 'electronics'])) {
      return 'Shopping';
    }
    
    // Healthcare
    if (_containsAny(allText, ['hospital', 'clinic', 'doctor', 'pharmacy', 'medical', 'health', 'medicine', 'dental'])) {
      return 'Healthcare';
    }
    
    // Entertainment
    if (_containsAny(allText, ['movie', 'cinema', 'theater', 'game', 'entertainment', 'park', 'museum', 'concert'])) {
      return 'Entertainment';
    }
    
    // Default to "Other" if no match
    return 'Other';
  }

  /// Helper method to check if text contains any of the keywords
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Calculate confidence score based on text recognition quality
  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    int elementCount = 0;
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          // In real implementation, you might have access to confidence scores
          // For now, we'll estimate based on text quality
          totalConfidence += _estimateElementConfidence(element.text);
          elementCount++;
        }
      }
    }
    
    return elementCount > 0 ? (totalConfidence / elementCount).clamp(0.0, 1.0) : 0.0;
  }

  /// Estimate confidence for a text element
  double _estimateElementConfidence(String text) {
    if (text.isEmpty) return 0.0;
    
    // Higher confidence for:
    // - Longer text
    // - Text with letters and numbers
    // - Text without many special characters
    
    double confidence = 0.5; // Base confidence
    
    if (text.length > 3) confidence += 0.2;
    if (RegExp(r'[a-zA-Z]').hasMatch(text)) confidence += 0.2;
    if (RegExp(r'[0-9]').hasMatch(text)) confidence += 0.1;
    
    // Reduce confidence for too many special characters
    final specialCharCount = text.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '').length;
    if (specialCharCount > text.length * 0.3) {
      confidence -= 0.2;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Extract expense data from raw OCR text
  Map<String, dynamic>? extractExpenseData(String text) {
    if (text.isEmpty) return null;
    
    try {
      final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
      
      // Extract amount
      final amount = _extractAmount(lines);
      if (amount == null) return null;
      
      // Extract other data
      final merchant = _extractMerchant(lines);
      final date = _extractDate(lines);
      final items = _extractItems(lines);
      final category = _suggestCategory(merchant, items);
      
      return {
        'amount': amount,
        'date': date?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'description': merchant ?? 'Receipt',
        'category': category ?? 'Other',
        'rawText': text,
      };
    } catch (e) {
      return null;
    }
  }
}

/// Result of OCR processing
class OCRResult {
  final bool success;
  final String message;
  final String rawText;
  final double? extractedAmount;
  final String? extractedMerchant;
  final DateTime? extractedDate;
  final List<String> extractedItems;
  final double confidence;
  final String? suggestedCategory;

  OCRResult({
    required this.success,
    required this.message,
    required this.rawText,
    this.extractedAmount,
    this.extractedMerchant,
    this.extractedDate,
    this.extractedItems = const [],
    this.confidence = 0.0,
    this.suggestedCategory,
  });

  /// Convert to expense model with provided user and category info
  ExpenseModel? toExpenseModel({
    required String userId,
    required String categoryId,
    String paymentMethod = 'Cash',
  }) {
    if (!success || extractedAmount == null) return null;
    
    return ExpenseModel(
      id: const Uuid().v4(),
      userId: userId,
      categoryId: categoryId,
      amount: extractedAmount!,
      description: extractedMerchant ?? 'OCR Expense',
      paymentMethod: paymentMethod,
      transactionDate: extractedDate ?? DateTime.now(),
      createdAt: DateTime.now(),
      type: ExpenseType.expense,
      notes: 'Imported from receipt via OCR',
    );
  }

  @override
  String toString() {
    return 'OCRResult{success: $success, amount: $extractedAmount, merchant: $extractedMerchant, confidence: $confidence}';
  }
}

/// Internal data structure for parsed receipt data
class ReceiptData {
  final double? amount;
  final String? merchant;
  final DateTime? date;
  final List<String> items;
  final String? suggestedCategory;

  ReceiptData({
    this.amount,
    this.merchant,
    this.date,
    this.items = const [],
    this.suggestedCategory,
  });
}

/// Extension for easier OCR integration
extension OCRServiceExtension on OCRService {
  /// Quick process for simple amount extraction
  Future<double?> extractAmountFromImage(String imagePath) async {
    final result = await processImage(imagePath);
    return result.extractedAmount;
  }
  
  /// Process image and create expense model directly
  Future<ExpenseModel?> createExpenseFromReceipt({
    required String imagePath,
    required String userId,
    required List<CategoryModel> categories,
    String defaultPaymentMethod = 'Cash',
  }) async {
    final result = await processImage(imagePath);
    if (!result.success || result.extractedAmount == null) return null;
    
    // Find matching category or use default
    String categoryId = categories.first.id; // Default to first category
    
    if (result.suggestedCategory != null) {
      final matchingCategory = categories.firstWhere(
        (cat) => cat.name == result.suggestedCategory,
        orElse: () => categories.first,
      );
      categoryId = matchingCategory.id;
    }
    
    return result.toExpenseModel(
      userId: userId,
      categoryId: categoryId,
      paymentMethod: defaultPaymentMethod,
    );
  }
}