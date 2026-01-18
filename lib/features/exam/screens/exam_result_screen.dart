// lib/features/exam/screens/exam_result_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/widgets/brutalist_button.dart';
import 'package:lulusasn/features/exam/models/exam_result_model.dart';
import 'dart:math' as math;

import '../models/question_model.dart';

/// Duolingo-style Exam Result Screen
///
/// Flow: exam session -> exam result -> MainNavigationScreen (tab Belajar)
/// Design: Celebration animation, clear metrics, encouraging feedback
class ExamResultScreen extends StatefulWidget {
  final ExamResultModel result;

  const ExamResultScreen({super.key, required this.result});

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _progressController;
  late AnimationController _confettiController;

  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation for score circle
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Slide animation for content
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: widget.result.accuracy)
        .animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );

    // Confetti animation for high scores
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
      _slideController.forward();
      _progressController.forward();

      if (widget.result.accuracy >= 0.8) {
        _confettiController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    // Navigate back to MainNavigationScreen (tab Belajar/exam list)
    Navigator.of(context).popUntil((route) => route.settings.name == '/home');
  }

  void _handleReview() {
    Navigator.of(
      context,
    ).pushNamed('/exam/review', arguments: {'examId': widget.result.examId});
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.result.accuracy;
    final isPassed = widget.result.isPassed;

    return Scaffold(
      backgroundColor: _getBackgroundColor(accuracy),
      body: Stack(
        children: [
          // Confetti animation overlay
          if (accuracy >= 0.8)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ConfettiPainter(
                        animation: _confettiController.value,
                      ),
                    );
                  },
                ),
              ),
            ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Animated score circle
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: _ScoreCircle(
                            animation: _progressAnimation,
                            accuracy: accuracy,
                            isPassed: isPassed,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Title & subtitle
                        SlideTransition(
                          position: _slideAnimation,
                          child: _ResultTitle(
                            accuracy: accuracy,
                            isPassed: isPassed,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Stats cards
                        SlideTransition(
                          position: _slideAnimation,
                          child: _StatsCards(result: widget.result),
                        ),

                        const SizedBox(height: 24),

                        // Encouragement message
                        SlideTransition(
                          position: _slideAnimation,
                          child: _EncouragementCard(
                            accuracy: accuracy,
                            isPassed: isPassed,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Review button
                        SlideTransition(
                          position: _slideAnimation,
                          child: _ReviewButton(onReview: _handleReview),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom CTA
                _BottomCTA(onContinue: _handleContinue, isPassed: isPassed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(double accuracy) {
    // 🆕 Jika ada Likert, gunakan skema warna berbeda
    final hasLikert =
        widget.result.answers?.any(
          (a) => a.questionType == QuestionType.likert,
        ) ??
        false;

    if (hasLikert) {
      // Skema warna untuk Likert (berdasarkan skor %)
      if (accuracy >= 0.85) return const Color(0xFFFFF4E6); // warm gold
      if (accuracy >= 0.7) return const Color(0xFFF0F9FF); // cool blue
      if (accuracy >= 0.5) return const Color(0xFFFFFBEB); // soft yellow
      return const Color(0xFFFEF2F2); // soft red
    } else {
      // Skema warna untuk Objective (original)
      if (accuracy >= 0.85) return const Color(0xFFF0FFF4); // green tint
      if (accuracy >= 0.7) return const Color(0xFFF0F9FF); // blue tint
      if (accuracy >= 0.5) return const Color(0xFFFFFBEB); // yellow tint
      return const Color(0xFFFEF2F2); // red tint
    }
  }
}

// ==============================================================================
// SCORE CIRCLE
// ==============================================================================

class _ScoreCircle extends StatelessWidget {
  final Animation<double> animation;
  final double accuracy;
  final bool isPassed;

  const _ScoreCircle({
    required this.animation,
    required this.accuracy,
    required this.isPassed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // 🆕 Gunakan percentage dari skor, bukan accuracy (untuk Likert)
        final displayPercentage = (animation.value * 100).toInt();

        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: _getColor().withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Progress ring
              Positioned.fill(
                child: CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: animation.value,
                    color: _getColor(),
                  ),
                ),
              ),

              // Center content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_getEmoji(), style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      '$displayPercentage%',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: _getColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Skor Akhir', // 🆕 Ganti dari "Akurasi" jadi "Skor Akhir"
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getColor() {
    if (accuracy >= 0.85) return AppColors.success;
    if (accuracy >= 0.7) return AppColors.primary;
    if (accuracy >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  String _getEmoji() {
    if (accuracy >= 0.9) return '🏆';
    if (accuracy >= 0.8) return '🎉';
    if (accuracy >= 0.7) return '👏';
    if (accuracy >= 0.6) return '👍';
    return '💪';
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background circle
    final bgPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==============================================================================
// RESULT TITLE
// ==============================================================================

class _ResultTitle extends StatelessWidget {
  final double accuracy;
  final bool isPassed;

  const _ResultTitle({required this.accuracy, required this.isPassed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _getTitle(),
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _getSubtitle(),
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getTitle() {
    if (accuracy >= 0.9) return 'Sempurna!';
    if (accuracy >= 0.8) return 'Luar Biasa!';
    if (accuracy >= 0.7) return 'Bagus Sekali!';
    if (accuracy >= 0.6) return 'Cukup Baik!';
    return 'Tetap Semangat!';
  }

  String _getSubtitle() {
    if (isPassed) return 'Kamu berhasil melewati ujian ini';
    return 'Ayo coba lagi, kamu pasti bisa!';
  }
}

// ==============================================================================
// STATS CARDS
// ==============================================================================

class _StatsCards extends StatelessWidget {
  final ExamResultModel result;

  const _StatsCards({required this.result});

  // 🆕 Helper: Hitung total skor maksimal
  int _getMaxPossibleScore() {
    if (result.answers == null || result.answers!.isEmpty) {
      return result.totalQuestions * 5; // Fallback: asumsi semua soal = 5 poin
    }

    int maxScore = 0;
    for (var answer in result.answers!) {
      if (answer.questionType == QuestionType.likert) {
        maxScore += 5; // Likert max = 5
      } else {
        maxScore += 5; // Objective/YesNo max = 5
      }
    }
    return maxScore;
  }

  // 🆕 Helper: Hitung total skor aktual
  int _getActualScore() {
    if (result.answers == null || result.answers!.isEmpty) {
      return result.correctCount * 5; // Fallback
    }

    return result.answers!.fold<int>(0, (sum, answer) => sum + answer.score);
  }

  // 🆕 Check apakah ada soal Likert
  bool _hasLikertQuestions() {
    if (result.answers == null) return false;
    return result.answers!.any((a) => a.questionType == QuestionType.likert);
  }

  @override
  Widget build(BuildContext context) {
    final hasLikert = _hasLikertQuestions();
    final actualScore = _getActualScore();
    final maxScore = _getMaxPossibleScore();

    return Column(
      children: [
        // 🆕 Jika ada Likert, tampilkan Skor dulu (prioritas)
        if (hasLikert) ...[
          _ScoreCard(
            icon: Icons.stars_rounded,
            value: '$actualScore',
            maxValue: maxScore,
            label: 'Total Skor',
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
        ],

        // Row untuk Benar/Salah/Waktu
        Row(
          children: [
            if (hasLikert)
              // Jika ada Likert, tampilkan "Dijawab" bukan "Benar"
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle_rounded,
                  value: '${result.correctCount}',
                  label: 'Dijawab',
                  color: AppColors.success,
                ),
              )
            else
              // Jika pure Objective, tampilkan "Benar"
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle_rounded,
                  value: '${result.correctCount}',
                  label: 'Benar',
                  color: AppColors.success,
                ),
              ),

            const SizedBox(width: 12),

            // Waktu
            Expanded(
              child: _StatCard(
                icon: Icons.timer_rounded,
                value: result.formattedDuration,
                label: 'Waktu',
                color: AppColors.cyan,
              ),
            ),

            const SizedBox(width: 12),

            // Rata-rata per soal
            Expanded(
              child: _StatCard(
                icon: Icons.speed_rounded,
                value: '${result.averageTimePerQuestion.toInt()}s',
                label: 'Rata-rata',
                color: AppColors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headingMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// ENCOURAGEMENT CARD
// ==============================================================================

class _EncouragementCard extends StatelessWidget {
  final double accuracy;
  final bool isPassed;

  const _EncouragementCard({required this.accuracy, required this.isPassed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.tips_and_updates_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getMessage(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMessage() {
    if (accuracy >= 0.9) {
      return 'Pertahankan konsistensi! Latihan rutin adalah kunci sukses ujian.';
    } else if (accuracy >= 0.8) {
      return 'Fokus pada detail! Setiap soal adalah kesempatan untuk belajar.';
    } else if (accuracy >= 0.7) {
      return 'Review materi yang kurang dipahami. Jangan ragu mencoba lagi!';
    } else if (accuracy >= 0.6) {
      return 'Latihan membuat sempurna. Konsisten adalah kuncinya!';
    } else {
      return 'Jangan menyerah! Setiap latihan membuatmu lebih pintar.';
    }
  }
}

// ==============================================================================
// REVIEW BUTTON
// ==============================================================================

class _ReviewButton extends StatelessWidget {
  final VoidCallback onReview;

  const _ReviewButton({required this.onReview});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onReview,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.blue, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_rounded, color: AppColors.blue),
            const SizedBox(width: 12),
            Text(
              'Lihat Pembahasan',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// BOTTOM CTA
// ==============================================================================

class _BottomCTA extends StatelessWidget {
  final VoidCallback onContinue;
  final bool isPassed;

  const _BottomCTA({required this.onContinue, required this.isPassed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: DuolingoButton.primary(text: 'LANJUTKAN', onPressed: onContinue),
      ),
    );
  }
}

// ==============================================================================
// CONFETTI PAINTER
// ==============================================================================

class _ConfettiPainter extends CustomPainter {
  final double animation;

  _ConfettiPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent animation
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final y = (baseY + animation * size.height) % size.height;

      final colorIndex = i % AppColors.chartColors.length;
      paint.color = AppColors.chartColors[colorIndex].withOpacity(0.7);

      // Draw confetti shapes
      if (i % 3 == 0) {
        // Circle
        canvas.drawCircle(Offset(x, y), 4, paint);
      } else if (i % 3 == 1) {
        // Rectangle
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: 8, height: 4),
          paint,
        );
      } else {
        // Triangle
        final path = Path()
          ..moveTo(x, y - 4)
          ..lineTo(x - 4, y + 4)
          ..lineTo(x + 4, y + 4)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==============================================================================
// SCORE CARD (Big score display untuk Likert)
// ==============================================================================

class _ScoreCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final int maxValue;
  final String label;
  final Color color;

  const _ScoreCard({
    required this.icon,
    required this.value,
    required this.maxValue,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (int.parse(value) / maxValue * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),

          const SizedBox(width: 16),

          // Score
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: AppTextStyles.displaySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    Text(
                      ' / $maxValue',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Percentage badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$percentage%',
              style: AppTextStyles.headingSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
