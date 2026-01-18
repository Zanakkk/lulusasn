// lib/features/exam/models/question_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipe soal yang didukung
enum QuestionType {
  yesNo('yesno'),
  likert('likert'),
  objective('objective');

  final String value;
  const QuestionType(this.value);

  static QuestionType fromString(String value) {
    return QuestionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => QuestionType.objective,
    );
  }
}

/// Model untuk Question
///
/// Mendukung 3 tipe soal:
/// - Yes/No (benar/salah)
/// - Likert Scale (1-5 untuk TKP)
/// - Objective (pilihan ganda A-E)
class QuestionModel {
  final String questionId;
  final String question;
  final QuestionType type;
  final List<String> options; // Untuk objective type
  final int
  correctAnswer; // index untuk objective, 0/1 untuk yesno, 1-5 untuk likert
  final List<int>? optionScores; // 🆕 TAMBAH INI: [1,2,3,4,5] untuk likert
  final String explanationShort; // Free user (1-2 kalimat)
  final String explanationFull; // Premium user (lengkap + video)
  final String category; // TWK, TIU, TKP
  final String subcategory; // TWK_Pancasila, TIU_Logika, etc
  final List<String> tags;
  final int difficulty; // 0-100
  final bool isActive;
  final DateTime createdAt;

  const QuestionModel({
    required this.questionId,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,

    this.optionScores, // 🆕 TAMBAH INI (nullable)
    required this.explanationShort,
    required this.explanationFull,
    required this.category,
    required this.subcategory,
    required this.tags,
    required this.difficulty,
    required this.isActive,
    required this.createdAt,
  });

  // ==========================================================================
  // FACTORY CONSTRUCTORS
  // ==========================================================================

