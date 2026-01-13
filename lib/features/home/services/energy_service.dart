// lib/features/home/services/energy_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lulusasn/core/services/firebase_service.dart';
import 'package:lulusasn/features/home/models/energy_model.dart';

/// Service untuk Energy Management
///
/// Handles:
/// - Fetch energy data
/// - Consume energy (start exam)
/// - Refill energy (diamond / rewarded ad)
/// - Auto-regeneration calculation
class EnergyService {
  static final EnergyService _instance = EnergyService._internal();
  factory EnergyService() => _instance;
  EnergyService._internal();

  final _firestore = FirebaseService.instance.firestore;
  final _auth = FirebaseService.instance.auth;

  // ============================================================================
  // FETCH ENERGY
  // ============================================================================

  /// Get user's energy data (one-time fetch)
  Future<EnergyModel> getEnergy() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User tidak login');
    }

    final doc = await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) {
      throw Exception('User data tidak ditemukan');
    }

    final data = doc.data();
    final energyData = data?['energy'] as Map<String, dynamic>?;

    if (energyData == null) {
      // Return default jika belum ada
      return EnergyModel.defaultFree();
    }

    return EnergyModel.fromFirestore(energyData);
  }

  /// Stream energy data (real-time updates)
  Stream<EnergyModel> streamEnergy() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.error(Exception('User tidak login'));
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('User data tidak ditemukan');
      }

      final data = snapshot.data();
      final energyData = data?['energy'] as Map<String, dynamic>?;

      if (energyData == null) {
        return EnergyModel.defaultFree();
      }

      return EnergyModel.fromFirestore(energyData);
    });
  }

  // ============================================================================
  // CONSUME ENERGY (Start Exam)
  // ============================================================================

  /// Consume 1 energy untuk start exam
  ///
  /// Returns: updated EnergyModel
  /// Throws: Exception jika energy tidak cukup
  Future<EnergyModel> consumeEnergy() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User tidak login');
    }

    final userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction<EnergyModel>((transaction) async {
      final userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw Exception('User data tidak ditemukan');
      }

      final data = userDoc.data()!;
      final isPremium = data['isPremium'] as bool? ?? false;

      // Premium users bypass energy system
      if (isPremium) {
        // Return unlimited energy model
        return EnergyModel.defaultPremium();
      }

      // Free users: check energy
      final energyData = data['energy'] as Map<String, dynamic>?;
      if (energyData == null) {
        throw Exception('Energy data tidak ditemukan');
      }

      final energy = EnergyModel.fromFirestore(energyData);
      final currentEnergy = energy.calculateCurrentEnergy();

      if (currentEnergy <= 0) {
        throw InsufficientEnergyException(
          'Energy habis! Tunggu ${energy.minutesUntilNext()} menit lagi.',
        );
      }

      // Update energy
      final now = DateTime.now();
      final updatedEnergy = energy.copyWith(
        current: currentEnergy - 1,
        lastUsed: now,
        lastRegen: energy.current == energy.max ? now : energy.lastRegen,
        totalUsed: energy.totalUsed + 1,
      );

      transaction.update(userRef, {
        'energy': updatedEnergy.toFirestore(),
      });

      return updatedEnergy;
    });
  }

  // ============================================================================
  // REFILL ENERGY
  // ============================================================================

  /// Refill energy dengan 1 diamond (full refill)
  ///
  /// Returns: updated EnergyModel
  /// Throws: Exception jika diamond tidak cukup
  Future<EnergyModel> refillWithDiamond() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User tidak login');
    }

    final userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction<EnergyModel>((transaction) async {
      final userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw Exception('User data tidak ditemukan');
      }

      final data = userDoc.data()!;
      final diamond = data['diamond'] as int? ?? 0;

      if (diamond < 1) {
        throw InsufficientDiamondException('Diamond tidak cukup!');
      }

      final energyData = data['energy'] as Map<String, dynamic>?;
      if (energyData == null) {
        throw Exception('Energy data tidak ditemukan');
      }

      final energy = EnergyModel.fromFirestore(energyData);
      final now = DateTime.now();

      // Full refill
      final updatedEnergy = energy.copyWith(
        current: energy.max,
        lastRegen: now,
      );

      transaction.update(userRef, {
        'energy': updatedEnergy.toFirestore(),
        'diamond': FieldValue.increment(-1),
        'diamondStats.totalSpent': FieldValue.increment(1),
      });

      return updatedEnergy;
    });
  }

  /// Add energy dari rewarded ad (+1 energy)
  ///
  /// Returns: updated EnergyModel
  Future<EnergyModel> addEnergyFromAd() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User tidak login');
    }

    final userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction<EnergyModel>((transaction) async {
      final userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw Exception('User data tidak ditemukan');
      }

      final data = userDoc.data()!;
      final energyData = data['energy'] as Map<String, dynamic>?;
      if (energyData == null) {
        throw Exception('Energy data tidak ditemukan');
      }

      final energy = EnergyModel.fromFirestore(energyData);
      final currentEnergy = energy.calculateCurrentEnergy();

      // Tidak bisa exceed max
      if (currentEnergy >= energy.max) {
        throw Exception('Energy sudah penuh!');
      }

      final now = DateTime.now();
      final updatedEnergy = energy.copyWith(
        current: currentEnergy + 1,
        lastRegen: currentEnergy + 1 == energy.max ? now : energy.lastRegen,
      );

      transaction.update(userRef, {
        'energy': updatedEnergy.toFirestore(),
        'ads.totalRewardedWatched': FieldValue.increment(1),
        'ads.lastRewardedAt': Timestamp.fromDate(now),
      });

      return updatedEnergy;
    });
  }

  // ============================================================================
  // UPGRADE TO PREMIUM
  // ============================================================================

  /// Upgrade user energy settings to premium
  ///
  /// Called saat user upgrade premium (dari payment webhook)
  Future<void> upgradeToPremium(String userId) async {
    final userRef = _firestore.collection('users').doc(userId);

    await userRef.update({
      'energy.max': 10,
      'energy.regenRate': 5,
      'energy.current': FieldValue.increment(5), // Bonus +5 energy
    });
  }

  /// Downgrade user energy settings (premium expired)
  Future<void> downgradeToFree(String userId) async {
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(userRef);
      final data = doc.data()!;
      final energyData = data['energy'] as Map<String, dynamic>;
      final energy = EnergyModel.fromFirestore(energyData);

      // Set to free limits (cap at 5)
      final newCurrent = energy.current > 5 ? 5 : energy.current;

      transaction.update(userRef, {
        'energy.max': 5,
        'energy.regenRate': 10,
        'energy.current': newCurrent,
      });
    });
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Check if user can start exam (ada energy atau premium)
  Future<bool> canStartExam() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    final isPremium = data['isPremium'] as bool? ?? false;

    // Premium = always can start
    if (isPremium) return true;

    // Free user: check energy
    final energyData = data['energy'] as Map<String, dynamic>?;
    if (energyData == null) return false;

    final energy = EnergyModel.fromFirestore(energyData);
    return energy.canStartExam();
  }
}

// ==============================================================================
// CUSTOM EXCEPTIONS
// ==============================================================================

class InsufficientEnergyException implements Exception {
  final String message;
  InsufficientEnergyException(this.message);

  @override
  String toString() => message;
}

class InsufficientDiamondException implements Exception {
  final String message;
  InsufficientDiamondException(this.message);

  @override
  String toString() => message;
}