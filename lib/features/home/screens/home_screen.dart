// lib/features/home/screens/home_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/services/firebase_service.dart';
import 'package:lulusasn/features/home/models/energy_model.dart';
import 'package:lulusasn/features/home/models/streak_model.dart';
import 'package:lulusasn/features/home/services/energy_service.dart';
import 'package:lulusasn/features/home/services/streak_service.dart';
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
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadEnergyData();
    _startEnergyTimer();
  }

  @override
  void dispose() {
    _energyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, user?.displayName ?? 'User', screenWidth),
      body: _buildResponsiveBody(context, screenWidth),
    );
  }

  void _startEnergyTimer() {
    _energyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _currentEnergy != null) {
        setState(() {});
      }
    });
  }

  Future<void> _loadEnergyData() async {
    final userId = FirebaseService.instance.currentUser?.uid;
    if (userId == null) return;

    final userDoc = await FirebaseService.instance.firestore
        .collection('users')
        .doc(userId)
        .get();

    final energyService = EnergyService();
    final energy = await energyService.getEnergy();
    final isPremium = userDoc.data()?['isPremium'] as bool? ?? false;

    if (mounted) {
      setState(() {
        _currentEnergy = energy;
        _isPremium = isPremium;
      });
    }
  }

  // ============================================================================
  // DUOLINGO-STYLE APP BAR
  // ============================================================================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String userName,
    double screenWidth,
  ) {
    final isMobile = screenWidth < _Breakpoints.mobile;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      toolbarHeight: isMobile ? 64 : 72,
      automaticallyImplyLeading: false, // ✅ Hilangkan tombol back
      title: Row(
        children: [
          // Logo/Brand
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF58CC02),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'LULUS',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Streak Display
        if (_currentEnergy != null) ...[
          _buildStreakWidget(context, isMobile),
          const SizedBox(width: 8),
        ],

        // Energy Display
        if (_currentEnergy != null) ...[
          _buildEnergyWidget(context, isMobile),
          const SizedBox(width: 12),
        ],

        // Profile Menu Button
        PopupMenuButton<String>(
          offset: const Offset(0, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: Icon(Icons.person, size: 20, color: Colors.grey[700]),
          ),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 20, color: Colors.grey[700]),
                  const SizedBox(width: 12),
                  const Text(
                    'Profil',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: Color(0xFFFF4B4B),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF4B4B),
                    ),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'profile') {
              Navigator.pushNamed(context, AppRoutes.profile);
            } else if (value == 'logout') {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  content: const Text(
                    'Apakah Anda yakin ingin keluar?',
                    style: TextStyle(fontSize: 15),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3C3C3C),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4B4B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                await FirebaseService.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                }
              }
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

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
  // ENERGY WIDGET (Duolingo Style)
  // ============================================================================

  Widget _buildEnergyWidget(BuildContext context, bool isMobile) {
    if (_currentEnergy == null) return const SizedBox.shrink();

    final currentEnergy = _currentEnergy!.calculateCurrentEnergy();
    final maxEnergy = _currentEnergy!.max;
    final isFull = currentEnergy >= maxEnergy;

    // Calculate time until next energy
    String timeText = '';
    if (!_isPremium && !isFull) {
      final minutesUntilNext = _currentEnergy!.minutesUntilNext();
      final now = DateTime.now();
      final lastRegen = _currentEnergy!.lastRegen;
      final totalSeconds = minutesUntilNext * 60;
      final elapsedSeconds =
          now.difference(lastRegen).inSeconds %
          (_currentEnergy!.regenRate * 60);
      final remainingSeconds =
          totalSeconds - (elapsedSeconds % (_currentEnergy!.regenRate * 60));

      final minutes = remainingSeconds ~/ 60;
      final seconds = remainingSeconds % 60;
      timeText =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return GestureDetector(
      onTap: () => _showEnergyBottomSheet(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: _isPremium ? const Color(0xFFFFF9E6) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isPremium ? const Color(0xFFFFD700) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Heart Icon
            Icon(
              _isPremium ? Icons.bolt : Icons.favorite,
              color: _isPremium
                  ? const Color(0xFFFFD700)
                  : const Color(0xFFFF4B4B),
              size: isMobile ? 18 : 20,
            ),
            const SizedBox(width: 6),

            // Energy Count or "PRO"
            if (_isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$currentEnergy',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                      height: 1.0,
                    ),
                  ),
                  if (!isFull && timeText.isNotEmpty)
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        height: 1.0,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // STREAK WIDGET (Duolingo Style)
  // ============================================================================

  Widget _buildStreakWidget(BuildContext context, bool isMobile) {
    return FutureBuilder<StreakModel>(
      future: StreakService().getStreak(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final streak = snapshot.data!;

        return GestureDetector(
          onTap: () => _showStreakBottomSheet(context, streak),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF9500), width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: const Color(0xFFFF9500),
                  size: isMobile ? 18 : 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '${streak.current}',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================================
  // BOTTOM SHEETS
  // ============================================================================

  void _showEnergyBottomSheet(BuildContext context) {
    if (_currentEnergy == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isPremium ? Icons.bolt : Icons.favorite,
                  color: _isPremium
                      ? const Color(0xFFFFD700)
                      : const Color(0xFFFF4B4B),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  _isPremium ? 'Unlimited Energy' : 'Energy Sistem',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isPremium) ...[
              const Text('✨ Anda adalah Premium Member!'),
              const SizedBox(height: 8),
              const Text('• Energy tanpa batas'),
              const Text('• Latihan sepuasnya'),
              const Text('• Tanpa iklan'),
            ] else ...[
              Text(
                'Energy: ${_currentEnergy!.calculateCurrentEnergy()}/${_currentEnergy!.max}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Regenerasi: 1 energy per ${_currentEnergy!.regenRate} menit',
              ),
              const SizedBox(height: 8),
              Text('Total digunakan: ${_currentEnergy!.totalUsed}'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Color(0xFFFFD700)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Upgrade ke PRO untuk energy unlimited!',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF58CC02),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakBottomSheet(BuildContext context, StreakModel streak) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFFF9500),
                  size: 32,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Streak Anda',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Current Streak: ${streak.current} hari',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('Longest Streak: ${streak.longest} hari'),
            const SizedBox(height: 8),
            Text('Status: ${streak.getStatus().displayText}'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF58CC02),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
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
          AppRoutes.examPre, // ✅ FIX: Ganti dari AppRoutes.exam ke AppRoutes.examPre
          arguments: {
            'category': category,
            'questionCount': 10, // Default 10 soal
            'energyCost': 1,     // 1 energy per exam
            'isPremium': false,  // TODO: Get from user doc
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
