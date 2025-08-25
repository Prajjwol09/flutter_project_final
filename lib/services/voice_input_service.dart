import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceInputService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _isInitialized = false;
  static bool _isListening = false;

  /// Initialize speech recognition
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  /// Start listening for voice input
  static Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError('Speech recognition not available');
        return;
      }
    }

    if (_isListening) {
      await stopListening();
    }

    try {
      _isListening = true;
      await _speech.listen(
        onResult: (result) {
          debugPrint('Speech result: ${result.recognizedWords}');
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          onDevice: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } catch (e) {
      _isListening = false;
      onError('Failed to start listening: $e');
    }
  }

  /// Stop listening
  static Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Check if currently listening
  static bool get isListening => _isListening;

  /// Check if speech recognition is available
  static bool get isAvailable => _isInitialized && _speech.isAvailable;

  /// Parse expense data from voice input text
  static Map<String, dynamic> parseExpenseFromVoice(String voiceInput) {
    final input = voiceInput.toLowerCase().trim();
    if (input.isEmpty) return {};

    // Extract amount
    final amount = _extractAmount(input);
    
    // Extract description
    final description = _extractDescription(input, amount);
    
    // Extract category
    final category = _extractCategory(input);
    
    // Extract payment method
    final paymentMethod = _extractPaymentMethod(input);

    return {
      'amount': amount?.toString() ?? '',
      'description': description ?? '',
      'category': category,
      'paymentMethod': paymentMethod,
      'extractedText': voiceInput,
    };
  }

  /// Extract amount from voice input
  static double? _extractAmount(String input) {
    // Patterns for amount extraction
    final patterns = [
      RegExp(r'(?:spent|paid|cost|price|amount|bill|total|rupees?|rs\.?)\s*(?:is|was|of)?\s*(\d+(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'(\d+(?:\.\d{2})?)\s*(?:rupees?|rs\.?|dollars?|taka)', caseSensitive: false),
      RegExp(r'(\d+(?:\.\d{2})?)', caseSensitive: false), // Any number
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        final amount = double.tryParse(match.group(1) ?? '');
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }

    return null;
  }

  /// Extract description from voice input
  static String? _extractDescription(String input, double? amount) {
    // Remove amount and common phrases
    String cleaned = input;
    
    // Remove amount references
    if (amount != null) {
      cleaned = cleaned.replaceAll(RegExp(r'\b${amount.toString()}\b'), '');
      cleaned = cleaned.replaceAll(RegExp(r'\b${amount.toInt()}\b'), '');
    }
    
    // Remove common expense phrases
    final removePatterns = [
      r'\b(?:i\s+)?(?:spent|paid|bought|purchased|cost|price|bill|total|amount)\b',
      r'\b(?:rupees?|rs\.?|dollars?|taka)\b',
      r'\b(?:for|on|at|in|from)\b',
      r'\b(?:today|yesterday|this\s+morning|this\s+evening)\b',
      r'\b(?:add|create|new)\s+expense\b',
    ];
    
    for (final pattern in removePatterns) {
      cleaned = cleaned.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }
    
    // Clean up extra spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned.isNotEmpty ? cleaned : null;
  }

  /// Extract category from voice input
  static String? _extractCategory(String input) {
    final categoryKeywords = {
      'food & dining': ['food', 'restaurant', 'lunch', 'dinner', 'breakfast', 'meal', 'eating', 'cafe', 'hotel'],
      'transportation': ['bus', 'taxi', 'fuel', 'petrol', 'diesel', 'transport', 'travel', 'auto', 'rickshaw'],
      'shopping': ['shopping', 'clothes', 'dress', 'shoes', 'market', 'mall', 'store', 'grocery'],
      'entertainment': ['movie', 'cinema', 'game', 'entertainment', 'fun', 'party', 'music'],
      'health & medical': ['medicine', 'doctor', 'hospital', 'medical', 'pharmacy', 'health', 'treatment'],
      'education': ['book', 'education', 'course', 'class', 'school', 'college', 'study'],
      'utilities': ['electricity', 'water', 'internet', 'phone', 'utility', 'bill'],
      'personal care': ['haircut', 'salon', 'beauty', 'cosmetics', 'personal', 'care'],
    };

    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (input.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  /// Extract payment method from voice input
  static String _extractPaymentMethod(String input) {
    if (input.contains('cash')) return 'cash';
    if (input.contains('card') || input.contains('credit') || input.contains('debit')) return 'card';
    if (input.contains('esewa')) return 'esewa';
    if (input.contains('khalti')) return 'khalti';
    if (input.contains('ime pay')) return 'imePay';
    if (input.contains('digital') || input.contains('online')) return 'digitalWallet';
    
    return 'cash'; // Default
  }

  /// Get supported locales
  static Future<List<stt.LocaleName>> getSupportedLocales() async {
    if (!_isInitialized) await initialize();
    return await _speech.locales();
  }

  /// Dispose resources
  static void dispose() {
    stopListening();
  }
}
