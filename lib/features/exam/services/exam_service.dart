// lib/features/exam/services/exam_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lulusasn/core/services/firebase_service.dart';
import 'package:lulusasn/features/exam/models/answer_model.dart';
import 'package:lulusasn/features/exam/models/exam_result_model.dart';
import 'package:lulusasn/features/exam/models/question_model.dart';
import 'package:lulusasn/features/exam/services/question_service.dart';
import 'package:lulusasn/features/home/services/energy_service.dart';

/// Service untuk Exam Session Management
///
/// OPTIMIZATION STRATEGY:
/// 1. In-memory session state (zero Firestore reads during exam)
/// 2. Single batch write saat submit (bukan N writes!)
/// 3. Optimistic UI updates
/// 4. Aggregate calculations client-side
/// 5. Transaction untuk atomic updates
///
/// FIRESTORE WRITES: 1 batch write = 3-4 operations (bukan 10+ operations!)
class ExamService {
  static final ExamService _instance = ExamService._internal();
  factory ExamService() => _instance;
  ExamService._internal();

  final _firestore = FirebaseService.instance.firestore;
  final _auth = FirebaseService.instance.auth;
  final _questionService = QuestionService();
  final _energyService = EnergyService();

  // In-memory session state (NO Firestore persistence during exam)
  ExamSession? _currentSession;

  // ==========================================================================
  // START EXAM SESSION
  // ==========================================================================

  /// Start new exam session
  ///
  /// OPTIMIZATION:
  /// - Energy check first (fail fast)
  /// - Questions fetched adaptively (1 query)
  /// - Session kept in-memory only
  /// - Zero Firestore writes until submit
  ///
  /// FIRESTORE READS: ~15 docs (question selection)
  /// FIRESTORE WRITES: 0 (sampai submit!)
  Future<ExamSession> startExam({
    required String category,
    int questionCount = 10,
    bool useAdaptive = true,
    String? packageId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User tidak login');
    }

    print('🚀 Starting exam - Category: $category, PackageId: $packageId');

    // 1. Check if can start (energy check)
    final canStart = await _energyService.canStartExam();
    if (!canStart) {
      throw InsufficientEnergyException('Energy habis!');
    }

    // 2. Consume energy
    final updatedEnergy = await _energyService.consumeEnergy();

    // 3. Fetch questions
    List<QuestionModel> questions;

    if (packageId != null && packageId.isNotEmpty) {
      print('📦 Fetching from package: $packageId');
      questions = await _questionService.getQuestionsFromPackage(packageId);
    } else {
      print('🎲 Fetching adaptive questions');
      questions = await _questionService.selectQuestionsAdaptive(
        category: category,
        count: questionCount,
        useAdaptive: useAdaptive,
      );
    }

    print('✅ Got ${questions.length} questions');

    if (questions.isEmpty) {
      throw Exception('Tidak ada soal tersedia untuk kategori $category');
    }

    // 4. Create in-memory session (ZERO Firestore writes!)
    final now = DateTime.now();
    final examId = 'exam_${now.millisecondsSinceEpoch}';

    final session = ExamSession(
      examId: examId,
      userId: userId,
      category: category,
      packageId: packageId, // 🆕 SIMPAN packageId
      questions: questions,
      answers: questions
          .asMap()
          .entries
          .map(
            (e) => AnswerModel.fromQuestion(
              question: e.value,
              questionOrder: e.key + 1,
            ),
          )
          .toList(),
      startedAt: now,
      energyBefore: updatedEnergy.current + 1, // Before consumption
      energyAfter: updatedEnergy.current,
      currentQuestionIndex: 0,
      isPremium: false, // TODO: Get from user doc
    );

    _currentSession = session;

    return session;
  }

  // ==========================================================================
  // SESSION MANAGEMENT (IN-MEMORY ONLY)
  // ==========================================================================

  /// Get current active session
  ExamSession? getCurrentSession() {
    return _currentSession;
  }

  /// Submit answer untuk current question
  ///
  /// OPTIMIZATION: Pure in-memory operation, ZERO Firestore!
  ExamSession submitAnswer(int answer) {
    if (_currentSession == null) {
      throw Exception('Tidak ada session aktif');
    }

    final session = _currentSession!;
    final currentIndex = session.currentQuestionIndex;

    // Validate index
    if (currentIndex >= session.answers.length) {
      throw Exception('Invalid question index');
    }

    // Update answer in-memory
    final updatedAnswers = List<AnswerModel>.from(session.answers);
    updatedAnswers[currentIndex] = updatedAnswers[currentIndex].submitAnswer(
      answer,
    );

    // Move to next question
    final nextIndex = currentIndex + 1;

    _currentSession = session.copyWith(
      answers: updatedAnswers,
      currentQuestionIndex: nextIndex,
    );

    return _currentSession!;
  }

