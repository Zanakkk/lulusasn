// lib/features/home/services/streak_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lulusasn/core/services/firebase_service.dart';
import 'package:lulusasn/features/home/models/streak_model.dart';

/// Service untuk Streak Management
///
/// Handles:
/// - Fetch streak data
/// - Update streak setelah exam
/// - Claim milestone rewards
/// - Freeze streak (premium feature)
class StreakService {
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  final _firestore = FirebaseService.instance.firestore;
  final _auth = FirebaseService.instance.auth;

  // Helper: format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================================
  // FETCH STREAK
  // ============================================================================

  /// Get user's streak data (one-time fetch)
  Future<StreakModel> getStreak() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User tidak login');
    }

    final doc = await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) {
      throw Exception('User data tidak ditemukan');
    }

    final data = doc.data()!;

    // Extract streak fields
    final streak = StreakModel(
      current: data['streak'] as int? ?? 0,
      longest: data['longestStreak'] as int? ?? 0,
      lastActiveDate: data['lastActiveDate'] as String? ?? _formatDate(DateTime.now()),
      lastUpdated: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      achievedMilestones: _parseAchievedMilestones(data['achievedMilestones']),
    );

    return streak;
  }

  /// Stream streak data (real-time updates)
  Stream<StreakModel> streamStreak() {
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

      final data = snapshot.data()!;

      return StreakModel(
        current: data['streak'] as int? ?? 0,
        longest: data['longestStreak'] as int? ?? 0,
        lastActiveDate: data['lastActiveDate'] as String? ?? _formatDate(DateTime.now()),
        lastUpdated: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        achievedMilestones: _parseAchievedMilestones(data['achievedMilestones']),
      );
    });
  }

  // Parse achieved milestones dari Firestore
  List<StreakMilestone> _parseAchievedMilestones(dynamic data) {
    if (data == null) return [];

    final list = data as List<dynamic>;
    return list
        .map((m) => StreakMilestone.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  // ============================================================================
  // UPDATE STREAK (After Exam Completion)
  // ============================================================================

  /// Update streak setelah user complete exam
  ///
  /// Returns: StreakUpdateResult (new streak, rewards, milestone achieved)
  Future<StreakUpdateResult> updateStreakAfterExam() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User tidak login');
    }

    final userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction<StreakUpdateResult>((transaction) async {
      final userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw Exception('User data tidak ditemukan');
      }

      final data = userDoc.data()!;
      final currentStreak = data['streak'] as int? ?? 0;
      final longestStreak = data['longestStreak'] as int? ?? 0;
      final lastActiveDate = data['lastActiveDate'] as String? ?? '';
      final achievedMilestones = _parseAchievedMilestones(data['achievedMilestones']);

      final today = _formatDate(DateTime.now());
      final yesterday = _formatDate(DateTime.now().subtract(const Duration(days: 1)));

      int newStreak;
      bool isNewRecord = false;
      StreakMilestone? milestoneAchieved;

      // Case 1: Sudah practice hari ini
      if (lastActiveDate == today) {
        newStreak = currentStreak; // No change
      }
      // Case 2: Kemarin practice (continue streak)
      else if (lastActiveDate == yesterday) {
        newStreak = currentStreak + 1;

        // Check milestone
        milestoneAchieved = _checkMilestone(newStreak, achievedMilestones);
      }
      // Case 3: Streak broken (reset to 1)
      else {
        newStreak = 1;
      }

      // Update longest streak if needed
      final newLongestStreak = newStreak > longestStreak ? newStreak : longestStreak;
      isNewRecord = newStreak > longestStreak;

      // Prepare update
      final updateData = {
        'streak': newStreak,
        'longestStreak': newLongestStreak,
        'lastActiveDate': today,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add milestone if achieved
      if (milestoneAchieved != null) {
        final updatedMilestones = [...achievedMilestones, milestoneAchieved];
        updateData['achievedMilestones'] = updatedMilestones.map((m) => m.toMap()).toList();

        // Add rewards
        updateData['xp'] = FieldValue.increment(milestoneAchieved.xpReward);
        if (milestoneAchieved.diamondReward > 0) {
          updateData['diamond'] = FieldValue.increment(milestoneAchieved.diamondReward);
        }
      }

      transaction.update(userRef, updateData);

      return StreakUpdateResult(
        newStreak: newStreak,
        isNewRecord: isNewRecord,
        milestoneAchieved: milestoneAchieved,
        wasContinued: lastActiveDate == yesterday,
        wasBroken: lastActiveDate != yesterday && lastActiveDate != today,
      );
    });
  }

  // Check if streak reached a milestone
  StreakMilestone? _checkMilestone(
      int newStreak,
      List<StreakMilestone> achievedMilestones,
      ) {
    final allMilestones = StreakMilestone.allMilestones;

    for (final milestone in allMilestones) {
      if (milestone.days == newStreak) {
        final isAlreadyAchieved = achievedMilestones.any((m) => m.days == milestone.days);
        if (!isAlreadyAchieved) {
          return milestone;
        }
      }
    }

    return null;
  }

  // ============================================================================
  // CLAIM REWARDS
  // ============================================================================

  /// Claim unclaimed milestone rewards
  ///
  /// Returns: List of claimed rewards
  Future<List<StreakMilestone>> claimUnclaimedRewards() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User tidak login');
    }

    final userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction<List<StreakMilestone>>((transaction) async {
      final userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw Exception('User data tidak ditemukan');
      }

      final data = userDoc.data()!;
      final currentStreak = data['streak'] as int? ?? 0;
      final achievedMilestones = _parseAchievedMilestones(data['achievedMilestones']);

      // Find unclaimed rewards
      final unclaimed = StreakMilestone.allMilestones.where((m) {
        return m.days <= currentStreak &&
            !achievedMilestones.any((achieved) => achieved.days == m.days);
      }).toList();

      if (unclaimed.isEmpty) {
        return [];
      }

      // Calculate total rewards
      int totalXP = 0;
      int totalDiamond = 0;
      for (final milestone in unclaimed) {
        totalXP += milestone.xpReward;
        totalDiamond += milestone.diamondReward;
      }

      // Update milestones
      final updatedMilestones = [...achievedMilestones, ...unclaimed];

      transaction.update(userRef, {
        'achievedMilestones': updatedMilestones.map((m) => m.toMap()).toList(),
        'xp': FieldValue.increment(totalXP),
        'diamond': FieldValue.increment(totalDiamond),
      });

      return unclaimed;
    });
  }

  // ============================================================================
  // FREEZE STREAK (Premium Feature)
  // ============================================================================

  /// Freeze streak for 1 day (cost: 1 diamond)
  /// User can skip 1 day without breaking streak
  Future<void> freezeStreak() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User tidak login');
    }

    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw Exception('User data tidak ditemukan');
      }

      final data = userDoc.data()!;
      final diamond = data['diamond'] as int? ?? 0;

      if (diamond < 1) {
        throw Exception('Diamond tidak cukup!');
      }

      final lastActiveDate = data['lastActiveDate'] as String? ?? '';
      final today = _formatDate(DateTime.now());

      // Sudah freeze hari ini
      if (lastActiveDate == today) {
        throw Exception('Streak sudah aman hari ini!');
      }

      transaction.update(userRef, {
        'lastActiveDate': today, // Set as if practiced today
        'diamond': FieldValue.increment(-1),
        'diamondStats.totalSpent': FieldValue.increment(1),
      });
    });
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Check if user practiced today
  Future<bool> isPracticedToday() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return false;

    final lastActiveDate = doc.data()!['lastActiveDate'] as String? ?? '';
    return lastActiveDate == _formatDate(DateTime.now());
  }

  /// Get days since last active
  Future<int> daysSinceLastActive() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 999;

    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return 999;

    final lastActiveDate = doc.data()!['lastActiveDate'] as String? ?? '';
    if (lastActiveDate.isEmpty) return 999;

    final lastDate = DateTime.parse(lastActiveDate);
    final today = DateTime.now();

    return today.difference(lastDate).inDays;
  }
}

// ==============================================================================
// STREAK UPDATE RESULT
// ==============================================================================

class StreakUpdateResult {
  final int newStreak;
  final bool isNewRecord;
  final StreakMilestone? milestoneAchieved;
  final bool wasContinued;
  final bool wasBroken;

  const StreakUpdateResult({
    required this.newStreak,
    required this.isNewRecord,
    this.milestoneAchieved,
    required this.wasContinued,
    required this.wasBroken,
  });

  bool get hasReward => milestoneAchieved != null;

  String get statusMessage {
    if (milestoneAchieved != null) {
      return '🎉 Streak $newStreak hari! Milestone "${milestoneAchieved!.badgeName}" tercapai!';
    }
    if (isNewRecord) {
      return '🔥 Rekor baru! Streak $newStreak hari!';
    }
    if (wasContinued) {
      return '🔥 Streak $newStreak hari!';
    }
    if (wasBroken) {
      return '💔 Streak terputus. Mulai lagi dari hari ke-1!';
    }
    return 'Streak $newStreak hari';
  }

  @override
  String toString() {
    return 'StreakUpdateResult(streak: $newStreak, milestone: ${milestoneAchieved?.badgeName ?? "none"})';
  }
}