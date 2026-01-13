// lib/features/home/widgets/streak_counter.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/features/home/models/streak_model.dart';

/// Streak Counter Widget
///
/// Menampilkan:
/// - Fire icon dengan streak count
/// - Status indicator (active, at risk, broken)
/// - Progress ke next milestone
/// - Visual feedback berdasarkan status
class StreakCounter extends StatelessWidget {
  final StreakModel streak;
  final VoidCallback? onTap;

  const StreakCounter({
    super.key,
    required this.streak,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = streak.getStatus();
    final color = _getStreakColor(status);
    final nextMilestone = streak.getNextMilestone();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.paddingMD,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: AppColors.black, width: AppSpacing.borderThick),
          boxShadow: const [
            BoxShadow(
              color: AppColors.black,
              offset: AppSpacing.shadowMedium,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan fire icon
            Row(
              children: [
                _buildFireIcon(status),
                AppSpacing.horizontalGapMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STREAK',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${streak.current} HARI',
                        style: AppTextStyles.streakCount.copyWith(
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),

            AppSpacing.verticalGapMD,

            // Progress ke milestone
            if (nextMilestone != null) ...[
              _buildMilestoneProgress(nextMilestone, color),
            ] else ...[
              _buildMaxStreak(),
            ],

            AppSpacing.verticalGapSM,

            // Longest streak
            _buildLongestStreak(),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // FIRE ICON
  // ============================================================================

  Widget _buildFireIcon(StreakStatus status) {
    IconData icon;
    Color iconColor;

    switch (status) {
      case StreakStatus.active:
        icon = Icons.local_fire_department;
        iconColor = AppColors.streakFire;
        break;
      case StreakStatus.atRisk:
        icon = Icons.local_fire_department_outlined;
        iconColor = AppColors.warning;
        break;
      case StreakStatus.broken:
        icon = Icons.heart_broken;
        iconColor = AppColors.textTertiary;
        break;
    }

    return Container(
      padding: AppSpacing.paddingSM,
      decoration: BoxDecoration(
        color: iconColor,
        border: Border.all(color: AppColors.black, width: AppSpacing.borderThin),
      ),
      child: Icon(
        icon,
        color: AppColors.white,
        size: AppSpacing.iconMD,
      ),
    );
  }

  // ============================================================================
  // STATUS BADGE
  // ============================================================================

  Widget _buildStatusBadge(StreakStatus status) {
    String text;
    Color bgColor;

    switch (status) {
      case StreakStatus.active:
        text = '🔥 AKTIF';
        bgColor = AppColors.success;
        break;
      case StreakStatus.atRisk:
        text = '⚠️ BAHAYA';
        bgColor = AppColors.warning;
        break;
      case StreakStatus.broken:
        text = '💔 PUTUS';
        bgColor = AppColors.textTertiary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: AppColors.black, width: AppSpacing.borderThin),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================================
  // MILESTONE PROGRESS
  // ============================================================================

  Widget _buildMilestoneProgress(StreakMilestone milestone, Color color) {
    final progress = streak.progressToNextMilestone();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Target: ${milestone.days} hari',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${streak.current}/${milestone.days}',
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        AppSpacing.verticalGapSM,

        // Progress bar
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.borderLight.withOpacity(0.2),
            border: Border.all(color: AppColors.black, width: AppSpacing.borderThin),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                border: Border(
                  right: BorderSide(color: AppColors.black, width: AppSpacing.borderThin),
                ),
              ),
            ),
          ),
        ),
        AppSpacing.verticalGapSM,

        // Reward preview
        Container(
          padding: AppSpacing.paddingSM,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.black, width: AppSpacing.borderThin),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎁 Hadiah: ',
                style: AppTextStyles.labelSmall,
              ),
              Text(
                '+${milestone.xpReward} XP',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (milestone.diamondReward > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '+${milestone.diamondReward} 💎',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // MAX STREAK (All Milestones Achieved)
  // ============================================================================

  Widget _buildMaxStreak() {
    return Container(
      padding: AppSpacing.paddingSM,
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.2),
        border: Border.all(color: AppColors.gold, width: AppSpacing.borderThin),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.gold, size: AppSpacing.iconSM),
          AppSpacing.horizontalGapSM,
          Expanded(
            child: Text(
              'Semua milestone tercapai! 🎉',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // LONGEST STREAK
  // ============================================================================

  Widget _buildLongestStreak() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.black, width: AppSpacing.borderThin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.military_tech, size: AppSpacing.iconXS, color: AppColors.black),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Rekor: ${streak.longest} hari',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  Color _getStreakColor(StreakStatus status) {
    switch (status) {
      case StreakStatus.active:
        return AppColors.streakFire;
      case StreakStatus.atRisk:
        return AppColors.warning;
      case StreakStatus.broken:
        return AppColors.textTertiary;
    }
  }
}