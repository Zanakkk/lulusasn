// lib/features/exam/services/question_service.dart

// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lulusasn/core/services/firebase_service.dart';
import 'package:lulusasn/features/exam/models/question_model.dart';

/// Service untuk Question Management
///
/// OPTIMIZATION STRATEGY:
/// 1. Adaptive question selection (server-side filtering)
/// 2. Anti-repetition dengan client-side cache (7 hari)
/// 3. Batch reads (1 query untuk 10 soal)
/// 4. Composite index untuk fast filtering
/// 5. In-memory shuffle (zero Firestore reads)
///
/// FIRESTORE READS: 1 query = 10-15 documents (bukan 10 queries!)
class QuestionService {
  static final QuestionService _instance = QuestionService._internal();
  factory QuestionService() => _instance;
  QuestionService._internal();

  final _firestore = FirebaseService.instance.firestore;
  final _auth = FirebaseService.instance.auth;

  // Client-side cache untuk anti-repetition
  final Map<String, Set<String>> _recentQuestionIds = {};
  static const int _antiRepeatDays = 7;

  // ==========================================================================
  // ADAPTIVE QUESTION SELECTION (CORE ALGORITHM)
  // ==========================================================================

  /// Select questions adaptively based on user skills
  ///
  /// Algorithm:
  /// - 40% dari weak areas (accuracy < 60%)
  /// - 40% dari current level (±10 difficulty)
  /// - 20% challenging (+20 difficulty)
  ///
  /// FIRESTORE OPTIMIZATION:
  /// - 3 queries total (weak, current, hard)
  /// - Each query fetches 4-5 docs
  /// - Client-side shuffle & dedup
  /// - Total reads: ~15 docs (bukan 10 queries × N docs!)


  // ==========================================================================
  // FETCH STRATEGIES (SERVER-SIDE FILTERING)
  // ==========================================================================

// lib/features/exam/services/question_service.dart

  /// 🆕 OPTIMIZED: Single query dengan composite index
  Future<List<QuestionModel>> selectQuestionsAdaptive({
    required String category,
    int count = 10,
    bool useAdaptive = true,
  }) async
  {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User tidak login');

    try {
      // 1. Get recent IDs dari cache collection (1 read!)
      final recentIds = await _getRecentQuestionIdsOptimized(userId);

      // 2. Get user skills (1 read)
      final userSkills = await _getUserSkills(userId, category);

      // 3. Calculate difficulty range
      final avgSkill = userSkills.isEmpty
          ? 50.0
          : userSkills.values.reduce((a, b) => a + b) / userSkills.length;

      final targetDiff = (avgSkill * 100).round();
      final minDiff = (targetDiff - 20).clamp(0, 100);
      final maxDiff = (targetDiff + 20).clamp(0, 100);

      // 4. SINGLE QUERY dengan composite index (1 query = 15-20 docs)
      final snapshot = await _firestore
          .collection('questions')
          .where('cat', isEqualTo: category)
          .where('diff', isGreaterThanOrEqualTo: minDiff)
          .where('diff', isLessThanOrEqualTo: maxDiff)
          .where('active', isEqualTo: true)
          .limit(count * 3) // Fetch extra untuk filtering
          .get();

      // 5. Filter out recent questions (client-side)
      final questions = snapshot.docs
          .map((doc) => QuestionModel.fromFirestore(doc))
          .where((q) => !recentIds.contains(q.questionId))
          .toList();

      questions.shuffle();
      return questions.take(count).toList();

    } catch (e) {
      return _selectRandomQuestions(category, count);
    }
  }

  /// 🆕 OPTIMIZED: Get recent IDs dari dedicated collection (1 read!)
  Future<Set<String>> _getRecentQuestionIdsOptimized(String userId) async {
    // Check in-memory cache first
    if (_recentQuestionIds.containsKey(userId)) {
      return _recentQuestionIds[userId]!;
    }

    try {
      // Single doc read untuk recent questions
      final doc = await _firestore
          .collection('user_activity')
          .doc(userId)
          .get();

      if (!doc.exists) return {};

      final data = doc.data()!;
      final recentIds = (data['recentQuestions'] as List<dynamic>?)
          ?.cast<String>()
          .toSet() ?? {};

      // Cache for session
      _recentQuestionIds[userId] = recentIds;

      return recentIds;
    } catch (e) {
      return {};
    }
  }

  /// Get questions from exam package (embedded questions)
  // lib/features/exam/services/question_service.dart

