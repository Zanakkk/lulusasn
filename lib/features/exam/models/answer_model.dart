// lib/features/exam/models/answer_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lulusasn/features/exam/models/question_model.dart';

/// Model untuk User Answer
///
/// Menyimpan jawaban user untuk satu soal
/// Digunakan untuk:
/// - Tracking jawaban selama exam session
/// - Save ke Firestore setelah exam selesai
/// - Analisis performa user
class AnswerModel {
  final String answerId;
  final String questionId;
  final int questionOrder; // Urutan soal dalam exam (1-based)

  // Question metadata (denormalized untuk fast read)
  final QuestionType questionType;
  final String category;
  final String subcategory;
  final int difficulty;

  // User answer
  final int? userAnswer; // null = belum dijawab
  final int correctAnswer;
  final bool isCorrect;

  // Timing
  final DateTime timeStarted;
  final DateTime? timeAnswered; // null = belum dijawab
  final int timeTaken; // seconds
  final DateTime answeredAt;

  // 🆕 Scoring
  final int score; // Skor yang didapat (1-5 untuk likert, 0/5 untuk objective)

  const AnswerModel({
    required this.answerId,
    required this.questionId,
    required this.questionOrder,
    required this.questionType,
    required this.category,
    required this.subcategory,
    required this.difficulty,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.timeStarted,
    required this.timeAnswered,
    required this.timeTaken,
    required this.answeredAt,
    this.score = 0, // 🆕 Default 0
  });

  // ==========================================================================
  // FACTORY CONSTRUCTORS
  // ==========================================================================

