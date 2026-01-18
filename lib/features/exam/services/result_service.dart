// lib/features/exam/services/result_service.dart

import 'package:lulusasn/core/services/firebase_service.dart';
import 'package:lulusasn/features/exam/models/answer_model.dart';
import 'package:lulusasn/features/exam/models/exam_result_model.dart';
import 'package:lulusasn/features/exam/models/question_model.dart';

/// Service untuk Result Calculation & Analytics
///
/// OPTIMIZATION STRATEGY:
/// 1. Pure calculation functions (zero Firestore reads)
/// 2. Aggregate data sudah di user doc (1 read untuk semua stats)
/// 3. Client-side computation untuk analytics
/// 4. Batch updates untuk skill calibration
/// 5. Cached leaderboard results
///
/// PRINCIPLE: Calculate client-side, store aggregate server-side
class ResultService {
  static final ResultService _instance = ResultService._internal();
  factory ResultService() => _instance;
  ResultService._internal();

  final _firestore = FirebaseService.instance.firestore;
  final _auth = FirebaseService.instance.auth;

  // ==========================================================================
  // RESULT CALCULATION (PURE FUNCTIONS - ZERO FIRESTORE)
  // ==========================================================================

  /// Calculate exam result dari list of answers
  ///
  /// OPTIMIZATION: Pure computation, no Firestore reads!
  /// Called by ExamService saat submit exam
  ExamResultModel calculateResult({
    required String examId,
    required String packageId,
    required DateTime startedAt,
    required List<AnswerModel> answers,
    required int energyBefore,
    required int energyAfter,
    required int streakDay,
    String? category,
  }) {
    return ExamResultModel.fromAnswers(
      examId: examId,
      startedAt: startedAt,
      answers: answers,
      energyBefore: energyBefore,
      energyAfter: energyAfter,
      streakDay: streakDay,
      category: category,
      packageId: packageId,
    );
  }

  /// Calculate accuracy untuk specific category
  double calculateCategoryAccuracy(List<AnswerModel> answers, String category) {
    final categoryAnswers = answers
        .where((a) => a.category == category && a.isAnswered)
        .toList();

    if (categoryAnswers.isEmpty) return 0.0;

    final correct = categoryAnswers.where((a) => a.isCorrect).length;
    return correct / categoryAnswers.length;
  }

  /// Calculate accuracy untuk specific question type
  double calculateTypeAccuracy(List<AnswerModel> answers, QuestionType type) {
    final typeAnswers = answers
        .where((a) => a.questionType == type && a.isAnswered)
        .toList();

    if (typeAnswers.isEmpty) return 0.0;

    final correct = typeAnswers.where((a) => a.isCorrect).length;
    return correct / typeAnswers.length;
  }

  /// Calculate average time per question
  double calculateAverageTime(List<AnswerModel> answers) {
    final answeredQuestions = answers.where((a) => a.isAnswered).toList();

    if (answeredQuestions.isEmpty) return 0.0;

    final totalTime = answeredQuestions
        .map((a) => a.timeTaken)
        .reduce((a, b) => a + b);

    return totalTime / answeredQuestions.length;
  }

  /// Get weak areas (subcategories dengan accuracy < 60%)
  Map<String, double> identifyWeakAreas(List<AnswerModel> answers) {
    final subcategoryGroups = <String, List<AnswerModel>>{};

    // Group by subcategory
    for (final answer in answers.where((a) => a.isAnswered)) {
      final subcategory = answer.subcategory;
      subcategoryGroups[subcategory] = (subcategoryGroups[subcategory] ?? [])
        ..add(answer);
    }

    // Calculate accuracy per subcategory
    final weakAreas = <String, double>{};

    subcategoryGroups.forEach((subcategory, subAnswers) {
      final correct = subAnswers.where((a) => a.isCorrect).length;
      final accuracy = correct / subAnswers.length;

      if (accuracy < 0.6) {
        weakAreas[subcategory] = accuracy;
      }
    });

    // Sort by accuracy (lowest first)
    final sortedEntries = weakAreas.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Map.fromEntries(sortedEntries);
  }

  // ==========================================================================
  // USER STATISTICS (AGGREGATE READS)
  // ==========================================================================

