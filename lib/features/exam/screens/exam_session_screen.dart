// lib/features/exam/screens/exam_session_screen.dart

// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/features/exam/services/exam_service.dart';
import 'package:lulusasn/features/exam/widgets/question_card.dart';
import 'package:lulusasn/features/exam/widgets/answer_options.dart';
import 'package:lulusasn/features/exam/widgets/exam_timer.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/brutalist_button.dart';
import 'ad_interstitial_page.dart';
import 'adsense.dart';

/// Exam Session Screen - Professional Grade
///
/// Features:
/// - Responsive layout (Mobile/Tablet/Desktop)
/// - Question navigation dengan grid overview
/// - Review unanswered questions
/// - Haptic feedback
/// - Smooth animations
/// - Memory optimized
class ExamSessionScreen extends StatefulWidget {
  final String category;
  final int questionCount;

  const ExamSessionScreen({
    super.key,
    required this.category,
    this.questionCount = 10,
  });

  @override
  State<ExamSessionScreen> createState() => _ExamSessionScreenState();
}

class _ExamSessionScreenState extends State<ExamSessionScreen>
    with SingleTickerProviderStateMixin {
  late final ExamService _examService;
  AnimationController? _pageTransitionController; // ✅ GANTI jadi nullable

  ExamSession? _session;
  bool _isLoading = true;
  String? _error;
  final Map<int, int> _answers = {}; // questionIndex -> answer
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;
  @override
  @override
  void initState() {
    super.initState();
    _examService = ExamService();
    _setupAnimations();
    _loadSession();

    // Preload interstitial ad untuk mobile
    if (!kIsWeb && AdConfig.adsEnabled) {
      AdInterstitialController.load();
    }
  }

  @override
  void dispose() {
    _pageTransitionController?.dispose();
    // No need to dispose AdInterstitialController here - it's a singleton
    super.dispose();
  }

  Future<void> _finishExam() async {
    HapticFeedback.mediumImpact();

    // Check unanswered questions
    final totalQuestions = _session?.questions.length ?? 0;
    final unansweredCount = totalQuestions - _answers.length;

    if (unansweredCount > 0) {
      final shouldContinue = await _showUnansweredDialog(unansweredCount);
      if (shouldContinue != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Submit all answers
      for (var entry in _answers.entries) {
        _examService.submitAnswerAtIndex(entry.key, entry.value);
      }

      final result = await _examService.submitExam();

      if (!mounted) return;

      HapticFeedback.heavyImpact();

      // ========================================================================
      // AD LOGIC - NAVIGATE TO AD PAGE
      // ========================================================================

      if (AdConfig.adsEnabled) {
        // Navigate ke halaman Ad Interstitial (baik web maupun mobile)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdsInterstitialPage(
              title: 'Preparing Your Results...',
              subtitle: 'Please wait while we calculate your score',
              skipDelaySeconds: 5,
              showSkipButton: true,
              onContinue: () {
                Navigator.of(context).pushReplacementNamed(
                  AppRoutes.examResult,
                  arguments: {'result': result},
                );
              },
            ),
          ),
        );
      } else {
        // Jika ads disabled, langsung ke result
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.examResult,
          arguments: {'result': result},
        );
      }

      // ========================================================================
      // END AD LOGIC
      // ========================================================================
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      HapticFeedback.heavyImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setupAnimations() {
    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _loadSession() {
    final session = _examService.getCurrentSession();

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session tidak ditemukan'),
            backgroundColor: AppColors.error,
          ),
        );
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _session = session;
      _isLoading = false;
    });
  }

  void _handleAnswerSelected(int answer) {
    if (_isSubmitting) return;

    HapticFeedback.selectionClick();

    setState(() {
      _answers[_currentQuestionIndex] = answer;
    });
  }

  void _goToQuestion(int index) {
    if (index == _currentQuestionIndex || _isSubmitting) return;

    HapticFeedback.lightImpact();

    setState(() {
      _currentQuestionIndex = index;
    });

    _pageTransitionController?.forward(from: 0);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < (_session?.questions.length ?? 0) - 1) {
      _goToQuestion(_currentQuestionIndex + 1);
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _goToQuestion(_currentQuestionIndex - 1);
    }
  }

  void _showQuestionOverview() {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuestionOverviewSheet(
        session: _session!,
        answers: _answers,
        currentIndex: _currentQuestionIndex,
        onQuestionTap: (index) {
          Navigator.pop(context);
          _goToQuestion(index);
        },
      ),
    );
  }

  Future<bool?> _showUnansweredDialog(int count) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _UnansweredQuestionsDialog(count: count),
    );
  }

  Future<bool> _handleWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ExitConfirmationDialog(),
    );

    if (shouldExit == true) {
      _examService.cancelExam();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: _LoadingView(),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _ErrorView(error: _error!),
      );
    }

    final session = _session;
    if (session == null || session.questions.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _handleWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: _ResponsiveExamLayout(
        session: session,
        currentQuestionIndex: _currentQuestionIndex,
        answers: _answers,
        isSubmitting: _isSubmitting,
        onAnswerSelected: _handleAnswerSelected,
        onPrevious: _previousQuestion,
        onNext: _nextQuestion,
        onFinish: _finishExam,
        onShowOverview: _showQuestionOverview,
        onExit: _handleWillPop,
      ),
    );
  }
}

