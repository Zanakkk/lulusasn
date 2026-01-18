// lib/features/exam/models/exam_package_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lulusasn/features/exam/models/question_model.dart';

/// Exam Package Model
///
/// Model untuk paket latihan soal yang ditampilkan di ExamListScreen
/// Architecture:
/// - 1 document di collection 'exam_packages'
/// - Questions embedded (compact format) untuk fast read
/// - Metadata lengkap (difficulty, time estimate, energy cost)
class ExamPackageModel {
  final String packageId;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int questionCount;
  final int estimatedMinutes;
  final int energyCost;
  final bool isPremium;
  final bool isActive;
  final int order;
  final List<CompactQuestion> questions;
  final DateTime createdAt;

  const ExamPackageModel({
    required this.packageId,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.questionCount,
    required this.estimatedMinutes,
    required this.energyCost,
    required this.isPremium,
    required this.isActive,
    required this.order,
    required this.questions,
    required this.createdAt,
  });

  // ==========================================================================
  // FACTORY CONSTRUCTORS
  // ==========================================================================

  /// Create dari Firestore document
  factory ExamPackageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final questionsData = data['questions'] as List<dynamic>? ?? [];

    return ExamPackageModel(
      packageId: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      difficulty: data['difficulty'] as String? ?? 'medium',
      questionCount: data['questionCount'] as int? ?? 10,
      estimatedMinutes: data['estimatedMinutes'] as int? ?? 15,
      energyCost: data['energyCost'] as int? ?? 1,
      isPremium: data['isPremium'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      order: data['order'] as int? ?? 0,
      questions: questionsData
          .map((q) => CompactQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ==========================================================================
  // TO FIRESTORE
  // ==========================================================================

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'questionCount': questionCount,
      'estimatedMinutes': estimatedMinutes,
      'energyCost': energyCost,
      'isPremium': isPremium,
      'isActive': isActive,
      'order': order,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ==========================================================================
  // BUSINESS LOGIC
  // ==========================================================================

  /// Get difficulty label (Indonesian)
  String getDifficultyLabel() {
    switch (difficulty) {
      case 'easy':
        return 'Mudah';
      case 'medium':
        return 'Sedang';
      case 'hard':
        return 'Sulit';
      default:
        return 'Sedang';
    }
  }

  /// Get full QuestionModel list
  List<QuestionModel> getQuestionModels() {
    return questions
        .asMap()
        .entries
        .map((entry) => entry.value.toQuestionModel('${packageId}_q${entry.key}'))
        .toList();
  }

  // ==========================================================================
  // COPY WITH
  // ==========================================================================

  ExamPackageModel copyWith({
    String? packageId,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    int? questionCount,
    int? estimatedMinutes,
    int? energyCost,
    bool? isPremium,
    bool? isActive,
    int? order,
    List<CompactQuestion>? questions,
    DateTime? createdAt,
  }) {
    return ExamPackageModel(
      packageId: packageId ?? this.packageId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      questionCount: questionCount ?? this.questionCount,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      energyCost: energyCost ?? this.energyCost,
      isPremium: isPremium ?? this.isPremium,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ExamPackageModel(id: $packageId, title: $title, questions: ${questions.length})';
  }
}

// ==============================================================================
// COMPACT QUESTION (Embedded Format)
// ==============================================================================

/// Compact Question Format (untuk embedded di exam packages)
///
/// Menggunakan short field names untuk save storage:
/// - q = question
/// - type = question type
/// - opts = options
/// - ans = answer
/// - exp = explanation
/// - cat = category
/// - sub = subcategory
/// - diff = difficulty
class CompactQuestion {
  final String q;
  final String type;
  final List<String> opts;
  final int ans;
  final String exp;
  final String cat;
  final String sub;
  final int diff;

  const CompactQuestion({
    required this.q,
    required this.type,
    required this.opts,
    required this.ans,
    required this.exp,
    required this.cat,
    required this.sub,
    required this.diff,
  });

  // ==========================================================================
  // FACTORY CONSTRUCTORS
  // ==========================================================================

  factory CompactQuestion.fromMap(Map<String, dynamic> map) {
    return CompactQuestion(
      q: map['q'] as String? ?? '',
      type: map['type'] as String? ?? 'objective',
      opts: (map['opts'] as List<dynamic>?)?.cast<String>() ?? [],
      ans: map['ans'] as int? ?? 0,
      exp: map['exp'] as String? ?? '',
      cat: map['cat'] as String? ?? '',
      sub: map['sub'] as String? ?? '',
      diff: map['diff'] as int? ?? 50,
    );
  }

  // ==========================================================================
  // TO MAP
  // ==========================================================================

  Map<String, dynamic> toMap() {
    return {
      'q': q,
      'type': type,
      'opts': opts,
      'ans': ans,
      'exp': exp,
      'cat': cat,
      'sub': sub,
      'diff': diff,
    };
  }

  // ==========================================================================
  // CONVERSION
  // ==========================================================================

  /// Convert to QuestionModel untuk compatibility dengan existing services
  QuestionModel toQuestionModel(String questionId) {
    return QuestionModel(
      questionId: questionId,
      question: q,
      type: QuestionType.fromString(type),
      options: opts,
      correctAnswer: ans,
      explanationShort: exp,
      explanationFull: exp,
      category: cat,
      subcategory: sub,
      tags: [],
      difficulty: diff,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  // ==========================================================================
  // COPY WITH
  // ==========================================================================

  CompactQuestion copyWith({
    String? q,
    String? type,
    List<String>? opts,
    int? ans,
    String? exp,
    String? cat,
    String? sub,
    int? diff,
  }) {
    return CompactQuestion(
      q: q ?? this.q,
      type: type ?? this.type,
      opts: opts ?? this.opts,
      ans: ans ?? this.ans,
      exp: exp ?? this.exp,
      cat: cat ?? this.cat,
      sub: sub ?? this.sub,
      diff: diff ?? this.diff,
    );
  }

  @override
  String toString() {
    return 'CompactQuestion(q: ${q.substring(0, 30)}..., type: $type)';
  }
}