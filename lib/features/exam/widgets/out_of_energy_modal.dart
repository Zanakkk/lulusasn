// lib/features/exam/widgets/out_of_energy_modal.dart

import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';

/// Out of Energy Modal
///
/// Blocking modal saat energy habis
/// Features:
/// - Energy countdown timer
/// - Watch ad option (rewarded)
/// - Refill with diamond
/// - Upgrade to premium CTA
/// - Duolingo-style fun design
class OutOfEnergyModal extends StatelessWidget {
  final int currentEnergy;
  final int maxEnergy;
  final Duration timeUntilNextEnergy;
  final VoidCallback? onWatchAd;
  final VoidCallback? onRefillDiamond;
  final VoidCallback? onUpgradePremium;
  final VoidCallback? onWait;

  const OutOfEnergyModal({
    super.key,
    required this.currentEnergy,
    required this.maxEnergy,
    required this.timeUntilNextEnergy,
    this.onWatchAd,
    this.onRefillDiamond,
    this.onUpgradePremium,
    this.onWait,
  });

  static Future<void> show({
    required BuildContext context,
    required int currentEnergy,
    required int maxEnergy,
    required Duration timeUntilNextEnergy,
    VoidCallback? onWatchAd,
    VoidCallback? onRefillDiamond,
    VoidCallback? onUpgradePremium,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OutOfEnergyModal(
        currentEnergy: currentEnergy,
        maxEnergy: maxEnergy,
        timeUntilNextEnergy: timeUntilNextEnergy,
        onWatchAd: onWatchAd,
        onRefillDiamond: onRefillDiamond,
        onUpgradePremium: onUpgradePremium,
        onWait: () => Navigator.of(context).pop(),
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.error,
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.bolt_outlined,
                size: 48,
                color: AppColors.error,
              ),
            ),

            SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              'Energy Habis!',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: AppSpacing.sm),

            // Energy display
            _EnergyDisplay(
              current: currentEnergy,
              max: maxEnergy,
            ),

            SizedBox(height: AppSpacing.md),

            // Countdown
            Text(
              '+1 dalam ${_formatTime(timeUntilNextEnergy)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            SizedBox(height: AppSpacing.xl),

            // Watch ad option (PRIMARY CTA)
            if (onWatchAd != null)
              _OptionCard(
                icon: Icons.play_circle_outline_rounded,
                iconColor: AppColors.success,
                title: 'Tonton Iklan 30 Detik',
                subtitle: '+1 Energy GRATIS',
                onTap: onWatchAd,
                isPrimary: true,
              ),

            SizedBox(height: AppSpacing.md),

            // Alternative options
            Text(
              'Atau pilih:',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            SizedBox(height: AppSpacing.md),

            // Refill with diamond
            if (onRefillDiamond != null)
              _SmallOption(
                icon: Icons.diamond_outlined,
                label: 'Refill dengan 1 Diamond',
                onTap: onRefillDiamond,
              ),

            SizedBox(height: AppSpacing.sm),

            // Wait
            if (onWait != null)
              _SmallOption(
                icon: Icons.schedule_outlined,
                label: 'Tunggu ${_formatTime(timeUntilNextEnergy)}',
                onTap: onWait,
              ),

            SizedBox(height: AppSpacing.xl),

            // Premium upsell
            if (onUpgradePremium != null)
              _PremiumUpsell(onTap: onUpgradePremium),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// ENERGY DISPLAY
// ==============================================================================

class _EnergyDisplay extends StatelessWidget {
  final int current;
  final int max;

  const _EnergyDisplay({
    required this.current,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(max, (index) {
        final isFilled = index < current;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            isFilled ? Icons.favorite : Icons.favorite_border,
            color: isFilled ? AppColors.error : AppColors.neutral,
            size: 32,
          ),
        );
      }),
    );
  }
}

// ==============================================================================
// OPTION CARD (PRIMARY CTA)
// ==============================================================================

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _OptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: iconColor,
            width: 3,
          ),
          boxShadow: isPrimary
              ? [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 32,
              ),
            ),

            SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              color: iconColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// SMALL OPTION
// ==============================================================================

class _SmallOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SmallOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// PREMIUM UPSELL
// ==============================================================================

class _PremiumUpsell extends StatelessWidget {
  final VoidCallback? onTap;

  const _PremiumUpsell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.primary,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'UPGRADE PREMIUM',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSpacing.md),

            _PremiumFeature(text: '• Energy UNLIMITED'),
            _PremiumFeature(text: '• TANPA IKLAN'),
            _PremiumFeature(text: '• Pembahasan lengkap'),

            SizedBox(height: AppSpacing.md),

            Text(
              'Rp 49.000/bulan',
              style: AppTextStyles.headingMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumFeature extends StatelessWidget {
  final String text;

  const _PremiumFeature({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}