// ==============================================================================
// RESPONSIVE EXAM LAYOUT
// ==============================================================================

class _ResponsiveExamLayout extends StatelessWidget {
  final ExamSession session;
  final int currentQuestionIndex;
  final Map<int, int> answers;
  final bool isSubmitting;
  final Function(int) onAnswerSelected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final VoidCallback onShowOverview;
  final Future<bool> Function() onExit;

  const _ResponsiveExamLayout({
    required this.session,
    required this.currentQuestionIndex,
    required this.answers,
    required this.isSubmitting,
    required this.onAnswerSelected,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
    required this.onShowOverview,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1024;
        final isTablet = constraints.maxWidth > 600 && !isDesktop;

        if (isDesktop) {
          return _DesktopLayout(
            session: session,
            currentQuestionIndex: currentQuestionIndex,
            answers: answers,
            isSubmitting: isSubmitting,
            onAnswerSelected: onAnswerSelected,
            onPrevious: onPrevious,
            onNext: onNext,
            onFinish: onFinish,
            onQuestionTap: (index) {
              // Navigate directly in desktop
            },
            onExit: onExit,
          );
        }

        if (isTablet) {
          return _TabletLayout(
            session: session,
            currentQuestionIndex: currentQuestionIndex,
            answers: answers,
            isSubmitting: isSubmitting,
            onAnswerSelected: onAnswerSelected,
            onPrevious: onPrevious,
            onNext: onNext,
            onFinish: onFinish,
            onShowOverview: onShowOverview,
            onExit: onExit,
          );
        }

        return _MobileLayout(
          session: session,
          currentQuestionIndex: currentQuestionIndex,
          answers: answers,
          isSubmitting: isSubmitting,
          onAnswerSelected: onAnswerSelected,
          onPrevious: onPrevious,
          onNext: onNext,
          onFinish: onFinish,
          onShowOverview: onShowOverview,
          onExit: onExit,
        );
      },
    );
  }
}

// ==============================================================================
// MOBILE LAYOUT
// ==============================================================================

class _MobileLayout extends StatelessWidget {
  final ExamSession session;
  final int currentQuestionIndex;
  final Map<int, int> answers;
  final bool isSubmitting;
  final Function(int) onAnswerSelected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final VoidCallback onShowOverview;
  final Future<bool> Function() onExit;

