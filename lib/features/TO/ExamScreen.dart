// lib/features/tryout/screens/exam_session_screen.dart

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/constants/text_styles.dart';

/// Exam Session Screen - REDESIGNED (Duolingo + Reference Style)
///
/// UI Improvements:
/// - Side navigation panel (desktop/tablet)
/// - Responsive layout (mobile/tablet/desktop)
/// - Clean card-based design
/// - Better visual hierarchy
/// - Smooth animations
///
/// Database Strategy:
/// - Create exam_sessions doc on start (1 write)
/// - Update answers in memory (no writes during exam)
/// - Save to exam_results on finish (1 write)
class ExamSessionScreen extends StatefulWidget {
  final String tryoutId;
  final String subtestId;
  final Map<String, dynamic> subtestData;

  const ExamSessionScreen({
    super.key,
    required this.tryoutId,
    required this.subtestId,
    required this.subtestData,
  });

  @override
  State<ExamSessionScreen> createState() => _ExamSessionScreenState();
}

class _ExamSessionScreenState extends State<ExamSessionScreen>
    with TickerProviderStateMixin {
  // ==========================================================================
  // STATE VARIABLES
  // ==========================================================================
  bool _isLoading = true;
  String? _error;

  // Questions data
  List<Map<String, dynamic>> _questions = [];

  // User answers (stored in memory only)
  Map<int, int> _answers = {}; // questionIndex -> selectedOptionIndex

  // Navigation
  int _currentQuestionIndex = 0;
  final PageController _pageController = PageController();

  // Timer
  Timer? _timer;
  int _remainingSeconds = 0;
  late int _totalSeconds;

  // Session metadata
  String? _sessionId;
  DateTime? _startTime;

  // Animations
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController; // ← TAMBAH INI
  // ← TAMBAH INI

  // UI State
  bool _showNavigator = false;

  // ==========================================================================
  // LIFECYCLE
  // ==========================================================================
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadQuestionsAndStartSession();
  }

  String getCurrentUserIdSafe() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid;
    }
    throw Exception('User not logged in');
  }

  void _initializeAnimations() {
    // Fade animation (lebih lama)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500), // ← 300ms → 500ms
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut, // ← easeOut → easeInOut
      ),
    );

    // ✅ SLIDE ANIMATION (baru)
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose(); // ← TAMBAH INI
    super.dispose();
  }

  Future<void> _loadQuestionsAndStartSession() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ✅ PAKAI DATA DARI subtestData
      final questionsList = widget.subtestData['questions'] as List<dynamic>?;

      if (questionsList == null || questionsList.isEmpty) {
        throw Exception('Tidak ada soal di subtes ini');
      }

      _questions = questionsList
          .map((q) => Map<String, dynamic>.from(q as Map))
          .toList();

      // Initialize timer
      final estimatedMinutes = widget.subtestData['estimatedMinutes'] ?? 30;
      _totalSeconds = estimatedMinutes * 60;
      _remainingSeconds = _totalSeconds;

      // Create session ID and start time
      _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      _startTime = DateTime.now();

      // TODO: Create exam_sessions document (optional, for tracking)
      // await _createSessionInFirebase();

      // Start timer
      _startTimer();

      // Start animation
      _fadeController.forward();

      setState(() => _isLoading = false);
    } catch (e) {
      print(e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _showTimeUpDialog();
      }
    });
  }

  // ==========================================================================
  // NAVIGATION METHODS
  // ==========================================================================
  void _goToQuestion(int index) {
    if (index < 0 || index >= _questions.length) return;

    HapticFeedback.selectionClick();

    final isForward = index > _currentQuestionIndex;

    setState(() {
      _currentQuestionIndex = index;
      _showNavigator = false;
    });

    // ✅ UPDATE SLIDE DIRECTION

    // ✅ SMOOTH PAGE TRANSITION (hilangkan NeverScrollableScrollPhysics)
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400), // ← 300ms → 400ms
      curve: Curves.easeOutCubic, // ← easeInOut → easeOutCubic
    );

    // ✅ START ANIMATIONS
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  void _goToPrevious() {
    if (_currentQuestionIndex > 0) {
      _goToQuestion(_currentQuestionIndex - 1);
    }
  }

  void _goToNext() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _goToQuestion(_currentQuestionIndex + 1);
    }
  }

  // ==========================================================================
  // ANSWER HANDLING
  // ==========================================================================
  void _selectAnswer(int optionIndex) {
    HapticFeedback.mediumImpact();

    setState(() {
      _answers[_currentQuestionIndex] = optionIndex;
    });

    // ✅ AUTO ADVANCE LEBIH CEPAT (600ms → 400ms)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _currentQuestionIndex < _questions.length - 1) {
        _goToNext();
      }
    });
  }

  // ==========================================================================
  // SUBMIT & FINISH
  // ==========================================================================
  Future<void> _submitExam() async {
    try {
      HapticFeedback.heavyImpact();

      final endTime = DateTime.now();
      final totalTimeSeconds = endTime.difference(_startTime!).inSeconds;

      // Calculate scores
      int correctAnswers = 0;
      int wrongAnswers = 0;
      final Map<String, Map<String, int>> categoryScores = {};
      final List<Map<String, dynamic>> detailedAnswers = [];

      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final userAnswer = _answers[i];
        final correctAnswer = question['correctIndex'] as int?;
        final category = question['category'] as String? ?? 'N/A';

        final isCorrect = userAnswer != null && userAnswer == correctAnswer;

        if (isCorrect) {
          correctAnswers++;
        } else if (userAnswer != null) {
          wrongAnswers++;
        }

        // Category tracking
        if (!categoryScores.containsKey(category)) {
          categoryScores[category] = {'correct': 0, 'total': 0};
        }
        categoryScores[category]!['total'] =
            (categoryScores[category]!['total'] ?? 0) + 1;
        if (isCorrect) {
          categoryScores[category]!['correct'] =
              (categoryScores[category]!['correct'] ?? 0) + 1;
        }

        detailedAnswers.add({
          'questionId': question['id'] ?? 'q_$i',
          'userAnswer': userAnswer,
          'correctAnswer': correctAnswer,
          'isCorrect': isCorrect,
        });
      }

      final unanswered = _questions.length - _answers.length;
      final score = (_questions.length > 0)
          ? ((correctAnswers / _questions.length) * 100).round()
          : 0;

      // Format category scores
      final categoryScoresFormatted = categoryScores.map(
        (category, scores) => MapEntry(category, {
          'correct': scores['correct'],
          'total': scores['total'],
          'percentage': scores['total']! > 0
              ? ((scores['correct']! / scores['total']!) * 100).round()
              : 0,
        }),
      );

      String currentUserId = getCurrentUserIdSafe();
      final resultId = 'result_${DateTime.now().millisecondsSinceEpoch}';

      // ✅ WRITE: Save exam result
      await FirebaseFirestore.instance
          .collection('exam_results')
          .doc(resultId)
          .set({
            'userId': currentUserId,
            'tryoutId': widget.tryoutId,
            'subtestId': widget.subtestId,
            'sessionId': _sessionId,
            'totalQuestions': _questions.length,
            'correctAnswers': correctAnswers,
            'wrongAnswers': wrongAnswers,
            'unanswered': unanswered,
            'score': score,
            'categoryScores': categoryScoresFormatted,
            'startedAt': Timestamp.fromDate(_startTime!),
            'completedAt': Timestamp.fromDate(endTime),
            'totalTimeSeconds': totalTimeSeconds,
            'answers': detailedAnswers,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // ✅ WRITE: Update or Create user_tryouts progress
      final userTryoutRef = FirebaseFirestore.instance
          .collection('user_tryouts')
          .doc('${currentUserId}_tryout_${widget.tryoutId}');

      // 🔥 CEK DULU: Apakah dokumen sudah ada?
      final userTryoutDoc = await userTryoutRef.get();

      if (userTryoutDoc.exists) {
        // ✅ Dokumen sudah ada, UPDATE saja
        final existingData = userTryoutDoc.data() as Map<String, dynamic>;
        final subtestProgress =
            existingData['subtestProgress'] as Map<String, dynamic>? ?? {};
        final currentSubtest =
            subtestProgress[widget.subtestId] as Map<String, dynamic>? ?? {};
        final currentBestScore = currentSubtest['bestScore'] as int? ?? 0;

        await userTryoutRef.update({
          'subtestProgress.${widget.subtestId}.status': 'completed',
          'subtestProgress.${widget.subtestId}.attempts': FieldValue.increment(
            1,
          ),
          'subtestProgress.${widget.subtestId}.bestScore':
              score > currentBestScore ? score : currentBestScore,
          'subtestProgress.${widget.subtestId}.lastAttemptAt':
              FieldValue.serverTimestamp(),
          'lastAttemptAt': FieldValue.serverTimestamp(),
          'totalAttempts': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // ✅ Dokumen belum ada, BUAT BARU
        await userTryoutRef.set({
          'userId': currentUserId,
          'tryoutId': widget.tryoutId,
          'subtestProgress': {
            widget.subtestId: {
              'status': 'completed',
              'attempts': 1,
              'bestScore': score,
              'lastAttemptAt': FieldValue.serverTimestamp(),
            },
          },
          'lastAttemptAt': FieldValue.serverTimestamp(),
          'totalAttempts': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        // Navigate back with success message
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: AppSpacing.sm),
                Text('Ujian selesai! Skor: $score/100'),
              ],
            ),
            backgroundColor: const Color(0xFF58CC02),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(AppSpacing.md),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: const Color(0xFFFF4B4B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // ==========================================================================
  // UI BUILD METHODS
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: _buildLoadingView(),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: _buildErrorView(),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitConfirmation();
        return shouldExit ?? false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 1024;
            final isTablet =
                constraints.maxWidth > 768 && constraints.maxWidth <= 1024;

            if (isDesktop || isTablet) {
              return _buildDesktopLayout();
            } else {
              return _buildMobileLayout();
            }
          },
        ),
      ),
    );
  }

  // ==========================================================================
  // DESKTOP LAYOUT (Side Navigator)
  // ==========================================================================
  Widget _buildDesktopLayout() {
    return SafeArea(
      child: Row(
        children: [
          // LEFT SIDEBAR - Navigation
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: const Color(0xFFE5E5E5), width: 2),
              ),
            ),
            child: Column(
              children: [
                _buildSidebarHeader(),
                _buildProgressStats(),
                const Divider(height: 1, thickness: 2),
                Expanded(child: _buildQuestionGrid()),
                const Divider(height: 1, thickness: 2),
                _buildSidebarFooter(),
              ],
            ),
          ),

          // RIGHT CONTENT - Question
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildQuestionView()),
                _buildBottomNavigation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // MOBILE LAYOUT
  // ==========================================================================
  Widget _buildMobileLayout() {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              _buildMobileHeader(),
              Expanded(child: _buildQuestionView()),
              _buildBottomNavigation(),
            ],
          ),

          // Sliding Navigator Panel
          if (_showNavigator)
            GestureDetector(
              onTap: () => setState(() => _showNavigator = false),
              child: Container(color: Colors.black54),
            ),

          if (_showNavigator)
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                elevation: 8,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: double.infinity,
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildSidebarHeader(),
                      _buildProgressStats(),
                      const Divider(height: 1, thickness: 2),
                      Expanded(child: _buildQuestionGrid()),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SIDEBAR COMPONENTS
  // ==========================================================================
  Widget _buildSidebarHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFF1CB0F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              color: Color(0xFF1CB0F6),
              size: 24,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Navigasi Soal',
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.subtestData['name'] ?? 'Ujian',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF777777),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStats() {
    final answered = _answers.length;
    final total = _questions.length;
    final unanswered = total - answered;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _buildStatBox(
              icon: Icons.check_circle_rounded,
              label: 'Terjawab',
              value: '$answered',
              color: const Color(0xFF58CC02),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatBox(
              icon: Icons.radio_button_unchecked_rounded,
              label: 'Belum',
              value: '$unanswered',
              color: const Color(0xFFE5E5E5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.headingMedium.copyWith(
              color: color == const Color(0xFFE5E5E5)
                  ? const Color(0xFF999999)
                  : color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF777777),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final isAnswered = _answers.containsKey(index);
        final isCurrent = index == _currentQuestionIndex;

        Color bgColor;
        Color borderColor;
        Color textColor;

        if (isCurrent) {
          bgColor = const Color(0xFF58CC02);
          borderColor = const Color(0xFF46A302);
          textColor = Colors.white;
        } else if (isAnswered) {
          bgColor = const Color(0xFF58CC02).withOpacity(0.1);
          borderColor = const Color(0xFF58CC02);
          textColor = const Color(0xFF58CC02);
        } else {
          bgColor = Colors.white;
          borderColor = const Color(0xFFE5E5E5);
          textColor = const Color(0xFF4B4B4B);
        }

        return InkWell(
          onTap: () => _goToQuestion(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: const Color(0xFF46A302).withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _showReviewDialog,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            backgroundColor: const Color(0xFF58CC02),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF46A302), width: 2),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_rounded, size: 20),
              SizedBox(width: AppSpacing.sm),
              const Text(
                'SELESAI',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // TOP BAR (Desktop)
  // ==========================================================================
  Widget _buildTopBar() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final isLowTime = _remainingSeconds < 300;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 2)),
      ),
      child: Row(
        children: [
          // Question counter
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1CB0F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1CB0F6), width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.quiz_rounded,
                      color: Color(0xFF1CB0F6),
                      size: 20,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      '${_currentQuestionIndex + 1}/${_questions.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: const Color(0xFF1CB0F6),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.md),
              // Category badge
              if (_questions.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9333EA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF9333EA),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.category_rounded,
                        color: Color(0xFF9333EA),
                        size: 18,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        _questions[_currentQuestionIndex]['category'] ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF9333EA),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const Spacer(),

          // Timer
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isLowTime
                  ? const Color(0xFFFF4B4B).withOpacity(0.1)
                  : const Color(0xFF1CB0F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLowTime
                    ? const Color(0xFFFF4B4B)
                    : const Color(0xFF1CB0F6),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_rounded,
                  color: isLowTime
                      ? const Color(0xFFFF4B4B)
                      : const Color(0xFF1CB0F6),
                  size: 22,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isLowTime
                        ? const Color(0xFFFF4B4B)
                        : const Color(0xFF1CB0F6),
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: AppSpacing.md),

          // Exit button
          IconButton(
            onPressed: () async {
              final shouldExit = await _showExitConfirmation();
              if (shouldExit == true && mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.close_rounded),
            iconSize: 28,
            color: const Color(0xFF4B4B4B),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF7F7F7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE5E5E5), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // MOBILE HEADER
  // ==========================================================================
  Widget _buildMobileHeader() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final isLowTime = _remainingSeconds < 300;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 3)),
      ),
      child: Row(
        children: [
          // Menu button (open navigator)
          IconButton(
            onPressed: () => setState(() => _showNavigator = true),
            icon: const Icon(Icons.menu_rounded),
            iconSize: 28,
            color: const Color(0xFF4B4B4B),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF7F7F7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE5E5E5), width: 2),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),

          // Question counter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soal ${_currentQuestionIndex + 1} dari ${_questions.length}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_questions.isNotEmpty)
                  Text(
                    _questions[_currentQuestionIndex]['category'] ?? 'N/A',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFF777777),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Timer
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isLowTime
                  ? const Color(0xFFFF4B4B).withOpacity(0.1)
                  : const Color(0xFF1CB0F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLowTime
                    ? const Color(0xFFFF4B4B)
                    : const Color(0xFF1CB0F6),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_rounded,
                  size: 20,
                  color: isLowTime
                      ? const Color(0xFFFF4B4B)
                      : const Color(0xFF1CB0F6),
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isLowTime
                        ? const Color(0xFFFF4B4B)
                        : const Color(0xFF1CB0F6),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // QUESTION VIEW
  // ==========================================================================
  Widget _buildQuestionView() {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _questions.length,
      onPageChanged: (index) {
        setState(() => _currentQuestionIndex = index);
        _fadeController.reset();
        _fadeController.forward();
      },
      itemBuilder: (context, index) {
        return _buildQuestionCard(_questions[index], index);
      },
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    final questionText = question['question'] as String? ?? '';
    final options = question['options'] as List<dynamic>? ?? [];
    final selectedAnswer = _answers[index];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question Card
                Container(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE5E5E5),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Text(
                    questionText,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: const Color(0xFF1A1A1A),
                      height: 1.6,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),

                SizedBox(height: AppSpacing.xl),

                // Options
                ...List.generate(options.length, (optionIndex) {
                  final optionLabel = String.fromCharCode(
                    65 + optionIndex,
                  ); // A, B, C...
                  final optionText = options[optionIndex].toString();
                  final isSelected = selectedAnswer == optionIndex;

                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildOptionCard(
                      label: optionLabel,
                      text: optionText,
                      optionIndex: optionIndex,
                      isSelected: isSelected,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String label,
    required String text,
    required int optionIndex,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _selectAnswer(optionIndex),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF58CC02) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF46A302)
                : const Color(0xFFE5E5E5),
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF46A302).withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Row(
          children: [
            // Label circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFF7F7F7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF46A302)
                      : const Color(0xFFE5E5E5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? const Color(0xFF58CC02)
                        : const Color(0xFF4B4B4B),
                  ),
                ),
              ),
            ),

            SizedBox(width: AppSpacing.md),

            // Option text
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),

            // Checkmark
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // BOTTOM NAVIGATION
  // ==========================================================================
  Widget _buildBottomNavigation() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5), width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Row(
              children: [
                // Previous Button
                Expanded(
                  child: TextButton(
                    onPressed: _currentQuestionIndex > 0 ? _goToPrevious : null,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      backgroundColor: const Color(0xFFF7F7F7),
                      foregroundColor: const Color(0xFF4B4B4B),
                      disabledBackgroundColor: const Color(
                        0xFFF7F7F7,
                      ).withOpacity(0.5),
                      disabledForegroundColor: const Color(
                        0xFF4B4B4B,
                      ).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _currentQuestionIndex > 0
                              ? const Color(0xFFE5E5E5)
                              : const Color(0xFFE5E5E5).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back_rounded, size: 20),
                        SizedBox(width: AppSpacing.xs),
                        const Text(
                          'SEBELUMNYA',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: AppSpacing.md),

                // Next Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentQuestionIndex < _questions.length - 1
                        ? _goToNext
                        : _showReviewDialog,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      backgroundColor: const Color(0xFF58CC02),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Color(0xFF46A302),
                          width: 2,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentQuestionIndex < _questions.length - 1
                              ? 'SELANJUTNYA'
                              : 'SELESAI',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Icon(
                          _currentQuestionIndex < _questions.length - 1
                              ? Icons.arrow_forward_rounded
                              : Icons.check_rounded,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // DIALOGS
  // ==========================================================================
  void _showReviewDialog() {
    final unanswered = _questions.length - _answers.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE5E5E5), width: 3),
        ),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: const Color(0xFF1CB0F6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF1CB0F6),
                  size: 48,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                'Review Jawaban',
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
                ),
                child: Column(
                  children: [
                    _buildReviewStat(
                      icon: Icons.check_circle_rounded,
                      label: 'Terjawab',
                      value: '${_answers.length}',
                      color: const Color(0xFF58CC02),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _buildReviewStat(
                      icon: Icons.radio_button_unchecked_rounded,
                      label: 'Belum Dijawab',
                      value: '$unanswered',
                      color: const Color(0xFFFF9600),
                    ),
                  ],
                ),
              ),
              if (unanswered > 0) ...[
                SizedBox(height: AppSpacing.md),
                Text(
                  'Kamu masih punya $unanswered soal yang belum dijawab',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF777777),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        backgroundColor: const Color(0xFFF7F7F7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFFE5E5E5),
                            width: 2,
                          ),
                        ),
                      ),
                      child: const Text(
                        'REVIEW',
                        style: TextStyle(
                          color: Color(0xFF777777),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _submitExam();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        backgroundColor: const Color(0xFF58CC02),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFF46A302),
                            width: 2,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'SELESAI',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF4B4B4B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.headingSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFFF4B4B), width: 3),
          ),
          child: Container(
            padding: EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4B4B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.timer_off_rounded,
                    color: Color(0xFFFF4B4B),
                    size: 48,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Waktu Habis!',
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Ujian akan otomatis diselesaikan',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF777777),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _submitExam();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      backgroundColor: const Color(0xFFFF4B4B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Color(0xFFCC0000),
                          width: 2,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showExitConfirmation() async {
    HapticFeedback.mediumImpact();

    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF9600), width: 3),
        ),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9600).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFFF9600),
                  size: 48,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                'Keluar dari Ujian?',
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Progres kamu akan hilang dan tidak dapat dikembalikan',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF777777),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        backgroundColor: const Color(0xFFF7F7F7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFFE5E5E5),
                            width: 2,
                          ),
                        ),
                      ),
                      child: const Text(
                        'BATAL',
                        style: TextStyle(
                          color: Color(0xFF777777),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        backgroundColor: const Color(0xFFFF4B4B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFFCC0000),
                            width: 2,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'KELUAR',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // LOADING & ERROR VIEWS
  // ==========================================================================
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: const Color(0xFF1CB0F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF1CB0F6)),
              strokeWidth: 4,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          Text(
            'Memuat Soal...',
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Mohon tunggu sebentar',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4B4B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF4B4B),
                size: 64,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Gagal Memuat Soal',
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? 'Unknown error',
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF777777),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                backgroundColor: const Color(0xFF58CC02),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF46A302), width: 2),
                ),
                elevation: 0,
              ),
              child: const Text(
                'KEMBALI',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
