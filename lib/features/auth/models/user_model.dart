// lib/features/auth/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// User data model - represents complete user document in Firestore
///
/// Matches Firestore schema exactly for type safety
// lib/core/models/user_model.dart

// lib/core/models/user_model.dart

class UserModel {
  // === BASIC INFO ===
  final String userId;
  final String email;
  final String displayName;
  final String photoURL;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  // === PRICE (pengganti energy) ===
  final int price;

  // === GAMIFICATION ===
  final int xp;
  final int level;
  final int streak;
  final int longestStreak;
  final String? lastActiveDate; // YYYY-MM-DD format

  // === AGGREGATED STATS ===
  final UserStats stats;

  // === SKILLS (Adaptive Learning) ===
  final Map<String, SkillData> skills;

  // === SETTINGS ===
  final UserSettings settings;

  // === GOAL (from onboarding) ===
  final String? goal;

  // === OWNED TRYOUTS ===
  final List<String> ownedTryouts; // Array of tryout IDs

  const UserModel({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.photoURL,
    required this.createdAt,
    this.lastLoginAt,
    required this.price,
    required this.xp,
    required this.level,
    required this.streak,
    required this.longestStreak,
    this.lastActiveDate,
    required this.stats,
    required this.skills,
    required this.settings,
    this.goal,
    this.ownedTryouts = const [],
  });

  // ============================================================================
  // FACTORY: FROM FIRESTORE
  // ============================================================================

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      userId: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoURL: data['photoURL'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),

      price: data['price'] as int? ?? 0,

      xp: data['xp'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      streak: data['streak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      lastActiveDate: data['lastActiveDate'] as String?,

      stats: UserStats.fromMap(
        data['stats'] as Map<String, dynamic>? ?? {},
      ),

      skills: _parseSkills(data['skills'] as Map<String, dynamic>? ?? {}),

      settings: UserSettings.fromMap(
        data['settings'] as Map<String, dynamic>? ?? {},
      ),

      goal: data['goal'] as String?,

      ownedTryouts: List<String>.from(data['ownedTryouts'] ?? []),
    );
  }

  // Helper to parse skills map
  static Map<String, SkillData> _parseSkills(Map<String, dynamic> skillsMap) {
    return skillsMap.map(
          (key, value) => MapEntry(
        key,
        SkillData.fromMap(value as Map<String, dynamic>),
      ),
    );
  }

  // ============================================================================
  // FACTORY: CREATE NEW USER (Default values for registration)
  // ============================================================================

  factory UserModel.createNew({
    required String userId,
    required String email,
    String? displayName,
    String? photoURL,
    String? goal,
  }) {
    final now = DateTime.now();

    return UserModel(
      userId: userId,
      email: email,
      displayName: displayName ?? email.split('@').first,
      photoURL: photoURL ?? '',
      createdAt: now,
      lastLoginAt: now,

      // Starting price
      price: 0,

      // Starting gamification
      xp: 0,
      level: 1,
      streak: 0,
      longestStreak: 0,
      lastActiveDate: null,

      // Empty stats
      stats: const UserStats(
        totalExams: 0,
        totalQuestions: 0,
        totalCorrect: 0,
        overallAccuracy: 0,
        byCategory: {
          'TWK': CategoryStats(total: 0, correct: 0, accuracy: 0),
          'TIU': CategoryStats(total: 0, correct: 0, accuracy: 0),
          'TKP': CategoryStats(total: 0, correct: 0, accuracy: 0),
        },
      ),

      // Empty skills
      skills: const {},

      // Default settings
      settings: const UserSettings(
        notifications: true,
        soundEnabled: true,
        darkMode: false,
      ),

      goal: goal,

      // No tryouts owned yet
      ownedTryouts: const [],
    );
  }

  // ============================================================================
  // TO FIRESTORE
  // ============================================================================

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt':
      lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,

      'price': price,

      'xp': xp,
      'level': level,
      'streak': streak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate,

      'stats': stats.toMap(),

      'skills': skills.map((key, value) => MapEntry(key, value.toMap())),

      'settings': settings.toMap(),

      if (goal != null) 'goal': goal,

      'ownedTryouts': ownedTryouts,
    };
  }

  // ============================================================================
  // COPY WITH
  // ============================================================================

  UserModel copyWith({
    String? displayName,
    String? photoURL,
    DateTime? lastLoginAt,
    int? price,
    int? xp,
    int? level,
    int? streak,
    int? longestStreak,
    String? lastActiveDate,
    UserStats? stats,
    Map<String, SkillData>? skills,
    UserSettings? settings,
    String? goal,
    List<String>? ownedTryouts,
  }) {
    return UserModel(
      userId: userId,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      price: price ?? this.price,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      stats: stats ?? this.stats,
      skills: skills ?? this.skills,
      settings: settings ?? this.settings,
      goal: goal ?? this.goal,
      ownedTryouts: ownedTryouts ?? this.ownedTryouts,
    );
  }

  // ============================================================================
  // HELPER METHODS FOR TRYOUTS
  // ============================================================================

  /// Check if user owns a specific tryout
  bool ownsTryout(String tryoutId) {
    return ownedTryouts.contains(tryoutId);
  }

  /// Get count of owned tryouts
  int get ownedTryoutCount => ownedTryouts.length;
}

