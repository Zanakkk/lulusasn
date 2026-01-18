// lib/features/exam/models/exam_result_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lulusasn/features/exam/models/answer_model.dart';

/// Model untuk Exam Result
///
/// Menyimpan hasil exam user:
/// - Total questions, correct count, accuracy
/// - Breakdown by category (TWK, TIU, TKP)
/// - Breakdown by type (yesno, likert, objective)
/// - XP earned, streak info
/// - Energy usage
class ExamResultModel {
  final String examId;
  final String? packageId; // 🆕 TAMBAH INI
  final DateTime startedAt;
  final DateTime? completedAt;
  final int duration; // seconds
  final String category; // "TWK", "TIU", "TKP", or "mixed"
  final List<AnswerModel>? answers; // 🆕 OPTIONAL embedded answers
  // Energy info
  final int energyUsed;
  final int energyBefore;
  final int energyAfter;

  // Aggregated results
  final int totalQuestions;
  final int correctCount;
  final double accuracy;

  // Breakdown by type
  final Map<String, CategoryResult> byType;

  // Breakdown by category
  final Map<String, CategoryResult> byCategory;

  // Gamification
  final int xpEarned;
  final int bonusXP;
  final int streakDay;

  // Ads (untuk free users)
  final bool adsShown;
  final String? adType; // "interstitial", "rewarded"

  const ExamResultModel({
    required this.examId,
    required this.packageId, // 🆕 TAMBAH INI
    required this.startedAt,
    required this.completedAt,
    required this.duration,
    required this.category,
    required this.energyUsed,
    required this.energyBefore,
    required this.energyAfter,
    required this.totalQuestions,
    required this.correctCount,
    required this.accuracy,
    required this.byType,
    required this.byCategory,
    required this.xpEarned,
    required this.bonusXP,
    required this.streakDay,
    required this.adsShown,
    required this.adType,
    required this.answers, // 🆕 TAMBAH
  });

  // ==========================================================================
  // FACTORY CONSTRUCTORS
  // ==========================================================================

  /// Create dari Firestore document
  factory ExamResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final resultsData = data['results'] as Map<String, dynamic>? ?? {};

    // 🆕 Parse embedded answers
    final answersData = data['answers'] as List<dynamic>?;
    final answers = answersData?.map((a) =>
        AnswerModel.fromMap(a as Map<String, dynamic>)
    ).toList();


