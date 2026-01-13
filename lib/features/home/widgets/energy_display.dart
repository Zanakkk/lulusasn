// lib/features/home/widgets/energy_display.dart

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/features/home/models/energy_model.dart';

/// Energy Display Widget
/// 
/// Menampilkan:
/// - Current energy dengan hearts visual
/// - Countdown timer untuk next energy
/// - Progress bar regeneration
/// - Max energy indicator
class EnergyDisplay extends StatefulWidget {
  final EnergyModel energy;
  final bool isPremium;
  final VoidCallback? onTap;

  const EnergyDisplay({
    super.key,
    required this.energy,
    this.isPremium = false,
    this.onTap,
  });

  @override
  State<EnergyDisplay> createState() => _EnergyDisplayState();
}

class _EnergyDisplayState extends State<EnergyDisplay> {
  Timer? _timer;
  int _currentEnergy = 0;
  int _minutesUntilNext = 0;
  int _secondsUntilNext = 0;

  @override
  void initState() {
    super.initState();
    _updateEnergy();
    _startTimer();
  }

  @override
  void didUpdateWidget(EnergyDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.energy != widget.energy) {
      _updateEnergy();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateEnergy();
        });
      }
    });
  }

  void _updateEnergy() {
    _currentEnergy = widget.energy.calculateCurrentEnergy();

    if (_currentEnergy < widget.energy.max) {
      final minutesUntilNext = widget.energy.minutesUntilNext();
      final now = DateTime.now();
      final lastRegen = widget.energy.lastRegen;
      final totalSeconds = minutesUntilNext * 60;
      final elapsedSeconds = now.difference(lastRegen).inSeconds % (widget.energy.regenRate * 60);
      final remainingSeconds = totalSeconds - (elapsedSeconds % (widget.energy.regenRate * 60));

      _minutesUntilNext = remainingSeconds ~/ 60;
      _secondsUntilNext = remainingSeconds % 60;
    } else {
      _minutesUntilNext = 0;
      _secondsUntilNext = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPremium) {
      return _buildPremiumEnergy();
    }
    return _buildFreeEnergy();
  }

  // ============================================================================
  // PREMIUM ENERGY (Unlimited)
  // ============================================================================

  Widget _buildPremiumEnergy() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: AppSpacing.paddingMD,
        decoration: BoxDecoration(
          color: AppColors.gold,
          border: Border.all(color: AppColors.black, width: AppSpacing.borderThick),
          boxShadow: const [
            BoxShadow(
              color: AppColors.black,
              offset: AppSpacing.shadowMedium,
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: AppSpacing.paddingSM,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.black, width: AppSpacing.borderThin),
              ),
              child: const Icon(
                Icons.flash_on,
                color: AppColors.gold,
                size: AppSpacing.iconMD,
              ),
            ),
            AppSpacing.horizontalGapMD,
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UNLIMITED',
                    style: AppTextStyles.energyCount.copyWith(
                      color: AppColors.black,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'Premium Member',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.black,
                border: Border.all(color: AppColors.black, width: AppSpacing.borderThin),
              ),
              child: Text(
                '⭐ PRO',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // FREE ENERGY (With Timer)
  // ============================================================================

  Widget _buildFreeEnergy() {
    final isFull = _currentEnergy >= widget.energy.max;
    final percentage = _currentEnergy / widget.energy.max;
    final color = AppColors.getEnergyColor(percentage);

    return GestureDetector(
      onTap: widget.onTap,
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
            // Header
            Row(
              children: [
                Container(
                  padding: AppSpacing.paddingSM,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: AppColors.black, width: AppSpacing.borderThin),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppColors.white,
                    size: AppSpacing.iconMD,
                  ),
                ),
                AppSpacing.horizontalGapMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENERGY',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$_currentEnergy/${widget.energy.max}',
                        style: AppTextStyles.energyCount.copyWith(
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isFull) _buildTimer(),
              ],
            ),

            AppSpacing.verticalGapMD,

            // Hearts Visual
            _buildHeartsVisual(color),

            if (!isFull) ...[
              AppSpacing.verticalGapMD,
              _buildProgressBar(color),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HEARTS VISUAL
  // ============================================================================

  Widget _buildHeartsVisual(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.energy.max, (index) {
        final isFilled = index < _currentEnergy;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Icon(
            isFilled ? Icons.favorite : Icons.favorite_border,
            color: isFilled ? color : AppColors.borderLight,
            size: 28,
          ),
        );
      }),
    );
  }

  // ============================================================================
  // TIMER
  // ============================================================================

  Widget _buildTimer() {
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
          const Icon(
            Icons.access_time,
            size: AppSpacing.iconXS,
            color: AppColors.black,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '+1 dalam ${_minutesUntilNext.toString().padLeft(2, '0')}:${_secondsUntilNext.toString().padLeft(2, '0')}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // PROGRESS BAR
  // ============================================================================

  Widget _buildProgressBar(Color color) {
    final progress = widget.energy.regenProgress();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Regenerasi energy...',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.verticalGapSM,
        Container(
          height: 8,
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
      ],
    );
  }
}