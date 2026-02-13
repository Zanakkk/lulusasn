// lib/features/tryout/screens/exam_review_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/constants/text_styles.dart';

/// Exam Review Screen - Review exam results with detailed feedback
///
/// Features:
/// - Score summary with breakdown
/// - Question-by-question review with explanations
/// - Correct/Wrong/Unanswered filter
/// - Category performance stats
/// - Expandable question cards
/// - Professional Duolingo-style design
/// - Responsive layout
class ExamReviewScreen extends StatefulWidget {
  final String resultId;

  const ExamReviewScreen({super.key, required this.resultId});

  @override
  State<ExamReviewScreen> createState() => _ExamReviewScreenState();
}

class _ExamReviewScreenState extends State<ExamReviewScreen> {
  bool _isLoading = true;
  String? _error;

  // Result data
  Map<String, dynamic>? _resultData;
  List<Map<String, dynamic>> _questions = [];

  // Filter state
  String _filter = 'all'; // 'all', 'correct', 'wrong', 'unanswered'

  @override
  void initState() {
    super.initState();
    _loadReviewData();
  }

  Future<void> _loadReviewData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load exam result
      final resultDoc = await FirebaseFirestore.instance
          .collection('exam_results')
          .doc(widget.resultId)
          .get();

      if (!resultDoc.exists) {
        throw Exception('Hasil ujian tidak ditemukan');
      }

      final resultData = resultDoc.data()!;

      // Load questions from tryout
      final subtestId = resultData['subtestId'] as String;
      final tryoutId = resultData['tryoutId'] as String;

      final tryoutDoc = await FirebaseFirestore.instance
          .collection('tryouts')
          .doc(tryoutId)
          .get();

      if (!tryoutDoc.exists) {
        throw Exception('Data tryout tidak ditemukan');
      }

      final tryoutData = tryoutDoc.data()!;
      final subtests = tryoutData['subtests'] as List<dynamic>;

      // Find the correct subtest
      final subtest = subtests.firstWhere(
        (s) => (s['id'] ?? s['name']) == subtestId,
        orElse: () => null,
      );

      if (subtest == null) {
        throw Exception('Subtest tidak ditemukan');
      }

      final questionsList = subtest['questions'] as List<dynamic>;
      final answers = resultData['answers'] as List<dynamic>;

      // Merge questions with user answers
      final mergedQuestions = <Map<String, dynamic>>[];
      for (int i = 0; i < questionsList.length; i++) {
        final question = Map<String, dynamic>.from(questionsList[i]);
        final answer = answers[i] as Map<String, dynamic>;

        mergedQuestions.add({
          ...question,
          'userAnswer': answer['userAnswer'],
          'isCorrect': answer['isCorrect'],
        });
      }

      setState(() {
        _resultData = resultData;
        _questions = mergedQuestions;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredQuestions {
    if (_filter == 'all') return _questions;

    return _questions.where((q) {
      final isCorrect = q['isCorrect'] as bool;
      final userAnswer = q['userAnswer'];

      if (_filter == 'correct') return isCorrect;
      if (_filter == 'wrong') return !isCorrect && userAnswer != null;
      if (_filter == 'unanswered') return userAnswer == null;

      return true;
    }).toList();
  }

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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: _buildResponsiveLayout(),
    );
  }

  Widget _buildResponsiveLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1024;

