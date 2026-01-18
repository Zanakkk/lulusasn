// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import '../../../app/routes.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/extensions.dart';
import '../service/user_service.dart';

/// Goal setting screen untuk first-time user
/// Performance: Minimal state, optimistic UI updates
class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  String? _selectedGoal;
  bool _isLoading = false;

  // Goal options (const for performance)
  static const _goals = [
    _Goal(
      id: 'cpns',
      icon: LineIcons.userTie,
      title: 'CPNS',
      subtitle: 'Calon Pegawai Negeri Sipil',
      color: AppColors.blue,
    ),
    _Goal(
      id: 'bumn',
      icon: LineIcons.building,
      title: 'BUMN',
      subtitle: 'Badan Usaha Milik Negara',
      color: AppColors.purple,
    ),
    _Goal(
      id: 'kedinasan',
      icon: LineIcons.university,
      title: 'KEDINASAN',
      subtitle: 'Sekolah Kedinasan',
      color: AppColors.green,
    ),
    _Goal(
      id: 'other',
      icon: LineIcons.bullseye,
      title: 'LAINNYA',
      subtitle: 'Persiapan umum',
      color: AppColors.orange,
    ),
  ];

  void _onGoalTapped(String goalId) {
    setState(() => _selectedGoal = goalId);
  }

  Future<void> _onContinue() async {
    if (_selectedGoal == null) {
      context.showError('Pilih tujuan kamu terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseService.instance.currentUser;
      if (user == null) throw Exception('User not found');

      // ✅ USE UserService (GANTI SEMUA CODE LAMA)
      await UserService.instance.createNewUser(
        userId: user.uid,
        email: user.email!,
        displayName: user.displayName,
        photoURL: user.photoURL,
        goal: _selectedGoal,
      );

      // Mark first launch as complete
      await StorageService.instance.setFirstLaunchCompleted();

      if (!mounted) return;

      // Navigate to home (replace entire stack)
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );

      // Show success message
      context.showSuccess('Selamat datang di LulusASN! 🎉');
    } catch (e) {
      if (!mounted) return;
      context.showError('Gagal menyimpan data: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'PILIH TUJUAN',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: AppColors.black,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppColors.black),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Description
            Padding(
              padding: AppSpacing.paddingLG,
              child: Text(
                'Pilih tujuan utama kamu agar kami bisa memberikan rekomendasi latihan yang sesuai',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            // Goals list (scrollable)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: AppSpacing.paddingMD,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 600,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _goals.map((goal) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _GoalCard(
                            goal: goal,
                            isSelected: _selectedGoal == goal.id,
                            onTap: () => _onGoalTapped(goal.id),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
              child: SizedBox(
                width: isMobile ? double.infinity : 400,
                height: AppSpacing.buttonHeightLG,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    disabledBackgroundColor: AppColors.textSecondary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text(
                          'LANJUTKAN',
                          style: AppTextStyles.buttonLarge,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// GOAL DATA CLASS (Immutable)
// ============================================================================

class _Goal {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _Goal({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

// ============================================================================
// GOAL CARD WIDGET (Performance optimized)
// ============================================================================

class _GoalCard extends StatelessWidget {
  final _Goal goal;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          color: isSelected ? goal.color.withOpacity(0.1) : AppColors.white,
          border: Border.all(
            color: isSelected ? goal.color : AppColors.black,
            width: isSelected ? 4 : 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? goal.color : AppColors.black,
              offset: isSelected
                  ? AppSpacing.shadowMedium
                  : AppSpacing.shadowSmall,
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: goal.color,
                border: Border.all(color: AppColors.black, width: 3),
              ),
              child: Icon(goal.icon, size: 32, color: AppColors.white),
            ),

            AppSpacing.horizontalGapMD,

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goal.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark (if selected)
            if (isSelected)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: goal.color,
                  border: Border.all(color: AppColors.black, width: 2),
                ),
                child: const Icon(
                  LineIcons.check,
                  size: 20,
                  color: AppColors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
