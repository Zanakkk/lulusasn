// lib/features/exam/widgets/result_summary.dart

import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/features/exam/models/exam_result_model.dart';

/// Result Summary Widget
///
/// Duolingo-style result card:
/// - Big score display
/// - Accuracy breakdown
/// - XP earned
/// - Performance message
/// - Fun animations
class ResultSummary extends StatefulWidget {
  final ExamResultModel result;
  final VoidCallback? onReview;
  final VoidCallback? onContinue;

  const ResultSummary({
    super.key,
    required this.result,
    this.onReview,
    this.onContinue,
  });

  @override
  State<ResultSummary> createState() => _ResultSummaryState();
}

class _ResultSummaryState extends State<ResultSummary>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.border,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(0, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // Big score display
            ScaleTransition(
              scale: _scaleAnimation,
              child: _BigScoreDisplay(result: widget.result),
            ),

            SizedBox(height: AppSpacing.xl),

            // Stats grid
            _StatsGrid(result: widget.result),

            SizedBox(height: AppSpacing.xl),

            // Category breakdown
            _CategoryBreakdown(result: widget.result),

            SizedBox(height: AppSpacing.xl),

            // XP earned
            _XPEarned(result: widget.result),

            SizedBox(height: AppSpacing.xl),

            // Performance message
            _PerformanceMessage(result: widget.result),

            SizedBox(height: AppSpacing.xl),

            // Action buttons
            _ActionButtons(
              onReview: widget.onReview,
              onContinue: widget.onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// BIG SCORE DISPLAY
// ==============================================================================

class _BigScoreDisplay extends StatelessWidget {
  final ExamResultModel result;

  const _BigScoreDisplay({required this.result});

  Color get _scoreColor {
    if (result.accuracy >= 0.85) return AppColors.success;
    if (result.accuracy >= 0.7) return AppColors.primary;
    if (result.accuracy >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  IconData get _scoreIcon {
    if (result.accuracy >= 0.85) return Icons.emoji_events_rounded;
    if (result.accuracy >= 0.7) return Icons.celebration_rounded;
    if (result.accuracy >= 0.5) return Icons.thumb_up_rounded;
    return Icons.trending_up_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _scoreColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: _scoreColor,
              width: 3,
            ),
          ),
          child: Icon(
            _scoreIcon,
            size: 48,
            color: _scoreColor,
          ),
        ),

        SizedBox(height: AppSpacing.lg),

        // Score
        Text(
          '${result.correctCount}/${result.totalQuestions}',
          style: AppTextStyles.displayLarge.copyWith(
            color: _scoreColor,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: AppSpacing.xs),

        // Accuracy percentage
        Text(
          '${(result.accuracy * 100).toInt()}% Benar',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        SizedBox(height: AppSpacing.sm),

        // Grade
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: _scoreColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: _scoreColor,
              width: 2,
            ),
          ),
          child: Text(
            'Nilai: ${result.accuracyGrade}',
            style: AppTextStyles.headingSmall.copyWith(
              color: _scoreColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// STATS GRID
// ==============================================================================

class _StatsGrid extends StatelessWidget {
  final ExamResultModel result;

  const _StatsGrid({required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.access_time_rounded,
            label: 'Waktu',
            value: result.formattedDuration,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.speed_rounded,
            label: 'Rata-rata',
            value: '${result.averageTimePerQuestion.toInt()}s',
            color: AppColors.tiu,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.headingSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// CATEGORY BREAKDOWN
// ==============================================================================

class _CategoryBreakdown extends StatelessWidget {
  final ExamResultModel result;

  const _CategoryBreakdown({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.byCategory.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Per Kategori',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        ...result.byCategory.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: _CategoryRow(
              category: entry.key,
              stats: entry.value,
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final CategoryResult stats;

  const _CategoryRow({
    required this.category,
    required this.stats,
  });

  Color get _categoryColor {
    switch (category.toUpperCase()) {
      case 'TWK':
        return AppColors.twk;
      case 'TIU':
        return AppColors.tiu;
      case 'TKP':
        return AppColors.tkp;
      default:
        return AppColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Category badge
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: _categoryColor,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              category,
              style: AppTextStyles.labelMedium.copyWith(
                color: _categoryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        SizedBox(width: AppSpacing.md),

        // Progress bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${stats.correct}/${stats.total}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(stats.accuracy * 100).toInt()}%',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _categoryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: LinearProgressIndicator(
                  value: stats.accuracy,
                  backgroundColor: AppColors.neutral.withOpacity(0.2),
                  color: _categoryColor,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// XP EARNED
// ==============================================================================

class _XPEarned extends StatelessWidget {
  final ExamResultModel result;

  const _XPEarned({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.stars_rounded,
            color: AppColors.primary,
            size: 32,
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            '+${result.totalXP} XP',
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (result.bonusXP > 0) ...[
            SizedBox(width: AppSpacing.xs),
            Text(
              '(+${result.bonusXP} bonus)',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==============================================================================
// PERFORMANCE MESSAGE
// ==============================================================================

class _PerformanceMessage extends StatelessWidget {
  final ExamResultModel result;

  const _PerformanceMessage({required this.result});

  @override
  Widget build(BuildContext context) {
    return Text(
      result.performanceMessage,
      style: AppTextStyles.headingMedium.copyWith(
        color: AppColors.textPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ==============================================================================
// ACTION BUTTONS
// ==============================================================================

class _ActionButtons extends StatelessWidget {
  final VoidCallback? onReview;
  final VoidCallback? onContinue;

  const _ActionButtons({
    this.onReview,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onReview != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.all(AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  side: BorderSide(
                    color: AppColors.primary,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                'Lihat Pembahasan',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        if (onReview != null && onContinue != null)
          SizedBox(height: AppSpacing.md),

        if (onContinue != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                elevation: 0,
              ),
              child: Text(
                'Lanjutkan',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}