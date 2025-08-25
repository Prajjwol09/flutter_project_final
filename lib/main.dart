import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'config/environment_config.dart';
import 'theme/app_theme.dart';
import 'utils/design_tokens.dart';
import 'screens/splash/splash_screen_enhanced.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/main/main_screen.dart';
import 'providers/auth_provider.dart';
import 'services/local_storage_service.dart';
import 'services/error_handling_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error handling first
  ErrorHandlingService.initialize();
  
  try {
    // Initialize environment configuration first
    try {
      await EnvironmentConfig.init();
      if (kDebugMode) {
        print('✅ Environment config initialized successfully');
      }
    } catch (envError) {
      if (kDebugMode) {
        print('⚠️ Environment config initialization failed, using defaults: $envError');
      }
      // Continue with defaults
    }
    
    // Initialize Local Storage (Hive) with better error handling
    try {
      await LocalStorageService.init();
      if (kDebugMode) {
        print('✅ Local storage initialized successfully');
      }
    } catch (localStorageError) {
      if (kDebugMode) {
        print('⚠️ Local storage initialization failed, continuing without it: $localStorageError');
      }
      // Continue without local storage - app can still work
    }
    
    // Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      if (kDebugMode) {
        print('✅ Firebase initialized successfully');
      }
    } catch (firebaseError) {
      if (kDebugMode) {
        print('❌ Firebase initialization failed: $firebaseError');
      }
      throw firebaseError;
    }
    
    if (kDebugMode) {
      print('🚀 Starting app with ProviderScope');
    }
    
    runApp(const ProviderScope(child: MyApp()));
  } catch (error, stackTrace) {
    if (kDebugMode) {
      print('💥 Critical initialization error: $error');
    }
    
    // Report the error
    try {
      ErrorHandlingService().handleBusinessError(
        'Critical app initialization failed: $error',
        context: 'main',
        stackTrace: stackTrace,
      );
    } catch (_) {
      // Error handling itself failed, continue with fallback
    }
    
    // Fallback app if initialization fails
    runApp(ProviderScope(child: ErrorApp(error: error.toString())));
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Finlytic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light.copyWith(
        textTheme: GoogleFonts.interTextTheme(AppTheme.light.textTheme),
      ),
      darkTheme: AppTheme.dark.copyWith(
        textTheme: GoogleFonts.interTextTheme(AppTheme.dark.textTheme),
      ),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends ConsumerWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(userProvider);
    
    return authState.when(
      data: (user) {
        if (user != null) {
          return const MainScreen();
        } else {
          return const AuthWrapper();
        }
      },
      loading: () => const SplashScreenEnhanced(),
      error: (error, stack) => ErrorDisplayWidget(
        error: error.toString(),
        onRetry: () {
          ref.invalidate(userProvider);
        },
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finlytic - Error',
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(DesignTokens.space6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: DesignTokens.error,
                ),
                SizedBox(height: DesignTokens.space6),
                Text(
                  'App Initialization Failed',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: DesignTokens.error,
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                ),
                SizedBox(height: DesignTokens.space4),
                Text(
                  'We encountered an error while starting the app. Please restart the application.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: DesignTokens.space6),
                ExpansionTile(
                  title: Text('Error Details'),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(DesignTokens.space4),
                      child: Text(
                        error,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ErrorDisplayWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  
  const ErrorDisplayWidget({
    super.key, 
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.space6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bug_report,
                color: DesignTokens.error,
                size: 48,
              ),
              SizedBox(height: DesignTokens.space4),
              Text(
                'Something went wrong',
                style: TextStyle(
                  color: DesignTokens.error,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: DesignTokens.space2),
              Text(
                'Please try again or contact support if the problem persists.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DesignTokens.error,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: DesignTokens.space4),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              SizedBox(height: DesignTokens.space4),
              ExpansionTile(
                title: Text(
                  'Error Details',
                  style: TextStyle(
                    color: DesignTokens.error,
                    fontSize: 14,
                  ),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(DesignTokens.space4),
                    child: Text(
                      error,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: DesignTokens.neutral600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