  /// Create dari Firestore document
  factory QuestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return QuestionModel(
      questionId: doc.id,
      question: data['question'] as String? ?? '',
      type: QuestionType.fromString(data['type'] as String? ?? 'objective'),
      options: (data['options'] as List<dynamic>?)?.cast<String>() ?? [],
      correctAnswer: data['correctAnswer'] as int? ?? 0,
      optionScores: (data['optionScores'] as List<dynamic>?)?.cast<int>(), // 🆕 TAMBAH INI

      explanationShort: data['explanationShort'] as String? ?? '',
      explanationFull: data['explanationFull'] as String? ?? '',
      category: data['category'] as String? ?? '',
      subcategory: data['subcategory'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      difficulty: data['difficulty'] as int? ?? 50,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create dari Map (untuk testing)
  factory QuestionModel.fromMap(Map<String, dynamic> data) {
    return QuestionModel(
      questionId: data['questionId'] as String? ?? '',
      question: data['question'] as String? ?? '',
      type: QuestionType.fromString(data['type'] as String? ?? 'objective'),
      options: (data['options'] as List<dynamic>?)?.cast<String>() ?? [],
      correctAnswer: data['correctAnswer'] as int? ?? 0,
      explanationShort: data['explanationShort'] as String? ?? '',
      explanationFull: data['explanationFull'] as String? ?? '',
      category: data['category'] as String? ?? '',
      subcategory: data['subcategory'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      difficulty: data['difficulty'] as int? ?? 50,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt'] as DateTime
          : DateTime.now(),
    );
  }

  // ==========================================================================
  // TO FIRESTORE
  // ==========================================================================

  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'type': type.value,
      'options': options,
      'correctAnswer': correctAnswer,

      'optionScores': optionScores, // 🆕 TAMBAH INI
      'explanationShort': explanationShort,
      'explanationFull': explanationFull,
      'category': category,
      'subcategory': subcategory,
      'tags': tags,
      'difficulty': difficulty,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'question': question,
      'type': type.value,
      'options': options,
      'correctAnswer': correctAnswer,

      'optionScores': optionScores, // 🆕 TAMBAH INI
      'explanationShort': explanationShort,
      'explanationFull': explanationFull,
      'category': category,
      'subcategory': subcategory,
      'tags': tags,
      'difficulty': difficulty,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  // ==========================================================================
  // BUSINESS LOGIC
  // ==========================================================================

  /// Get display label untuk options (A, B, C, D, E)
  String getOptionLabel(int index) {
    if (type == QuestionType.objective) {
      return String.fromCharCode(65 + index); // A, B, C, D, E
    }
    return '';
  }

  /// Get likert scale label
  String getLikertLabel(int value) {
    switch (value) {
      case 1:
        return 'Sangat Tidak Setuju';
      case 2:
        return 'Tidak Setuju';
      case 3:
        return 'Netral';
      case 4:
        return 'Setuju';
      case 5:
        return 'Sangat Setuju';
      default:
        return '';
    }
  }

  /// Check if answer is correct
  bool isCorrectAnswer(int userAnswer) {
    return userAnswer == correctAnswer;
  }

  /// Get difficulty label
  String getDifficultyLabel() {
    if (difficulty < 30) return 'Mudah';
    if (difficulty < 70) return 'Sedang';
    return 'Sulit';
  }

  /// Validate question data
  bool isValid() {
    if (question.isEmpty) return false;
    if (category.isEmpty) return false;

    switch (type) {
      case QuestionType.yesNo:
        return correctAnswer == 0 || correctAnswer == 1;
      case QuestionType.likert:
        return correctAnswer >= 1 && correctAnswer <= 5;
      case QuestionType.objective:
        return options.length >= 2 &&
            correctAnswer >= 0 &&
            correctAnswer < options.length;
    }
  }

  // ==========================================================================
  // COPY WITH
  // ==========================================================================

  QuestionModel copyWith({
    String? questionId,
    String? question,
    QuestionType? type,
    List<String>? options,
    int? correctAnswer,

    List<int>? optionScores, // 🆕 TAMBAH INI
    String? explanationShort,
    String? explanationFull,
    String? category,
    String? subcategory,
    List<String>? tags,
    int? difficulty,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return QuestionModel(
      questionId: questionId ?? this.questionId,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,

      optionScores: optionScores ?? this.optionScores, // 🆕 TAMBAH INI
      explanationShort: explanationShort ?? this.explanationShort,
      explanationFull: explanationFull ?? this.explanationFull,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ==========================================================================
  // EQUALITY & HASH
  // ==========================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is QuestionModel && other.questionId == questionId;
  }

  @override
  int get hashCode => questionId.hashCode;

  // ==========================================================================
  // TO STRING
  // ==========================================================================

  @override
  String toString() {
    return 'QuestionModel(id: $questionId, type: ${type.value}, category: $category, difficulty: $difficulty)';
  }

  // Tambahkan di bagian BUSINESS LOGIC (sekitar baris 150)

  /// Get skor untuk jawaban likert (skor 1-5 berdasarkan index 0-4)
  /// Get skor untuk jawaban likert (skor 1-5 berdasarkan index 0-4)
  /// Get skor untuk jawaban likert
  int getLikertScore(int answerIndex) {
    if (type != QuestionType.likert) return 0;

    // Validasi index
    if (answerIndex < 0 || answerIndex >= options.length) return 0;

    // 🆕 Jika ada optionScores, gunakan itu
    if (optionScores != null && answerIndex < optionScores!.length) {
      return optionScores![answerIndex];
    }

    // Fallback: Index 0-4 = skor 1-5
    return answerIndex + 1;
  }

  /// Get skor untuk semua opsi (untuk display di review)
  List<int> getAllOptionScores() {
    if (type != QuestionType.likert) return [];

    if (optionScores != null) {
      return optionScores!;
    }

    // Fallback: generate 1-5
    return List.generate(options.length, (i) => i + 1);
  }

  /// Check apakah ini jawaban optimal (skor tertinggi)
  bool isOptimalAnswer(int answerIndex) {
    if (type != QuestionType.likert) {
      return answerIndex == correctAnswer;
    }

    final scores = getAllOptionScores();
    if (scores.isEmpty || answerIndex >= scores.length) return false;

    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    return scores[answerIndex] == maxScore;
  }
  /// Get jawaban optimal untuk likert (skor tertinggi)
  int getOptimalLikertAnswer() {
    if (type != QuestionType.likert) return 0;
    return options.length - 1; // Index terakhir = skor tertinggi
  }

  /// Get skor maksimal untuk tipe soal ini
  int getMaxScore() {
    switch (type) {
      case QuestionType.likert:
        return 5; // Skor maksimal likert
      case QuestionType.objective:
      case QuestionType.yesNo:
        return 5; // Skor tetap untuk benar
    }
  }

  /// Check apakah ini jawaban optimal untuk likert
  bool isOptimalLikertAnswer(int userAnswer) {
    if (type != QuestionType.likert) return false;

    // Jawaban optimal adalah yang skornya tertinggi
    return userAnswer == correctAnswer;
  }
}