  /// Skip current question (mark as unanswered)
  ExamSession skipQuestion() {
    if (_currentSession == null) {
      throw Exception('Tidak ada session aktif');
    }

    final session = _currentSession!;
    final nextIndex = session.currentQuestionIndex + 1;

    _currentSession = session.copyWith(currentQuestionIndex: nextIndex);

    return _currentSession!;
  }

  // Tambahkan di section SESSION MANAGEMENT (IN-MEMORY ONLY)
  // Setelah method submitAnswer()

  /// Submit answer untuk question di index tertentu
  ///
  /// OPTIMIZATION: Pure in-memory operation, ZERO Firestore!
  /// Digunakan untuk navigasi bebas antar soal
  ExamSession submitAnswerAtIndex(int questionIndex, int answer) {
    if (_currentSession == null) {
      throw Exception('Tidak ada session aktif');
    }

    final session = _currentSession!;

    // Validate index
    if (questionIndex < 0 || questionIndex >= session.answers.length) {
      throw Exception('Invalid question index: $questionIndex');
    }

    // Update answer in-memory
    final updatedAnswers = List<AnswerModel>.from(session.answers);
    updatedAnswers[questionIndex] = updatedAnswers[questionIndex].submitAnswer(
      answer,
    );

    _currentSession = session.copyWith(answers: updatedAnswers);

    return _currentSession!;
  }

  /// Check if exam is completed
  bool isExamCompleted() {
    if (_currentSession == null) return false;

    final session = _currentSession!;
    return session.currentQuestionIndex >= session.questions.length;
  }

  /// Get current question
  QuestionModel? getCurrentQuestion() {
    if (_currentSession == null) return null;

    final session = _currentSession!;
    if (session.currentQuestionIndex >= session.questions.length) {
      return null;
    }

    return session.questions[session.currentQuestionIndex];
  }

  /// Get progress (answered / total)
  ExamProgress getProgress() {
    if (_currentSession == null) {
      return ExamProgress(current: 0, total: 0, percentage: 0.0);
    }

    final session = _currentSession!;
    final answeredCount = session.answers.where((a) => a.isAnswered).length;

    return ExamProgress(
      current: answeredCount,
      total: session.questions.length,
      percentage: answeredCount / session.questions.length,
    );
  }

  // ==========================================================================
  // SUBMIT EXAM (BATCH WRITE)
  // ==========================================================================

  /// Submit exam and save to Firestore
  ///
  /// CRITICAL OPTIMIZATION: Single batch write with transaction!
  ///
  /// FIRESTORE WRITES:
  /// - 1 exam doc write
  /// - N answer docs write (batched in 1 transaction)
  /// - 1 user stats update
  /// Total: 3-4 write operations (bukan 10-15!)
  // lib/features/exam/services/exam_service.dart

  /// 🆕 OPTIMIZED: Single batch write (3 writes total, bukan 11+!)
  // lib/features/exam/services/exam_service.dart

