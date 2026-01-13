// lib/features/home/models/streak_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk Streak System
///
/// Streak = hari berturut-turut user menyelesaikan minimal 1 exam
/// Rewards di milestone: 3, 7, 14, 30 hari
class StreakModel {
  final int current;
  final int longest;
  final String lastActiveDate; // Format: YYYY-MM-DD
  final DateTime lastUpdated;
  final List<StreakMilestone> achievedMilestones;

  const StreakModel({
    required this.current,
    required this.longest,
    required this.lastActiveDate,
    required this.lastUpdated,
    required this.achievedMilestones,
  });

  // ============================================================================
  // FACTORY CONSTRUCTORS
  // ============================================================================

  /// Create dari Firestore document
  factory StreakModel.fromFirestore(Map<String, dynamic> data) {
    final milestonesData = data['achievedMilestones'] as List<dynamic>? ?? [];
    final milestones = milestonesData
        .map((m) => StreakMilestone.fromMap(m as Map<String, dynamic>))
        .toList();

    return StreakModel(
      current: data['current'] as int? ?? 0,
      longest: data['longest'] as int? ?? 0,
      lastActiveDate: data['lastActiveDate'] as String? ?? _todayString(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      achievedMilestones: milestones,
    );
  }

  /// Default streak (new user)
  factory StreakModel.defaultStreak() {
    return StreakModel(
      current: 0,
      longest: 0,
      lastActiveDate: _todayString(),
      lastUpdated: DateTime.now(),
      achievedMilestones: [],
    );
  }

  // Helper: format today as YYYY-MM-DD
  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ============================================================================
  // TO FIRESTORE
  // ============================================================================

  Map<String, dynamic> toFirestore() {
    return {
      'current': current,
      'longest': longest,
      'lastActiveDate': lastActiveDate,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'achievedMilestones': achievedMilestones.map((m) => m.toMap()).toList(),
    };
  }

  // ============================================================================
  // BUSINESS LOGIC
  // ============================================================================

  /// Check apakah hari ini sudah practice
  bool isPracticedToday() {
    return lastActiveDate == _todayString();
  }

  /// Check apakah kemarin practice (untuk streak continuation)
  bool isPracticedYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    return lastActiveDate == yesterdayStr;
  }

  /// Get next milestone yang belum achieved
  StreakMilestone? getNextMilestone() {
    final allMilestones = StreakMilestone.allMilestones;

    for (final milestone in allMilestones) {
      final isAchieved = achievedMilestones.any((m) => m.days == milestone.days);
      if (!isAchieved && current < milestone.days) {
        return milestone;
      }
    }

    return null;
  }

  /// Progress menuju next milestone (0.0 - 1.0)
  double progressToNextMilestone() {
    final next = getNextMilestone();
    if (next == null) return 1.0;

    // Find previous milestone
    final allMilestones = StreakMilestone.allMilestones;
    final nextIndex = allMilestones.indexOf(next);
    final prevDays = nextIndex > 0 ? allMilestones[nextIndex - 1].days : 0;

    final range = next.days - prevDays;
    final progress = current - prevDays;

    return (progress / range).clamp(0.0, 1.0);
  }

  /// Check apakah hari ini ada reward yang bisa di-claim
  List<StreakMilestone> getUnclaimedRewards() {
    final milestones = StreakMilestone.allMilestones
        .where((m) => m.days <= current)
        .toList();

    return milestones.where((m) {
      return !achievedMilestones.any((achieved) => achieved.days == m.days);
    }).toList();
  }

  /// Status streak (active, at_risk, broken)
  StreakStatus getStatus() {
    if (current == 0) return StreakStatus.broken;
    if (isPracticedToday()) return StreakStatus.active;
    if (isPracticedYesterday()) return StreakStatus.atRisk;
    return StreakStatus.broken;
  }

  // ============================================================================
  // COPY WITH
  // ============================================================================

  StreakModel copyWith({
    int? current,
    int? longest,
    String? lastActiveDate,
    DateTime? lastUpdated,
    List<StreakMilestone>? achievedMilestones,
  }) {
    return StreakModel(
      current: current ?? this.current,
      longest: longest ?? this.longest,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      achievedMilestones: achievedMilestones ?? this.achievedMilestones,
    );
  }

  // ============================================================================
  // EQUALITY & HASH
  // ============================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StreakModel &&
        other.current == current &&
        other.longest == longest &&
        other.lastActiveDate == lastActiveDate;
  }

  @override
  int get hashCode {
    return Object.hash(current, longest, lastActiveDate);
  }

  // ============================================================================
  // TO STRING
  // ============================================================================

  @override
  String toString() {
    return 'StreakModel(current: $current, longest: $longest, status: ${getStatus()})';
  }
}

// ==============================================================================
// STREAK MILESTONE
// ==============================================================================

/// Reward milestone untuk streak
class StreakMilestone {
  final int days;
  final int xpReward;
  final int diamondReward;
  final String badgeName;

  const StreakMilestone({
    required this.days,
    required this.xpReward,
    required this.diamondReward,
    required this.badgeName,
  });

  // Predefined milestones
  static const milestone3Days = StreakMilestone(
    days: 3,
    xpReward: 50,
    diamondReward: 0,
    badgeName: 'Konsisten',
  );

  static const milestone7Days = StreakMilestone(
    days: 7,
    xpReward: 100,
    diamondReward: 1,
    badgeName: 'Semangat',
  );

  static const milestone14Days = StreakMilestone(
    days: 14,
    xpReward: 200,
    diamondReward: 2,
    badgeName: 'Tekun',
  );

  static const milestone30Days = StreakMilestone(
    days: 30,
    xpReward: 500,
    diamondReward: 5,
    badgeName: 'Dedikasi',
  );

  static const List<StreakMilestone> allMilestones = [
    milestone3Days,
    milestone7Days,
    milestone14Days,
    milestone30Days,
  ];

  // Firestore conversion
  factory StreakMilestone.fromMap(Map<String, dynamic> data) {
    return StreakMilestone(
      days: data['days'] as int,
      xpReward: data['xpReward'] as int,
      diamondReward: data['diamondReward'] as int,
      badgeName: data['badgeName'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'days': days,
      'xpReward': xpReward,
      'diamondReward': diamondReward,
      'badgeName': badgeName,
    };
  }

  @override
  String toString() {
    return 'StreakMilestone(${days}d: +${xpReward}XP, +$diamondReward💎, "$badgeName")';
  }
}

// ==============================================================================
// STREAK STATUS ENUM
// ==============================================================================

enum StreakStatus {
  active,   // Hari ini sudah practice
  atRisk,   // Kemarin practice, hari ini belum
  broken,   // Sudah > 1 hari tidak practice
}

extension StreakStatusExtension on StreakStatus {
  String get displayText {
    switch (this) {
      case StreakStatus.active:
        return 'Streak aktif! 🔥';
      case StreakStatus.atRisk:
        return 'Streak dalam bahaya! ⚠️';
      case StreakStatus.broken:
        return 'Streak terputus 💔';
    }
  }

  String get emoji {
    switch (this) {
      case StreakStatus.active:
        return '🔥';
      case StreakStatus.atRisk:
        return '⚠️';
      case StreakStatus.broken:
        return '💔';
    }
  }
}