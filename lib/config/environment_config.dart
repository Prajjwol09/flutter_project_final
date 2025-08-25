import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (!_isInitialized) {
      try {
        await dotenv.load(fileName: ".env");
        _isInitialized = true;
      } catch (e) {
        // Fallback to hardcoded values for development
        // In production, this should throw an error
        // Note: .env file not found, using fallback configuration
        _isInitialized = true;
      }
    }
  }

  // Firebase Web Configuration
  static String get firebaseWebApiKey =>
      dotenv.env['FIREBASE_WEB_API_KEY'] ?? 'AIzaSyAGp0jFQdDNXqsY25DnigSt555-R1ATxBc';

  static String get firebaseWebAppId =>
      dotenv.env['FIREBASE_WEB_APP_ID'] ?? '1:843034568787:web:2b5dc971d33ff73db93ea6';

  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_WEB_MESSAGING_SENDER_ID'] ?? '843034568787';

  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? 'finlytic-f0253';

  static String get firebaseAuthDomain =>
      dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'finlytic-f0253.firebaseapp.com';

  static String get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'finlytic-f0253.firebasestorage.app';

  static String get firebaseMeasurementId =>
      dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? 'G-7437NMMNEH';

  // Firebase Android Configuration
  static String get firebaseAndroidApiKey =>
      dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? 'AIzaSyDZl3vXY8SjIGz1YXZKTNOltLdcmqCR18s';

  static String get firebaseAndroidAppId =>
      dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '1:843034568787:android:5a8bd872dddd2ccfb93ea6';

  // Firebase iOS Configuration
  static String get firebaseIosApiKey =>
      dotenv.env['FIREBASE_IOS_API_KEY'] ?? 'AIzaSyAPMf3__QszS4GvsLn2o9XTNnfeh21-x5Q';

  static String get firebaseIosAppId =>
      dotenv.env['FIREBASE_IOS_APP_ID'] ?? '1:843034568787:ios:c5ed3ccdf2462795b93ea6';

  static String get firebaseIosClientId =>
      dotenv.env['FIREBASE_IOS_CLIENT_ID'] ?? '843034568787-q6lltlr7p8plsdp9nhs8j4i93i40f8l7.apps.googleusercontent.com';

  static String get firebaseIosBundleId =>
      dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? 'com.finlytic.finlytic';

  static String get firebaseAndroidClientId =>
      dotenv.env['FIREBASE_ANDROID_CLIENT_ID'] ?? '843034568787-aea1b579aqs62ihvr79kcnt891jlcbb4.apps.googleusercontent.com';

  // Firebase Windows Configuration
  static String get firebaseWindowsApiKey =>
      dotenv.env['FIREBASE_WINDOWS_API_KEY'] ?? 'AIzaSyAGp0jFQdDNXqsY25DnigSt555-R1ATxBc';

  static String get firebaseWindowsAppId =>
      dotenv.env['FIREBASE_WINDOWS_APP_ID'] ?? '1:843034568787:web:f9797503ff225031b93ea6';

  static String get firebaseWindowsMeasurementId =>
      dotenv.env['FIREBASE_WINDOWS_MEASUREMENT_ID'] ?? 'G-C9QT7B2QTT';

  // Environment Detection
  static bool get isProduction => dotenv.env['ENVIRONMENT'] == 'production';
  static bool get isDevelopment => dotenv.env['ENVIRONMENT'] == 'development';
  static bool get isDebug => !isProduction;

  // Security Configuration
  static bool get enableEncryption => dotenv.env['ENABLE_ENCRYPTION']?.toLowerCase() == 'true';
  static String get encryptionKey => dotenv.env['ENCRYPTION_KEY'] ?? 'default_dev_key_change_in_production';

  // API Configuration
  static String get baseApiUrl => dotenv.env['BASE_API_URL'] ?? 'https://api.finlytic.com';
  static String get aiServiceUrl => dotenv.env['AI_SERVICE_URL'] ?? 'https://ai.finlytic.com';
  static String get ocrServiceUrl => dotenv.env['OCR_SERVICE_URL'] ?? 'https://ocr.finlytic.com';

  // Feature Flags
  static bool get enableAiFeatures => dotenv.env['ENABLE_AI_FEATURES']?.toLowerCase() != 'false';
  static bool get enableOcrFeatures => dotenv.env['ENABLE_OCR_FEATURES']?.toLowerCase() != 'false';
  static bool get enableVoiceInput => dotenv.env['ENABLE_VOICE_INPUT']?.toLowerCase() != 'false';
  static bool get enableBiometrics => dotenv.env['ENABLE_BIOMETRICS']?.toLowerCase() != 'false';

  // Logging Configuration
  static bool get enableDetailedLogging => dotenv.env['ENABLE_DETAILED_LOGGING']?.toLowerCase() == 'true';
  static String get logLevel => dotenv.env['LOG_LEVEL'] ?? 'info';
}