    return ExamResultModel(
      examId: doc.id,packageId: data['packageId'] as String?, // 🆕 AMBIL packageId

      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      duration: data['duration'] as int? ?? 0,
      category: data['category'] as String? ?? 'mixed',
      energyUsed: data['energyUsed'] as int? ?? 1,
      energyBefore: data['energyBefore'] as int? ?? 5,
      energyAfter: data['energyAfter'] as int? ?? 4,
      totalQuestions: resultsData['totalQuestions'] as int? ?? 0,
      correctCount: resultsData['correctCount'] as int? ?? 0,
      accuracy: (resultsData['accuracy'] as num?)?.toDouble() ?? 0.0,
      byType: _parseBreakdown(resultsData['byType'] as Map<String, dynamic>?),
      byCategory: _parseBreakdown(resultsData['byCategory'] as Map<String, dynamic>?),
      xpEarned: data['xpEarned'] as int? ?? 0,
      bonusXP: data['bonusXP'] as int? ?? 0,
      streakDay: data['streakDay'] as int? ?? 0,
      adsShown: data['adsShown'] as bool? ?? false,
      adType: data['adType'] as String?,
      answers: answers, // 🆕
    );
  }

  /// Create dari list of answers (saat exam selesai)
  factory ExamResultModel.fromAnswers({
    required String examId,
    required String? packageId,
    required DateTime startedAt,
    required List<AnswerModel> answers,
    required int energyBefore,
    required int energyAfter,
    required int streakDay,
    String? category,
  }) {
    final now = DateTime.now();
    final duration = now.difference(startedAt).inSeconds;

    // Calculate totals
    final totalQuestions = answers.length;
    final correctCount = answers.where((a) => a.isCorrect).length;
    final accuracy = totalQuestions > 0 ? correctCount / totalQuestions : 0.0;

    // Group by type
    final byType = <String, CategoryResult>{};
    final typeGroups = <String, List<AnswerModel>>{};

    for (final answer in answers) {
      final type = answer.questionType.value;
      typeGroups[type] = (typeGroups[type] ?? [])..add(answer);
    }

    typeGroups.forEach((type, typeAnswers) {
      final total = typeAnswers.length;
      final correct = typeAnswers.where((a) => a.isCorrect).length;
      byType[type] = CategoryResult(
        total: total,
        correct: correct,
        accuracy: total > 0 ? correct / total : 0.0,
      );
    });

    // Group by category
    final byCategory = <String, CategoryResult>{};
    final categoryGroups = <String, List<AnswerModel>>{};

    for (final answer in answers) {
      final cat = answer.category;
      categoryGroups[cat] = (categoryGroups[cat] ?? [])..add(answer);
    }

    categoryGroups.forEach((cat, catAnswers) {
      final total = catAnswers.length;
      final correct = catAnswers.where((a) => a.isCorrect).length;
      byCategory[cat] = CategoryResult(
        total: total,
        correct: correct,
        accuracy: total > 0 ? correct / total : 0.0,
      );
    });

    // Calculate XP (base: 10 per correct answer)
    final baseXP = correctCount * 10;
    final bonusXP = _calculateBonusXP(accuracy, duration, totalQuestions);

    return ExamResultModel(
      examId: examId,
      packageId: packageId, // 🆕 SIMPAN packageId
      startedAt: startedAt,
      completedAt: now,
      duration: duration,
      category: category ?? 'mixed',
      energyUsed: 1,
      energyBefore: energyBefore,
      energyAfter: energyAfter,
      totalQuestions: totalQuestions,
      correctCount: correctCount,
      accuracy: accuracy,
      byType: byType,
      byCategory: byCategory,
      xpEarned: baseXP,
      bonusXP: bonusXP,
      streakDay: streakDay,
      adsShown: false,
      adType: null, answers: [],
    );
  }

  // ==========================================================================
  // TO FIRESTORE
  // ==========================================================================

  Map<String, dynamic> toFirestore() {
    return {'packageId': packageId, // 🆕 SIMPAN packageId
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'duration': duration,
      'category': category,
      'energyUsed': energyUsed,
      'energyBefore': energyBefore,
      'energyAfter': energyAfter,
      'results': {
        'totalQuestions': totalQuestions,
        'correctCount': correctCount,
        'accuracy': accuracy,
        'byType': byType.map((k, v) => MapEntry(k, v.toMap())),
        'byCategory': byCategory.map((k, v) => MapEntry(k, v.toMap())),
      },
      'xpEarned': xpEarned,
      'bonusXP': bonusXP,
      'streakDay': streakDay,
      'adsShown': adsShown,
      'adType': adType,
      if (answers != null)
        'answers': answers!.map((a) => a.toMap()).toList(), // 🆕
    };
  }

  // ==========================================================================
  // BUSINESS LOGIC
  // ==========================================================================

  /// Total XP (base + bonus)
  int get totalXP => xpEarned + bonusXP;

  /// Passing grade (70%)
  bool get isPassed => accuracy >= 0.7;

  /// Accuracy grade (A, B, C, D, E)
  String get accuracyGrade {
    if (accuracy >= 0.9) return 'A';
    if (accuracy >= 0.8) return 'B';
    if (accuracy >= 0.7) return 'C';
    if (accuracy >= 0.6) return 'D';
    return 'E';
  }

  /// Performance message
  String get performanceMessage {
    if (accuracy >= 0.9) return 'Luar biasa! 🔥';
    if (accuracy >= 0.8) return 'Sangat bagus! 👏';
    if (accuracy >= 0.7) return 'Bagus! 👍';
    if (accuracy >= 0.6) return 'Cukup baik!';
    if (accuracy >= 0.5) return 'Terus berlatih!';
    return 'Jangan menyerah! 💪';
  }

  /// Average time per question (seconds)
  double get averageTimePerQuestion {
    return totalQuestions > 0 ? duration / totalQuestions : 0.0;
  }

  /// Format duration to readable string (MM:SS)
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  static Map<String, CategoryResult> _parseBreakdown(Map<String, dynamic>? data) {
    if (data == null) return {};

    return data.map((key, value) {
      final map = value as Map<String, dynamic>;
      return MapEntry(
        key,
        CategoryResult(
          total: map['total'] as int? ?? 0,
          correct: map['correct'] as int? ?? 0,
          accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
        ),
      );
    });
  }

  static int _calculateBonusXP(double accuracy, int duration, int totalQuestions) {
    int bonus = 0;

    // Accuracy bonus
    if (accuracy >= 0.9) {
      bonus += 50; // Perfect score
    } else if (accuracy >= 0.8) {
      bonus += 30;
    } else if (accuracy >= 0.7) {
      bonus += 10;
    }

    // Speed bonus (avg < 30s per question)
    final avgTime = duration / totalQuestions;
    if (avgTime < 30) {
      bonus += 20;
    } else if (avgTime < 45) {
      bonus += 10;
    }

    return bonus;
  }

  // ==========================================================================
  // COPY WITH
  // ==========================================================================

  ExamResultModel copyWith({
    String? examId,String? packageId, // 🆕 TAMBAH INI
    DateTime? startedAt,
    DateTime? completedAt,
    int? duration,
    String? category,
    int? energyUsed,
    int? energyBefore,
    int? energyAfter,
    int? totalQuestions,
    int? correctCount,
    double? accuracy,
    Map<String, CategoryResult>? byType,
    Map<String, CategoryResult>? byCategory,
    int? xpEarned,
    int? bonusXP,
    int? streakDay,
    bool? adsShown,
    String? adType,
    List<AnswerModel>? answers,
  }) {
    return ExamResultModel(
      examId: examId ?? this.examId, packageId: packageId ?? this.packageId, // 🆕 TAMBAH INI
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      energyUsed: energyUsed ?? this.energyUsed,
      energyBefore: energyBefore ?? this.energyBefore,
      energyAfter: energyAfter ?? this.energyAfter,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctCount: correctCount ?? this.correctCount,
      accuracy: accuracy ?? this.accuracy,
      byType: byType ?? this.byType,
      byCategory: byCategory ?? this.byCategory,
      xpEarned: xpEarned ?? this.xpEarned,
      bonusXP: bonusXP ?? this.bonusXP,
      streakDay: streakDay ?? this.streakDay,
      adsShown: adsShown ?? this.adsShown,
      adType: adType ?? this.adType,
      answers: answers ?? this.answers,
    );
  }

  // ==========================================================================
  // EQUALITY & HASH
  // ==========================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExamResultModel && other.examId == examId;
  }

  @override
  int get hashCode => examId.hashCode;

  // ==========================================================================
  // TO STRING
  // ==========================================================================

  @override
  String toString() {
    return 'ExamResultModel(id: $examId, score: $correctCount/$totalQuestions, accuracy: ${(accuracy * 100).toStringAsFixed(1)}%, xp: $totalXP)';
  }
}

// ==============================================================================
// CATEGORY RESULT (Helper class)
// ==============================================================================

/// Result breakdown per category/type
class CategoryResult {
  final int total;
  final int correct;
  final double accuracy;

  const CategoryResult({
    required this.total,
    required this.correct,
    required this.accuracy,
  });

  Map<String, dynamic> toMap() {
    return {
      'total': total,
      'correct': correct,
      'accuracy': accuracy,
    };
  }

  @override
  String toString() {
    return 'CategoryResult($correct/$total = ${(accuracy * 100).toStringAsFixed(1)}%)';
  }
}