  /// Get user's overall statistics
  ///
  /// OPTIMIZATION: 1 document read untuk semua stats!
  /// Semua agregasi sudah disimpan di user doc
  Future<UserStatistics> getUserStatistics() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User tidak login');
    }

    final doc = await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) {
      return UserStatistics.empty();
    }

    final data = doc.data()!;
    final statsData = data['stats'] as Map<String, dynamic>? ?? {};

    return UserStatistics(
      totalExams: statsData['totalExams'] as int? ?? 0,
      totalQuestions: statsData['totalQuestions'] as int? ?? 0,
      totalCorrect: statsData['totalCorrect'] as int? ?? 0,
      overallAccuracy:
          (statsData['overallAccuracy'] as num?)?.toDouble() ?? 0.0,
      byCategory: _parseStatsCategory(
        statsData['byCategory'] as Map<String, dynamic>?,
      ),
      xp: data['xp'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      streak: data['streak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
    );
  }

  /// Parse category statistics
  Map<String, CategoryStats> _parseStatsCategory(Map<String, dynamic>? data) {
    if (data == null) return {};

    return data.map((key, value) {
      final map = value as Map<String, dynamic>;
      return MapEntry(
        key,
        CategoryStats(
          total: map['total'] as int? ?? 0,
          correct: map['correct'] as int? ?? 0,
          accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
        ),
      );
    });
  }

  // ==========================================================================
  // SKILL ANALYSIS (READ FROM USER DOC)
  // ==========================================================================

  /// Get detailed skill analysis per subcategory
  ///
  /// OPTIMIZATION: 1 document read
  Future<Map<String, SkillData>> getSkillAnalysis() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};

    final doc = await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) return {};

    final data = doc.data()!;
    final skillsData = data['skills'] as Map<String, dynamic>? ?? {};

    return skillsData.map((key, value) {
      final map = value as Map<String, dynamic>;
      final total = map['total'] as int? ?? 0;
      final correct = map['correct'] as int? ?? 0;

      return MapEntry(
        key,
        SkillData(
          subcategory: key,
          level: map['level'] as int? ?? 0,
          total: total,
          correct: correct,
          accuracy: total > 0 ? correct / total : 0.0,
        ),
      );
    });
  }

  /// Get skill mastery level (Beginner, Intermediate, Advanced, Expert)
  SkillLevel getSkillLevel(double accuracy, int questionsAnswered) {
    if (questionsAnswered < 10) {
      return SkillLevel.beginner;
    } else if (questionsAnswered < 30) {
      if (accuracy >= 0.8) return SkillLevel.intermediate;
      return SkillLevel.beginner;
    } else if (questionsAnswered < 100) {
      if (accuracy >= 0.85) return SkillLevel.advanced;
      if (accuracy >= 0.7) return SkillLevel.intermediate;
      return SkillLevel.beginner;
    } else {
      if (accuracy >= 0.9) return SkillLevel.expert;
      if (accuracy >= 0.8) return SkillLevel.advanced;
      if (accuracy >= 0.7) return SkillLevel.intermediate;
      return SkillLevel.beginner;
    }
  }

  // ==========================================================================
  // COMPARISON & BENCHMARKING
  // ==========================================================================

  /// Compare user performance dengan average
  ///
  /// OPTIMIZATION: Use pre-calculated aggregates (cloud function nightly)
  /// Fallback: Calculate dari sample data
  Future<PerformanceComparison> compareWithAverage() async {
    final userStats = await getUserStatistics();

    // TODO: Fetch global averages dari aggregated collection
    // For now, use hardcoded benchmarks
    const benchmarkAccuracy = {'TWK': 0.65, 'TIU': 0.60, 'TKP': 0.75};

    final comparisons = <String, ComparisonData>{};

    userStats.byCategory.forEach((category, stats) {
      final benchmark = benchmarkAccuracy[category] ?? 0.65;
      final difference = stats.accuracy - benchmark;

      comparisons[category] = ComparisonData(
        category: category,
        userAccuracy: stats.accuracy,
        averageAccuracy: benchmark,
        difference: difference,
        percentile: _calculatePercentile(stats.accuracy, benchmark),
      );
    });

    return PerformanceComparison(
      overallAccuracy: userStats.overallAccuracy,
      overallAverage: 0.65,
      byCategory: comparisons,
    );
  }

  /// Calculate percentile (simplified)
  int _calculatePercentile(double userAccuracy, double average) {
    if (userAccuracy >= average + 0.2) return 90;
    if (userAccuracy >= average + 0.1) return 75;
    if (userAccuracy >= average) return 50;
    if (userAccuracy >= average - 0.1) return 25;
    return 10;
  }

  // ==========================================================================
  // PROGRESS TRACKING
  // ==========================================================================

  /// Get progress over time (last N exams)
  ///
  /// OPTIMIZATION: Fetch exam docs saja (tanpa answers)
  Future<List<ProgressPoint>> getProgressHistory({int limit = 30}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('exams')
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .get();

    final results = snapshot.docs
        .map((doc) => ExamResultModel.fromFirestore(doc))
        .toList();

    // Reverse untuk chronological order
    results.sort((a, b) => a.completedAt!.compareTo(b.completedAt!));

    return results.map((result) {
      return ProgressPoint(
        date: result.completedAt!,
        accuracy: result.accuracy,
        xpEarned: result.totalXP,
        category: result.category,
      );
    }).toList();
  }

  /// Calculate improvement rate (% change dalam 7 hari)
  Future<double> calculateImprovementRate() async {
    final history = await getProgressHistory(limit: 30);

    if (history.length < 2) return 0.0;

    final now = DateTime.now();
    final weekAgo = now.subtract(Duration(days: 7));

    final recentAccuracies = history
        .where((p) => p.date.isAfter(weekAgo))
        .map((p) => p.accuracy)
        .toList();

    final olderAccuracies = history
        .where((p) => p.date.isBefore(weekAgo))
        .map((p) => p.accuracy)
        .toList();

    if (recentAccuracies.isEmpty || olderAccuracies.isEmpty) return 0.0;

    final recentAvg =
        recentAccuracies.reduce((a, b) => a + b) / recentAccuracies.length;
    final olderAvg =
        olderAccuracies.reduce((a, b) => a + b) / olderAccuracies.length;

    return ((recentAvg - olderAvg) / olderAvg) * 100;
  }

  // ==========================================================================
  // INSIGHTS & RECOMMENDATIONS
  // ==========================================================================

  /// Generate personalized insights
  Future<List<String>> generateInsights() async {
    final insights = <String>[];
    final stats = await getUserStatistics();
    final weakAreas = await _getWeakSubcategories();
    final improvement = await calculateImprovementRate();

    // Streak insights
    if (stats.streak >= 7) {
      insights.add('🔥 Streak ${stats.streak} hari! Pertahankan konsistensi.');
    } else if (stats.streak == 0) {
      insights.add('Mulai streak baru hari ini!');
    }

    // Performance insights
    if (stats.overallAccuracy >= 0.85) {
      insights.add('💪 Performa excellent! Kamu di top 10%.');
    } else if (stats.overallAccuracy < 0.6) {
      insights.add('Fokus pada pemahaman konsep dasar.');
    }

    // Improvement insights
    if (improvement > 10) {
      insights.add(
        '📈 Akurasi meningkat ${improvement.toStringAsFixed(1)}% minggu ini!',
      );
    } else if (improvement < -10) {
      insights.add('Perlu lebih banyak latihan rutin.');
    }

    // Weak area recommendations
    if (weakAreas.isNotEmpty) {
      final topWeak = weakAreas.entries.first;
      insights.add('🎯 Fokus latihan: ${topWeak.key}');
    }

    return insights;
  }

  /// Get weak subcategories (internal helper)
  Future<Map<String, double>> _getWeakSubcategories() async {
    final skills = await getSkillAnalysis();

    final weak = <String, double>{};
    skills.forEach((key, skill) {
      if (skill.total >= 5 && skill.accuracy < 0.6) {
        weak[key] = skill.accuracy;
      }
    });

    // Sort by accuracy
    final sorted = weak.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Map.fromEntries(sorted.take(3));
  }
}

