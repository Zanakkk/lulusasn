// lib/features/exam/screens/exam_review_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/widgets/brutalist_button.dart';
import 'package:lulusasn/features/exam/models/exam_result_model.dart';
import 'package:lulusasn/features/exam/models/answer_model.dart';
import 'package:lulusasn/features/exam/models/question_model.dart';
import 'package:lulusasn/features/exam/services/question_service.dart';

import '../../../core/services/firebase_service.dart';

/// Exam Review Screen - Duolingo Style with Responsive Design
///
/// Features:
/// - Responsive layout (mobile pagination, desktop grid navigation)
/// - Pagination untuk mobile (satu soal per halaman)
/// - Grid navigation untuk desktop (jump ke soal manapun)
/// - Explanation short & full dengan toggle
/// - Filter by status (all/correct/incorrect)
/// - Optimized data fetching (1-2 reads max)
class ExamReviewScreen extends StatefulWidget {
  final String examId;

  const ExamReviewScreen({super.key, required this.examId});

  @override
  State<ExamReviewScreen> createState() => _ExamReviewScreenState();
}

class _ExamReviewScreenState extends State<ExamReviewScreen> {
  final _questionService = QuestionService();
  final _pageController = PageController();
  final _scrollController = ScrollController();

  ExamResultModel? _result;
  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, correct, incorrect
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadReviewData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReviewData() async {
    try {
      final userId = FirebaseService.instance.auth.currentUser?.uid;
      if (userId == null) throw Exception('User tidak login');

      // 🔥 OPTIMIZED: Single read untuk exam result dengan embedded answers
      final examDoc = await FirebaseService.instance.firestore
          .collection('users')
          .doc(userId)
          .collection('exams')
          .doc(widget.examId)
          .get();

      if (!examDoc.exists) {
        throw Exception('Exam tidak ditemukan');
      }

      final result = ExamResultModel.fromFirestore(examDoc);

      if (result.answers == null || result.answers!.isEmpty) {
        throw Exception('Tidak ada jawaban tersedia');
      }

      // 🔥 Get questions dari exam package (1 read saja!)
      final questionIds = result.answers!.map((a) => a.questionId).toList();
      final packageId = _extractPackageId(questionIds.first);

      List<QuestionModel> questions = [];

      if (packageId != null) {
        questions = await _loadQuestionsFromPackage(packageId, result.answers!);
      } else {
        questions = await _loadIndividualQuestions(result.answers!);
      }

      setState(() {
        _result = result;
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat review: $e')));
      }
    }
  }

  String? _extractPackageId(String questionId) {
    final parts = questionId.split('_');
    if (parts.length >= 3 && parts[0] == 'q') {
      return parts[1];
    }
    return null;
  }

  Future<List<QuestionModel>> _loadQuestionsFromPackage(
    String packageId,
    List<AnswerModel> answers,
  ) async {
    final packageDoc = await FirebaseService.instance.firestore
        .collection('exam_packages')
        .doc(packageId)
        .get();

    if (!packageDoc.exists) return [];

    final data = packageDoc.data()!;
    final questionsData = data['questions'] as List<dynamic>? ?? [];

    final allQuestions = questionsData.asMap().entries.map((entry) {
      final index = entry.key;
      final q = entry.value as Map<String, dynamic>;

      return QuestionModel(
        questionId: 'q_${packageId}_$index',
        question: q['question'] as String? ?? '',
        type: QuestionType.fromString(q['type'] as String? ?? 'objective'),
        options: (q['options'] as List<dynamic>?)?.cast<String>() ?? [],
        correctAnswer: q['correctAnswer'] as int? ?? 0,
        explanationShort: q['explanationShort'] as String? ?? '',
        explanationFull: q['explanationFull'] as String? ?? '',
        category: q['category'] as String? ?? '',
        subcategory: q['subcategory'] as String? ?? '',
        tags: (q['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        difficulty: q['difficulty'] as int? ?? 50,
        isActive: q['isActive'] as bool? ?? true,
        createdAt: (q['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();

    final orderedQuestions = <QuestionModel>[];
    for (final answer in answers) {
      final question = allQuestions.firstWhere(
        (q) => q.questionId == answer.questionId,
        orElse: () => _createDummyQuestion(answer),
      );
      orderedQuestions.add(question);
    }

    return orderedQuestions;
  }

  Future<List<QuestionModel>> _loadIndividualQuestions(
    List<AnswerModel> answers,
  ) async {
    final questions = <QuestionModel>[];

    for (final answer in answers) {
      final question = await _questionService.getQuestionById(
        answer.questionId,
      );
      questions.add(question ?? _createDummyQuestion(answer));
    }

    return questions;
  }

  List<AnswerModel> get _filteredAnswers {
    if (_result?.answers == null) return [];

    switch (_filter) {
      case 'correct':
        return _result!.answers!.where((a) => a.isCorrect).toList();
      case 'incorrect':
        return _result!.answers!.where((a) => !a.isCorrect).toList();
      default:
        return _result!.answers!;
    }
  }

  void _jumpToQuestion(int index) {
    if (_isMobile) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Desktop: scroll to question
      final questionHeight = 600.0; // Approximate height
      _scrollController.animateTo(
        index * questionHeight,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  bool get _isMobile => MediaQuery.of(context).size.width < 768;

  void _handleDone() {
    Navigator.of(context).popUntil((route) => route.settings.name == '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: _handleDone,
        ),
        title: Text(
          'Review Jawaban',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _result == null
          ? _buildErrorState()
          : _isMobile
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
    );
  }

  // 📱 MOBILE LAYOUT - Pagination
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _SummaryHeader(result: _result!),
        _FilterTabs(
          currentFilter: _filter,
          result: _result!,
          onFilterChanged: (filter) {
            setState(() {
              _filter = filter;
              _currentPage = 0;
            });
          },
        ),
        Expanded(
          child: _filteredAnswers.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Question counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Soal ${_currentPage + 1} dari ${_filteredAnswers.length}',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // PageView
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemCount: _filteredAnswers.length,
                        itemBuilder: (context, index) {
                          final answer = _filteredAnswers[index];
                          final question = _questions.firstWhere(
                            (q) => q.questionId == answer.questionId,
                            orElse: () => _createDummyQuestion(answer),
                          );

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _QuestionReviewCard(
                              answer: answer,
                              question: question,
                              questionNumber: answer.questionOrder,
                            ),
                          );
                        },
                      ),
                    ),
                    // Navigation buttons
                    _MobileNavigation(
                      currentPage: _currentPage,
                      totalPages: _filteredAnswers.length,
                      onPrevious: _currentPage > 0
                          ? () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            )
                          : null,
                      onNext: _currentPage < _filteredAnswers.length - 1
                          ? () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            )
                          : null,
                      onDone: _handleDone,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // 🖥️ DESKTOP LAYOUT - Grid Navigation + Scrollable
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left sidebar - Navigation grid
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              _SummaryHeader(result: _result!),
              _FilterTabs(
                currentFilter: _filter,
                result: _result!,
                onFilterChanged: (filter) {
                  setState(() => _filter = filter);
                },
              ),
              Expanded(
                child: _filteredAnswers.isEmpty
                    ? _buildEmptyState()
                    : _QuestionNavigationGrid(
                        answers: _filteredAnswers,
                        currentIndex: _currentPage,
                        onQuestionTap: _jumpToQuestion,
                      ),
              ),
              _DesktopBottomAction(onDone: _handleDone),
            ],
          ),
        ),
        // Right content - Scrollable questions
        Expanded(
          child: _filteredAnswers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  itemCount: _filteredAnswers.length,
                  itemBuilder: (context, index) {
                    final answer = _filteredAnswers[index];
                    final question = _questions.firstWhere(
                      (q) => q.questionId == answer.questionId,
                      orElse: () => _createDummyQuestion(answer),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: _QuestionReviewCard(
                        answer: answer,
                        question: question,
                        questionNumber: answer.questionOrder,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('Gagal memuat review', style: AppTextStyles.headingMedium),
          const SizedBox(height: 24),
          DuolingoButton.secondary(text: 'KEMBALI', onPressed: _handleDone),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎯', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Tidak ada soal untuk ditampilkan',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  QuestionModel _createDummyQuestion(AnswerModel answer) {
    return QuestionModel(
      questionId: answer.questionId,
      question: 'Soal tidak tersedia',
      type: answer.questionType,
      options: [],
      correctAnswer: answer.correctAnswer,
      explanationShort: 'Penjelasan tidak tersedia',
      explanationFull: '',
      category: answer.category,
      subcategory: answer.subcategory,
      tags: [],
      difficulty: answer.difficulty,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }
}

// ==============================================================================
// SUMMARY HEADER - Compact & Responsive
// ==============================================================================

class _SummaryHeader extends StatelessWidget {
  final ExamResultModel result;

  const _SummaryHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _CompactStat(
                icon: Icons.check_circle,
                color: AppColors.success,
                value: result.correctCount,
              ),
              const SizedBox(width: 8),
              _CompactStat(
                icon: Icons.cancel,
                color: AppColors.error,
                value: result.totalQuestions - result.correctCount,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Text(
                  '${(result.accuracy * 100).toInt()}% Akurasi',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;

  const _CompactStat({
    required this.icon,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: AppTextStyles.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// FILTER TABS
// ==============================================================================

class _FilterTabs extends StatelessWidget {
  final String currentFilter;
  final ExamResultModel result;
  final ValueChanged<String> onFilterChanged;

  const _FilterTabs({
    required this.currentFilter,
    required this.result,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final incorrectCount = result.totalQuestions - result.correctCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'Semua',
            count: result.totalQuestions,
            isSelected: currentFilter == 'all',
            onTap: () => onFilterChanged('all'),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Benar',
            count: result.correctCount,
            color: AppColors.success,
            isSelected: currentFilter == 'correct',
            onTap: () => onFilterChanged('correct'),
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Salah',
            count: incorrectCount,
            color: AppColors.error,
            isSelected: currentFilter == 'incorrect',
            onTap: () => onFilterChanged('incorrect'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            '$label ($count)',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? activeColor : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// QUESTION NAVIGATION GRID (Desktop)
// ==============================================================================

class _QuestionNavigationGrid extends StatelessWidget {
  final List<AnswerModel> answers;
  final int currentIndex;
  final ValueChanged<int> onQuestionTap;

  const _QuestionNavigationGrid({
    required this.answers,
    required this.currentIndex,
    required this.onQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: answers.length,
      itemBuilder: (context, index) {
        final answer = answers[index];
        final isActive = index == currentIndex;

        return GestureDetector(
          onTap: () => onQuestionTap(index),
          child: Container(
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : (answer.isCorrect
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? AppColors.primary
                    : (answer.isCorrect ? AppColors.success : AppColors.error),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${answer.questionOrder}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isActive
                      ? Colors.white
                      : (answer.isCorrect
                            ? AppColors.success
                            : AppColors.error),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==============================================================================
// QUESTION REVIEW CARD - Enhanced dengan Explanation Full
// ==============================================================================

class _QuestionReviewCard extends StatefulWidget {
  final AnswerModel answer;
  final QuestionModel question;
  final int questionNumber;

  const _QuestionReviewCard({
    required this.answer,
    required this.question,
    required this.questionNumber,
  });

  @override
  State<_QuestionReviewCard> createState() => _QuestionReviewCardState();
}

class _QuestionReviewCardState extends State<_QuestionReviewCard> {
  bool _showExplanation = false;
  bool _showFullExplanation = false;

  @override
  Widget build(BuildContext context) {
    final isCorrect = widget.answer.isCorrect;
    final statusColor = isCorrect ? AppColors.success : AppColors.error;
    final hasFullExplanation = widget.question.explanationFull.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.questionNumber}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: statusColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCorrect ? 'Benar' : 'Salah',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.answer.subcategory,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _CategoryBadge(category: widget.answer.category),
              ],
            ),
          ),

          // Question
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.question.question,
              style: AppTextStyles.bodyLarge.copyWith(
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Options
          // Di dalam build method _QuestionReviewCard, ganti bagian Options:
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                widget.question.options.length,
                    (index) {
                  // 🆕 Untuk likert, ambil semua skor
                  final optionScores = widget.question.type == QuestionType.likert
                      ? widget.question.getAllOptionScores()
                      : null;

                  return _OptionTile(
                    index: index,
                    option: widget.question.options[index],
                    isUserAnswer: widget.answer.userAnswer == index,
                    isCorrectAnswer: widget.answer.correctAnswer == index,
                    isCorrect: widget.answer.isCorrect,
                    questionType: widget.question.type, // 🆕 TAMBAH INI
                    optionScore: optionScores?[index], // 🆕 TAMBAH INI
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Explanation toggle
          InkWell(
            onTap: () {
              setState(() => _showExplanation = !_showExplanation);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                border: Border(
                  top: BorderSide(color: AppColors.border.withOpacity(0.5)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _showExplanation
                          ? 'Sembunyikan Pembahasan'
                          : 'Lihat Pembahasan',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _showExplanation
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // Explanation content
          if (_showExplanation)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.02),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Short explanation
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Penjelasan Singkat',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.question.explanationShort.isNotEmpty
                              ? widget.question.explanationShort
                              : 'Penjelasan tidak tersedia',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Full explanation (jika ada)
                  if (hasFullExplanation) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        setState(
                          () => _showFullExplanation = !_showFullExplanation,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_stories,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _showFullExplanation
                                    ? 'Sembunyikan Pembahasan Lengkap'
                                    : 'Lihat Pembahasan Lengkap',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(
                              _showFullExplanation
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: AppColors.warning,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showFullExplanation)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          widget.question.explanationFull,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ==============================================================================
// CATEGORY BADGE
// ==============================================================================

class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  Color get _color {
    switch (category.toUpperCase()) {
      case 'TWK':
        return AppColors.blue;
      case 'TIU':
        return AppColors.warning;
      case 'TKP':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ==============================================================================
// OPTION TILE
// ==============================================================================

class _OptionTile extends StatelessWidget {
  final int index;
  final String option;
  final bool isUserAnswer;
  final bool isCorrectAnswer;
  final bool isCorrect;
  final QuestionType questionType; // 🆕 TAMBAH INI
  final int? optionScore; // 🆕 TAMBAH INI

  const _OptionTile({
    required this.index,
    required this.option,
    required this.isUserAnswer,
    required this.isCorrectAnswer,
    required this.isCorrect,
    required this.questionType, // 🆕 TAMBAH INI
    this.optionScore, // 🆕 TAMBAH INI
  });

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    Color? borderColor;
    IconData? icon;
    Widget? scoreWidget;

    // 🆕 LOGIKA BARU: Bedakan objective vs likert
    if (questionType == QuestionType.likert) {
      // LIKERT: Tampilkan skor tiap opsi dengan warna gradasi
      if (isUserAnswer) {
        backgroundColor = _getLikertColor(optionScore).withOpacity(0.15);
        borderColor = _getLikertColor(optionScore);
        icon = Icons.person; // User's choice
      } else {
        backgroundColor = _getLikertColor(optionScore).withOpacity(0.05);
        borderColor = _getLikertColor(optionScore).withOpacity(0.3);
      }

      // Score badge untuk likert
      scoreWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _getLikertColor(optionScore),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${optionScore ?? 0}',
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      // OBJECTIVE/YESNO: Logika lama (hijau untuk benar, merah untuk salah)
      if (isCorrectAnswer) {
        backgroundColor = AppColors.success.withOpacity(0.1);
        borderColor = AppColors.success;
        icon = Icons.check_circle;
      } else if (isUserAnswer && !isCorrect) {
        backgroundColor = AppColors.error.withOpacity(0.1);
        borderColor = AppColors.error;
        icon = Icons.cancel;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: borderColor != null ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Label (A, B, C, D, E)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: borderColor?.withOpacity(0.1) ?? AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor ?? AppColors.border,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + index),
                style: AppTextStyles.labelMedium.copyWith(
                  color: borderColor ?? AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Option text
          Expanded(
            child: Text(
              option,
              style: AppTextStyles.bodyMedium.copyWith(
                color: borderColor ?? AppColors.textPrimary,
                fontWeight: borderColor != null && isUserAnswer
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),

          // Icon atau score widget
          if (scoreWidget != null) ...[
            const SizedBox(width: 8),
            scoreWidget,
          ] else if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, color: borderColor, size: 22),
          ],
        ],
      ),
    );
  }

  // 🆕 Helper untuk warna likert berdasarkan skor
  Color _getLikertColor(int? score) {
    if (score == null) return AppColors.textSecondary;

    switch (score) {
      case 1:
        return const Color(0xFFFF4B4B); // Red (rendah)
      case 2:
        return const Color(0xFFFF9600); // Orange
      case 3:
        return const Color(0xFFFFC800); // Yellow (netral)
      case 4:
        return const Color(0xFF58CC02); // Light green
      case 5:
        return const Color(0xFF48B002); // Green (tinggi)
      default:
        return AppColors.textSecondary;
    }
  }
}

// ==============================================================================
// MOBILE NAVIGATION
// ==============================================================================

class _MobileNavigation extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onDone;

  const _MobileNavigation({
    required this.currentPage,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous button
            Expanded(
              child: DuolingoButton.secondary(
                text: 'SEBELUMNYA',
                onPressed: onPrevious,
              ),
            ),
            const SizedBox(width: 12),
            // Next or Done button
            Expanded(
              flex: currentPage == totalPages - 1 ? 2 : 1,
              child: currentPage == totalPages - 1
                  ? DuolingoButton.primary(text: 'SELESAI', onPressed: onDone)
                  : DuolingoButton.primary(
                      text: 'SELANJUTNYA',
                      onPressed: onNext,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// DESKTOP BOTTOM ACTION
// ==============================================================================

class _DesktopBottomAction extends StatelessWidget {
  final VoidCallback onDone;

  const _DesktopBottomAction({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: DuolingoButton.primary(text: 'SELESAI REVIEW', onPressed: onDone),
    );
  }
}

// ==============================================================================
// BRUTALIST BUTTON EXTENSIONS (if not exist)
// ==============================================================================

enum IconPosition { left, right }

extension DuolingoButtonExtension on DuolingoButton {
  static Widget primary({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    IconPosition iconPosition = IconPosition.left,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null
            ? AppColors.primary
            : const Color(0xFFCCCCCC), // ✅ Abu-abu kalau disabled
        foregroundColor: onPressed != null
            ? Colors.white
            : const Color(0xFF999999), // ✅ Text abu-abu kalau disabled
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: onPressed != null
                ? AppColors.primary
                : const Color(0xFFBBBBBB), // ✅ Border abu-abu
            width: 2,
          ),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null && iconPosition == IconPosition.left) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (icon != null && iconPosition == IconPosition.right) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 20),
          ],
        ],
      ),
    );
  }

  static Widget secondary({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    IconPosition iconPosition = IconPosition.left,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border, width: 2),
        ),
        side: BorderSide(color: AppColors.border, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null && iconPosition == IconPosition.left) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (icon != null && iconPosition == IconPosition.right) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 20),
          ],
        ],
      ),
    );
  }
}
