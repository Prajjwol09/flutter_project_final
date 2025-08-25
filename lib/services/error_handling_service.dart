import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import '../config/environment_config.dart';

/// Comprehensive error handling and monitoring service
class ErrorHandlingService {
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  // Error storage
  final List<AppError> _errorHistory = [];
  final StreamController<AppError> _errorStream = StreamController<AppError>.broadcast();
  
  // Configuration
  static const int _maxErrorHistory = 100;
  static const Duration _errorBurstThreshold = Duration(seconds: 10);
  static const int _maxErrorsInBurst = 5;
  
  // Error tracking
  final Map<String, int> _errorCounts = {};
  final Map<String, DateTime> _lastErrorTimes = {};

  /// Error stream for listening to errors
  Stream<AppError> get errorStream => _errorStream.stream;

  /// Get error history
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);

  /// Initialize error handling
  static void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      ErrorHandlingService().handleFlutterError(details);
    };

    // Catch unhandled async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      ErrorHandlingService().handleUnhandledError(error, stack);
      return true;
    };
  }

  /// Handle Flutter framework errors
  void handleFlutterError(FlutterErrorDetails details) {
    final error = AppError(
      type: ErrorType.flutter,
      message: details.exception.toString(),
      stackTrace: details.stack?.toString(),
      timestamp: DateTime.now(),
      context: details.context?.toString(),
      library: details.library,
    );

    _processError(error);
  }

  /// Handle unhandled async errors
  void handleUnhandledError(Object error, StackTrace stack) {
    final appError = AppError(
      type: ErrorType.unhandled,
      message: error.toString(),
      stackTrace: stack.toString(),
      timestamp: DateTime.now(),
    );

    _processError(appError);
  }

  /// Handle business logic errors
  void handleBusinessError(
    String message, {
    String? context,
    Map<String, dynamic>? metadata,
    ErrorSeverity severity = ErrorSeverity.medium,
    StackTrace? stackTrace,
  }) {
    final error = AppError(
      type: ErrorType.business,
      message: message,
      stackTrace: stackTrace?.toString(),
      timestamp: DateTime.now(),
      context: context,
      metadata: metadata,
      severity: severity,
    );

    _processError(error);
  }

  /// Handle network errors
  void handleNetworkError(
    String message, {
    String? endpoint,
    int? statusCode,
    Map<String, dynamic>? requestData,
    StackTrace? stackTrace,
  }) {
    final error = AppError(
      type: ErrorType.network,
      message: message,
      stackTrace: stackTrace?.toString(),
      timestamp: DateTime.now(),
      metadata: {
        'endpoint': endpoint,
        'statusCode': statusCode,
        'requestData': requestData,
      },
    );

    _processError(error);
  }

  /// Handle Firebase errors
  void handleFirebaseError(
    String message, {
    String? operation,
    String? collection,
    StackTrace? stackTrace,
  }) {
    final error = AppError(
      type: ErrorType.firebase,
      message: message,
      stackTrace: stackTrace?.toString(),
      timestamp: DateTime.now(),
      metadata: {
        'operation': operation,
        'collection': collection,
      },
    );

    _processError(error);
  }

  /// Handle authentication errors
  void handleAuthError(
    String message, {
    String? authMethod,
    StackTrace? stackTrace,
  }) {
    final error = AppError(
      type: ErrorType.authentication,
      message: message,
      stackTrace: stackTrace?.toString(),
      timestamp: DateTime.now(),
      metadata: {
        'authMethod': authMethod,
      },
      severity: ErrorSeverity.high,
    );

    _processError(error);
  }

  /// Handle validation errors
  void handleValidationError(
    String message, {
    String? field,
    dynamic value,
    StackTrace? stackTrace,
  }) {
    final error = AppError(
      type: ErrorType.validation,
      message: message,
      stackTrace: stackTrace?.toString(),
      timestamp: DateTime.now(),
      metadata: {
        'field': field,
        'value': value?.toString(),
      },
      severity: ErrorSeverity.low,
    );

    _processError(error);
  }

  /// Process and store error
  void _processError(AppError error) {
    // Check for error bursts
    if (_isErrorBurst(error)) {
      _handleErrorBurst(error);
      return;
    }

    // Add to history
    _addToHistory(error);

    // Update error counts
    _updateErrorCounts(error);

    // Stream the error
    _errorStream.add(error);

    // Log in development
    if (kDebugMode) {
      _logError(error);
    }

    // Report to external services in production
    if (kReleaseMode) {
      _reportToExternalServices(error);
    }
  }

  /// Check if this is part of an error burst
  bool _isErrorBurst(AppError error) {
    final errorKey = '${error.type}_${error.message}';
    final lastTime = _lastErrorTimes[errorKey];
    final count = _errorCounts[errorKey] ?? 0;

    if (lastTime != null && 
        DateTime.now().difference(lastTime) < _errorBurstThreshold &&
        count >= _maxErrorsInBurst) {
      return true;
    }

    return false;
  }

  /// Handle error burst (rate limiting)
  void _handleErrorBurst(AppError error) {
    final burstError = AppError(
      type: ErrorType.system,
      message: 'Error burst detected: ${error.message}',
      timestamp: DateTime.now(),
      severity: ErrorSeverity.critical,
      metadata: {
        'originalError': error.toJson(),
        'burstCount': _errorCounts['${error.type}_${error.message}'],
      },
    );

    _addToHistory(burstError);
    _errorStream.add(burstError);

    if (kDebugMode) {
      print('🚨 ERROR BURST DETECTED: ${error.message}');
    }
  }

  /// Add error to history
  void _addToHistory(AppError error) {
    _errorHistory.add(error);

    // Maintain max history size
    if (_errorHistory.length > _maxErrorHistory) {
      _errorHistory.removeAt(0);
    }
  }

  /// Update error counts and timing
  void _updateErrorCounts(AppError error) {
    final errorKey = '${error.type}_${error.message}';
    _errorCounts[errorKey] = (_errorCounts[errorKey] ?? 0) + 1;
    _lastErrorTimes[errorKey] = error.timestamp;
  }

  /// Log error for development
  void _logError(AppError error) {
    // In production, use proper logging service instead of print
    // For development only - remove print statements for production
    if (EnvironmentConfig.isDevelopment) {
      // Note: Development logging - [${error.type.name.toUpperCase()}] ${error.message}
      
      if (error.context != null) {
        // Context: ${error.context}
      }
      
      if (error.metadata != null && error.metadata!.isNotEmpty) {
        // Metadata: ${error.metadata}
      }
      
      if (error.stackTrace != null && error.severity.index >= ErrorSeverity.medium.index) {
        // Stack trace: ${error.stackTrace}
      }
    }
  }

  /// Report error to external services
  void _reportToExternalServices(AppError error) {
    // In a real app, you would send errors to services like:
    // - Firebase Crashlytics
    // - Sentry
    // - Bugsnag
    // - Custom analytics service
    
    // Example implementation:
    // FirebaseCrashlytics.instance.recordError(
    //   error.message,
    //   error.stackTrace != null ? StackTrace.fromString(error.stackTrace!) : null,
    //   information: [error.toJson()],
    // );
  }

  /// Get emoji for error type
  String _getErrorEmoji(ErrorType type) {
    switch (type) {
      case ErrorType.flutter:
        return '🐛';
      case ErrorType.network:
        return '🌐';
      case ErrorType.firebase:
        return '🔥';
      case ErrorType.authentication:
        return '🔐';
      case ErrorType.validation:
        return '✅';
      case ErrorType.business:
        return '💼';
      case ErrorType.system:
        return '⚙️';
      case ErrorType.unhandled:
        return '❌';
    }
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStatistics() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final last7Days = now.subtract(const Duration(days: 7));

    final recent24h = _errorHistory.where((e) => e.timestamp.isAfter(last24Hours)).toList();
    final recent7d = _errorHistory.where((e) => e.timestamp.isAfter(last7Days)).toList();

    final typeCountsAll = <String, int>{};
    final typeCounts24h = <String, int>{};
    final severityCounts = <String, int>{};

    for (final error in _errorHistory) {
      typeCountsAll[error.type.name] = (typeCountsAll[error.type.name] ?? 0) + 1;
      severityCounts[error.severity.name] = (severityCounts[error.severity.name] ?? 0) + 1;
    }

    for (final error in recent24h) {
      typeCounts24h[error.type.name] = (typeCounts24h[error.type.name] ?? 0) + 1;
    }

    return {
      'totalErrors': _errorHistory.length,
      'errorsLast24h': recent24h.length,
      'errorsLast7d': recent7d.length,
      'errorsByType': typeCountsAll,
      'errorsByTypeLast24h': typeCounts24h,
      'errorsBySeverity': severityCounts,
      'mostCommonErrors': _getMostCommonErrors(),
      'errorRate24h': recent24h.length / 24, // errors per hour
    };
  }

  /// Get most common errors
  List<Map<String, dynamic>> _getMostCommonErrors() {
    final errorCounts = <String, int>{};
    
    for (final error in _errorHistory) {
      final key = '${error.type.name}: ${error.message}';
      errorCounts[key] = (errorCounts[key] ?? 0) + 1;
    }

    final sorted = errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((entry) => {
      'error': entry.key,
      'count': entry.value,
    }).toList();
  }

  /// Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
    _errorCounts.clear();
    _lastErrorTimes.clear();
  }

  /// Get errors by type
  List<AppError> getErrorsByType(ErrorType type) {
    return _errorHistory.where((error) => error.type == type).toList();
  }

  /// Get errors by severity
  List<AppError> getErrorsBySeverity(ErrorSeverity severity) {
    return _errorHistory.where((error) => error.severity == severity).toList();
  }

  /// Export error log
  String exportErrorLog() {
    final buffer = StringBuffer();
    buffer.writeln('=== FINLYTIC ERROR LOG ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Errors: ${_errorHistory.length}');
    buffer.writeln();

    for (final error in _errorHistory) {
      buffer.writeln('[$_getErrorEmoji(error.type)] ${error.timestamp.toIso8601String()}');
      buffer.writeln('Type: ${error.type.name}');
      buffer.writeln('Severity: ${error.severity.name}');
      buffer.writeln('Message: ${error.message}');
      
      if (error.context != null) {
        buffer.writeln('Context: ${error.context}');
      }
      
      if (error.metadata != null && error.metadata!.isNotEmpty) {
        buffer.writeln('Metadata: ${jsonEncode(error.metadata)}');
      }
      
      if (error.stackTrace != null) {
        buffer.writeln('Stack Trace:');
        buffer.writeln(error.stackTrace);
      }
      
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  /// Dispose resources
  void dispose() {
    _errorStream.close();
  }
}

/// Error types
enum ErrorType {
  flutter,
  network,
  firebase,
  authentication,
  validation,
  business,
  system,
  unhandled,
}

/// Error severity levels
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// Application error model
class AppError {
  final ErrorType type;
  final String message;
  final String? stackTrace;
  final DateTime timestamp;
  final String? context;
  final String? library;
  final Map<String, dynamic>? metadata;
  final ErrorSeverity severity;

  AppError({
    required this.type,
    required this.message,
    this.stackTrace,
    required this.timestamp,
    this.context,
    this.library,
    this.metadata,
    this.severity = ErrorSeverity.medium,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'stackTrace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'library': library,
      'metadata': metadata,
      'severity': severity.name,
    };
  }

  factory AppError.fromJson(Map<String, dynamic> json) {
    return AppError(
      type: ErrorType.values.firstWhere((e) => e.name == json['type']),
      message: json['message'],
      stackTrace: json['stackTrace'],
      timestamp: DateTime.parse(json['timestamp']),
      context: json['context'],
      library: json['library'],
      metadata: json['metadata'],
      severity: ErrorSeverity.values.firstWhere((e) => e.name == json['severity'], orElse: () => ErrorSeverity.medium),
    );
  }

  @override
  String toString() {
    return 'AppError(type: $type, message: $message, severity: $severity)';
  }
}