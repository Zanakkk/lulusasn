// lib/app/routes.dart

import 'package:flutter/material.dart';

// Lazy imports for code splitting
import 'package:lulusasn/features/auth/screens/splash_screen.dart'
    deferred as splash;
import 'package:lulusasn/features/auth/screens/login_screen.dart'
    deferred as login;
import 'package:lulusasn/features/home/screens/home_screen.dart'
    deferred as home;

import '../features/auth/screens/goal_setting_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';

// ============================================================================
// ROUTE NAMES
// ============================================================================

/// Static route name constants.
/// Never use string literals for navigation - always reference these.
abstract class AppRoutes {
  AppRoutes._();

  // ==================== PUBLIC ROUTES ====================
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String goalSetting = '/goal-setting';
  static const String onboarding = '/onboarding';

  // ==================== AUTHENTICATED ROUTES ====================
  static const String home = '/home';
  static const String examSession = '/exam';
  static const String examResult = '/exam/result';

  static const String learn = '/learn';
  static const String learnCategory = '/learn/category';
  static const String learnReview = '/learn/review';

  static const String leaderboard = '/leaderboard';
  static const String userProfile = '/user';

  static const String exam = '/exam';
  static const String premium = '/premium';


  static const String profile = '/profile';
  static const String statistics = '/profile/statistics';
  static const String achievements = '/profile/achievements';
  static const String settings = '/profile/settings';

  // ==================== PAYMENT ROUTES ====================
  static const String diamondPurchase = '/diamond';
  static const String premiumUpgrade = '/premium';
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment/success';
  static const String paymentFailed = '/payment/failed';

  // ==================== ERROR ROUTES ====================
  static const String notFound = '/404';

  // ==================== ADMIN ROUTES ====================
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminQuestions = '/admin/questions';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminPayments = '/admin/payments';
}

// ============================================================================
// ROUTE GENERATOR
// ============================================================================

/// Centralized route generator for the entire app.
///
/// Performance:
/// - Uses deferred loading for code splitting
/// - Stateless - no rebuilds on navigation
///
/// Web-specific:
/// - Preserves browser back/forward
/// - Supports deep linking
/// - Clean URLs (no hash fragments)
class AppRouter {
  AppRouter._();

  /// Generate route based on RouteSettings
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? AppRoutes.notFound;
    final Object? _ = settings.arguments;

    switch (routeName) {
      // ==================== PUBLIC ROUTES ====================
      case AppRoutes.splash:
        return _buildRoute(settings, (_) async {
          await splash.loadLibrary();
          return splash.SplashScreen();
        });

      case AppRoutes.login:
        return _buildRoute(settings, (_) async {
          await login.loadLibrary();
          return login.LoginScreen();
        });

      // ==================== AUTHENTICATED ROUTES ====================
      case AppRoutes.home:
        return _buildRoute(settings, (_) async {
          await home.loadLibrary();
          return home.HomeScreen();
        });

      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case AppRoutes.goalSetting:
        return MaterialPageRoute(builder: (_) => const GoalSettingScreen());

      // TODO: Add more routes as features are built
      // case AppRoutes.examSession:
      // case AppRoutes.learn:
      // case AppRoutes.profile:
      // etc...

      // ==================== ERROR ROUTES ====================
      case AppRoutes.notFound:
      default:
        return _buildRoute(settings, (_) async => const NotFoundScreen());
    }
  }

  /// Unknown route handler
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const NotFoundScreen(),
    );
  }

  /// Build MaterialPageRoute with deferred builder
  static MaterialPageRoute _buildRoute(
    RouteSettings settings,
    Future<Widget> Function(BuildContext) builder,
  ) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return FutureBuilder<Widget>(
          future: builder(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return ErrorScreen(error: snapshot.error.toString());
              }
              return snapshot.data!;
            }
            return const LoadingScreen();
          },
        );
      },
    );
  }
}

// ============================================================================
// FALLBACK SCREENS
// ============================================================================

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '404',
              style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Halaman tidak ditemukan'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.splash),
              child: const Text('KEMBALI KE HOME'),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Terjadi Kesalahan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black),
      ),
    );
  }
}