  const _MobileLayout({
    required this.session,
    required this.currentQuestionIndex,
    required this.answers,
    required this.isSubmitting,
    required this.onAnswerSelected,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
    required this.onShowOverview,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final currentQuestion = session.questions[currentQuestionIndex];
    final selectedAnswer = answers[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / session.questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _ExamHeader(
              progress: progress,
              currentIndex: currentQuestionIndex,
              total: session.questions.length,
              startTime: session.startedAt,
              onExit: onExit,
              onShowOverview: onShowOverview,
            ),

            // Question Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    QuestionCard(
                      question: currentQuestion.question,
                      category: currentQuestion.category,
                      difficulty: currentQuestion.getDifficultyLabel(),
                      questionNumber: currentQuestionIndex + 1,
                      totalQuestions: session.questions.length,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AnswerOptions(
                      type: currentQuestion.type,
                      options: currentQuestion.options,
                      selectedAnswer: selectedAnswer,
                      onAnswerSelected: onAnswerSelected,
                      enabled: !isSubmitting,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            _MobileBottomNav(
              currentIndex: currentQuestionIndex,
              totalQuestions: session.questions.length,
              hasAnswer: selectedAnswer != null,
              isSubmitting: isSubmitting,
              onPrevious: onPrevious,
              onNext: onNext,
              onFinish: onFinish,
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// TABLET LAYOUT
// ==============================================================================

class _TabletLayout extends StatelessWidget {
  final ExamSession session;
  final int currentQuestionIndex;
  final Map<int, int> answers;
  final bool isSubmitting;
  final Function(int) onAnswerSelected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final VoidCallback onShowOverview;
  final Future<bool> Function() onExit;

  const _TabletLayout({
    required this.session,
    required this.currentQuestionIndex,
    required this.answers,
    required this.isSubmitting,
    required this.onAnswerSelected,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
    required this.onShowOverview,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final currentQuestion = session.questions[currentQuestionIndex];
    final selectedAnswer = answers[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / session.questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _ExamHeader(
              progress: progress,
              currentIndex: currentQuestionIndex,
              total: session.questions.length,
              startTime: session.startedAt,
              onExit: onExit,
              onShowOverview: onShowOverview,
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        QuestionCard(
                          question: currentQuestion.question,
                          category: currentQuestion.category,
                          difficulty: currentQuestion.getDifficultyLabel(),
                          questionNumber: currentQuestionIndex + 1,
                          totalQuestions: session.questions.length,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AnswerOptions(
                          type: currentQuestion.type,
                          options: currentQuestion.options,
                          selectedAnswer: selectedAnswer,
                          onAnswerSelected: onAnswerSelected,
                          enabled: !isSubmitting,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _MobileBottomNav(
              currentIndex: currentQuestionIndex,
              totalQuestions: session.questions.length,
              hasAnswer: selectedAnswer != null,
              isSubmitting: isSubmitting,
              onPrevious: onPrevious,
              onNext: onNext,
              onFinish: onFinish,
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// DESKTOP LAYOUT (Sidebar + Content)
// ==============================================================================

class _DesktopLayout extends StatelessWidget {
  final ExamSession session;
  final int currentQuestionIndex;
  final Map<int, int> answers;
  final bool isSubmitting;
  final Function(int) onAnswerSelected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final Function(int) onQuestionTap;
  final Future<bool> Function() onExit;

  const _DesktopLayout({
    required this.session,
    required this.currentQuestionIndex,
    required this.answers,
    required this.isSubmitting,
    required this.onAnswerSelected,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
    required this.onQuestionTap,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final currentQuestion = session.questions[currentQuestionIndex];
    final selectedAnswer = answers[currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 280,
            color: Colors.white,
            child: _DesktopSidebar(
              session: session,
              currentIndex: currentQuestionIndex,
              answers: answers,
              onQuestionTap: onQuestionTap,
              onExit: onExit,
            ),
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: AppColors.border, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Soal ${currentQuestionIndex + 1} dari ${session.questions.length}',
                        style: AppTextStyles.headingMedium,
                      ),
                      const Spacer(),
                      TotalExamTimer(startTime: session.startedAt),
                    ],
                  ),
                ),

                // Question Content
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.xl * 2),
                        child: Column(
                          children: [
                            QuestionCard(
                              question: currentQuestion.question,
                              category: currentQuestion.category,
                              difficulty: currentQuestion.getDifficultyLabel(),
                              questionNumber: currentQuestionIndex + 1,
                              totalQuestions: session.questions.length,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            AnswerOptions(
                              type: currentQuestion.type,
                              options: currentQuestion.options,
                              selectedAnswer: selectedAnswer,
                              onAnswerSelected: onAnswerSelected,
                              enabled: !isSubmitting,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        child: DuolingoButton.secondary(
                          text: 'SEBELUMNYA',
                          onPressed: currentQuestionIndex > 0
                              ? onPrevious
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      SizedBox(
                        width: 180,
                        child:
                            currentQuestionIndex == session.questions.length - 1
                            ? DuolingoButton.primary(
                                text: 'SELESAI',
                                onPressed: isSubmitting ? null : onFinish,
                                isLoading: isSubmitting,
                              )
                            : DuolingoButton.primary(
                                text: 'SELANJUTNYA',
                                onPressed: onNext,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// DESKTOP SIDEBAR
// ==============================================================================

class _DesktopSidebar extends StatelessWidget {
  final ExamSession session;
  final int currentIndex;
  final Map<int, int> answers;
  final Function(int) onQuestionTap;
  final Future<bool> Function() onExit;

  const _DesktopSidebar({
    required this.session,
    required this.currentIndex,
    required this.answers,
    required this.onQuestionTap,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 2),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () async {
                  final shouldExit = await onExit();
                  if (shouldExit && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Navigasi Soal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Progress Summary
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _ProgressSummary(
            total: session.questions.length,
            answered: answers.length,
          ),
        ),

        // Question Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemCount: session.questions.length,
            itemBuilder: (context, index) {
              final isAnswered = answers.containsKey(index);
              final isCurrent = index == currentIndex;

              return _QuestionGridItem(
                number: index + 1,
                isAnswered: isAnswered,
                isCurrent: isCurrent,
                onTap: () => onQuestionTap(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// EXAM HEADER (Mobile/Tablet)
// ==============================================================================

class _ExamHeader extends StatelessWidget {
  final double progress;
  final int currentIndex;
  final int total;
  final DateTime startTime;
  final Future<bool> Function() onExit;
  final VoidCallback onShowOverview;

  const _ExamHeader({
    required this.progress,
    required this.currentIndex,
    required this.total,
    required this.startTime,
    required this.onExit,
    required this.onShowOverview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () async {
                  final shouldExit = await onExit();
                  if (shouldExit && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 12,
                        backgroundColor: AppColors.border.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              TotalExamTimer(startTime: startTime),
              IconButton(
                icon: const Icon(Icons.grid_view_rounded),
                onPressed: onShowOverview,
                tooltip: 'Lihat semua soal',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// MOBILE BOTTOM NAVIGATION
// ==============================================================================

class _MobileBottomNav extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final bool hasAnswer;
  final bool isSubmitting;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  const _MobileBottomNav({
    required this.currentIndex,
    required this.totalQuestions,
    required this.hasAnswer,
    required this.isSubmitting,
    required this.onPrevious,
    required this.onNext,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final isLastQuestion = currentIndex == totalQuestions - 1;
    final canGoPrevious = currentIndex > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive text based on width
            final isNarrow = constraints.maxWidth < 400;

            final previousText = isNarrow ? 'PREV' : 'SEBELUMNYA';
            final nextText = isNarrow ? 'NEXT' : 'SELANJUTNYA';
            final finishText = isSubmitting
                ? (isNarrow ? 'LOADING...' : 'MEMPROSES...')
                : (isNarrow ? 'FINISH' : 'SELESAI');

            return Row(
              children: [
                if (canGoPrevious)
                  Expanded(
                    child: DuolingoButton.secondary(
                      text: previousText,
                      onPressed: isSubmitting ? null : onPrevious,
                    ),
                  ),
                if (canGoPrevious) const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: isLastQuestion
                      ? DuolingoButton.primary(
                          text: finishText,
                          onPressed: isSubmitting ? null : onFinish,
                          isLoading: isSubmitting,
                        )
                      : DuolingoButton.primary(
                          text: nextText,
                          onPressed: isSubmitting ? null : onNext,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ==============================================================================
// QUESTION OVERVIEW SHEET (Mobile/Tablet)
// ==============================================================================

class _QuestionOverviewSheet extends StatelessWidget {
  final ExamSession session;
  final Map<int, int> answers;
  final int currentIndex;
  final Function(int) onQuestionTap;

  const _QuestionOverviewSheet({
    required this.session,
    required this.answers,
    required this.currentIndex,
    required this.onQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.border, width: 3),
          left: BorderSide(color: AppColors.border, width: 3),
          right: BorderSide(color: AppColors.border, width: 3),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text('Navigasi Soal', style: AppTextStyles.headingLarge),
                const SizedBox(height: AppSpacing.md),
                _ProgressSummary(
                  total: session.questions.length,
                  answered: answers.length,
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 2, color: AppColors.border),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
              ),
              itemCount: session.questions.length,
              itemBuilder: (context, index) {
                final isAnswered = answers.containsKey(index);
                final isCurrent = index == currentIndex;

                return _QuestionGridItem(
                  number: index + 1,
                  isAnswered: isAnswered,
                  isCurrent: isCurrent,
                  onTap: () => onQuestionTap(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// PROGRESS SUMMARY
// ==============================================================================

class _ProgressSummary extends StatelessWidget {
  final int total;
  final int answered;

  const _ProgressSummary({required this.total, required this.answered});

  @override
  Widget build(BuildContext context) {
    final unanswered = total - answered;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            icon: Icons.check_circle_rounded,
            label: 'Terjawab',
            value: answered,
            color: AppColors.success,
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          _SummaryItem(
            icon: Icons.radio_button_unchecked_rounded,
            label: 'Belum',
            value: unanswered,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ==============================================================================
// QUESTION GRID ITEM
// ==============================================================================

class _QuestionGridItem extends StatelessWidget {
  final int number;
  final bool isAnswered;
  final bool isCurrent;
  final VoidCallback onTap;

  const _QuestionGridItem({
    required this.number,
    required this.isAnswered,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.primary
              : isAnswered
              ? AppColors.success.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? AppColors.primary
                : isAnswered
                ? AppColors.success
                : AppColors.border,
            width: 2,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCurrent
                      ? Colors.white
                      : isAnswered
                      ? AppColors.success
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (isAnswered && !isCurrent)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.success,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// UNANSWERED QUESTIONS DIALOG
// ==============================================================================

class _UnansweredQuestionsDialog extends StatelessWidget {
  final int count;

  const _UnansweredQuestionsDialog({required this.count});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 3),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(0, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.warning,
              size: 64,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Ada $count Soal Belum Terjawab',
              style: AppTextStyles.headingLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Soal yang tidak dijawab akan dihitung salah. Yakin ingin melanjutkan?',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: DuolingoButton.secondary(
                    text: 'REVIEW',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DuolingoButton.primary(
                    text: 'LANJUT',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// EXIT CONFIRMATION DIALOG
// ==============================================================================

class _ExitConfirmationDialog extends StatelessWidget {
  const _ExitConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 3),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(0, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Keluar dari Ujian?',
              style: AppTextStyles.headingLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Progress kamu akan hilang dan energy tidak dikembalikan.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: DuolingoButton.secondary(
                    text: 'BATAL',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DuolingoButton.danger(
                    text: 'KELUAR',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// LOADING & ERROR VIEWS
// ==============================================================================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Memuat soal...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;

  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Terjadi Kesalahan', style: AppTextStyles.headingLarge),
            const SizedBox(height: AppSpacing.md),
            Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            DuolingoButton.primary(
              text: 'KEMBALI',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