  Future<ExamResultModel> submitExam() async {
    if (_currentSession == null) throw Exception('Tidak ada session aktif');

    final session = _currentSession!;
    final userId = session.userId;

    // Calculate result
    final result = ExamResultModel.fromAnswers(
      examId: session.examId,
      startedAt: session.startedAt,
      answers: session.answers,
      energyBefore: session.energyBefore,
      energyAfter: session.energyAfter,
      streakDay: 0,
      category: session.category,
      packageId: session.packageId, // 🆕 TAMBAH INI
    );

    final userRef = _firestore.collection('users').doc(userId);
    final examRef = userRef.collection('exams').doc(session.examId);
    final activityRef = _firestore.collection('user_activity').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final userData = userDoc.data()!;

      // Calculate streak
      final lastActiveDate = userData['lastActiveDate'] as String?;
      final currentStreak = userData['streak'] as int? ?? 0;
      final today = DateTime.now().toIso8601String().split('T')[0];

      int newStreak = 1;
      if (lastActiveDate != null) {
        final yesterday = DateTime.now().subtract(Duration(days: 1));
        final yesterdayStr = yesterday.toIso8601String().split('T')[0];

        if (lastActiveDate == yesterdayStr) {
          newStreak = currentStreak + 1;
        } else if (lastActiveDate == today) {
          newStreak = currentStreak;
        }
      }

      final updatedResult = result.copyWith(streakDay: newStreak);

      // 🆕 WRITE 1: Exam doc dengan packageId
      transaction.set(examRef, {
        ...updatedResult.toFirestore(),
        'packageId': session.packageId, // 🆕 SIMPAN packageId
        'answers': session.answers.map((a) => a.toMap()).toList(),
        'questionIds': session.answers.map((a) => a.questionId).toList(),
      });

      // WRITE 2: Update user stats
      transaction.update(userRef, {
        'stats.totalExams': FieldValue.increment(1),
        'stats.totalQuestions': FieldValue.increment(result.totalQuestions),
        'stats.totalCorrect': FieldValue.increment(result.correctCount),
        'xp': FieldValue.increment(updatedResult.totalXP),
        'streak': newStreak,
        'longestStreak': newStreak > (userData['longestStreak'] as int? ?? 0)
            ? newStreak
            : userData['longestStreak'],
        'lastActiveDate': today,
      });

      // WRITE 3: Update recent questions
      transaction.set(activityRef, {
        'recentQuestions': FieldValue.arrayUnion(
          session.answers.map((a) => a.questionId).toList(),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return updatedResult;
    });

    _currentSession = null;
    return result;
  }

  // ==========================================================================
  // CANCEL EXAM
  // ==========================================================================

  /// Cancel current exam session (discard progress)
  ///
  /// OPTIMIZATION: Pure in-memory operation, ZERO Firestore
  /// Note: Energy sudah consumed, tidak bisa di-refund
  void cancelExam() {
    _currentSession = null;
  }

  // ==========================================================================
  // FETCH PAST RESULTS
  // ==========================================================================

  /// Get user's past exam results (paginated)
  ///
  /// OPTIMIZATION:
  /// - Fetch exam docs only (bukan dengan answers subcollection!)
  /// - Paginated dengan limit
  /// - Sort by completedAt DESC
  ///
  /// FIRESTORE READS: {limit} exam docs (default 20)
  Future<List<ExamResultModel>> getPastResults({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User tidak login');
    }

    Query query = _firestore
        .collection('users')
        .doc(userId)
        .collection('exams')
        .orderBy('completedAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => ExamResultModel.fromFirestore(doc))
        .toList();
  }

  /// Get single exam result by ID
  Future<ExamResultModel?> getExamResult(String examId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('exams')
        .doc(examId)
        .get();

    if (!doc.exists) return null;

    return ExamResultModel.fromFirestore(doc);
  }

  /// Get answers for specific exam
  ///
  /// OPTIMIZATION: Fetch only when needed (user clicks "Review")
  Future<List<AnswerModel>> getExamAnswers(String examId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('exams')
        .doc(examId)
        .collection('answers')
        .orderBy('questionOrder')
        .get();

    return snapshot.docs.map((doc) => AnswerModel.fromFirestore(doc)).toList();
  }
}

// ==============================================================================
// EXAM SESSION (IN-MEMORY STATE)
// ==============================================================================

/// In-memory exam session state
///
/// CRITICAL: Tidak disimpan ke Firestore sampai submit!
/// Semua state management dilakukan di client-side
class ExamSession {
  final String examId;
  final String userId;
  final String category;
  final String? packageId; // 🆕 TAMBAH INI
  final List<QuestionModel> questions;
  final List<AnswerModel> answers;
  final DateTime startedAt;
  final int energyBefore;
  final int energyAfter;
  final int currentQuestionIndex;
  final bool isPremium;

  const ExamSession({
    required this.examId,
    required this.userId,
    required this.category,
    required this.packageId, // 🆕 TAMBAH INI
    required this.questions,
    required this.answers,
    required this.startedAt,
    required this.energyBefore,
    required this.energyAfter,
    required this.currentQuestionIndex,
    required this.isPremium,
  });

  /// Current question
  QuestionModel get currentQuestion => questions[currentQuestionIndex];

  /// Current answer
  AnswerModel get currentAnswer => answers[currentQuestionIndex];

  /// Is completed
  bool get isCompleted => currentQuestionIndex >= questions.length;

  /// Progress percentage
  double get progressPercentage {
    return currentQuestionIndex / questions.length;
  }

  /// Total answered
  int get answeredCount {
    return answers.where((a) => a.isAnswered).length;
  }

  /// Duration so far (seconds)
  int get currentDuration {
    return DateTime.now().difference(startedAt).inSeconds;
  }

  ExamSession copyWith({
    String? examId,
    String? userId,
    String? category,
    String? packageId, // 🆕 TAMBAH INI
    List<QuestionModel>? questions,
    List<AnswerModel>? answers,
    DateTime? startedAt,
    int? energyBefore,
    int? energyAfter,
    int? currentQuestionIndex,
    bool? isPremium,
  }) {
    return ExamSession(
      examId: examId ?? this.examId,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      packageId: packageId ?? this.packageId, // 🆕 TAMBAH INI
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      startedAt: startedAt ?? this.startedAt,
      energyBefore: energyBefore ?? this.energyBefore,
      energyAfter: energyAfter ?? this.energyAfter,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}

// ==============================================================================
// EXAM PROGRESS
// ==============================================================================

class ExamProgress {
  final int current;
  final int total;
  final double percentage;

  const ExamProgress({
    required this.current,
    required this.total,
    required this.percentage,
  });

  String get displayText => '$current/$total';
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
