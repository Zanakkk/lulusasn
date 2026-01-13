// lib/core/services/firebase_service.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Centralized Firebase initialization and configuration.
///
/// Responsibilities:
/// - Initialize Firebase
/// - Configure Firestore settings
/// - Setup auth persistence
/// - Provide singleton instances
class FirebaseService {
  // Singleton pattern
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _initialized = false;

  // Lazy getters for Firebase instances
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Initialize Firebase with platform-specific optimizations
  ///
  /// Call this once in main() before runApp()
  Future<void> initialize() async {
    if (_initialized) {
      if (kDebugMode) {
        print('⚠️ Firebase already initialized');
      }
      return;
    }

    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure Firestore for web optimization
      _configureFirestore();

      // Configure Auth persistence
      _configureAuth();

      _initialized = true;

      if (kDebugMode) {
        print('✅ Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Configure Firestore settings for optimal web performance
  void _configureFirestore() {
    firestore.settings = const Settings(
      // Enable persistence for offline support
      persistenceEnabled: true,

      // Cache size (10 MB for web)
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    if (kDebugMode) {
      print('✅ Firestore configured');
    }
  }

  /// Configure Firebase Auth persistence
  void _configureAuth() {
    // Set persistence to LOCAL (survives browser refresh)
    auth.setPersistence(Persistence.LOCAL);

    if (kDebugMode) {
      print('✅ Auth persistence configured');
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => auth.currentUser != null;

  /// Get current user
  User? get currentUser => auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => auth.authStateChanges();

  /// Sign out (clears all local state)
  Future<void> signOut() async {
    try {
      await auth.signOut();

      if (kDebugMode) {
        print('✅ User signed out');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sign out failed: $e');
      }
      rethrow;
    }
  }

  /// Check if email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Get user ID
  String? get userId => currentUser?.uid;

  /// Get user email
  String? get userEmail => currentUser?.email;

  /// Reload current user (to check email verification status)
  Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  /// Delete current user account (DANGEROUS)
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();

      if (kDebugMode) {
        print('✅ Account deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Account deletion failed: $e');
      }
      rethrow;
    }
  }
}
