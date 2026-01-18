// lib/features/exam/widgets/exam_timer.dart

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';

/// Exam Timer Widget
///
/// Timer per soal dengan visual feedback:
/// - Countdown format MM:SS
/// - Color warning saat < 10 detik
/// - Auto-submit saat waktu habis (optional)
/// - Duolingo-style design
class ExamTimer extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onTimerEnd;
  final bool showWarning;
  final bool autoSubmit;

  const ExamTimer({
    super.key,
    this.initialSeconds = 60,
    this.onTimerEnd,
    this.showWarning = true,
    this.autoSubmit = false,
  });

  @override
  State<ExamTimer> createState() => _ExamTimerState();
}

class _ExamTimerState extends State<ExamTimer>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late int _remainingSeconds;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;

    // Pulse animation untuk warning
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;

          // Pulse animation saat < 10 detik
          if (_remainingSeconds <= 10 && widget.showWarning) {
            _pulseController.forward().then((_) {
              _pulseController.reverse();
            });
          }
        } else {
          _timer.cancel();
          widget.onTimerEnd?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_remainingSeconds <= 10) {
      return AppColors.error;
    } else if (_remainingSeconds <= 30) {
      return AppColors.warning;
    }
    return AppColors.primary;
  }

  IconData get _timerIcon {
    if (_remainingSeconds <= 10) {
      return Icons.timer_off_outlined;
    }
    return Icons.timer_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isWarning = _remainingSeconds <= 10;

    return ScaleTransition(
      scale: isWarning && widget.showWarning
          ? _pulseAnimation
          : AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: _timerColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: _timerColor,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _timerIcon,
              color: _timerColor,
              size: 20,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              _formatTime(),
              style: AppTextStyles.headingSmall.copyWith(
                color: _timerColor,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// TOTAL EXAM TIMER (Keseluruhan exam)
// ==============================================================================

class TotalExamTimer extends StatefulWidget {
  final DateTime startTime;

  const TotalExamTimer({
    super.key,
    required this.startTime,
  });

  @override
  State<TotalExamTimer> createState() => _TotalExamTimerState();
}

class _TotalExamTimerState extends State<TotalExamTimer> {
  late Timer _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds = DateTime.now().difference(widget.startTime).inSeconds;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime() {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutral.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            color: AppColors.textSecondary,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            _formatTime(),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}