// lib/features/exam/widgets/answer_options.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/features/exam/models/question_model.dart';

/// Answer Options Widget - Duolingo Style
///
/// Adaptive widget dengan 3 tipe soal:
/// - Yes/No (Benar/Salah) - Colorful dengan icon
/// - Likert Scale (1-5) - Gradient circles
/// - Multiple Choice (A-E) - Playful cards
///
/// Features:
/// - Smooth bounce animation saat dipilih
/// - Colorful & vibrant design
/// - Shadow effects untuk depth
/// - Haptic-ready interactions
class AnswerOptions extends StatefulWidget {
  final QuestionType type;
  final List<String> options;
  final int? selectedAnswer;
  final ValueChanged<int> onAnswerSelected;
  final bool enabled;

  const AnswerOptions({
    super.key,
    required this.type,
    required this.options,
    required this.selectedAnswer,
    required this.onAnswerSelected,
    this.enabled = true,
  });

  @override
  State<AnswerOptions> createState() => _AnswerOptionsState();
}

class _AnswerOptionsState extends State<AnswerOptions>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  int? _lastTappedIndex;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _bounceAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.05), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 30),
        ]).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (!widget.enabled) return;

    setState(() => _lastTappedIndex = index);
    _bounceController.forward(from: 0);

    // Delay untuk animasi bounce selesai dulu
    Future.delayed(const Duration(milliseconds: 150), () {
      widget.onAnswerSelected(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case QuestionType.yesNo:
        return _YesNoOptions(
          selectedAnswer: widget.selectedAnswer,
          onAnswerSelected: _handleTap,
          enabled: widget.enabled,
          bounceAnimation: _bounceAnimation,
          lastTappedIndex: _lastTappedIndex,
        );

      case QuestionType.likert:
        return _LikertOptions(
          options: widget.options, // 🆕 TAMBAHKAN INI
          selectedAnswer: widget.selectedAnswer,
          onAnswerSelected: _handleTap,
          enabled: widget.enabled,
          bounceAnimation: _bounceAnimation,
          lastTappedIndex: _lastTappedIndex,
        );

      case QuestionType.objective:
        return _MultipleChoiceOptions(
          options: widget.options,
          selectedAnswer: widget.selectedAnswer,
          onAnswerSelected: _handleTap,
          enabled: widget.enabled,
          bounceAnimation: _bounceAnimation,
          lastTappedIndex: _lastTappedIndex,
        );
    }
  }
}

// ==============================================================================
// YES / NO OPTIONS - Colorful & Fun
// ==============================================================================

class _YesNoOptions extends StatelessWidget {
  final int? selectedAnswer;
  final ValueChanged<int> onAnswerSelected;
  final bool enabled;
  final Animation<double> bounceAnimation;
  final int? lastTappedIndex;

  const _YesNoOptions({
    required this.selectedAnswer,
    required this.onAnswerSelected,
    required this.enabled,
    required this.bounceAnimation,
    required this.lastTappedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ColorfulOptionButton(
            label: 'BENAR',
            icon: Icons.check_circle_rounded,
            isSelected: selectedAnswer == 1,
            onTap: () => onAnswerSelected(1),
            enabled: enabled,
            bounceAnimation: bounceAnimation,
            shouldAnimate: lastTappedIndex == 1,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF58CC02), Color(0xFF48B002)],
            ),
            selectedColor: AppColors.success,
            borderColor: const Color(0xFF48B002),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ColorfulOptionButton(
            label: 'SALAH',
            icon: Icons.cancel_rounded,
            isSelected: selectedAnswer == 0,
            onTap: () => onAnswerSelected(0),
            enabled: enabled,
            bounceAnimation: bounceAnimation,
            shouldAnimate: lastTappedIndex == 0,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF6B6B), Color(0xFFFF4B4B)],
            ),
            selectedColor: AppColors.error,
            borderColor: const Color(0xFFEA2B2B),
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// LIKERT SCALE - Gradient Circles
// ==============================================================================

// ==============================================================================
// LIKERT SCALE - Full Options dengan Text
// ==============================================================================

class _LikertOptions extends StatelessWidget {
  final List<String> options; // 🆕 TAMBAHKAN INI
  final int? selectedAnswer;
  final ValueChanged<int> onAnswerSelected;
  final bool enabled;
  final Animation<double> bounceAnimation;
  final int? lastTappedIndex;

  const _LikertOptions({
    required this.options, // 🆕 TAMBAHKAN INI
    required this.selectedAnswer,
    required this.onAnswerSelected,
    required this.enabled,
    required this.bounceAnimation,
    required this.lastTappedIndex,
  });

