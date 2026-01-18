// lib/features/exam/screens/pre_exam_screen.dart

// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/widgets/brutalist_button.dart';

import '../../home/services/energy_service.dart'
    hide InsufficientEnergyException;
import '../services/exam_service.dart';
import '../widgets/out_of_energy_modal.dart';

/// Pre-Exam Screen - Duolingo Style
///
/// Responsive design dengan breakpoints:
/// - Mobile: < 600px (single column)
/// - Tablet: 600-1024px (optimized spacing)
/// - Desktop: > 1024px (max width 800px, centered)
///
/// Features:
/// - Haptic feedback on interactions
/// - Smooth animations
/// - Professional layout inspired by Duolingo
/// - Optimized performance
class PreExamScreen extends StatefulWidget {
  final String? packageId;
  final String category;
  final int questionCount;
  final int energyCost;
  final bool isPremium;
  final String? title;

  const PreExamScreen({
    super.key,
    this.packageId,
    required this.category,
    this.questionCount = 10,
    this.energyCost = 1,
    this.isPremium = false,
    this.title,
  });

  @override
  State<PreExamScreen> createState() => _PreExamScreenState();
}

class _PreExamScreenState extends State<PreExamScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color get _categoryColor {
    switch (widget.category.toUpperCase()) {
      case 'TWK':
        return AppColors.twk;
      case 'TIU':
        return AppColors.tiu;
      case 'TKP':
        return AppColors.tkp;
      default:
        return AppColors.primary;
    }
  }

  String get _displayTitle => widget.title ?? _categoryTitle;

  String get _categoryTitle {
    switch (widget.category.toUpperCase()) {
      case 'TWK':
        return 'Tes Wawasan Kebangsaan';
      case 'TIU':
        return 'Tes Intelegensia Umum';
      case 'TKP':
        return 'Tes Karakteristik Pribadi';
      default:
        return widget.category;
    }
  }

  int get _estimatedMinutes => (widget.questionCount * 1.5).ceil();

  Future<void> _startExam() async {
    if (_isLoading) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final examService = ExamService();
      final energyService = EnergyService();

      // ✅ 1. Check energy SEBELUM start exam
      final canStart = await energyService.canStartExam();

      if (!canStart) {
        // ✅ 2. Jika energy habis, ambil data real untuk modal
        final energyData = await energyService.getEnergy();
        final currentEnergy = energyData.calculateCurrentEnergy();
        final maxEnergy = energyData.max;

        // Calculate time until next energy
        final minutesUntilNext = energyData.minutesUntilNext();
        final timeUntilNext = Duration(minutes: minutesUntilNext);

        if (!mounted) return;

        HapticFeedback.lightImpact();

        // ✅ 3. Show modal dengan data REAL
        await OutOfEnergyModal.show(
          context: context,
          currentEnergy: currentEnergy,
          maxEnergy: maxEnergy,
          timeUntilNextEnergy: timeUntilNext,
          onWatchAd: () => Navigator.pop(context),
          onRefillDiamond: () => Navigator.pop(context),
          onUpgradePremium: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/premium');
          },
        );

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pop(); // Back to home
        }
        return;
      }

      // ✅ 4. Start exam (ini akan consume energy -1)
      final session = await examService.startExam(
        category: widget.category,
        questionCount: widget.questionCount,
        packageId: widget.packageId,
      );

      if (!mounted) return;

      HapticFeedback.heavyImpact();

      // ✅ 5. Navigate ke exam session
      Navigator.of(context).pushReplacementNamed(
        '/exam/session',
        arguments: {'sessionId': session.examId},
      );
    } on InsufficientEnergyException {
      // ✅ Fallback jika ada exception (seharusnya sudah di-handle di atas)
      if (!mounted) return;

      final energyService = EnergyService();
      final energyData = await energyService.getEnergy();
      final currentEnergy = energyData.calculateCurrentEnergy();
      final maxEnergy = energyData.max;
      final minutesUntilNext = energyData.minutesUntilNext();

      HapticFeedback.lightImpact();

      await OutOfEnergyModal.show(
        context: context,
        currentEnergy: currentEnergy,
        maxEnergy: maxEnergy,
        timeUntilNextEnergy: Duration(minutes: minutesUntilNext),
        onWatchAd: () => Navigator.pop(context),
        onRefillDiamond: () => Navigator.pop(context),
        onUpgradePremium: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/premium');
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;

      HapticFeedback.heavyImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _ResponsiveLayout(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildContent(),
                  ),
                ),
              ),
              _buildBottomCTA(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Row(
        children: [
          _CloseButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: AppSpacing.md),
          Text('Siap Latihan?', style: AppTextStyles.headingMedium),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroIllustration(category: widget.category, color: _categoryColor),
          const SizedBox(height: AppSpacing.xl),
          _TitleSection(title: _displayTitle),
          const SizedBox(height: AppSpacing.lg),
          _StatsRow(
            questionCount: widget.questionCount,
            estimatedMinutes: _estimatedMinutes,
            categoryColor: _categoryColor,
          ),
          const SizedBox(height: AppSpacing.md),
          _EnergyCostCard(cost: widget.energyCost, isPremium: widget.isPremium),
          const SizedBox(height: AppSpacing.xl),
          const _TipsSection(),
          const SizedBox(height: AppSpacing.xl),
          _EncouragementBanner(color: _categoryColor),
          const SizedBox(height: 100), // Space for bottom CTA
        ],
      ),
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: DuolingoButton.primary(
        text: _isLoading ? 'MEMUAT...' : 'MULAI LATIHAN',
        onPressed: _isLoading ? null : _startExam,
      ),
    );
  }
}

