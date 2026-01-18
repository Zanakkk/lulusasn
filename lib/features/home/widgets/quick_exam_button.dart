// lib/features/home/widgets/quick_exam_button.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';

/// Duolingo-Style Quick Exam Button Widget
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
    final colors = _getColors();

    return GestureDetector(
      onTapDown: isInteractive
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: isInteractive ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isInteractive
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: isInteractive ? widget.onPressed : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _isPressed && isInteractive ? 0.98 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: widget.isDisabled ? 0.6 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: widget.isDisabled
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors.gradientColors,
                    ),
              color: widget.isDisabled ? AppColors.gray200 : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isDisabled
                    ? AppColors.gray300
                    : colors.borderColor,
                width: 2,
              ),
              boxShadow: [
                if (!widget.isDisabled)
                  BoxShadow(
                    color: colors.shadowColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: widget.isLoading ? _buildLoading() : _buildContent(colors),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // CONTENT
  // ============================================================================

  Widget _buildContent(_ButtonColors colors) {
    final label = widget.customLabel ?? _getDefaultLabel();
    final icon = widget.customIcon ?? _getDefaultIcon();

    return Row(
      children: [
        // Icon container
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),

        const SizedBox(width: 16),

        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
              if (!widget.isDisabled) ...[
                const SizedBox(height: 4),
                Text(
                  _getSubtitle(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Arrow
        if (!widget.isDisabled && !widget.isLoading)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 18,
            ),
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
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Memuat...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // COLORS & VARIANTS
  // ============================================================================

  _ButtonColors _getColors() {
    if (widget.isDisabled) {
      return _ButtonColors(
        gradientColors: [AppColors.gray200, AppColors.gray200],
        borderColor: AppColors.gray300,
        shadowColor: Colors.transparent,
      );
    }

    switch (widget.variant) {
      case QuickExamButtonVariant.primary:
        return _ButtonColors(
          gradientColors: [AppColors.green, AppColors.darkGreen],
          borderColor: AppColors.darkGreen,
          shadowColor: AppColors.green,
        );
      case QuickExamButtonVariant.twk:
        return _ButtonColors(
          gradientColors: [AppColors.blue, const Color(0xFF0D8BBF)],
          borderColor: const Color(0xFF0D8BBF),
          shadowColor: AppColors.blue,
        );
      case QuickExamButtonVariant.tiu:
        return _ButtonColors(
          gradientColors: [AppColors.orange, const Color(0xFFE08600)],
          borderColor: const Color(0xFFE08600),
          shadowColor: AppColors.orange,
        );
      case QuickExamButtonVariant.tkp:
        return _ButtonColors(
          gradientColors: [AppColors.green, AppColors.darkGreen],
          borderColor: AppColors.darkGreen,
          shadowColor: AppColors.green,
        );
    }
  }

  String _getDefaultLabel() {
    if (widget.isDisabled) return 'Energy Habis';

    switch (widget.variant) {
      case QuickExamButtonVariant.primary:
        return 'Mulai Ujian Campuran';
      case QuickExamButtonVariant.twk:
        return 'Ujian TWK';
      case QuickExamButtonVariant.tiu:
        return 'Ujian TIU';
      case QuickExamButtonVariant.tkp:
        return 'Ujian TKP';
    }
  }

  IconData _getDefaultIcon() {
    if (widget.isDisabled) return Icons.lock_rounded;

    switch (widget.variant) {
      case QuickExamButtonVariant.primary:
        return Icons.play_circle_fill_rounded;
      case QuickExamButtonVariant.twk:
        return Icons.menu_book_rounded;
      case QuickExamButtonVariant.tiu:
        return Icons.psychology_rounded;
      case QuickExamButtonVariant.tkp:
        return Icons.emoji_people_rounded;
    }
  }

  String _getSubtitle() {
    switch (widget.variant) {
      case QuickExamButtonVariant.primary:
        return '10 soal • ±5 menit';
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
// BUTTON COLORS
// ==============================================================================

class _ButtonColors {
  final List<Color> gradientColors;
  final Color borderColor;
  final Color shadowColor;

  _ButtonColors({
    required this.gradientColors,
    required this.borderColor,
    required this.shadowColor,
  });
}

// ==============================================================================
// QUICK EXAM BUTTON VARIANT
// ==============================================================================

enum QuickExamButtonVariant {
  primary, // Green gradient - default
  twk, // Blue gradient
  tiu, // Orange gradient
  tkp, // Green gradient
}

// ==============================================================================
// CATEGORY SELECTOR
// ==============================================================================

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.category_rounded,
                  color: AppColors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Kategori',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Fokus latihan per kategori ujian',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Categories
        QuickExamButton(
          variant: QuickExamButtonVariant.twk,
          isDisabled: !hasEnergy,
          onPressed: () => onCategorySelected(QuickExamButtonVariant.twk),
        ),
        const SizedBox(height: 12),

        QuickExamButton(
          variant: QuickExamButtonVariant.tiu,
          isDisabled: !hasEnergy,
          onPressed: () => onCategorySelected(QuickExamButtonVariant.tiu),
        ),
        const SizedBox(height: 12),

        QuickExamButton(
          variant: QuickExamButtonVariant.tkp,
          isDisabled: !hasEnergy,
          onPressed: () => onCategorySelected(QuickExamButtonVariant.tkp),
        ),
      ],
    );
  }
}
