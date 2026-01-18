// lib/features/home/screens/home_screen.dart

// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/services/firebase_service.dart';
import 'package:lulusasn/features/home/models/energy_model.dart';
import 'package:lulusasn/features/home/services/energy_service.dart';
import 'package:lulusasn/features/home/widgets/progress_chart.dart';
import 'package:lulusasn/features/home/widgets/quick_exam_button.dart';
import 'package:lulusasn/app/routes.dart';

/// Responsive breakpoints following Material Design guidelines
class _Breakpoints {
  static const double mobile = 600;
  static const double tablet = 840;
  static const double desktop = 1240;

  // Max content width for readability (Google-style)
  static const double maxContentWidth = 1200;
}

/// Home Screen - Responsive Dashboard
///
/// Layout Strategy:
/// - Mobile (< 600): Single column, full width
/// - Tablet (600-840): Two columns with margins
/// - Desktop (> 840): Centered content with max-width constraint
///
/// Performance:
/// - Single StreamBuilder for combined data
/// - Const constructors where possible
/// - Efficient layout calculations
///
///
///
///
///
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _energyTimer;
  EnergyModel? _currentEnergy;

  @override
  void initState() {
    super.initState();
    _loadEnergyData();
    _startEnergyTimer(); // Timer untuk countdown UI
  }

  @override
  void dispose() {
    _energyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildResponsiveBody(context, screenWidth),
    );
  }

  void _startEnergyTimer() {
    _energyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _currentEnergy != null) {
        // ✅ Cek apakah ada regenerasi baru
        final newEnergy = _currentEnergy!.calculateCurrentEnergy();
        final oldEnergy = _currentEnergy!.current;

        // ✅ Jika energy bertambah (regenerasi), update Firestore
        if (newEnergy > oldEnergy && newEnergy <= _currentEnergy!.max) {
          _loadEnergyData(); // Reload dan save
        } else {
          // ✅ Hanya update UI (untuk countdown timer)
          setState(() {});
        }
      }
    });
  }

  Future<void> _loadEnergyData() async {
    final userId = FirebaseService.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final userDoc = await FirebaseService.instance.firestore
          .collection('users')
          .doc(userId)
          .get();

      final energyService = EnergyService();
      final energy = await energyService.getEnergy();

      // ✅ Hitung current energy dengan regenerasi
      final currentEnergy = energy.calculateCurrentEnergy();

      // ✅ Jika ada regenerasi, update ke Firestore
      if (currentEnergy != energy.current && currentEnergy < energy.max) {
        final now = DateTime.now();
        final updatedEnergy = energy.copyWith(
          current: currentEnergy,
          lastRegen: now,
        );

        await FirebaseService.instance.firestore
            .collection('users')
            .doc(userId)
            .update({'energy': updatedEnergy.toFirestore()});

        if (mounted) {
          setState(() {
            _currentEnergy = updatedEnergy;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentEnergy = energy;
          });
        }
      }
    } catch (e) {
      print('Error loading energy: $e');
    }
  }

  // ============================================================================
  // DUOLINGO-STYLE APP BAR
  // ============================================================================

  // ============================================================================
  // MOBILE LAYOUT (< 600px) - Single Column
  // ============================================================================

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildQuickExamSection(),
        AppSpacing.verticalGapLG,
        _buildWeeklyProgressSection(),
        AppSpacing.verticalGapLG,
        _buildCategorySection(),
        AppSpacing.verticalGapXXL,
      ],
    );
  }

  // ============================================================================
  // TABLET LAYOUT (600-1240px) - Two Columns
  // ============================================================================

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top: Progress (full width)
        _buildWeeklyProgressSection(),
        const SizedBox(height: 32),

        // Middle: Quick Exam (full width)
        _buildQuickExamSection(),
        const SizedBox(height: 32),

        // Bottom: Categories (grid)
        _buildCategorySection(),
        const SizedBox(height: 48),
      ],
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT (> 1240px) - Grid Layout
  // ============================================================================

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Row: Progress + Quick Exam
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Progress
            Expanded(flex: 2, child: _buildWeeklyProgressSection()),
            const SizedBox(width: 32),

            // Right Column: Quick Exam CTA
            Expanded(flex: 3, child: _buildQuickExamSection()),
          ],
        ),
        const SizedBox(height: 40),

        // Bottom: Categories (horizontal grid)
        _buildCategorySection(),
        const SizedBox(height: 64),
      ],
    );
  }

  // ============================================================================
  // RESPONSIVE BODY LAYOUT
  // ============================================================================

  Widget _buildResponsiveBody(BuildContext context, double screenWidth) {
    // Determine layout
    final isMobile = screenWidth < _Breakpoints.mobile;
    final isTablet =
        screenWidth >= _Breakpoints.mobile &&
        screenWidth < _Breakpoints.desktop;
    final _ = screenWidth >= _Breakpoints.desktop;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _Breakpoints.maxContentWidth,
            ),
            child: Padding(
              padding: _getResponsivePadding(screenWidth),
              child: isMobile
                  ? _buildMobileLayout(context)
                  : isTablet
                  ? _buildTabletLayout(context)
                  : _buildDesktopLayout(context),
            ),
          ),
        ),
      ),
    );
  }

  EdgeInsets _getResponsivePadding(double screenWidth) {
    if (screenWidth < _Breakpoints.mobile) {
      return AppSpacing.paddingMD;
    } else if (screenWidth < _Breakpoints.desktop) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

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
        Builder(
          builder: (context) => QuickExamButton(
            variant: QuickExamButtonVariant.primary,
            onPressed: () => _startExam(context, 'MIXED'),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyProgressSection() {
    return FutureBuilder<List<DailyProgress>>(
      future: _getWeeklyProgress(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
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

  Widget _buildCategorySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _Breakpoints.mobile;

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
              builder: (context) => isMobile
                  ? _buildCategoryVertical(context)
                  : _buildCategoryGrid(context),
            ),
          ],
        );
      },
    );
  }

  // Category layouts
  Widget _buildCategoryVertical(BuildContext context) {
    return Column(
      children: [
        QuickExamButton(
          variant: QuickExamButtonVariant.twk,
          onPressed: () => _startExam(context, 'TWK'),
        ),
        AppSpacing.verticalGapMD,
        QuickExamButton(
          variant: QuickExamButtonVariant.tiu,
          onPressed: () => _startExam(context, 'TIU'),
        ),
        AppSpacing.verticalGapMD,
        QuickExamButton(
          variant: QuickExamButtonVariant.tkp,
          onPressed: () => _startExam(context, 'TKP'),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: QuickExamButton(
            variant: QuickExamButtonVariant.twk,
            onPressed: () => _startExam(context, 'TWK'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: QuickExamButton(
            variant: QuickExamButtonVariant.tiu,
            onPressed: () => _startExam(context, 'TIU'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: QuickExamButton(
            variant: QuickExamButtonVariant.tkp,
            onPressed: () => _startExam(context, 'TKP'),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // DATA STREAMS & FUTURES
  // ============================================================================

  Future<List<DailyProgress>> _getWeeklyProgress() async {
    final userId = FirebaseService.instance.currentUser?.uid;
    if (userId == null) return [];

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final exams = await FirebaseService.instance.firestore
        .collection('users')
        .doc(userId)
        .collection('exams')
        .where('completedAt', isGreaterThan: sevenDaysAgo)
        .get();

    final Map<String, int> dailyCounts = {};

    for (var doc in exams.docs) {
      final completedAt =
          (doc.data()['completedAt'] as dynamic).toDate() as DateTime;
      final dateKey =
          '${completedAt.year}-${completedAt.month}-${completedAt.day}';
      dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
    }

    final List<DailyProgress> result = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      result.add(
        DailyProgress(date: date, examsCompleted: dailyCounts[dateKey] ?? 0),
      );
    }

    return result;
  }

  // ============================================================================
  // ACTIONS & DIALOGS
  // ============================================================================

  Future<void> _startExam(BuildContext context, String category) async {
    final energyService = EnergyService();

    try {
      // ✅ Check energy terlebih dahulu
      final canStart = await energyService.canStartExam();

      if (!canStart) {
        if (context.mounted) {
          _showOutOfEnergyDialog(context);
        }
        return;
      }

      // ✅ Navigate ke PreExamScreen (BELUM consume energy!)
      // Energy baru di-consume saat user klik "MULAI LATIHAN"
      if (context.mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes
              .examPre, // ✅ FIX: Ganti dari AppRoutes.exam ke AppRoutes.examPre
          arguments: {
            'category': category,
            'questionCount': 10, // Default 10 soal
            'energyCost': 1, // 1 energy per exam
            'isPremium': false, // TODO: Get from user doc
          },
        );
      }
    } on InsufficientEnergyException {
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
    final isDesktop = MediaQuery.of(context).size.width >= _Breakpoints.tablet;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: const RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.black,
            width: AppSpacing.borderThick,
          ),
        ),
        contentPadding: EdgeInsets.all(isDesktop ? 32 : 24),
        title: Row(
          children: [
            Container(
              padding: AppSpacing.paddingSM,
              decoration: BoxDecoration(
                color: AppColors.error,
                border: Border.all(
                  color: AppColors.black,
                  width: AppSpacing.borderThin,
                ),
              ),
              child: const Icon(Icons.favorite_border, color: AppColors.white),
            ),
            AppSpacing.horizontalGapMD,
            const Expanded(child: Text('Energy Habis!')),
          ],
        ),
        content: const Text(
          'Tunggu regenerasi atau isi ulang energy untuk melanjutkan latihan.',
        ),
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
}

// ============================================================================
// STATEFUL ENERGY DIALOG - Real-time Countdown
// ============================================================================

class _EnergyDialog extends StatefulWidget {
  final EnergyModel energy;
  final bool isPremium;

  const _EnergyDialog({required this.energy, required this.isPremium});

  @override
  State<_EnergyDialog> createState() => _EnergyDialogState();
}

class _EnergyDialogState extends State<_EnergyDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update UI setiap detik untuk countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentEnergy = widget.energy.calculateCurrentEnergy();
    final maxEnergy = widget.energy.max;
    final isFull = currentEnergy >= maxEnergy;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header dengan gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isPremium
                      ? [const Color(0xFFFFFBF0), const Color(0xFFFFF5D6)]
                      : [const Color(0xFFFFEFEF), const Color(0xFFFFE5E5)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isPremium
                          ? Icons.bolt_rounded
                          : Icons.favorite_rounded,
                      color: widget.isPremium
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFFF4B4B),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isPremium ? 'Unlimited' : 'Energy',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3C3C3C),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          widget.isPremium ? 'Premium Member' : 'Sistem Energi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: widget.isPremium
                  ? _buildPremiumContent()
                  : _buildFreeContent(currentEnergy, maxEnergy, isFull),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF58CC02),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Premium content - compact
  Widget _buildPremiumContent() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.all_inclusive,
                size: 40,
                color: Color(0xFFFFD700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Energy Tanpa Batas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3C3C3C),
                ),
              ),
              const SizedBox(height: 16),
              _buildPremiumBenefit(Icons.check_circle, 'Latihan sepuasnya'),
              const SizedBox(height: 8),
              _buildPremiumBenefit(Icons.check_circle, 'Tanpa iklan'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumBenefit(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF58CC02)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  // Free content - compact dengan real-time countdown
  Widget _buildFreeContent(int currentEnergy, int maxEnergy, bool isFull) {
    // Real-time countdown calculation
    final now = DateTime.now();
    final lastRegen = widget.energy.lastRegen;
    final secondsPassed = now.difference(lastRegen).inSeconds;
    final secondsPerEnergy = widget.energy.regenRate * 60;
    final secondsInCurrentCycle = secondsPassed % secondsPerEnergy;
    final secondsRemaining = secondsPerEnergy - secondsInCurrentCycle;
    final regenProgress = secondsInCurrentCycle / secondsPerEnergy;
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    final countdown =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Column(
      children: [
        // Energy count - compact
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$currentEnergy',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3C3C3C),
                letterSpacing: -1.5,
                height: 1.0,
              ),
            ),
            Text(
              ' / $maxEnergy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Compact energy bar
        Container(
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: currentEnergy / maxEnergy,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF4B4B), Color(0xFFFF6B6B)],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                // ✅ TAMBAH INI
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      maxEnergy,
                      (i) => Icon(
                        i < currentEnergy
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: i < currentEnergy
                            ? Colors.white
                            : Colors.grey[400],
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Compact info row
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                Icons.autorenew_rounded,
                '${widget.energy.regenRate} min',
                'Per energy',
                const Color(0xFF58CC02),
              ),
            ),
            if (!isFull) ...[
              const SizedBox(width: 12),
              Expanded(child: _buildCountdownCard(countdown, regenProgress)),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Compact upgrade CTA
        InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.premium);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBF0), Color(0xFFFFF5D6)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Upgrade ke PRO',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3C3C3C),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3C3C3C),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCard(String countdown, double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFF4B4B)),
                ),
              ),
              const Icon(
                Icons.schedule_rounded,
                color: Color(0xFFFF4B4B),
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            countdown,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3C3C3C),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'Berikutnya',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// UPDATE: Ganti _buildEnergyWidget onTap
// ============================================================================
// Di method _buildEnergyWidget(), ganti onTap menjadi:
// onTap: () => _showEnergyDialog(context),