// ==============================================================================
// DATA MODELS (FOR RESULT SERVICE)
// ==============================================================================

/// User overall statistics
class UserStatistics {
  final int totalExams;
  final int totalQuestions;
  final int totalCorrect;
  final double overallAccuracy;
  final Map<String, CategoryStats> byCategory;
  final int xp;
  final int level;
  final int streak;
  final int longestStreak;

  const UserStatistics({
    required this.totalExams,
    required this.totalQuestions,
    required this.totalCorrect,
    required this.overallAccuracy,
    required this.byCategory,
    required this.xp,
    required this.level,
    required this.streak,
    required this.longestStreak,
  });

  factory UserStatistics.empty() {
    return UserStatistics(
      totalExams: 0,
      totalQuestions: 0,
      totalCorrect: 0,
      overallAccuracy: 0.0,
      byCategory: {},
      xp: 0,
      level: 1,
      streak: 0,
      longestStreak: 0,
    );
  }
}

/// Category statistics
class CategoryStats {
  final int total;
  final int correct;
  final double accuracy;

  const CategoryStats({
    required this.total,
    required this.correct,
    required this.accuracy,
  });
}

/// Skill data per subcategory
class SkillData {
  final String subcategory;
  final int level;
  final int total;
  final int correct;
  final double accuracy;

  const SkillData({
    required this.subcategory,
    required this.level,
    required this.total,
    required this.correct,
    required this.accuracy,
  });
}

/// Skill level enum
enum SkillLevel {
  beginner('Pemula'),
  intermediate('Menengah'),
  advanced('Mahir'),
  expert('Expert');

  final String label;
  const SkillLevel(this.label);
}

/// Performance comparison
class PerformanceComparison {
  final double overallAccuracy;
  final double overallAverage;
  final Map<String, ComparisonData> byCategory;

  const PerformanceComparison({
    required this.overallAccuracy,
    required this.overallAverage,
    required this.byCategory,
  });
}

/// Comparison data per category
class ComparisonData {
  final String category;
  final double userAccuracy;
  final double averageAccuracy;
  final double difference;
  final int percentile;

  const ComparisonData({
    required this.category,
    required this.userAccuracy,
    required this.averageAccuracy,
    required this.difference,
    required this.percentile,
  });

  bool get aboveAverage => difference > 0;
}

/// Progress point untuk charting
class ProgressPoint {
  final DateTime date;
  final double accuracy;
  final int xpEarned;
  final String category;

  const ProgressPoint({
    required this.date,
    required this.accuracy,
    required this.xpEarned,
    required this.category,
  });
}
