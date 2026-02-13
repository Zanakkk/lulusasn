// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import '../../../app/routes.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/extensions.dart';

/// Duolingo-inspired onboarding screen with smooth animations
/// Features: Parallax effects, smooth transitions, responsive design
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  double _pageOffset = 0.0;

  late AnimationController _fadeController;
  late AnimationController _scaleController;

  // Duolingo-inspired slides with vibrant colors and engaging copy
  static const _slides = [
    _OnboardingSlide(
      icon: LineIcons.graduationCap,
      iconColor: Color(0xFF1CB0F6), // Duolingo blue
      backgroundColor: Color(0xFFDDF4FF),
      title: 'Ribuan soal berkualitas',
      description:
      'Latihan CPNS, BUMN, dan Kedinasan yang selalu diperbarui sesuai standar terbaru.',
      accentColor: Color(0xFF1CB0F6),
    ),
    _OnboardingSlide(
      icon: LineIcons.fire,
      iconColor: Color(0xFFFF9600), // Duolingo orange
      backgroundColor: Color(0xFFFFF4E6),
      title: 'Belajar lebih seru',
      description:
      'Raih streak harian, kumpulkan poin, dan bersaing di leaderboard bersama teman!',
      accentColor: Color(0xFFFF9600),
    ),
    _OnboardingSlide(
      icon: Icons.show_chart,
      iconColor: Color(0xFF58CC02), // Duolingo green
      backgroundColor: Color(0xFFE7F7E1),
      title: 'Pantau progress kamu',
      description:
      'Analisis mendalam untuk tahu kekuatan dan area yang perlu ditingkatkan.',
      accentColor: Color(0xFF58CC02),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageScroll);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.8,
      upperBound: 1.0,
    )..forward();
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    if (_pageController.hasClients) {
      setState(() {
        _pageOffset = _pageController.page ?? 0.0;
      });
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);

    // Animate on page change
    _scaleController.forward(from: 0.8);
  }

  Future<void> _onNext() async {
    if (_currentPage < _slides.length - 1) {
      await _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _completeOnboarding();
    }
  }

  Future<void> _onSkip() async {
    await _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await StorageService.instance.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = MediaQuery.of(context).size.width > 600 &&
        MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      backgroundColor: _slides[_currentPage].backgroundColor,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        color: _slides[_currentPage].backgroundColor,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = isMobile ? double.infinity :
              isTablet ? 700.0 : 1200.0;

              return Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: [
                      // Header with skip button
                      _buildHeader(isMobile),

                      // PageView slides with parallax
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          itemCount: _slides.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            // Calculate parallax offset
                            final pageOffset = (_pageOffset - index).abs();
                            final isCurrentPage = index == _currentPage;

                            return FadeTransition(
                              opacity: _fadeController,
                              child: ScaleTransition(
                                scale: _scaleController,
                                child: _OnboardingSlideWidget(
                                  slide: _slides[index],
                                  parallaxOffset: pageOffset,
                                  isCurrentPage: isCurrentPage,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Bottom section: indicator + button
                      _buildBottomSection(isMobile, isTablet),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentPage < _slides.length - 1)
            TextButton(
              onPressed: _onSkip,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 8 : 12,
                ),
              ),
              child: Text(
                'Lewati',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            )
          else
            SizedBox(height: isMobile ? 40 : 52),
        ],
      ),
    );
  }

  Widget _buildBottomSection(bool isMobile, bool isTablet) {
    final horizontalPadding = isMobile ? AppSpacing.lg :
    isTablet ? AppSpacing.xl : 48.0;
    final buttonWidth = isMobile ? double.infinity :
    isTablet ? 400.0 : 480.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.lg,
        horizontalPadding,
        isMobile ? AppSpacing.xl : AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicators (Duolingo style)
          _DuolingoPageIndicator(
            currentPage: _currentPage,
            pageCount: _slides.length,
            accentColor: _slides[_currentPage].accentColor,
          ),

          SizedBox(height: isMobile ? 32 : 40),

          // CTA Button (Duolingo style)
          SizedBox(
            width: buttonWidth,
            height: isMobile ? 50 : 56,
            child: ElevatedButton(
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: _slides[_currentPage].accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 12 : 16,
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.all(
                  Colors.white.withOpacity(0.1),
                ),
              ),
              child: Text(
                _currentPage < _slides.length - 1 ? 'Lanjutkan' : 'Mulai Sekarang',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ONBOARDING SLIDE DATA
// ============================================================================

class _OnboardingSlide {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String description;
  final Color accentColor;

  const _OnboardingSlide({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.description,
    required this.accentColor,
  });
}

// ============================================================================
// SLIDE WIDGET with Parallax
// ============================================================================
class _OnboardingSlideWidget extends StatelessWidget {
  final _OnboardingSlide slide;
  final double parallaxOffset;
  final bool isCurrentPage;

  const _OnboardingSlideWidget({
    required this.slide,
    required this.parallaxOffset,
    required this.isCurrentPage,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine device type based on width
        final width = constraints.maxWidth;
        final isMobile = width < 800;
        final isTablet = width >= 800 && width < 1024;

        // Responsive sizes
        final iconSize = isMobile ? 100.0 : (isTablet ? 130.0 : 150.0);
        final titleSize = isMobile ? 28.0 : (isTablet ? 32.0 : 36.0);
        final descSize = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);
        final maxWidth = isMobile ? 320.0 : (isTablet ? 420.0 : 480.0);
        final horizontalPadding = isMobile ? 20.0 : (isTablet ? 28.0 : 36.0);
        final iconTitleSpacing = isMobile ? 32.0 : (isTablet ? 40.0 : 48.0);
        final titleDescSpacing = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
        final iconBorderRadius = isMobile ? 24.0 : (isTablet ? 28.0 : 32.0);

        // Parallax effect calculation
        final opacity = (1 - parallaxOffset).clamp(0.0, 1.0);
        final scale = (1 - (parallaxOffset * 0.2)).clamp(0.8, 1.0);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Icon with Duolingo style
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: isCurrentPage ? 1.0 : 0.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (value * 0.2),
                          child: Transform.rotate(
                            angle: (1 - value) * 0.1,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(iconBorderRadius),
                          boxShadow: [
                            BoxShadow(
                              color: slide.iconColor.withOpacity(0.2),
                              blurRadius: isMobile ? 28 : (isTablet ? 32 : 36),
                              offset: Offset(0, isMobile ? 6 : (isTablet ? 8 : 10)),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          slide.icon,
                          size: iconSize * 0.5,
                          color: slide.iconColor,
                        ),
                      ),
                    ),

                    SizedBox(height: iconTitleSpacing),

                    // Title with fade-in animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: isCurrentPage ? 1.0 : 0.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        slide.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.2,
                          color: const Color(0xFF3C3C3C),
                        ),
                      ),
                    ),

                    SizedBox(height: titleDescSpacing),

                    // Description with delayed fade-in
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: isCurrentPage ? 1.0 : 0.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        slide.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: descSize,
                          fontWeight: FontWeight.w500,
                          height: 1.6,
                          color: const Color(0xFF777777),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// DUOLINGO-STYLE PAGE INDICATOR
// ============================================================================

class _DuolingoPageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final Color accentColor;

  const _DuolingoPageIndicator({
    required this.currentPage,
    required this.pageCount,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? accentColor : accentColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}