        if (isDesktop) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  // ==========================================================================
  // MOBILE LAYOUT
  // ==========================================================================
  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildScoreCard(),
              _buildCategoryStats(),
              _buildFilterTabs(),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
        _buildQuestionList(),
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }

  // ==========================================================================
  // DESKTOP LAYOUT
  // ==========================================================================
  Widget _buildDesktopLayout() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverPadding(
          padding: EdgeInsets.all(AppSpacing.xl),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN - Stats (sticky-like)
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildScoreCard(),
                          SizedBox(height: AppSpacing.lg),
                          _buildCategoryStats(),
                        ],
                      ),
                    ),

                    SizedBox(width: AppSpacing.xl),

                    // RIGHT COLUMN - Filter + Questions
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildFilterTabs(),
                          SizedBox(height: AppSpacing.lg),
                          // Questions list
                          ..._filteredQuestions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final question = entry.value;
                            final globalIndex = _questions.indexOf(question);
                            return _buildQuestionItem(
                              question,
                              globalIndex + 1,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }

  // ==========================================================================
  // APP BAR
  // ==========================================================================
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFF58CC02),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Review Ujian',
        style: AppTextStyles.headingMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded, color: Colors.white),
          onPressed: () {
            // TODO: Share functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Fitur berbagi segera hadir!'),
                backgroundColor: const Color(0xFF1CB0F6),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================================================
  // SCORE CARD
  // ==========================================================================
  Widget _buildScoreCard() {
    final score = _resultData?['score'] ?? 0;
    final correctAnswers = _resultData?['correctAnswers'] ?? 0;
    final wrongAnswers = _resultData?['wrongAnswers'] ?? 0;
    final unanswered = _resultData?['unanswered'] ?? 0;
    final totalQuestions = _resultData?['totalQuestions'] ?? 0;

    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;

    if (score >= 80) {
      scoreColor = const Color(0xFF58CC02);
      scoreLabel = 'Luar Biasa!';
      scoreIcon = Icons.emoji_events_rounded;
    } else if (score >= 60) {
      scoreColor = const Color(0xFF1CB0F6);
      scoreLabel = 'Bagus!';
      scoreIcon = Icons.thumb_up_rounded;
    } else if (score >= 40) {
      scoreColor = const Color(0xFFFF9600);
      scoreLabel = 'Cukup Baik';
      scoreIcon = Icons.psychology_rounded;
    } else {
      scoreColor = const Color(0xFFFF4B4B);
      scoreLabel = 'Perlu Belajar Lagi';
      scoreIcon = Icons.auto_awesome_rounded;
    }

    return Container(
      margin: EdgeInsets.all(AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor, scoreColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scoreColor.withOpacity(0.5), width: 3),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(scoreIcon, size: 48, color: Colors.white),
          ),

          SizedBox(height: AppSpacing.lg),

          // Score
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),

          Text(
            scoreLabel,
            style: AppTextStyles.headingMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(height: AppSpacing.xl),

          // Breakdown
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreStat(
                  icon: Icons.check_circle_rounded,
                  label: 'Benar',
                  value: '$correctAnswers',
                  color: Colors.white,
                ),
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildScoreStat(
                  icon: Icons.cancel_rounded,
                  label: 'Salah',
                  value: '$wrongAnswers',
                  color: Colors.white,
                ),
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildScoreStat(
                  icon: Icons.radio_button_unchecked_rounded,
                  label: 'Kosong',
                  value: '$unanswered',
                  color: Colors.white,
                ),
              ],
            ),
          ),

          SizedBox(height: AppSpacing.md),

          // Total questions
          Text(
            'Total: $totalQuestions Soal',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // CATEGORY STATS
  // ==========================================================================
  Widget _buildCategoryStats() {
    final categoryScores =
        _resultData?['categoryScores'] as Map<String, dynamic>? ?? {};

    if (categoryScores.isEmpty) return const SizedBox();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFF9333EA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFF9333EA),
                  size: 24,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Text(
                'Performa Per Kategori',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          ...categoryScores.entries.map((entry) {
            final category = entry.key;
            final data = entry.value as Map<String, dynamic>;
            final correct = data['correct'] ?? 0;
            final total = data['total'] ?? 1;
            final percentage = data['percentage'] ?? 0;

            Color barColor;
            if (percentage >= 80) {
              barColor = const Color(0xFF58CC02);
            } else if (percentage >= 60) {
              barColor = const Color(0xFF1CB0F6);
            } else if (percentage >= 40) {
              barColor = const Color(0xFFFF9600);
            } else {
              barColor = const Color(0xFFFF4B4B);
            }

            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$correct/$total',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF777777),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E5E5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage / 100,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: barColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ==========================================================================
  // FILTER TABS
  // ==========================================================================
  Widget _buildFilterTabs() {
    final correctCount = _questions.where((q) => q['isCorrect'] == true).length;
    final wrongCount = _questions
        .where((q) => q['isCorrect'] == false && q['userAnswer'] != null)
        .length;
    final unansweredCount = _questions
        .where((q) => q['userAnswer'] == null)
        .length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 3),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton(
              label: 'Semua',
              count: _questions.length,
              value: 'all',
              color: const Color(0xFF1CB0F6),
            ),
          ),
          Expanded(
            child: _buildFilterButton(
              label: 'Benar',
              count: correctCount,
              value: 'correct',
              color: const Color(0xFF58CC02),
            ),
          ),
          Expanded(
            child: _buildFilterButton(
              label: 'Salah',
              count: wrongCount,
              value: 'wrong',
              color: const Color(0xFFFF4B4B),
            ),
          ),
          Expanded(
            child: _buildFilterButton(
              label: 'Kosong',
              count: unansweredCount,
              value: 'unanswered',
              color: const Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required int count,
    required String value,
    required Color color,
  }) {
    final isActive = _filter == value;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.white : color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? Colors.white.withOpacity(0.9)
                    : const Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // QUESTION LIST
  // ==========================================================================
  Widget _buildQuestionList() {
    final questions = _filteredQuestions;

    if (questions.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: EdgeInsets.all(AppSpacing.lg),
          padding: EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E5E5), width: 3),
          ),
          child: Column(
            children: [
              Icon(
                Icons.filter_list_off_rounded,
                size: 48,
                color: const Color(0xFF999999),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Tidak ada soal',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: const Color(0xFF999999),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final question = questions[index];
          final globalIndex = _questions.indexOf(question);
          return _buildQuestionItem(question, globalIndex + 1);
        }, childCount: questions.length),
      ),
    );
  }

  Widget _buildQuestionItem(Map<String, dynamic> question, int number) {
    final isCorrect = question['isCorrect'] as bool? ?? false;
    final userAnswer = question['userAnswer'] as int?;
    final correctAnswer = question['correctIndex'] as int? ?? 0;
    final questionText = question['question'] as String? ?? '';
    final options = question['options'] as List<dynamic>? ?? [];
    final category = question['category'] as String? ?? '';
    final difficulty = question['difficulty'] as String? ?? 'medium';
    final explanationShort = question['explanationShort'] as String? ?? '';
    final explanationFull = question['explanationFull'] as String? ?? '';

    Color statusColor;
    String statusText;
    String statusEmoji;

    if (userAnswer == null) {
      statusColor = const Color(0xFF999999);
      statusText = 'Tidak Dijawab';
      statusEmoji = '⚪';
    } else if (isCorrect) {
      statusColor = const Color(0xFF58CC02);
      statusText = 'Jawaban Benar!';
      statusEmoji = '🎉';
    } else {
      statusColor = const Color(0xFFFF4B4B);
      statusText = 'Jawaban Salah';
      statusEmoji = '💭';
    }

    Color difficultyColor;
    String difficultyLabel;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        difficultyColor = const Color(0xFF58CC02);
        difficultyLabel = 'Mudah';
        break;
      case 'hard':
        difficultyColor = const Color(0xFFFF4B4B);
        difficultyLabel = 'Sulit';
        break;
      default:
        difficultyColor = const Color(0xFF1CB0F6);
        difficultyLabel = 'Sedang';
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 3),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: statusColor.withOpacity(0.05),
          highlightColor: statusColor.withOpacity(0.03),
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: false,
          trailing: const SizedBox.shrink(), // ← FIX: Remove default arrow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.15),
                  statusColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
            ),
            child: Row(
              children: [
                // Question number badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.md),

                // Status & Question
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            statusEmoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (category.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF9333EA,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF9333EA),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: difficultyColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                difficultyLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: difficultyColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: AppSpacing.sm),
                      // Question preview
                      Text(
                        questionText,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: const Color(0xFF4B4B4B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: AppSpacing.sm),

                // Custom arrow icon
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: statusColor,
                  size: 28,
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Options (NO duplicate question!)
                  ...List.generate(options.length, (index) {
                    final optionLabel = String.fromCharCode(65 + index);
                    final optionText = options[index].toString();
                    final isUserAnswer = userAnswer == index;
                    final isCorrectAnswer = correctAnswer == index;

                    Color? optionColor;
                    Color? optionBgColor;
                    IconData? optionIcon;
                    String? optionBadge;

                    if (isCorrectAnswer) {
                      optionColor = const Color(0xFF58CC02);
                      optionBgColor = const Color(0xFF58CC02).withOpacity(0.12);
                      optionIcon = Icons.check_circle_rounded;
                      optionBadge = '✓ Jawaban Benar';
                    } else if (isUserAnswer && !isCorrect) {
                      optionColor = const Color(0xFFFF4B4B);
                      optionBgColor = const Color(0xFFFF4B4B).withOpacity(0.12);
                      optionIcon = Icons.cancel_rounded;
                      optionBadge = '✗ Jawaban Anda';
                    }

                    return Container(
                      margin: EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: optionBgColor ?? Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: optionColor ?? const Color(0xFFE5E5E5),
                          width: optionColor != null ? 3 : 2,
                        ),
                        boxShadow: optionColor != null
                            ? [
                                BoxShadow(
                                  color: optionColor.withOpacity(0.2),
                                  offset: const Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (optionBadge != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: optionColor!.withOpacity(0.15),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(11),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    optionIcon,
                                    size: 14,
                                    color: optionColor,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    optionBadge,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: optionColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: optionColor != null
                                        ? LinearGradient(
                                            colors: [
                                              optionColor,
                                              optionColor.withOpacity(0.8),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: optionColor == null
                                        ? const Color(0xFFE5E5E5)
                                        : null,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      optionLabel,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: optionColor != null
                                            ? Colors.white
                                            : const Color(0xFF777777),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    optionText,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: const Color(0xFF1F1F1F),
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Explanation
                  if (explanationShort.isNotEmpty ||
                      explanationFull.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1CB0F6).withOpacity(0.1),
                            const Color(0xFF1CB0F6).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF1CB0F6).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1CB0F6),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF1CB0F6,
                                      ).withOpacity(0.3),
                                      offset: const Offset(0, 4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.lightbulb_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                'Pembahasan',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1CB0F6),
                                ),
                              ),
                            ],
                          ),
                          if (explanationShort.isNotEmpty) ...[
                            SizedBox(height: AppSpacing.md),
                            Container(
                              padding: EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF1CB0F6,
                                  ).withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF1CB0F6,
                                      ).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Ringkasan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1CB0F6),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: AppSpacing.sm),
                                  Text(
                                    explanationShort,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      height: 1.6,
                                      color: const Color(0xFF4B4B4B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (explanationFull.isNotEmpty) ...[
                            SizedBox(height: AppSpacing.sm),
                            Container(
                              padding: EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF1CB0F6,
                                  ).withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF9333EA,
                                      ).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Penjelasan Lengkap',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF9333EA),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: AppSpacing.sm),
                                  Text(
                                    explanationFull,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      height: 1.6,
                                      color: const Color(0xFF4B4B4B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // LOADING & ERROR
  // ==========================================================================
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF58CC02)),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Memuat Hasil...',
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.w800,
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
              'Terjadi Kesalahan',
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
              ),
              child: const Text(
                'KEMBALI',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
