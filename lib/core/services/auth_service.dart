// lib/core/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

/// Authentication service for all auth operations.
///
/// Responsibilities:
/// - Login/Register
/// - Password reset
/// - Email verification
/// - Error handling
class AuthService {
  // Singleton pattern
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseService.instance.auth;

  // ============================================================================
  // AUTHENTICATION OPERATIONS
  // ============================================================================

  /// Login with email and password
  ///
  /// Returns User if successful, throws FirebaseAuthException otherwise
  Future<User> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Login failed: User is null');
      }

      if (kDebugMode) {
        print('✅ Login successful: ${credential.user!.email}');
      }

      return credential.user!;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Login failed: ${e.code}');
      }
      throw _handleAuthException(e);
    }
  }

  /// Register with email and password
  ///
  /// Automatically sends verification email
  /// Returns User if successful, throws FirebaseAuthException otherwise
  Future<User> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Registration failed: User is null');
      }

      // Send verification email automatically
      await credential.user!.sendEmailVerification();

      if (kDebugMode) {
        print('✅ Registration successful: ${credential.user!.email}');
        print('📧 Verification email sent');
      }

      return credential.user!;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Registration failed: ${e.code}');
      }
      throw _handleAuthException(e);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());

      if (kDebugMode) {
        print('✅ Password reset email sent to: $email');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Password reset failed: ${e.code}');
      }
      throw _handleAuthException(e);
    }
  }

  /// Resend email verification
  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      if (user.emailVerified) {
        throw Exception('Email already verified');
      }

      await user.sendEmailVerification();

      if (kDebugMode) {
        print('✅ Verification email resent to: ${user.email}');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Resend verification failed: ${e.code}');
      }
      throw _handleAuthException(e);
    }
  }

  /// Check if email is verified
  ///
  /// Reloads user to get latest verification status
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;

      if (user == null) return false;

      // Reload user to get latest status
      await user.reload();

      final updatedUser = _auth.currentUser;
      return updatedUser?.emailVerified ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Email verification check failed: $e');
      }
      return false;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    await FirebaseService.instance.signOut();
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user first (required for sensitive operations)
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Now change password
      await user.updatePassword(newPassword);

      if (kDebugMode) {
        print('✅ Password changed successfully');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Password change failed: ${e.code}');
      }
      throw _handleAuthException(e);
    }
  }

  /// Update display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      await user.updateDisplayName(displayName.trim());
      await user.reload();

      if (kDebugMode) {
        print('✅ Display name updated: $displayName');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Display name update failed: ${e.code}');
      }
      throw _handleAuthException(e);
    }
  }

  /// Update profile photo URL
  Future<void> updatePhotoURL(String photoURL) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      await user.updatePhotoURL(photoURL.trim());
      await user.reload();

      if (kDebugMode) {
        print('✅ Photo URL updated');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Photo URL update failed: ${e.code}');
      }
      throw _handleAuthException(e);
    }
  }

  // ============================================================================
  // ERROR HANDLING
  // ============================================================================

  /// Convert FirebaseAuthException to user-friendly message
  AuthException _handleAuthException(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'user-not-found':
        message = 'Email tidak terdaftar';
        break;
      case 'wrong-password':
        message = 'Password salah';
        break;
      case 'email-already-in-use':
        message = 'Email sudah terdaftar';
        break;
      case 'weak-password':
        message = 'Password terlalu lemah (minimal 6 karakter)';
        break;
      case 'invalid-email':
        message = 'Format email tidak valid';
        break;
      case 'user-disabled':
        message = 'Akun ini telah dinonaktifkan';
        break;
      case 'too-many-requests':
        message = 'Terlalu banyak percobaan. Coba lagi nanti';
        break;
      case 'operation-not-allowed':
        message = 'Operasi tidak diizinkan';
        break;
      case 'network-request-failed':
        message = 'Koneksi internet bermasalah';
        break;
      case 'requires-recent-login':
        message = 'Silakan login ulang untuk melanjutkan';
        break;
      default:
        message = e.message ?? 'Terjadi kesalahan: ${e.code}';
    }

    return AuthException(code: e.code, message: message);
  }

  // ============================================================================
  // GETTERS
  // ============================================================================

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get user ID
  String? get userId => _auth.currentUser?.uid;

  /// Get user email
  String? get userEmail => _auth.currentUser?.email;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

// ============================================================================
// CUSTOM EXCEPTION
// ============================================================================

/// Custom authentication exception with user-friendly messages
class AuthException implements Exception {
  final String code;
  final String message;

  AuthException({required this.code, required this.message});

  @override
  String toString() => message;
}
