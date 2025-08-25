import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Firebase user stream provider
final firebaseUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// User data provider
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  return UserNotifier(ref);
});

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  UserNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref _ref;
  AuthService get _authService => _ref.read(authServiceProvider);

  void _init() {
    if (kDebugMode) {
      print('🔄 UserNotifier initializing...');
    }
    
    // Use a small delay to ensure LocalStorageService is initialized
    Future.delayed(const Duration(milliseconds: 100), () {
      // Try to load user from local storage first (if available)
      try {
        final localUser = LocalStorageService.getCurrentUser();
        if (localUser != null) {
          if (kDebugMode) {
            print('📋 Loaded user from local storage: ${localUser.email}');
          }
          state = AsyncValue.data(localUser);
        } else {
          if (kDebugMode) {
            print('📋 No user found in local storage');
          }
        }
      } catch (e) {
        // Local storage not initialized yet, that's fine
        if (kDebugMode) {
          debugPrint('Local storage not ready, will load from Firebase: $e');
        }
      }
    });

    // Listen to auth state changes
    try {
      _ref.listen(firebaseUserProvider, (previous, next) {
        if (kDebugMode) {
          print('🔥 Firebase auth state changed');
        }
        
        next.when(
          data: (user) {
            if (user != null) {
              if (kDebugMode) {
                print('👤 User authenticated: ${user.uid}');
              }
              _loadUserData(user.uid);
            } else {
              if (kDebugMode) {
                print('😆 User signed out');
              }
              state = const AsyncValue.data(null);
              _clearLocalUser();
            }
          },
          loading: () {
            if (kDebugMode) {
              print('⌛ Firebase user loading...');
            }
          },
          error: (error, stack) {
            if (kDebugMode) {
              print('❌ Firebase user error: $error');
            }
            state = AsyncValue.error(error, stack);
          },
        );
      });
      
      if (kDebugMode) {
        print('✅ UserNotifier initialized successfully');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ UserNotifier initialization failed: $e');
        print('Stack trace: $stack');
      }
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final user = await _authService.getUserData(uid);
      if (user != null) {
        state = AsyncValue.data(user);
        await _saveLocalUser(user);
      }
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Safely clear local user data
  Future<void> _clearLocalUser() async {
    try {
      await LocalStorageService.clearUser();
    } catch (e) {
      // Local storage not available, that's fine
      if (kDebugMode) {
        debugPrint('Could not clear local user, local storage not available: $e');
      }
    }
  }

  /// Safely save user to local storage
  Future<void> _saveLocalUser(UserModel user) async {
    try {
      await LocalStorageService.saveUser(user);
    } catch (e) {
      // Local storage not available, that's fine
      if (kDebugMode) {
        debugPrint('Could not save user locally, local storage not available: $e');
      }
    }
  }

  // Email Authentication
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String currency = 'NPR',
  }) async {
    try {
      state = const AsyncValue.loading();
      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        currency: currency,
      );
      
      if (user != null) {
        state = AsyncValue.data(user);
        await _saveLocalUser(user);
      }
      
      return user;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      state = const AsyncValue.loading();
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (user != null) {
        state = AsyncValue.data(user);
        await _saveLocalUser(user);
      }
      
      return user;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  // Google Authentication
  Future<UserModel?> signInWithGoogle() async {
    try {
      state = const AsyncValue.loading();
      final user = await _authService.signInWithGoogle();
      
      if (user != null) {
        state = AsyncValue.data(user);
        await _saveLocalUser(user);
      }
      
      return user;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  // Phone Authentication
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _authService.sendOTP(
        phoneNumber: phoneNumber,
        codeSent: onCodeSent,
        onError: onError,
      );
    } catch (error) {
      onError(error.toString());
    }
  }

  Future<UserModel?> verifyOTP({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
    String? name,
  }) async {
    try {
      state = const AsyncValue.loading();
      final user = await _authService.verifyOTP(
        verificationId: verificationId,
        smsCode: smsCode,
        phoneNumber: phoneNumber,
        name: name,
      );
      
      if (user != null) {
        state = AsyncValue.data(user);
        await _saveLocalUser(user);
      }
      
      return user;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (error) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
      await _clearLocalUser();
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  // Update User
  Future<void> updateUser(UserModel user) async {
    try {
      await _authService.updateUserData(user);
      state = AsyncValue.data(user);
      await _saveLocalUser(user);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      state = const AsyncValue.data(null);
      await _clearLocalUser();
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }
}

// Computed providers
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(userProvider);
  return user.value != null;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(userProvider);
  return user.value?.id;
});

final currentUserCurrencyProvider = Provider<String>((ref) {
  final user = ref.watch(userProvider);
  return user.value?.currency ?? 'NPR';
});