// ==============================================================================
// RESPONSIVE LAYOUT WRAPPER
// ==============================================================================

class _ResponsiveLayout extends StatelessWidget {
  final Widget child;

  const _ResponsiveLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop: max width 800px, centered
        if (constraints.maxWidth > 1024) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: child,
            ),
          );
        }
        // Mobile & Tablet: full width
        return child;
      },
    );
  }
}

// ==============================================================================
// CLOSE BUTTON
// ==============================================================================

class _CloseButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _CloseButton({required this.onPressed});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _isPressed ? AppColors.border : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.close_rounded,
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
    );
  }
}

// ==============================================================================
// HERO ILLUSTRATION
// ==============================================================================

class _HeroIllustration extends StatelessWidget {
  final String category;
  final Color color;

  const _HeroIllustration({required this.category, required this.color});

  IconData get _icon {
    switch (category.toUpperCase()) {
      case 'TWK':
        return Icons.flag_rounded;
      case 'TIU':
        return Icons.psychology_rounded;
      case 'TKP':
        return Icons.favorite_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(_icon, size: 70, color: color),
            ),
          );
        },
      ),
    );
  }
}

// ==============================================================================
// TITLE SECTION
// ==============================================================================

class _TitleSection extends StatelessWidget {
  final String title;

  const _TitleSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.displaySmall.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 28,
        height: 1.2,
      ),
    );
  }
}

// ==============================================================================
// STATS ROW (Responsive Grid)
// ==============================================================================

class _StatsRow extends StatelessWidget {
  final int questionCount;
  final int estimatedMinutes;
  final Color categoryColor;

  const _StatsRow({
    required this.questionCount,
    required this.estimatedMinutes,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    // Semua ukuran: 1 row dengan 2 kolom
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _InfoCard(
              icon: Icons.quiz_rounded,
              label: 'Soal',
              value: '$questionCount',
              color: categoryColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _InfoCard(
              icon: Icons.access_time_rounded,
              label: 'Estimasi',
              value: '$estimatedMinutes min',
              color: AppColors.neutral,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// INFO CARD
// ==============================================================================

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.headingLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// ENERGY COST CARD
// ==============================================================================

class _EnergyCostCard extends StatelessWidget {
  final int cost;
  final bool isPremium;

  const _EnergyCostCard({required this.cost, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return _PremiumBadge();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error.withOpacity(0.15),
            AppColors.error.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error, width: 3),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite, color: AppColors.error, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
                children: [
                  const TextSpan(text: 'Membutuhkan '),
                  TextSpan(
                    text: '$cost Energy',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  const TextSpan(text: ' untuk mulai'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Energy UNLIMITED',
              style: AppTextStyles.bodyLarge.copyWith(
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

// ==============================================================================
// TIPS SECTION
// ==============================================================================

class _TipsSection extends StatelessWidget {
  const _TipsSection();

  static const _tips = [
    _TipData(
      icon: Icons.speed_rounded,
      text: 'Baca soal dengan teliti, jangan terburu-buru',
    ),
    _TipData(
      icon: Icons.psychology_rounded,
      text: 'Fokus dan hindari distraksi',
    ),
    _TipData(
      icon: Icons.skip_next_rounded,
      text: 'Lewati soal sulit, kerjakan yang mudah dulu',
    ),
    _TipData(
      icon: Icons.trending_up_rounded,
      text: 'Konsistensi adalah kunci sukses!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tips Mengerjakan',
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._tips.map((tip) => _TipItem(data: tip)),
      ],
    );
  }
}

class _TipData {
  final IconData icon;
  final String text;

  const _TipData({required this.icon, required this.text});
}

class _TipItem extends StatelessWidget {
  final _TipData data;

  const _TipItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(data.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                data.text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// ENCOURAGEMENT BANNER
// ==============================================================================

class _EncouragementBanner extends StatelessWidget {
  final Color color;

  const _EncouragementBanner({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 3),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emoji_events_rounded, color: color, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Kamu bisa! Setiap soal adalah kesempatan untuk belajar 🚀',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
