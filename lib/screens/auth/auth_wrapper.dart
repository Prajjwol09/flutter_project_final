import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/design_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../main/main_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final userAsync = ref.watch(userProvider);
      if (kDebugMode) {
        debugPrint('AuthWrapper: userAsync state - ${userAsync.runtimeType}');
      }

      return userAsync.when(
        data: (user) {
          if (kDebugMode) {
            debugPrint('AuthWrapper: User data - ${user?.toString()}');
          }
          if (user != null) {
            return const MainScreen();
          } else {
            return const LoginScreen();
          }
        },
        loading: () {
          if (kDebugMode) {
            debugPrint('AuthWrapper: Loading state');
          }
          return _buildLoadingScreen(context);
        },
        error: (error, stack) {
          if (kDebugMode) {
            debugPrint('AuthWrapper: Error state - $error');
            debugPrint('AuthWrapper: Stack - $stack');
          }
          // Return login screen instead of error for auth errors
          return const LoginScreen();
        },
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('AuthWrapper: Exception caught - $e');
        debugPrint('AuthWrapper: Exception stack - $stack');
      }
      return _buildErrorScreen(context, e.toString());
    }
  }

  Widget _buildErrorScreen(BuildContext context, String error) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.error,
            ),
            const SizedBox(height: DesignTokens.space6),
            Text(
              'Initialization Error',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            ElevatedButton(
              onPressed: () {
                // Try to restart the app
                // You could implement app restart logic here
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: DesignTokens.space6),
            Text(
              'Finlytic',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Your personal finance companion',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.space8),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
