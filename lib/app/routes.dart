// lib/app/routes.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lulusasn/features/home/screens/StatisticScreen.dart';

import '../admin/Dashboard/AdminDashboard.dart';
import '../admin/pages/CreateTO.dart';
import '../admin/pages/ViewTO.dart';
import '../features/TO/owned_tryout_screen.dart';
import '../features/TO/tryout_detail_screen.dart';
import '../features/TO/tryout_marketplace_screen.dart';
import '../features/auth/screens/goal_setting_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import 'package:lulusasn/features/auth/screens/login_screen.dart';
import '../features/exam/models/exam_result_model.dart';
import '../features/exam/screens/ad_interstitial_page.dart';
import '../features/exam/screens/exam_list_screen.dart';
import '../features/exam/screens/exam_result_screen.dart';
import '../features/exam/screens/exam_review_screen.dart';
import '../features/exam/screens/exam_session_screen.dart';
import '../features/exam/screens/pre_exam_screen.dart';
import '../features/home/screens/ProfileScreen.dart';
import '../features/home/screens/leaderboard_screen.dart';
import '../features/main_navigation/main_screen..dart';

import 'package:lulusasn/features/auth/screens/splash_screen.dart';
import 'package:lulusasn/features/home/screens/home_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

// ============================================================================
// ROUTE NAMES
// ============================================================================

// lib/app/routes.dart

// ============================================================================
// ROUTE NAMES
// ============================================================================
// lib/app/routes.dart

// ============================================================================
// ROUTE NAMES
// ============================================================================

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
  static const String main = '/main';
  static const String home = '/home';
  static const String learn = '/learn';
  static const String leaderboard = '/leaderboard';
  static const String profile = '/profile';

  // ==================== Tryout ROUTES ====================
  static const String mytryout = '/my-tryout';
  static const String purchasetryout = '/purchase-tryout';
  static const String tryoutDetail = '/detail-tryout';

  // ==================== EXAM ROUTES ====================

  static const String examList = '/exam/list'; // 🆕 TAMBAH INI
  static const String examPre = '/exam/pre';
  static const String examSession = '/exam/session';
  static const String examAd = '/exam/ad'; // 🆕 NEW - Ad Interstitial Route
  static const String examResult = '/exam/result';
  static const String examReview = '/exam/review';

  // ==================== LEARN ROUTES ====================
  static const String learnCategory = '/learn/category';
  static const String learnReview = '/learn/review';

  // ==================== PROFILE ROUTES ====================
  static const String userProfile = '/user';
  static const String statistics = '/profile/statistics';
  static const String achievements = '/profile/achievements';
  static const String settings = '/profile/settings';

  // ==================== PAYMENT ROUTES ====================
  static const String diamondPurchase = '/diamond';
  static const String premium = '/premium';
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment/success';
  static const String paymentFailed = '/payment/failed';

  // ==================== ERROR ROUTES ====================
  static const String notFound = '/404';

  // ==================== ADMIN ROUTES ====================
  static const String adminMain = '/admin-main';
  static const String adminCreateTO = '/admin/create-to';
  static const String adminViewTO = '/admin/view-to';
  static const String adminDashboard = '/admin/dashboard';
}

// ============================================================================
// ROUTE GENERATOR
// ============================================================================

class AppRouter {
  AppRouter._();

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? AppRoutes.notFound;
    final Object? arguments = settings.arguments; // ✅ FIX: Extract arguments

    switch (routeName) {
      // ==================== PUBLIC ROUTES ====================
      case AppRoutes.splash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );

      case AppRoutes.onboarding:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingScreen(),
        );

      case AppRoutes.goalSetting:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const GoalSettingScreen(),
        );

      // ==================== AUTHENTICATED ROUTES ====================
      case AppRoutes.home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainNavigationScreen(),
        );
      case AppRoutes.adminMain:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminMainNavigationScreen(),
        );

      case AppRoutes.profile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProfileScreen(),
        );
      case AppRoutes.leaderboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LeaderboardScreen(),
        );

      case AppRoutes.statistics:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => StatisticsScreen(),
        );

      // Di dalam switch statement, tambahkan setelah case AppRoutes.adminMain:

      case AppRoutes.adminCreateTO:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CreateTryoutScreen(),
        );

      case AppRoutes.adminViewTO:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ViewTryoutScreen(),
        );

      case AppRoutes.mytryout:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MyTryoutsScreen(),
        );
      case AppRoutes.purchasetryout:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TryoutMarketplaceScreen(),
        );
      case AppRoutes.tryoutDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TryoutDetailScreen(tryoutId: ''),
        );

      case AppRoutes.adminDashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminDashboardScreen(),
        );
      // ==================== EXAM ROUTES ====================
      case AppRoutes.examList:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ExamListScreen(),
        );
      case AppRoutes.examPre:
        // ✅ FIX: Safe argument parsing
        final args = arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PreExamScreen(
            packageId: args['packageId'] as String?, // ✅ Extract dari args
            category: args['category'] as String? ?? 'TWK',
            questionCount: args['questionCount'] as int? ?? 10,
            energyCost: args['energyCost'] as int? ?? 1,
            isPremium: args['isPremium'] as bool? ?? false,
          ),
        );

      case AppRoutes.examSession:
        // ✅ FIX: Safe argument parsing
        final args = arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ExamSessionScreen(
            category: args['category'] as String? ?? 'TWK',
            questionCount: args['questionCount'] as int? ?? 10,
          ),
        );

      case AppRoutes.examAd:
        final args = arguments as Map<String, dynamic>? ?? {};
        final result = args['result'] as ExamResultModel?;

        if (result == null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const HomeScreen(),
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AdInterstitialScreen(
            result: result,
          ), // ✅ Gunakan AdInterstitialPage
        );

      case AppRoutes.examResult:
        // ✅ FIX: Safe argument parsing dengan null check
        final args = arguments as Map<String, dynamic>? ?? {};
        final result = args['result'] as ExamResultModel?;

        if (result == null) {
          // Redirect ke home jika result null
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const HomeScreen(),
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ExamResultScreen(result: result),
        );
      case AppRoutes.examReview:
        final args = arguments as Map<String, dynamic>? ?? {};
        final examId = args['examId'] as String?;

        if (examId == null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const HomeScreen(),
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ExamReviewScreen(examId: examId),
        );
      // ==================== ERROR ROUTES ====================
      case AppRoutes.notFound:
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const NotFoundScreen(),
        );
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const NotFoundScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF58CC02),
              ),
            ),
          );
        }

        // Not logged in
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // ✅ User logged in - cek apakah admin
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userDoc) {
            // Loading user data
            if (userDoc.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF58CC02),
                  ),
                ),
              );
            }

            // Error atau user doc tidak ada
            if (!userDoc.hasData || !userDoc.data!.exists) {
              return const LoginScreen();
            }

            // Cek field adminTrue
            final userData = userDoc.data!.data() as Map<String, dynamic>;
            final isAdmin = userData['admin'] ?? false;

            // Arahkan sesuai role
            if (isAdmin) {
              return const AdminMainNavigationScreen();
            } else {
              return const MainNavigationScreen();
            }
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
