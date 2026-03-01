// lib/app/routes.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../admin/pages/CreateTO.dart';
import '../admin/pages/ViewTO.dart';
import '../admin/pages/promotion_verification_screen.dart'
    show PromotionVerificationScreen;
import 'package:firebase_auth/firebase_auth.dart';
import '../users/TO/exam_review_screen.dart';
import '../users/TO/owned_tryout_screen.dart';
import '../users/TO/tryout_detail_screen.dart';
import '../users/TO/tryout_marketplace_screen.dart';
import '../users/auth/screens/goal_setting_screen.dart';
import 'package:lulusasn/users/auth/screens/login_screen.dart';
import '../users/home/screens/ProfileScreen.dart';
import '../users/main_navigation/main_screen..dart';
import 'theme.dart';

// ============================================================================
// ROUTE NAMES
// ============================================================================

abstract class AppRoutes {
  AppRoutes._();

  // Public
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String goalSetting = '/goal-setting';
  static const String onboarding = '/onboarding';

  // Authenticated
  static const String main = '/main';
  static const String home = '/home';
  static const String learn = '/learn';
  static const String leaderboard = '/leaderboard';
  static const String profile = '/profile';

  // Tryout
  static const String myTryout = '/my-tryout';
  static const String purchaseTryout = '/purchase-tryout';
  static const String tryoutDetail = '/tryout-detail';

  // Exam
  static const String examList = '/exam/list';
  static const String examPre = '/exam/pre';
  static const String examSession = '/exam/session';
  static const String examAd = '/exam/ad';
  static const String examResult = '/exam/result';
  static const String examReview = '/exam/review';

  // Learn
  static const String learnCategory = '/learn/category';
  static const String learnReview = '/learn/review';

  // Profile sub-pages
  static const String statistics = '/profile/statistics';
  static const String achievements = '/profile/achievements';
  static const String settings = '/profile/settings';

  // Payment
  static const String diamondPurchase = '/diamond';
  static const String premium = '/premium';
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment/success';
  static const String paymentFailed = '/payment/failed';

  // Admin
  static const String adminMain = '/admin-main';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminCreateTO = '/admin/create-to';
  static const String adminViewTO = '/admin/view-to';
  static const String adminVerificationTO = '/admin/verification';

  // Error
  static const String notFound = '/404';
}

// ============================================================================
// ROUTER
// ============================================================================

class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments; // bisa Map atau String tergantung route

    switch (settings.name) {
      // ── Public ──────────────────────────────────────────────────────────
      case AppRoutes.login:
        return _route(settings, const LoginScreen());

      case AppRoutes.goalSetting:
        return _route(settings, const GoalSettingScreen());

      // ── Authenticated ───────────────────────────────────────────────────
      case AppRoutes.main:
        return _route(settings, const MainNavigationScreen());

      case AppRoutes.profile:
        return _route(settings, const ProfileScreen());

      // ── Tryout ──────────────────────────────────────────────────────────
      case AppRoutes.myTryout:
        return _route(settings, const MyTryoutsScreen());

      // TryoutMarketplace tidak butuh currentGoal dari router.
      // Screen mengambil goal sendiri dari Firestore user doc.
      case AppRoutes.purchaseTryout:
        return _route(settings, const TryoutMarketplaceScreen());

      // Navigasi: Navigator.pushNamed(context, AppRoutes.tryoutDetail,
      //   arguments: {'tryoutId': 'abc123'})
      case AppRoutes.tryoutDetail:
        final map = args as Map<String, dynamic>? ?? {};
        final id = map['tryoutId'] as String? ?? '';
        if (id.isEmpty) return _fallback(settings);
        return _route(settings, TryoutDetailScreen(tryoutId: id));

      // Navigasi: Navigator.pushNamed(context, AppRoutes.examReview,
      //   arguments: {'resultId': 'xyz'})
      case AppRoutes.examReview:
        final map = args as Map<String, dynamic>? ?? {};
        final resultId = map['resultId'] as String? ?? '';
        if (resultId.isEmpty) return _fallback(settings);
        return _route(settings, ExamReviewScreen(resultId: resultId));

      // ── Admin ────────────────────────────────────────────────────────────
      case AppRoutes.adminMain:
        return _route(settings, const AdminMainNavigationScreen());

      case AppRoutes.adminCreateTO:
        return _route(settings, const CreateTryoutScreen());

      case AppRoutes.adminViewTO:
        return _route(settings, const ViewTryoutScreen());

      case AppRoutes.adminVerificationTO:
        return _route(settings, const PromotionVerificationScreen());

      // ── Error / default ──────────────────────────────────────────────────
      case AppRoutes.notFound:
      default:
        return _route(settings, const NotFoundScreen());
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) =>
      _route(settings, const NotFoundScreen());

  // ── Helpers ────────────────────────────────────────────────────────────────
  static MaterialPageRoute<dynamic> _route(RouteSettings s, Widget page) =>
      MaterialPageRoute(settings: s, builder: (_) => page);

  /// Fallback jika argumen wajib tidak tersedia — kembali ke NotFound
  static MaterialPageRoute<dynamic> _fallback(RouteSettings s) =>
      MaterialPageRoute(settings: s, builder: (_) => const NotFoundScreen());
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
// ignore_for_file: deprecated_member_use
// ─────────────────────────────────────────────────────────────────────────────
// 404 — NOT FOUND SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Gold accent strip ───────────────────────────────────
                Container(
                  width: 56,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: AppGradient.gold,
                    borderRadius: AppRadius.bFull,
                  ),
                ),
                AppSpacing.vlg,

                // ── 404 headline ────────────────────────────────────────
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppGradient.navy.createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    '404',
                    style: AppText.display.copyWith(
                      fontSize: 96,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -4,
                      height: 1,
                    ),
                  ),
                ),
                AppSpacing.vsm,

                Text(
                  'Halaman Tidak Ditemukan',
                  style: AppText.h2,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.vsm,

                Text(
                  'Sepertinya halaman yang kamu cari\nsudah dipindahkan atau tidak tersedia.',
                  style: AppText.bodySm,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.vxl,

                // ── CTA ─────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.splash,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Kembali ke Home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ErrorScreen extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorScreen({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Error icon badge ────────────────────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.softBg(AppColors.error),
                    borderRadius: AppRadius.bXl,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: AppColors.error,
                  ),
                ),
                AppSpacing.vlg,

                Text('Terjadi Kesalahan', style: AppText.h2),
                AppSpacing.vsm,

                Text(error, textAlign: TextAlign.center, style: AppText.bodySm),
                AppSpacing.vxl,

                // ── Actions ─────────────────────────────────────────────
                if (onRetry != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Coba Lagi'),
                    ),
                  ),
                  AppSpacing.vsm,
                ],

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.splash,
                    ),
                    child: const Text('Kembali ke Home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class LoadingScreen extends StatelessWidget {
  final String? message;
  const LoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Navy + Gold branded loader ──────────────────────────────
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring — gold
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.gold.withOpacity(0.3),
                    ),
                    value: 1,
                  ),
                  // Spinner — navy
                  const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            if (message != null) ...[
              AppSpacing.vmd,
              Text(message!, style: AppText.bodySm),
            ],
          ],
        ),
      ),
    );
  }
}