  /// 🆕 Get questions from exam package (EMBEDDED - 1 READ ONLY!)
  Future<List<QuestionModel>> getQuestionsFromPackage(String packageId) async {
    print('📦 Fetching questions from package: $packageId');

    final doc = await _firestore.collection('exam_packages').doc(packageId).get();

    if (!doc.exists) {
      throw Exception('Paket tidak ditemukan');
    }

    final data = doc.data()!;
    final questionsData = data['questions'] as List<dynamic>? ?? [];

    if (questionsData.isEmpty) {
      throw Exception('Paket tidak memiliki soal');
    }

    print('✅ Found ${questionsData.length} questions in package');

    // Parse embedded questions
    return questionsData.asMap().entries.map((entry) {
      final index = entry.key;
      final q = entry.value as Map<String, dynamic>;

      return QuestionModel(
        questionId: 'q_${packageId}_$index', // Generate unique ID
        question: q['question'] as String? ?? '',
        type: QuestionType.fromString(q['type'] as String? ?? 'objective'),
        options: (q['options'] as List<dynamic>?)?.cast<String>() ?? [],
        correctAnswer: q['correctAnswer'] as int? ?? 0,
        optionScores: (q['optionScores'] as List<dynamic>?)?.cast<int>(), // 🆕 TAMBAH INI

        explanationShort: q['explanationShort'] as String? ?? '',
        explanationFull: q['explanationFull'] as String? ?? '',
        category: q['category'] as String? ?? '',
        subcategory: q['subcategory'] as String? ?? '',
        tags: (q['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        difficulty: q['difficulty'] as int? ?? 50,
        isActive: q['isActive'] as bool? ?? true,
        createdAt: DateTime.now(),
      );
    }).toList();
  }
  // ==========================================================================
  // RANDOM SELECTION (FALLBACK)
  // ==========================================================================

  /// Random selection (when adaptive fails atau first-time user)
  Future<List<QuestionModel>> _selectRandomQuestions(
    String category,
    int count,
  ) async {
    final userId = _auth.currentUser?.uid;
    final recentIds = userId != null
        ? await _getRecentQuestionIds(userId)
        : <String>{};

    // Fetch lebih banyak untuk filtering
    final query = _firestore
        .collection('questions')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .limit(count * 3);

    final snapshot = await query.get();
    final questions = snapshot.docs
        .map((doc) => QuestionModel.fromFirestore(doc))
        .where((q) => !recentIds.contains(q.questionId))
        .toList();

    questions.shuffle();
    return questions.take(count).toList();
  }

  // ==========================================================================
  // USER SKILLS & ANTI-REPETITION
  // ==========================================================================

  /// Get user skills per subcategory
  /// OPTIMIZATION: 1 document read (user doc, bukan N subcategory docs)
  Future<Map<String, double>> _getUserSkills(
    String userId,
    String category,
  ) async {
    // Check in-memory cache first (5 min TTL)
    final _ = '$userId-$category';
    // TODO: Implement TTL cache if needed

    final doc = await _firestore.collection('users').doc(userId).get();

    if (!doc.exists) {
      return {};
    }

    final data = doc.data()!;
    final skills = data['skills'] as Map<String, dynamic>? ?? {};

    // Filter by category
    final categorySkills = <String, double>{};
    skills.forEach((key, value) {
      if (key.startsWith(category)) {
        final skillData = value as Map<String, dynamic>;
        final accuracy = skillData['accuracy'] as num? ?? 0.5;
        categorySkills[key] = accuracy.toDouble();
      }
    });

    return categorySkills;
  }

  /// Get recently answered question IDs (last 7 days)
  /// OPTIMIZATION: Client-side cache, NO Firestore query untuk list IDs
  Future<Set<String>> _getRecentQuestionIds(String userId) async {
    // Check in-memory cache
    if (_recentQuestionIds.containsKey(userId)) {
      return _recentQuestionIds[userId]!;
    }

    final cutoffDate = DateTime.now().subtract(Duration(days: _antiRepeatDays));

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('exams')
        .where(
          'completedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate),
        )
        .limit(50)
        .get();

    final recentIds = <String>{};

    for (final examDoc in snapshot.docs) {
      final answersSnapshot = await examDoc.reference
          .collection('answers')
          .get(); // ✅ FIX: Firestore Flutter TIDAK support .select()

      for (final answerDoc in answersSnapshot.docs) {
        final data = answerDoc.data();
        final qId = data['questionId'];

        if (qId is String && qId.isNotEmpty) {
          recentIds.add(qId);
        }
      }
    }

    // Cache for this session
    _recentQuestionIds[userId] = recentIds;

    return recentIds;
  }

  // ==========================================================================
  // FETCH SINGLE QUESTION (BY ID)
  // ==========================================================================

  /// Get single question by ID
  /// OPTIMIZATION: Direct doc read, no query
  Future<QuestionModel?> getQuestionById(String questionId) async {
    final doc = await _firestore.collection('questions').doc(questionId).get();

    if (!doc.exists) return null;

    return QuestionModel.fromFirestore(doc);
  }

  // ==========================================================================
  // CATEGORY STATS (FOR UI)
  // ==========================================================================

  /// Get total questions per category (cached result)
  /// OPTIMIZATION: Use aggregation count, not snapshot.size
  Future<Map<String, int>> getCategoryCounts() async {
    // This should ideally use Firestore count() aggregation
    // For now, cache in-memory and refresh periodically

    final results = await Future.wait([
      _firestore
          .collection('questions')
          .where('category', isEqualTo: 'TWK')
          .where('isActive', isEqualTo: true)
          .count()
          .get(),
      _firestore
          .collection('questions')
          .where('category', isEqualTo: 'TIU')
          .where('isActive', isEqualTo: true)
          .count()
          .get(),
      _firestore
          .collection('questions')
          .where('category', isEqualTo: 'TKP')
          .where('isActive', isEqualTo: true)
          .count()
          .get(),
    ]);

    return {
      'TWK': ?results[0].count,
      'TIU': ?results[1].count,
      'TKP': ?results[2].count,
    };
  }

  // ==========================================================================
  // CACHE MANAGEMENT
  // ==========================================================================

  /// Clear anti-repetition cache (call on logout)
  void clearCache() {
    _recentQuestionIds.clear();
  }

  /// Force refresh recent questions cache
  Future<void> refreshRecentCache(String userId) async {
    _recentQuestionIds.remove(userId);
    await _getRecentQuestionIds(userId);
  }
}
