import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import '../../../app/routes.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/extensions.dart';

/// Onboarding screen dengan 3 slides
/// Performance optimized: PageView with const widgets, minimal rebuilds
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Onboarding slides data (const for performance)
  static const _slides = [
    _OnboardingSlide(
      icon: LineIcons.graduationCap,
      iconColor: AppColors.blue,
      title: 'LATIHAN SOAL\nBERKUALITAS',
      description: 'Ribuan soal CPNS, BUMN, dan Kedinasan yang selalu diperbarui sesuai standar terbaru.',
    ),
    _OnboardingSlide(
      icon: Icons.bolt,
      iconColor: AppColors.orange,
      title: 'SISTEM\nGAMIFIKASI',
      description: 'Energy, streak, leaderboard, dan reward yang membuat belajar lebih seru dan konsisten.',
    ),
    _OnboardingSlide(
      icon: LineIcons.lineChart,
      iconColor: AppColors.green,
      title: 'PROGRESS\nTERUKUR',
      description: 'Analisis mendalam tentang kekuatan dan kelemahan kamu di setiap kategori soal.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _onNext() async {
    if (_currentPage < _slides.length - 1) {
      // Next page
      await _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete onboarding
      await _completeOnboarding();
    }
  }

  Future<void> _onSkip() async {
    await _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as completed
    await StorageService.instance.setOnboardingCompleted(true);

    if (!mounted) return;

    // Navigate to goal setting
    Navigator.pushReplacementNamed(context, AppRoutes.goalSetting);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (top right)
            if (_currentPage < _slides.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: AppSpacing.paddingMD,
                  child: TextButton(
                    onPressed: _onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text(
                      'LEWATI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: AppSpacing.xxl),

            // PageView slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _OnboardingSlideWidget(
                    slide: _slides[index],
                    isMobile: isMobile,
                  );
                },
              ),
            ),

            // Bottom section: indicator + button
            Padding(
              padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicators
                  _PageIndicator(
                    currentPage: _currentPage,
                    pageCount: _slides.length,
                  ),

                  AppSpacing.verticalGapLG,

                  // Next/Start button
                  SizedBox(
                    width: isMobile ? double.infinity : 400,
                    height: AppSpacing.buttonHeightLG,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        _currentPage < _slides.length - 1 ? 'LANJUT' : 'MULAI',
                        style: AppTextStyles.buttonLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ONBOARDING SLIDE DATA (Immutable)
// ============================================================================

class _OnboardingSlide {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });
}

// ============================================================================
// SLIDE WIDGET (Const-optimized)
// ============================================================================

class _OnboardingSlideWidget extends StatelessWidget {
  final _OnboardingSlide slide;
  final bool isMobile;

  const _OnboardingSlideWidget({
    required this.slide,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isMobile ? 400 : 500),
        padding: AppSpacing.paddingLG,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container (Neobrutalism style)
            Container(
              width: isMobile ? 120 : 160,
              height: isMobile ? 120 : 160,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(
                  color: AppColors.black,
                  width: AppSpacing.borderThick,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.black,
                    offset: AppSpacing.shadowLarge,
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                slide.icon,
                size: isMobile ? 60 : 80,
                color: slide.iconColor,
              ),
            ),

            SizedBox(height: isMobile ? AppSpacing.xl : AppSpacing.xxl),

            // Title
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 28 : 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                height: 1.1,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),

            // Description
            Text(
              slide.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PAGE INDICATOR (Minimal & Efficient)
// ============================================================================

class _PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const _PageIndicator({
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
            (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentPage == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentPage == index ? AppColors.black : AppColors.borderLight,
            border: Border.all(
              color: AppColors.black,
              width: 2,
            ),
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
    );
  }
}