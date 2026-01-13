// lib/features/home/widgets/quick_exam_button.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';

/// Quick Exam Button Widget
///
/// Tombol CTA utama untuk mulai ujian
/// Features:
/// - Animated hover effect
/// - Icon + text layout
/// - Multiple variants (primary, disabled, loading)
/// - Responsive sizing
class QuickExamButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final String? customLabel;
  final IconData? customIcon;
  final QuickExamButtonVariant variant;

  const QuickExamButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.customLabel,
    this.customIcon,
    this.variant = QuickExamButtonVariant.primary,
  });

  @override
  State<QuickExamButton> createState() => _QuickExamButtonState();
}

class _QuickExamButtonState extends State<QuickExamButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = !widget.isDisabled && !widget.isLoading;
    final color = _getColor();
    final bgColor = _getBgColor();

    return GestureDetector(
      onTapDown: isInteractive ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isInteractive ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isInteractive ? () => setState(() => _isPressed = false) : null,
      onTap: isInteractive ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: AppColors.black,
            width: AppSpacing.borderThick,
          ),
          boxShadow: [
            if (!_isPressed && isInteractive)
              const BoxShadow(
                color: AppColors.black,
                offset: AppSpacing.shadowLarge,
              ),
          ],
        ),
        transform: _isPressed && isInteractive
            ? Matrix4.translationValues(
          AppSpacing.shadowLarge.dx,
          AppSpacing.shadowLarge.dy,
          0,
        )
            : Matrix4.identity(),
        child: widget.isLoading ? _buildLoading() : _buildContent(color),
      ),
    );
  }

  // ============================================================================
  // CONTENT
  // ============================================================================

  Widget _buildContent(Color color) {
    final label = widget.customLabel ?? _getDefaultLabel();
    final icon = widget.customIcon ?? _getDefaultIcon();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon container
        Container(
          padding: AppSpacing.paddingSM,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.black, width: AppSpacing.borderThin),
          ),
          child: Icon(
            icon,
            color: color,
            size: AppSpacing.iconLG,
          ),
        ),

        AppSpacing.horizontalGapMD,

        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!widget.isDisabled) ...[
                const SizedBox(height: 2),
                Text(
                  _getSubtitle(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Arrow
        if (!widget.isDisabled)
          const Icon(
            Icons.arrow_forward,
            color: AppColors.white,
            size: AppSpacing.iconMD,
          ),
      ],
    );
  }

  // ============================================================================
  // LOADING
  // ============================================================================

  Widget _buildLoading() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: AppSpacing.iconMD,
          height: AppSpacing.iconMD,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(AppColors.white),
          ),
        ),
        AppSpacing.horizontalGapMD,
        Text(
          'MEMUAT...',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // VARIANTS
  // ============================================================================

  Color _getColor() {
    if (widget.isDisabled) return AppColors.textTertiary;

    switch (widget.variant) {
      case QuickExamButtonVariant.primary:
        return AppColors.success;
      case QuickExamButtonVariant.twk:
        return AppColors.twkColor;
      case QuickExamButtonVariant.tiu:
        return AppColors.tiuColor;
      case QuickExamButtonVariant.tkp:
        return AppColors.tkpColor;
    }
  }

  Color _getBgColor() {
    if (widget.isDisabled) return AppColors.textTertiary;

    switch (widget.variant) {
      case QuickExamButtonVariant.primary:
        return AppColors.success;
      case QuickExamButtonVariant.twk:
        return AppColors.twkColor;
      case QuickExamButtonVariant.tiu:
        return AppColors.tiuColor;
      case QuickExamButtonVariant.tkp:
        return AppColors.tkpColor;
    }
  }

  String _getDefaultLabel() {
    if (widget.isDisabled) return 'Energy Habis';

    switch (widget.variant) {
      case QuickExamButtonVariant.primary:
        return 'Mulai Ujian';
      case QuickExamButtonVariant.twk:
        return 'Ujian TWK';
      case QuickExamButtonVariant.tiu:
        return 'Ujian TIU';
      case QuickExamButtonVariant.tkp:
        return 'Ujian TKP';
    }
  }

  IconData _getDefaultIcon() {
    if (widget.isDisabled) return Icons.block;

    switch (widget.variant) {
      case QuickExamButtonVariant.primary:
        return Icons.play_circle_filled;
      case QuickExamButtonVariant.twk:
        return Icons.menu_book;
      case QuickExamButtonVariant.tiu:
        return Icons.psychology;
      case QuickExamButtonVariant.tkp:
        return Icons.emoji_people;
    }
  }

  String _getSubtitle() {
    switch (widget.variant) {
      case QuickExamButtonVariant.primary:
        return '10 soal · ±5 menit';
      case QuickExamButtonVariant.twk:
        return 'Tes Wawasan Kebangsaan';
      case QuickExamButtonVariant.tiu:
        return 'Tes Intelegensia Umum';
      case QuickExamButtonVariant.tkp:
        return 'Tes Karakteristik Pribadi';
    }
  }
}

// ==============================================================================
// QUICK EXAM BUTTON VARIANT
// ==============================================================================

enum QuickExamButtonVariant {
  primary,  // Hijau - default mulai ujian
  twk,      // TWK color
  tiu,      // TIU color
  tkp,      // TKP color
}

// ==============================================================================
// CATEGORY SELECTOR (Bonus Widget)
// ==============================================================================

/// Category Selector untuk pilih jenis ujian
class CategorySelector extends StatelessWidget {
  final Function(QuickExamButtonVariant) onCategorySelected;
  final bool hasEnergy;

  const CategorySelector({
    super.key,
    required this.onCategorySelected,
    this.hasEnergy = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: AppColors.white,
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
              const Icon(Icons.category, color: AppColors.black),
              AppSpacing.horizontalGapSM,
              Text(
                'PILIH KATEGORI UJIAN',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        AppSpacing.verticalGapMD,

        // Categories
        QuickExamButton(
          variant: QuickExamButtonVariant.twk,
          isDisabled: !hasEnergy,
          onPressed: () => onCategorySelected(QuickExamButtonVariant.twk),
        ),
        AppSpacing.verticalGapMD,

        QuickExamButton(
          variant: QuickExamButtonVariant.tiu,
          isDisabled: !hasEnergy,
          onPressed: () => onCategorySelected(QuickExamButtonVariant.tiu),
        ),
        AppSpacing.verticalGapMD,

        QuickExamButton(
          variant: QuickExamButtonVariant.tkp,
          isDisabled: !hasEnergy,
          onPressed: () => onCategorySelected(QuickExamButtonVariant.tkp),
        ),
      ],
    );
  }
}