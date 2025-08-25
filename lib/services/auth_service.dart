import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: kIsWeb ? '843034568787-aea1b579aqs62ihvr79kcnt891jlcbb4.apps.googleusercontent.com' : null,
    );
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String currency = 'NPR',
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        final userModel = UserModel(
          id: user.uid,
          email: email,
          name: name,
          currency: currency,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          authProvider: 'email',
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(userModel.toJson());

        return userModel;
      }
    } catch (e) {
      throw Exception('Failed to create account: ${e.toString()}');
    }
    return null;
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        return await getUserData(user.uid);
      }
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
    return null;
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      final User? user = result.user;

      if (user != null) {
        // Check if user exists
        final existingUser = await getUserData(user.uid);
        
        if (existingUser != null) {
          // Update auth provider if needed
          if (existingUser.authProvider != 'google') {
            final updatedUser = existingUser.copyWith(
              authProvider: 'google',
              updatedAt: DateTime.now(),
            );
            await updateUserData(updatedUser);
            return updatedUser;
          }
          return existingUser;
        } else {
          // Create new user
          final userModel = UserModel(
            id: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? 'Google User',
            currency: 'NPR',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            profileImageUrl: user.photoURL,
            authProvider: 'google',
          );

          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(user.uid)
              .set(userModel.toJson());

          return userModel;
        }
      }
    } catch (e) {
      throw Exception('Google sign in failed: ${e.toString()}');
    }
    return null;
  }

  // Phone authentication - Send OTP
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolve (this happens on Android sometimes)
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Phone verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      onError('Failed to send OTP: ${e.toString()}');
    }
  }

  // Phone authentication - Verify OTP
  Future<UserModel?> verifyOTP({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
    String? name,
  }) async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      final User? user = result.user;

      if (user != null) {
        // Check if user exists
        final existingUser = await getUserData(user.uid);
        
        if (existingUser != null) {
          // Update auth provider and phone number if needed
          if (existingUser.authProvider != 'phone' || existingUser.phoneNumber != phoneNumber) {
            final updatedUser = existingUser.copyWith(
              authProvider: 'phone',
              phoneNumber: phoneNumber,
              updatedAt: DateTime.now(),
            );
            await updateUserData(updatedUser);
            return updatedUser;
          }
          return existingUser;
        } else {
          // Create new user
          final userModel = UserModel(
            id: user.uid,
            email: user.email ?? '',
            name: name ?? 'Phone User',
            currency: 'NPR',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            phoneNumber: phoneNumber,
            authProvider: 'phone',
          );

          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(user.uid)
              .set(userModel.toJson());

          return userModel;
        }
      }
    } catch (e) {
      throw Exception('OTP verification failed: ${e.toString()}');
    }
    return null;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send reset email: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
    return null;
  }

  // Update user data
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .update(user.toJson());
    } catch (e) {
      throw Exception('Failed to update user data: ${e.toString()}');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .delete();
        
        // Delete Firebase Auth account
        await user.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }
}
