// lib/features/exam/widgets/question_card.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';

/// Question Card Widget - Duolingo Style
///
/// Modern card dengan:
/// - Smooth entrance animation
/// - Clean visual hierarchy
/// - Responsive typography
/// - Subtle depth effect
/// - Progress indicator
class QuestionCard extends StatefulWidget {
  final String question;
  final String category;
  final String difficulty;
  final int questionNumber;
  final int totalQuestions;

  const QuestionCard({
    super.key,
    required this.question,
    required this.category,
    required this.difficulty,
    required this.questionNumber,
    required this.totalQuestions,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _categoryColor {
    switch (widget.category.toUpperCase()) {
      case 'TWK':
        return AppColors.twk;
      case 'TIU':
        return AppColors.tiu;
      case 'TKP':
        return AppColors.tkp;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: _categoryColor.withOpacity(0.08),
                offset: const Offset(0, 8),
                blurRadius: 24,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressBar(),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildQuestionText(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = widget.questionNumber / widget.totalQuestions;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: progress),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: AppColors.border.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation(_categoryColor),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _QuestionNumberBadge(
          number: widget.questionNumber,
          total: widget.totalQuestions,
          color: _categoryColor,
        ),
        const SizedBox(width: AppSpacing.sm),
        _CategoryBadge(category: widget.category, color: _categoryColor),
        const Spacer(),
        _DifficultyIndicator(difficulty: widget.difficulty),
      ],
    );
  }

  Widget _buildQuestionText() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive font size
        final fontSize = constraints.maxWidth > 600 ? 22.0 : 20.0;

        return Text(
          widget.question,
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
            fontSize: fontSize,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}

// ==============================================================================
// QUESTION NUMBER BADGE
// ==============================================================================

class _QuestionNumberBadge extends StatelessWidget {
  final int number;
  final int total;
  final Color color;

  const _QuestionNumberBadge({
    required this.number,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.quiz_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$number/$total',
            style: AppTextStyles.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
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
  final Color color;

  const _CategoryBadge({required this.category, required this.color});

  IconData get _icon {
    switch (category.toUpperCase()) {
      case 'TWK':
        return Icons.balance_rounded;
      case 'TIU':
        return Icons.psychology_rounded;
      case 'TKP':
        return Icons.favorite_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            category.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// DIFFICULTY INDICATOR
// ==============================================================================

class _DifficultyIndicator extends StatelessWidget {
  final String difficulty;

  const _DifficultyIndicator({required this.difficulty});

  _DifficultyConfig get _config {
    switch (difficulty.toLowerCase()) {
      case 'mudah':
        return _DifficultyConfig(
          color: AppColors.success,
          icon: Icons.sentiment_satisfied_rounded,
          label: 'Mudah',
          dotCount: 1,
        );
      case 'sedang':
        return _DifficultyConfig(
          color: AppColors.warning,
          icon: Icons.sentiment_neutral_rounded,
          label: 'Sedang',
          dotCount: 2,
        );
      case 'sulit':
        return _DifficultyConfig(
          color: AppColors.error,
          icon: Icons.sentiment_very_dissatisfied_rounded,
          label: 'Sulit',
          dotCount: 3,
        );
      default:
        return _DifficultyConfig(
          color: AppColors.neutral,
          icon: Icons.help_outline_rounded,
          label: difficulty,
          dotCount: 0,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: config.color.withOpacity(0.4), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.color),
          const SizedBox(width: 4),
          if (config.dotCount > 0) ...[
            Row(
              children: List.generate(
                3,
                (index) => Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: index < config.dotCount
                        ? config.color
                        : config.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ] else ...[
            Text(
              config.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: config.color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DifficultyConfig {
  final Color color;
  final IconData icon;
  final String label;
  final int dotCount;

  const _DifficultyConfig({
    required this.color,
    required this.icon,
    required this.label,
    required this.dotCount,
  });
}
