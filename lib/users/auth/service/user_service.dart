// lib/features/auth/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/firebase_service.dart';
import '../models/user_model.dart';

/// User service untuk CRUD operations pada user data
///
/// Responsibilities:
/// - Create new user document (saat registrasi/goal setting)
/// - Read user data
/// - Update user data
/// - Initialize default values untuk user baru
class UserService {
  // Singleton pattern
  UserService._();
  static final UserService instance = UserService._();

  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;

  // ============================================================================
  // CREATE NEW USER (Called after registration or goal setting)
  // ============================================================================

  /// Create new user document with all default values
  ///
  /// Called di:
  /// 1. GoalSettingScreen (setelah pilih goal)
  /// 2. Atau langsung setelah registrasi jika skip onboarding
  Future<void> createNewUser({
    required String userId,
    required String email,
    String? displayName,
    String? photoURL,
    String? goal,
  }) async {
    try {
      // Create user model dengan default values
      final newUser = UserModel.createNew(
        userId: userId,
        email: email,
        displayName: displayName,
        photoURL: photoURL,
        goal: goal,
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .set(newUser.toFirestore());

      if (kDebugMode) {
        print('✅ User document created: $userId');
        print('   Email: $email');
        print('   Goal: ${goal ?? "not set"}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to create user document: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // CHECK IF USER EXISTS
  // ============================================================================

  /// Check if user document exists in Firestore
  ///
  /// Penting untuk cek apakah user sudah pernah complete onboarding
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking user existence: $e');
      }
      return false;
    }
  }

  // ============================================================================
  // READ USER DATA
  // ============================================================================

  /// Get user data (one-time read)
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        if (kDebugMode) {
          print('⚠️ User document not found: $userId');
        }
        return null;
      }

      return UserModel.fromFirestore(doc);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user: $e');
      }
      rethrow;
    }
  }

  /// Stream user data (real-time updates)
  Stream<UserModel?> streamUser(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // ============================================================================
  // UPDATE USER DATA
  // ============================================================================

  /// Update user displayName
  Future<void> updateDisplayName(String userId, String displayName) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'displayName': displayName,
      });

      if (kDebugMode) {
        print('✅ Display name updated: $displayName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update display name: $e');
      }
      rethrow;
    }
  }

  /// Update user photoURL
  Future<void> updatePhotoURL(String userId, String photoURL) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'photoURL': photoURL,
      });

      if (kDebugMode) {
        print('✅ Photo URL updated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update photo URL: $e');
      }
      rethrow;
    }
  }

  /// Update last login timestamp
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ Last login updated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update last login: $e');
      }
      // Don't throw - non-critical
    }
  }

  /// Update user settings
  Future<void> updateSettings(String userId, UserSettings settings) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'settings': settings.toMap(),
      });

      if (kDebugMode) {
        print('✅ Settings updated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update settings: $e');
      }
      rethrow;
    }
  }

  /// Update user goal
  Future<void> updateGoal(String userId, String goal) async {
    try {
      await _firestore.collection('users').doc(userId).update({'goal': goal});

      if (kDebugMode) {
        print('✅ Goal updated: $goal');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update goal: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // PREMIUM MANAGEMENT
  // ============================================================================

  /// Activate premium subscription
  Future<void> activatePremium(String userId, {int durationDays = 30}) async {
    try {
      final now = DateTime.now();
      final until = now.add(Duration(days: durationDays));

      await _firestore.collection('users').doc(userId).update({
        'isPremium': true,
        'premiumSince': Timestamp.fromDate(now),
        'premiumUntil': Timestamp.fromDate(until),
        'energy.max': 10, // Premium max energy
        'energy.regenRate': 5, // Premium regen rate (faster)
      });

      if (kDebugMode) {
        print('✅ Premium activated until: $until');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to activate premium: $e');
      }
      rethrow;
    }
  }

  /// Deactivate premium subscription (expired)
  Future<void> deactivatePremium(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isPremium': false,
        'energy.max': 5, // Free max energy
        'energy.regenRate': 10, // Free regen rate (slower)
      });

      if (kDebugMode) {
        print('✅ Premium deactivated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to deactivate premium: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // DIAMOND MANAGEMENT
  // ============================================================================

  /// Add diamonds to user (purchase)
  Future<void> addDiamonds(String userId, int amount) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'diamond': FieldValue.increment(amount),
        'diamondStats.totalPurchased': FieldValue.increment(amount),
      });

      if (kDebugMode) {
        print('✅ Diamonds added: +$amount');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to add diamonds: $e');
      }
      rethrow;
    }
  }

  /// Subtract diamonds from user (spent)
  Future<void> spendDiamonds(String userId, int amount) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(
          _firestore.collection('users').doc(userId),
        );

        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final currentDiamonds = userDoc.data()!['diamond'] as int? ?? 0;

        if (currentDiamonds < amount) {
          throw InsufficientDiamondException(
            'Insufficient diamonds: need $amount, have $currentDiamonds',
          );
        }

        transaction.update(userDoc.reference, {
          'diamond': FieldValue.increment(-amount),
          'diamondStats.totalSpent': FieldValue.increment(amount),
        });
      });

      if (kDebugMode) {
        print('✅ Diamonds spent: -$amount');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to spend diamonds: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // MIGRATION HELPER (For existing users without complete data)
  // ============================================================================

  /// Fix incomplete user documents (untuk existing users)
  ///
  /// Call this jika ada user lama yang document-nya belum lengkap
  Future<void> migrateIncompleteUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        throw Exception('User not found');
      }

      final data = doc.data()!;

      // Merge dengan default values
      final defaultUser = UserModel.createNew(
        userId: userId,
        email: data['email'] as String? ?? '',
        displayName: data['displayName'] as String?,
        photoURL: data['photoURL'] as String?,
        goal: data['goal'] as String?,
      );

      // Update dengan SetOptions.merge (tidak overwrite existing data)
      await _firestore
          .collection('users')
          .doc(userId)
          .set(defaultUser.toFirestore(), SetOptions(merge: true));

      if (kDebugMode) {
        print('✅ User document migrated: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Migration failed: $e');
      }
      rethrow;
    }
  }
}

// ============================================================================
// CUSTOM EXCEPTIONS
// ============================================================================

class InsufficientDiamondException implements Exception {
  final String message;
  InsufficientDiamondException(this.message);

  @override
  String toString() => message;
}