  List<Color> _getGradientColors(int index) {
    // Index 0-4 = level rendah ke tinggi
    switch (index) {
      case 0:
        return [const Color(0xFFFF6B6B), const Color(0xFFFF4B4B)]; // Red
      case 1:
        return [const Color(0xFFFFAA66), const Color(0xFFFF9600)]; // Orange
      case 2:
        return [const Color(0xFFFFC866), const Color(0xFFFFC800)]; // Yellow
      case 3:
        return [
          const Color(0xFF77DD77),
          const Color(0xFF58CC02),
        ]; // Light Green
      case 4:
        return [const Color(0xFF58CC02), const Color(0xFF48B002)]; // Green
      default:
        return [AppColors.gray300, AppColors.gray400];
    }
  }

  String _getLabel(int index) {
    return String.fromCharCode(65 + index); // A, B, C, D, E
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(options.length, (index) {
        final isSelected = selectedAnswer == index;
        final shouldAnimate = lastTappedIndex == index;
        final optionColors = _getGradientColors(index);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: enabled ? () => onAnswerSelected(index) : null,
            child: AnimatedBuilder(
              animation: bounceAnimation,
              builder: (context, child) {
                final scale = shouldAnimate ? bounceAnimation.value : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? optionColors[0].withOpacity(0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? optionColors[1] : AppColors.gray300,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: optionColors[1].withOpacity(0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    // Label Badge (A, B, C, D, E)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: optionColors,
                              )
                            : null,
                        color: isSelected ? null : AppColors.gray100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? optionColors[1]
                              : AppColors.gray300,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getLabel(index),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Option text
                    Expanded(
                      child: Text(
                        options[index],
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    // Score indicator (1-5)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(colors: optionColors)
                            : null,
                        color: isSelected ? null : AppColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? optionColors[1]
                              : AppColors.gray300,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${index + 1}', // Skor 1-5
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ==============================================================================
// MULTIPLE CHOICE - Playful Cards
// ==============================================================================

class _MultipleChoiceOptions extends StatelessWidget {
  final List<String> options;
  final int? selectedAnswer;
  final ValueChanged<int> onAnswerSelected;
  final bool enabled;
  final Animation<double> bounceAnimation;
  final int? lastTappedIndex;

  const _MultipleChoiceOptions({
    required this.options,
    required this.selectedAnswer,
    required this.onAnswerSelected,
    required this.enabled,
    required this.bounceAnimation,
    required this.lastTappedIndex,
  });

  String _getLabel(int index) {
    return String.fromCharCode(65 + index); // A, B, C, D, E
  }

  Color _getOptionColor(int index) {
    final colors = [
      AppColors.blue,
      AppColors.purple,
      AppColors.orange,
      AppColors.cyan,
      AppColors.pink,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(options.length, (index) {
        final isSelected = selectedAnswer == index;
        final shouldAnimate = lastTappedIndex == index;
        final optionColor = _getOptionColor(index);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: enabled ? () => onAnswerSelected(index) : null,
            child: AnimatedBuilder(
              animation: bounceAnimation,
              builder: (context, child) {
                final scale = shouldAnimate ? bounceAnimation.value : 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? optionColor.withOpacity(0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? optionColor : AppColors.gray300,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: optionColor.withOpacity(0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    // Label Badge (A, B, C, D, E)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  optionColor,
                                  AppColors.darken(optionColor, 0.1),
                                ],
                              )
                            : null,
                        color: isSelected ? null : AppColors.gray100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? optionColor : AppColors.gray300,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getLabel(index),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Option text
                    Expanded(
                      child: Text(
                        options[index],
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    // Checkmark dengan animasi
                    AnimatedScale(
                      scale: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.elasticOut,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: optionColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ==============================================================================
// COLORFUL OPTION BUTTON (YES/NO)
// ==============================================================================

class _ColorfulOptionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool enabled;
  final Animation<double> bounceAnimation;
  final bool shouldAnimate;
  final Gradient gradient;
  final Color selectedColor;
  final Color borderColor;

  const _ColorfulOptionButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.enabled,
    required this.bounceAnimation,
    required this.shouldAnimate,
    required this.gradient,
    required this.selectedColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedBuilder(
        animation: bounceAnimation,
        builder: (context, child) {
          final scale = shouldAnimate ? bounceAnimation.value : 1.0;
          return Transform.scale(scale: scale, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 72,
          decoration: BoxDecoration(
            gradient: isSelected ? gradient : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? borderColor : AppColors.gray300,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: selectedColor.withOpacity(0.4),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
