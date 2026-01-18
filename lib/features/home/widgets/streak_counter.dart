// lib/features/home/widgets/streak_counter.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/features/home/models/streak_model.dart';

/// Duolingo-Style Streak Counter Widget
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
    final nextMilestone = streak.getNextMilestone();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderPrimary, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _buildFireIcon(status),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Streak',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${streak.current} hari',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),

            const SizedBox(height: 20),

            // Progress ke milestone
            if (nextMilestone != null) ...[
              _buildMilestoneProgress(nextMilestone),
              const SizedBox(height: 12),
            ] else ...[
              _buildMaxStreak(),
              const SizedBox(height: 12),
            ],

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
    Color bgColor;
    Color iconColor;

    switch (status) {
      case StreakStatus.active:
        icon = Icons.local_fire_department;
        bgColor = const Color(0xFFFFF4E6);
        iconColor = AppColors.orange;
        break;
      case StreakStatus.atRisk:
        icon = Icons.local_fire_department_outlined;
        bgColor = const Color(0xFFFFF7ED);
        iconColor = AppColors.warning;
        break;
      case StreakStatus.broken:
        icon = Icons.heart_broken;
        bgColor = AppColors.gray100;
        iconColor = AppColors.gray400;
        break;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 28,
      ),
    );
  }

  // ============================================================================
  // STATUS BADGE
  // ============================================================================

  Widget _buildStatusBadge(StreakStatus status) {
    String text;
    Color bgColor;
    String emoji;

    switch (status) {
      case StreakStatus.active:
        text = 'Aktif';
        emoji = '🔥';
        bgColor = AppColors.success;
        break;
      case StreakStatus.atRisk:
        text = 'Bahaya';
        emoji = '⚠️';
        bgColor = AppColors.warning;
        break;
      case StreakStatus.broken:
        text = 'Putus';
        emoji = '💔';
        bgColor = AppColors.gray400;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MILESTONE PROGRESS
  // ============================================================================

  Widget _buildMilestoneProgress(StreakMilestone milestone) {
    final progress = streak.progressToNextMilestone();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Target ${milestone.days} hari',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${streak.current}/${milestone.days}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.gray100,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.orange, Color(0xFFFFB800)],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Reward preview
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Text('🎁', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hadiah: ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '+${milestone.xpReward} XP',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
              if (milestone.diamondReward > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '+${milestone.diamondReward} 💎',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.purple,
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
  // MAX STREAK
  // ============================================================================

  Widget _buildMaxStreak() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Semua milestone tercapai! 🎉',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.gray800,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.military_tech,
            size: 16,
            color: AppColors.gray600,
          ),
          const SizedBox(width: 6),
          Text(
            'Rekor: ${streak.longest} hari',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}