// ============================================================================
// NESTED DATA CLASSES
// ============================================================================

class DiamondStats {
  final int totalPurchased;
  final int totalSpent;

  const DiamondStats({
    required this.totalPurchased,
    required this.totalSpent,
  });

  factory DiamondStats.fromMap(Map<String, dynamic> map) {
    return DiamondStats(
      totalPurchased: map['totalPurchased'] as int? ?? 0,
      totalSpent: map['totalSpent'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalPurchased': totalPurchased,
      'totalSpent': totalSpent,
    };
  }
}

class EnergyData {
  final int current;
  final int max;
  final int regenRate;
  final DateTime lastRegen;
  final DateTime? lastUsed;
  final int totalUsed;

  const EnergyData({
    required this.current,
    required this.max,
    required this.regenRate,
    required this.lastRegen,
    this.lastUsed,
    required this.totalUsed,
  });

  factory EnergyData.fromMap(Map<String, dynamic> map) {
    return EnergyData(
      current: map['current'] as int? ?? 5,
      max: map['max'] as int? ?? 5,
      regenRate: map['regenRate'] as int? ?? 10,
      lastRegen: (map['lastRegen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUsed: (map['lastUsed'] as Timestamp?)?.toDate(),
      totalUsed: map['totalUsed'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'current': current,
      'max': max,
      'regenRate': regenRate,
      'lastRegen': Timestamp.fromDate(lastRegen),
      'lastUsed': lastUsed != null ? Timestamp.fromDate(lastUsed!) : null,
      'totalUsed': totalUsed,
    };
  }
}

class UserStats {
  final int totalExams;
  final int totalQuestions;
  final int totalCorrect;
  final double overallAccuracy;
  final Map<String, CategoryStats> byCategory;

  const UserStats({
    required this.totalExams,
    required this.totalQuestions,
    required this.totalCorrect,
    required this.overallAccuracy,
    required this.byCategory,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    final byCategory = (map['byCategory'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(
        key,
        CategoryStats.fromMap(value as Map<String, dynamic>),
      ),
    );

    return UserStats(
      totalExams: map['totalExams'] as int? ?? 0,
      totalQuestions: map['totalQuestions'] as int? ?? 0,
      totalCorrect: map['totalCorrect'] as int? ?? 0,
      overallAccuracy: (map['overallAccuracy'] as num?)?.toDouble() ?? 0.0,
      byCategory: byCategory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalExams': totalExams,
      'totalQuestions': totalQuestions,
      'totalCorrect': totalCorrect,
      'overallAccuracy': overallAccuracy,
      'byCategory': byCategory.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}

class CategoryStats {
  final int total;
  final int correct;
  final double accuracy;

  const CategoryStats({
    required this.total,
    required this.correct,
    required this.accuracy,
  });

  factory CategoryStats.fromMap(Map<String, dynamic> map) {
    return CategoryStats(
      total: map['total'] as int? ?? 0,
      correct: map['correct'] as int? ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total': total,
      'correct': correct,
      'accuracy': accuracy,
    };
  }
}

class SkillData {
  final int level;
  final int total;
  final int correct;
  final double accuracy;

  const SkillData({
    required this.level,
    required this.total,
    required this.correct,
    required this.accuracy,
  });

  factory SkillData.fromMap(Map<String, dynamic> map) {
    return SkillData(
      level: map['level'] as int? ?? 0,
      total: map['total'] as int? ?? 0,
      correct: map['correct'] as int? ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'total': total,
      'correct': correct,
      'accuracy': accuracy,
    };
  }
}

class AdsData {
  final int totalBannerImpressions;
  final int totalInterstitialShown;
  final int totalRewardedWatched;
  final DateTime? lastRewardedAt;

  const AdsData({
    required this.totalBannerImpressions,
    required this.totalInterstitialShown,
    required this.totalRewardedWatched,
    this.lastRewardedAt,
  });

  factory AdsData.fromMap(Map<String, dynamic> map) {
    return AdsData(
      totalBannerImpressions: map['totalBannerImpressions'] as int? ?? 0,
      totalInterstitialShown: map['totalInterstitialShown'] as int? ?? 0,
      totalRewardedWatched: map['totalRewardedWatched'] as int? ?? 0,
      lastRewardedAt: (map['lastRewardedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalBannerImpressions': totalBannerImpressions,
      'totalInterstitialShown': totalInterstitialShown,
      'totalRewardedWatched': totalRewardedWatched,
      'lastRewardedAt': lastRewardedAt != null ? Timestamp.fromDate(lastRewardedAt!) : null,
    };
  }
}

class UserSettings {
  final bool notifications;
  final bool soundEnabled;
  final bool darkMode;

  const UserSettings({
    required this.notifications,
    required this.soundEnabled,
    required this.darkMode,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      notifications: map['notifications'] as bool? ?? true,
      soundEnabled: map['soundEnabled'] as bool? ?? true,
      darkMode: map['darkMode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notifications': notifications,
      'soundEnabled': soundEnabled,
      'darkMode': darkMode,
    };
  }
}