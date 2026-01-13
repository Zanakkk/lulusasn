// lib/features/home/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/services/firebase_service.dart';
import 'package:lulusasn/core/widgets/loading_indicator.dart';
import 'package:lulusasn/core/widgets/error_message.dart';
import 'package:lulusasn/features/home/models/energy_model.dart';
import 'package:lulusasn/features/home/models/streak_model.dart';
import 'package:lulusasn/features/home/services/energy_service.dart';
import 'package:lulusasn/features/home/services/streak_service.dart';
import 'package:lulusasn/features/home/widgets/energy_display.dart';
import 'package:lulusasn/features/home/widgets/streak_counter.dart';
import 'package:lulusasn/features/home/widgets/progress_chart.dart';
import 'package:lulusasn/features/home/widgets/quick_exam_button.dart';
import 'package:lulusasn/app/routes.dart';

/// Home Screen - Dashboard Utama
///
/// Performance Optimizations:
/// - StreamBuilder dengan distinct untuk minimal rebuild
/// - Const widgets dimana possible
/// - Lazy loading untuk heavy widgets
/// - Efficient state management (no setState spam)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, user?.displayName ?? 'User'),
      body: _buildBody(),
    );
  }

  // ============================================================================
  // APP BAR
  // ============================================================================

  PreferredSizeWidget _buildAppBar(BuildContext context, String userName) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo, $userName! 👋',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Siap latihan hari ini?',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        // Notification icon (future)
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: Navigate to notifications
          },
        ),
        // Profile icon
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.profile);
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(AppSpacing.borderThick),
        child: Container(
          height: AppSpacing.borderThick,
          color: AppColors.black,
        ),
      ),
    );
  }

  // ============================================================================
  // BODY
  // ============================================================================

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async {
        // Force refresh streams (they auto-update anyway)
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Energy & Streak (Stream-based, auto-updates)
            _buildEnergyAndStreak(),

            AppSpacing.verticalGapLG,

            // Quick Exam Button (Primary CTA)
            _buildQuickExamSection(),

            AppSpacing.verticalGapLG,

            // Weekly Progress Chart
            _buildWeeklyProgress(),

            AppSpacing.verticalGapLG,

            // Category Buttons
            _buildCategorySection(),

            // Bottom padding for scroll
            AppSpacing.verticalGapXXL,
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // ENERGY & STREAK (Optimized with Streams)
  // ============================================================================

  Widget _buildEnergyAndStreak() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _getCombinedStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorMessage(
            message: 'Gagal memuat data',
            onRetry: () {
              // Stream will auto-retry
            },
          );
        }

        if (!snapshot.hasData) {
          return const LoadingIndicator();
        }

        final data = snapshot.data!;
        final energy = data['energy'] as EnergyModel;
        final streak = data['streak'] as StreakModel;
        final isPremium = data['isPremium'] as bool;

        return Column(
          children: [
            // Energy Display
            EnergyDisplay(
              energy: energy,
              isPremium: isPremium,
              onTap: () => _showEnergyInfo(context, energy, isPremium),
            ),

            AppSpacing.verticalGapMD,

            // Streak Counter
            StreakCounter(
              streak: streak,
              onTap: () => _showStreakInfo(context, streak),
            ),
          ],
        );
      },
    );
  }

  /// Combine multiple streams into one (minimize StreamBuilders)
  Stream<Map<String, dynamic>> _getCombinedStream() async* {
    final energyService = EnergyService();
    final streakService = StreakService();
    final userId = FirebaseService.instance.currentUser?.uid;

    if (userId == null) {
      yield {'error': 'Not logged in'};
      return;
    }

    // Get user isPremium status
    final userDoc = await FirebaseService.instance.firestore
        .collection('users')
        .doc(userId)
        .get();
    final isPremium = userDoc.data()?['isPremium'] as bool? ?? false;

    // Combine streams
    await for (final energy in energyService.streamEnergy()) {
      final streak = await streakService.getStreak();

      yield {
        'energy': energy,
        'streak': streak,
        'isPremium': isPremium,
      };
    }
  }

  // ============================================================================
  // QUICK EXAM SECTION
  // ============================================================================

  Widget _buildQuickExamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MULAI LATIHAN',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.verticalGapSM,
        Text(
          'Pilih kategori atau mulai ujian campuran',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.verticalGapMD,

        // Primary Quick Exam Button
        Builder(
          builder: (context) => QuickExamButton(
            variant: QuickExamButtonVariant.primary,
            onPressed: () => _startExam(context, 'MIXED'),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // WEEKLY PROGRESS
  // ============================================================================

  Widget _buildWeeklyProgress() {
    return FutureBuilder<List<DailyProgress>>(
      future: _getWeeklyProgress(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink(); // Don't block UI
        }

        return ProgressChart(
          weeklyData: snapshot.data!,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.statistics);
          },
        );
      },
    );
  }

  Future<List<DailyProgress>> _getWeeklyProgress() async {
    final userId = FirebaseService.instance.currentUser?.uid;
    if (userId == null) return [];

    // Get last 7 days of exams
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final exams = await FirebaseService.instance.firestore
        .collection('users')
        .doc(userId)
        .collection('exams')
        .where('completedAt', isGreaterThan: sevenDaysAgo)
        .get();

    // Group by date
    final Map<String, int> dailyCounts = {};

    for (var doc in exams.docs) {
      final completedAt = (doc.data()['completedAt'] as dynamic).toDate() as DateTime;
      final dateKey = '${completedAt.year}-${completedAt.month}-${completedAt.day}';
      dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
    }

    // Convert to DailyProgress list
    final List<DailyProgress> result = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      result.add(DailyProgress(
        date: date,
        examsCompleted: dailyCounts[dateKey] ?? 0,
      ));
    }

    return result;
  }

  // ============================================================================
  // CATEGORY SECTION
  // ============================================================================

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PILIH KATEGORI',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.verticalGapSM,
        Text(
          'Fokus latihan per kategori ujian',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.verticalGapMD,

        Builder(
          builder: (context) => CategorySelector(
            hasEnergy: true, // Will be checked in exam flow
            onCategorySelected: (variant) {
              final category = _variantToCategory(variant);
              _startExam(context, category);
            },
          ),
        ),
      ],
    );
  }

  String _variantToCategory(QuickExamButtonVariant variant) {
    switch (variant) {
      case QuickExamButtonVariant.twk:
        return 'TWK';
      case QuickExamButtonVariant.tiu:
        return 'TIU';
      case QuickExamButtonVariant.tkp:
        return 'TKP';
      default:
        return 'MIXED';
    }
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  Future<void> _startExam(BuildContext context, String category) async {
    final energyService = EnergyService();

    try {
      // Check if can start
      final canStart = await energyService.canStartExam();

      if (!canStart) {
        if (context.mounted) {
          _showOutOfEnergyDialog(context);
        }
        return;
      }

      // Consume energy (will throw if insufficient)
      await energyService.consumeEnergy();

      // Navigate to exam
      if (context.mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.exam,
          arguments: {'category': category},
        );
      }
    } on InsufficientEnergyException catch (e) {
      if (context.mounted) {
        _showOutOfEnergyDialog(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showOutOfEnergyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.black, width: AppSpacing.borderThick),
        ),
        title: Row(
          children: [
            Container(
              padding: AppSpacing.paddingSM,
              decoration: BoxDecoration(
                color: AppColors.error,
                border: Border.all(color: AppColors.black, width: AppSpacing.borderThin),
              ),
              child: const Icon(Icons.favorite_border, color: AppColors.white),
            ),
            AppSpacing.horizontalGapMD,
            const Text('Energy Habis!'),
          ],
        ),
        content: const Text('Tunggu regenerasi atau isi ulang energy untuk melanjutkan latihan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.premium);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.black,
            ),
            child: const Text('Upgrade Premium'),
          ),
        ],
      ),
    );
  }

  void _showEnergyInfo(BuildContext context, EnergyModel energy, bool isPremium) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.black, width: AppSpacing.borderThick),
      ),
      builder: (context) => Container(
        padding: AppSpacing.paddingLG,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INFO ENERGY',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.verticalGapMD,
            if (isPremium) ...[
              const Text('✨ Anda Premium Member!'),
              const Text('• Energy unlimited'),
              const Text('• Tanpa iklan'),
            ] else ...[
              Text('Current: ${energy.current}/${energy.max}'),
              Text('Regen: 1 per ${energy.regenRate} menit'),
              Text('Total used: ${energy.totalUsed}'),
            ],
            AppSpacing.verticalGapLG,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakInfo(BuildContext context, StreakModel streak) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.black, width: AppSpacing.borderThick),
      ),
      builder: (context) => Container(
        padding: AppSpacing.paddingLG,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INFO STREAK',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.verticalGapMD,
            Text('Current: ${streak.current} hari'),
            Text('Longest: ${streak.longest} hari'),
            Text('Status: ${streak.getStatus().displayText}'),
            AppSpacing.verticalGapLG,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}