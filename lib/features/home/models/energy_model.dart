// lib/features/home/models/energy_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk Energy System
///
/// Free user: max 5, regen 1 per 10 menit
/// Premium user: max 10, regen 1 per 5 menit
class EnergyModel {
  final int current;
  final int max;
  final int regenRate; // minutes per 1 energy
  final DateTime lastRegen;
  final DateTime lastUsed;
  final int totalUsed;

  const EnergyModel({
    required this.current,
    required this.max,
    required this.regenRate,
    required this.lastRegen,
    required this.lastUsed,
    required this.totalUsed,
  });

  // ============================================================================
  // FACTORY CONSTRUCTORS
  // ============================================================================

  /// Create dari Firestore document
  factory EnergyModel.fromFirestore(Map<String, dynamic> data) {
    return EnergyModel(
      current: data['current'] as int? ?? 0,
      max: data['max'] as int? ?? 5,
      regenRate: data['regenRate'] as int? ?? 10,
      lastRegen: (data['lastRegen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUsed: (data['lastUsed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalUsed: data['totalUsed'] as int? ?? 0,
    );
  }

  /// Default energy untuk free user
  factory EnergyModel.defaultFree() {
    final now = DateTime.now();
    return EnergyModel(
      current: 5,
      max: 5,
      regenRate: 10,
      lastRegen: now,
      lastUsed: now,
      totalUsed: 0,
    );
  }

  /// Default energy untuk premium user
  factory EnergyModel.defaultPremium() {
    final now = DateTime.now();
    return EnergyModel(
      current: 10,
      max: 10,
      regenRate: 5,
      lastRegen: now,
      lastUsed: now,
      totalUsed: 0,
    );
  }

  // ============================================================================
  // TO FIRESTORE
  // ============================================================================

  Map<String, dynamic> toFirestore() {
    return {
      'current': current,
      'max': max,
      'regenRate': regenRate,
      'lastRegen': Timestamp.fromDate(lastRegen),
      'lastUsed': Timestamp.fromDate(lastUsed),
      'totalUsed': totalUsed,
    };
  }

  // ============================================================================
  // BUSINESS LOGIC
  // ============================================================================

  /// Calculate current energy dengan auto-regeneration
  /// Returns actual current energy setelah dihitung regen
  int calculateCurrentEnergy() {
    // Sudah max
    if (current >= max) return max;

    // Hitung berapa menit sudah lewat
    final now = DateTime.now();
    final minutesPassed = now.difference(lastRegen).inMinutes;

    // Hitung berapa energy yang harus ditambahkan
    final energyToAdd = minutesPassed ~/ regenRate;

    // Return min(current + regen, max)
    final newEnergy = current + energyToAdd;
    return newEnergy > max ? max : newEnergy;
  }

  // ============================================================================
  // TAMBAHKAN METHOD INI di energy_model.dart
  // Di bagian BUSINESS LOGIC section
  // ============================================================================

  /// Berapa menit lagi sampai next energy regen
  int minutesUntilNext() {
    if (current >= max) return 0;

    final now = DateTime.now();
    final minutesPassed = now.difference(lastRegen).inMinutes;
    final minutesUntilNext = regenRate - (minutesPassed % regenRate);

    return minutesUntilNext;
  }

  /// Berapa menit lagi sampai full energy
  int minutesUntilFull() {
    final currentActual = calculateCurrentEnergy();
    if (currentActual >= max) return 0;

    final energyNeeded = max - currentActual;
    final baseMinutes = energyNeeded * regenRate;
    final minutesUntilNext = this.minutesUntilNext();

    return baseMinutes - regenRate + minutesUntilNext;
  }

  /// Progress regeneration (0.0 - 1.0) untuk timer bar
  double regenProgress() {
    if (current >= max) return 1.0;

    final now = DateTime.now();
    final secondsPassed = now.difference(lastRegen).inSeconds;
    final secondsPerEnergy = regenRate * 60;
    final secondsInCurrentCycle = secondsPassed % secondsPerEnergy;

    return secondsInCurrentCycle / secondsPerEnergy;
  }

  /// Apakah bisa start exam (current > 0)
  bool canStartExam() {
    return calculateCurrentEnergy() > 0;
  }

  // ============================================================================
  // COPY WITH
  // ============================================================================

  EnergyModel copyWith({
    int? current,
    int? max,
    int? regenRate,
    DateTime? lastRegen,
    DateTime? lastUsed,
    int? totalUsed,
  }) {
    return EnergyModel(
      current: current ?? this.current,
      max: max ?? this.max,
      regenRate: regenRate ?? this.regenRate,
      lastRegen: lastRegen ?? this.lastRegen,
      lastUsed: lastUsed ?? this.lastUsed,
      totalUsed: totalUsed ?? this.totalUsed,
    );
  }

  // ============================================================================
  // EQUALITY & HASH
  // ============================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EnergyModel &&
        other.current == current &&
        other.max == max &&
        other.regenRate == regenRate &&
        other.lastRegen == lastRegen &&
        other.lastUsed == lastUsed &&
        other.totalUsed == totalUsed;
  }

  @override
  int get hashCode {
    return Object.hash(current, max, regenRate, lastRegen, lastUsed, totalUsed);
  }

  // ============================================================================
  // TO STRING
  // ============================================================================

  @override
  String toString() {
    return 'EnergyModel(current: $current/$max, regenRate: ${regenRate}min, totalUsed: $totalUsed)';
  }
}
