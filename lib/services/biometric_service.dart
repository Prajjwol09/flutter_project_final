import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 🔐 Biometric Authentication Service
/// Handles fingerprint, face ID, and device authentication
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Cache for availability check
  bool? _isAvailableCache;
  List<BiometricType>? _availableTypesCache;

  /// Check if biometric authentication is available on device
  Future<bool> isAvailable() async {
    if (_isAvailableCache != null) return _isAvailableCache!;
    
    try {
      _isAvailableCache = await _localAuth.canCheckBiometrics;
      return _isAvailableCache!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking biometric availability: $e');
      }
      _isAvailableCache = false;
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (_availableTypesCache != null) return _availableTypesCache!;
    
    try {
      final isAvailable = await this.isAvailable();
      if (!isAvailable) {
        _availableTypesCache = [];
        return [];
      }

      _availableTypesCache = await _localAuth.getAvailableBiometrics();
      return _availableTypesCache!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting available biometrics: $e');
      }
      _availableTypesCache = [];
      return [];
    }
  }

  /// Check if device has enrolled biometrics
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking enrolled biometrics: $e');
      }
      return false;
    }
  }

  /// Authenticate using biometrics
  Future<BiometricAuthResult> authenticate({
    String localizedReason = 'Please authenticate to access your financial data',
    bool biometricOnly = false,
    bool stickyAuth = true,
    bool sensitiveTransaction = false,
  }) async {
    try {
      // Check if biometrics are available
      final isAvailable = await this.isAvailable();
      if (!isAvailable) {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.notAvailable,
          message: 'Biometric authentication is not available on this device',
        );
      }

      // Check if any biometrics are enrolled
      final hasEnrolled = await hasEnrolledBiometrics();
      if (!hasEnrolled) {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.notEnrolled,
          message: 'No biometrics are enrolled on this device',
        );
      }

      // Perform authentication
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: stickyAuth,
          sensitiveTransaction: sensitiveTransaction,
        ),
      );

      if (authenticated) {
        return BiometricAuthResult(
          success: true,
          message: 'Authentication successful',
        );
      } else {
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.userCancel,
          message: 'Authentication was cancelled by user',
        );
      }
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Unexpected biometric error: $e');
      }
      return BiometricAuthResult(
        success: false,
        errorType: BiometricErrorType.unknown,
        message: 'An unexpected error occurred during authentication',
      );
    }
  }

  /// Quick authenticate for app unlock
  Future<bool> quickAuthenticate() async {
    final result = await authenticate(
      localizedReason: 'Unlock Finlytic',
      biometricOnly: true,
      stickyAuth: false,
    );
    return result.success;
  }

  /// Authenticate for sensitive operations (payments, settings)
  Future<bool> authenticateForSensitiveOperation({
    required String operation,
  }) async {
    final result = await authenticate(
      localizedReason: 'Authenticate to $operation',
      biometricOnly: false,
      stickyAuth: true,
      sensitiveTransaction: true,
    );
    return result.success;
  }

  /// Get supported biometric types as user-friendly strings
  Future<List<String>> getSupportedBiometricNames() async {
    final types = await getAvailableBiometrics();
    return types.map((type) => _biometricTypeToString(type)).toList();
  }

  /// Check if specific biometric type is available
  Future<bool> isBiometricTypeAvailable(BiometricType type) async {
    final availableTypes = await getAvailableBiometrics();
    return availableTypes.contains(type);
  }

  /// Clear cached data (call when app state changes)
  void clearCache() {
    _isAvailableCache = null;
    _availableTypesCache = null;
  }



  /// Handle platform-specific exceptions
  BiometricAuthResult _handlePlatformException(PlatformException e) {
    if (kDebugMode) {
      debugPrint('🔐 Platform exception during biometric auth: ${e.code} - ${e.message}');
    }

    switch (e.code) {
      case 'NotAvailable':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.notAvailable,
          message: 'Biometric authentication is not available',
        );
      case 'NotEnrolled':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.notEnrolled,
          message: 'No biometrics enrolled on device',
        );
      case 'LockedOut':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.lockedOut,
          message: 'Biometric authentication is temporarily locked',
        );
      case 'PermanentlyLockedOut':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.permanentlyLockedOut,
          message: 'Biometric authentication is permanently locked',
        );
      case 'UserCancel':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.userCancel,
          message: 'Authentication cancelled by user',
        );
      case 'UserFallback':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.userFallback,
          message: 'User selected fallback authentication',
        );
      case 'BiometricOnlyNotSupported':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.notSupported,
          message: 'Biometric-only authentication not supported',
        );
      case 'DeviceNotSupported':
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.notSupported,
          message: 'Device does not support biometric authentication',
        );
      default:
        return BiometricAuthResult(
          success: false,
          errorType: BiometricErrorType.unknown,
          message: e.message ?? 'Unknown biometric authentication error',
        );
    }
  }

  /// Convert biometric type to user-friendly string
  String _biometricTypeToString(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris Scan';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }
}

/// Result of biometric authentication attempt
class BiometricAuthResult {
  final bool success;
  final BiometricErrorType? errorType;
  final String message;

  BiometricAuthResult({
    required this.success,
    this.errorType,
    required this.message,
  });

  @override
  String toString() {
    return 'BiometricAuthResult{success: $success, errorType: $errorType, message: $message}';
  }
}

/// Types of biometric authentication errors
enum BiometricErrorType {
  notAvailable,
  notEnrolled,
  notSupported,
  lockedOut,
  permanentlyLockedOut,
  userCancel,
  userFallback,
  unknown,
}

/// Extension for better error handling
extension BiometricErrorTypeExtension on BiometricErrorType {
  /// Get user-friendly error message
  String get userMessage {
    switch (this) {
      case BiometricErrorType.notAvailable:
        return 'Biometric authentication is not available on this device.';
      case BiometricErrorType.notEnrolled:
        return 'No biometrics are enrolled. Please set up biometric authentication in Settings.';
      case BiometricErrorType.notSupported:
        return 'This device does not support biometric authentication.';
      case BiometricErrorType.lockedOut:
        return 'Biometric authentication is temporarily locked due to too many failed attempts.';
      case BiometricErrorType.permanentlyLockedOut:
        return 'Biometric authentication is permanently locked. Please use device passcode.';
      case BiometricErrorType.userCancel:
        return 'Authentication was cancelled.';
      case BiometricErrorType.userFallback:
        return 'User chose to use alternative authentication method.';
      case BiometricErrorType.unknown:
        return 'An unknown error occurred during authentication.';
    }
  }

  /// Check if error is recoverable
  bool get isRecoverable {
    switch (this) {
      case BiometricErrorType.userCancel:
      case BiometricErrorType.userFallback:
      case BiometricErrorType.lockedOut:
        return true;
      case BiometricErrorType.notAvailable:
      case BiometricErrorType.notEnrolled:
      case BiometricErrorType.notSupported:
      case BiometricErrorType.permanentlyLockedOut:
      case BiometricErrorType.unknown:
        return false;
    }
  }

  /// Check if user should be directed to settings
  bool get shouldDirectToSettings {
    switch (this) {
      case BiometricErrorType.notEnrolled:
      case BiometricErrorType.permanentlyLockedOut:
        return true;
      default:
        return false;
    }
  }
}