  /// Create dari Firestore document
  factory AnswerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AnswerModel(
      answerId: doc.id,
      questionId: data['questionId'] as String? ?? '',
      questionOrder: data['questionOrder'] as int? ?? 0,
      questionType: QuestionType.fromString(
        data['questionType'] as String? ?? 'objective',
      ),
      category: data['category'] as String? ?? '',
      subcategory: data['subcategory'] as String? ?? '',
      difficulty: data['difficulty'] as int? ?? 50,
      userAnswer: data['userAnswer'] as int?,
      correctAnswer: data['correctAnswer'] as int? ?? 0,
      isCorrect: data['isCorrect'] as bool? ?? false,
      timeStarted:
          (data['timeStarted'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeAnswered: (data['timeAnswered'] as Timestamp?)?.toDate(),
      timeTaken: data['timeTaken'] as int? ?? 0,
      answeredAt:
          (data['answeredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      score: data['score'] as int? ?? 0, // 🆕
    );
  }

  /// 🆕 Create from Map (untuk embedded data)
  factory AnswerModel.fromMap(Map<String, dynamic> map) {
    return AnswerModel(
      answerId: map['answerId'] as String? ?? '',
      questionId: map['questionId'] as String? ?? '',
      questionOrder: map['questionOrder'] as int? ?? 0,
      questionType: QuestionType.fromString(
        map['questionType'] as String? ?? 'objective',
      ),
      category: map['category'] as String? ?? '',
      subcategory: map['subcategory'] as String? ?? '',
      difficulty: map['difficulty'] as int? ?? 50,
      userAnswer: map['userAnswer'] as int?,
      correctAnswer: map['correctAnswer'] as int? ?? 0,
      isCorrect: map['isCorrect'] as bool? ?? false,
      timeStarted: map['timeStarted'] is DateTime
          ? map['timeStarted'] as DateTime
          : DateTime.now(),
      timeAnswered: map['timeAnswered'] is DateTime
          ? map['timeAnswered'] as DateTime
          : null,
      timeTaken: map['timeTaken'] as int? ?? 0,
      answeredAt: map['answeredAt'] is DateTime
          ? map['answeredAt'] as DateTime
          : DateTime.now(),
      score: map['score'] as int? ?? 0, // 🆕
    );
  }

  /// Create dari QuestionModel (saat mulai soal)
  factory AnswerModel.fromQuestion({
    required QuestionModel question,
    required int questionOrder,
  }) {
    final now = DateTime.now();
    final answerId = 'ans_${now.millisecondsSinceEpoch}';

    return AnswerModel(
      answerId: answerId,
      questionId: question.questionId,
      questionOrder: questionOrder,
      questionType: question.type,
      category: question.category,
      subcategory: question.subcategory,
      difficulty: question.difficulty,
      userAnswer: null, // Belum dijawab
      correctAnswer: question.correctAnswer,
      isCorrect: false,
      timeStarted: now,
      timeAnswered: null,
      timeTaken: 0,
      answeredAt: now,
      score: 0, // 🆕
    );
  }

  // ==========================================================================
  // TO FIRESTORE
  // ==========================================================================

  Map<String, dynamic> toFirestore() {
    return {
      'questionId': questionId,
      'questionOrder': questionOrder,
      'questionType': questionType.value,
      'category': category,
      'subcategory': subcategory,
      'difficulty': difficulty,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'isCorrect': isCorrect,
      'timeStarted': Timestamp.fromDate(timeStarted),
      'timeAnswered': timeAnswered != null
          ? Timestamp.fromDate(timeAnswered!)
          : null,
      'timeTaken': timeTaken,
      'answeredAt': Timestamp.fromDate(answeredAt),
      'score': score, // 🆕
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'answerId': answerId,
      'questionId': questionId,
      'questionOrder': questionOrder,
      'questionType': questionType.value,
      'category': category,
      'subcategory': subcategory,
      'difficulty': difficulty,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'isCorrect': isCorrect,
      'timeStarted': timeStarted,
      'timeAnswered': timeAnswered,
      'timeTaken': timeTaken,
      'answeredAt': answeredAt,
      'score': score, // 🆕
    };
  }

  // ==========================================================================
  // BUSINESS LOGIC
  // ==========================================================================

  /// Check if soal sudah dijawab
  bool get isAnswered => userAnswer != null;

  /// Calculate time taken (auto-update saat belum dijawab)
  int getCurrentTimeTaken() {
    if (timeAnswered != null) {
      return timeTaken;
    }

    final now = DateTime.now();
    return now.difference(timeStarted).inSeconds;
  }

  /// Submit answer
  /// Submit answer
  AnswerModel submitAnswer(int answer) {
    final now = DateTime.now();
    final taken = now.difference(timeStarted).inSeconds;

    // 🆕 Untuk likert, tidak ada konsep "correct" karena semua jawaban valid
    final bool isAnswerCorrect;
    if (questionType == QuestionType.likert) {
      isAnswerCorrect = true; // Likert selalu "correct" selama dijawab
    } else {
      isAnswerCorrect = answer == correctAnswer;
    }

    return copyWith(
      userAnswer: answer,
      isCorrect: isAnswerCorrect,
      timeAnswered: now,
      timeTaken: taken,
      answeredAt: now,
    );
  }

  /// Get difficulty label
  String getDifficultyLabel() {
    if (difficulty < 30) return 'Mudah';
    if (difficulty < 70) return 'Sedang';
    return 'Sulit';
  }

  /// Get category color (untuk UI)
  String getCategoryColor() {
    switch (category.toUpperCase()) {
      case 'TWK':
        return '#1CB0F6'; // Blue
      case 'TIU':
        return '#FF9600'; // Orange
      case 'TKP':
        return '#58CC02'; // Green
      default:
        return '#888888'; // Gray
    }
  }

  // ==========================================================================
  // COPY WITH
  // ==========================================================================

  AnswerModel copyWith({
    String? answerId,
    String? questionId,
    int? questionOrder,
    QuestionType? questionType,
    String? category,
    String? subcategory,
    int? difficulty,
    int? userAnswer,
    int? correctAnswer,
    bool? isCorrect,
    DateTime? timeStarted,
    DateTime? timeAnswered,
    int? timeTaken,
    DateTime? answeredAt,
    int? score, // 🆕
  }) {
    return AnswerModel(
      answerId: answerId ?? this.answerId,
      questionId: questionId ?? this.questionId,
      questionOrder: questionOrder ?? this.questionOrder,
      questionType: questionType ?? this.questionType,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      difficulty: difficulty ?? this.difficulty,
      userAnswer: userAnswer ?? this.userAnswer,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      timeStarted: timeStarted ?? this.timeStarted,
      timeAnswered: timeAnswered ?? this.timeAnswered,
      timeTaken: timeTaken ?? this.timeTaken,
      answeredAt: answeredAt ?? this.answeredAt,
      score: score ?? this.score, // 🆕
    );
  }

  // ==========================================================================
  // EQUALITY & HASH
  // ==========================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AnswerModel && other.answerId == answerId;
  }

  @override
  int get hashCode => answerId.hashCode;

  // ==========================================================================
  // TO STRING
  // ==========================================================================

  @override
  String toString() {
    return 'AnswerModel(id: $answerId, question: $questionOrder, answered: $isAnswered, correct: $isCorrect, score: $score, time: ${timeTaken}s)';
  }
}
