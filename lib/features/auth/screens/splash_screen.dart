// lib/features/auth/screens/splash_screen_clean.dart

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../../../app/routes.dart';
import '../../../core/services/storage_service.dart';

/// Professional Splash Screen with smooth animations
/// Handles: Auth state, Onboarding status, Goal setting status
/// Fully Responsive: Mobile, Tablet, Desktop
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSplashSequence();
  }

  void _initAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  Future<void> _startSplashSequence() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    await _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final storage = StorageService.instance;

      // FLOW 1: User is NOT logged in
      if (user == null) {
        final hasSeenOnboarding = storage.isOnboardingCompleted;
        final hasEverLoggedIn = storage.hasEverLoggedIn;

        if (!hasEverLoggedIn && !hasSeenOnboarding) {
          _navigateTo(AppRoutes.onboarding);
        } else {
          _navigateTo(AppRoutes.login);
        }
        return;
      }

      // FLOW 2: Check email verification
      if (!user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        _navigateTo(AppRoutes.login);
        return;
      }

      // FLOW 3: Check Firestore user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _navigateTo(AppRoutes.onboarding);
        return;
      }

      final userData = userDoc.data()!;

      // FLOW 4: Check data completeness
      final String? goal = userData['goal'] as String?;
      if (goal == null || goal.isEmpty) {
        _navigateTo(AppRoutes.goalSetting);
        return;
      }

      final String? displayName = userData['displayName'] as String?;
      if (displayName == null || displayName.isEmpty) {
        _navigateTo(AppRoutes.onboarding);
        return;
      }

      // FLOW 5: Everything complete → Go to Home
      await storage.setHasEverLoggedIn(true);
      await storage.setOnboardingCompleted(true);
      await storage.setGoalCompleted();

      _navigateTo(AppRoutes.home);
    } catch (e) {
      debugPrint('❌ Splash navigation error: $e');

      if (e.toString().contains('firebase') ||
          e.toString().contains('network')) {
        final storage = StorageService.instance;
        if (storage.hasEverLoggedIn && storage.isOnboardingCompleted) {
          _navigateTo(AppRoutes.home);
          return;
        }
      }

      _navigateTo(AppRoutes.login);
    }
  }

  void _navigateTo(String route) {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF58CC02),
      body: ResponsiveBuilder(
        builder: (context, deviceType) {
          return Stack(
            children: [
              // Background gradient
              _buildBackground(),

              // Main content
              _buildMainContent(context, deviceType),

              // Loading indicator
              _buildLoadingIndicator(context, deviceType),

              // Version info
              _buildVersionInfo(context, deviceType),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF58CC02),
            Color(0xFF46A302),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, DeviceType deviceType) {
    final maxWidth = ResponsiveHelper.valueByDevice(
      context: context,
      mobile: double.infinity,
      tablet: 500.0,
      desktop: 600.0,
    );

    final horizontalPadding = ResponsiveHelper.valueByDevice(
      context: context,
      mobile: 20.0,
      tablet: 40.0,
      desktop: 60.0,
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  _buildLogo(context, deviceType),

                  SizedBox(
                    height: ResponsiveHelper.valueByDevice(
                      context: context,
                      mobile: 30.0,
                      tablet: 40.0,
                      desktop: 50.0,
                    ),
                  ),

                  // App name
                  _buildAppName(context, deviceType),

                  SizedBox(
                    height: ResponsiveHelper.valueByDevice(
                      context: context,
                      mobile: 8.0,
                      tablet: 12.0,
                      desktop: 16.0,
                    ),
                  ),

                  // Tagline
                  _buildTagline(context, deviceType),

                  // Extra tagline for tablet/desktop
                  if (deviceType != DeviceType.mobile) ...[
                    const SizedBox(height: 12),
                    _buildExtraTagline(context, deviceType),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, DeviceType deviceType) {
    final logoSize = ResponsiveHelper.valueByDevice(
      context: context,
      mobile: MediaQuery.of(context).size.width * 0.4,
      tablet: 220.0,
      desktop: 280.0,
    );

    final borderRadius = ResponsiveHelper.valueByDevice(
      context: context,
      mobile: 30.0,
      tablet: 35.0,
      desktop: 40.0,
    );

    final shadowBlur = ResponsiveHelper.valueByDevice(
      context: context,
      mobile: 30.0,
      tablet: 35.0,
      desktop: 40.0,
    );

    final shadowOffset = ResponsiveHelper.valueByDevice(
      context: context,
      mobile: 10.0,
      tablet: 12.0,
      desktop: 15.0,
    );

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: shadowBlur,
            offset: Offset(0, shadowOffset),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          'assets/Logo.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildAppName(BuildContext context, DeviceType deviceType) {
    final fontSize = ResponsiveHelper.valueByDevice(
      context: context,
      mobile: 36.0,
      tablet: 48.0,
      desktop: 56.0,
    );

    return Text(
      'LulusASN',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 1.5,
        shadows: const [
          Shadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }

  Widget _buildTagline(BuildContext context, DeviceType deviceType) {
    final fontSize = ResponsiveHelper.valueByDevice(
      context: context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 22.0,
    );

    return Text(
      'Persiapan Tes CPNS & PPPK',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: Colors.white.withOpacity(0.9),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildExtraTagline(BuildContext context, DeviceType deviceType) {
    final fontSize = ResponsiveHelper.valueByDevice(
      context: context,
      mobile: 14.0,
      tablet: 14.0,
      desktop: 16.0,
    );

    return Text(
      'Platform Belajar Terlengkap untuk ASN',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: Colors.white.withOpacity(0.8),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context, DeviceType deviceType) {
    final bottomPosition = ResponsiveHelper.valueByDevice(
      context: context,
      mobile: 60.0,
      tablet: 80.0,
      desktop: 100.0,
    );

    final indicatorSize = ResponsiveHelper.valueByDevice(
      context: context,
      mobile: 30.0,
      tablet: 35.0,
      desktop: 40.0,
    );

    final textSize = ResponsiveHelper.valueByDevice(
      context: context,
      mobile: 14.0,
      tablet: 16.0,
      desktop: 18.0,
    );

    final spacing = ResponsiveHelper.valueByDevice(
      context: context,
      mobile: 20.0,
      tablet: 22.0,
      desktop: 24.0,
    );

    return Positioned(
      bottom: bottomPosition,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            SizedBox(
              width: indicatorSize,
              height: indicatorSize,
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(height: spacing),
            Text(
              'Memuat...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: textSize,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo(BuildContext context, DeviceType deviceType) {
    final bottomPosition = ResponsiveHelper.valueByDevice(
      context: context,
      mobile: 20.0,
      tablet: 30.0,
      desktop: 40.0,
    );

    final textSize = ResponsiveHelper.valueByDevice(
      context: context,
      mobile: 12.0,
      tablet: 13.0,
      desktop: 14.0,
    );

    return Positioned(
      bottom: bottomPosition,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Text(
          'Version 1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: textSize,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
// lib/core/utils/responsive_helper.dart


/// Helper class untuk menentukan ukuran device dan responsive values
class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  // Device type detection
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
          MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  // Get value based on device type
  static T valueByDevice<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  // Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  // Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: valueByDevice(
        context: context,
        mobile: 16.0,
        tablet: 32.0,
        desktop: 48.0,
      ),
      vertical: valueByDevice(
        context: context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
    );
  }

  // Get max content width for desktop/tablet
  static double getMaxContentWidth(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: double.infinity,
      tablet: 700,
      desktop: 1200,
    );
  }

  // Font sizes
  static double getFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return valueByDevice(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// Widget untuk membuat responsive layout dengan builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = _getDeviceType(context);
    return builder(context, deviceType);
  }

  DeviceType _getDeviceType(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return DeviceType.desktop;
    } else if (ResponsiveHelper.isTablet(context)) {
      return DeviceType.tablet;
    }
    return DeviceType.mobile;
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
}