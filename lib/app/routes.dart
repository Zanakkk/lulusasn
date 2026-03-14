// lib/app/routes.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lulusasn/users/TO/payment/payment_status_screen.dart';
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
import 'dart:html' as html;
// ============================================================================
// ROUTE NAMES
// ============================================================================


abstract class AppRoutes {
  AppRoutes._();

  static const splash              = '/';
  static const login               = '/login';
  static const register            = '/register';
  static const forgotPassword      = '/forgot-password';
  static const goalSetting         = '/goal-setting';
  static const onboarding          = '/onboarding';
  static const main                = '/main';
  static const home                = '/home';
  static const learn               = '/learn';
  static const leaderboard         = '/leaderboard';
  static const profile             = '/profile';
  static const myTryout            = '/my-tryout';
  static const purchaseTryout      = '/purchase-tryout';
  static const tryoutDetail        = '/tryout-detail';
  static const examList            = '/exam/list';
  static const examPre             = '/exam/pre';
  static const examSession         = '/exam/session';
  static const examAd              = '/exam/ad';
  static const examResult          = '/exam/result';
  static const examReview          = '/exam/review';
  static const learnCategory       = '/learn/category';
  static const learnReview         = '/learn/review';
  static const statistics          = '/profile/statistics';
  static const achievements        = '/profile/achievements';
  static const settings            = '/profile/settings';
  static const diamondPurchase     = '/diamond';
  static const premium             = '/premium';
  static const payment             = '/payment';
  static const paymentSuccess      = '/payment/success';
  static const paymentFailed       = '/payment/failed';

  // ✅ Pakai prefix — billLinkId di-append saat push, di-parse saat deep link
  static const paymentStatusPrefix = '/payment/status/';

  static const adminMain           = '/admin-main';
  static const adminDashboard      = '/admin/dashboard';
  static const adminCreateTO       = '/admin/create-to';
  static const adminViewTO         = '/admin/view-to';
  static const adminVerificationTO = '/admin/verification';
  static const notFound            = '/404';

  // Helper: buat nama route lengkap dengan billLinkId
  static String paymentStatus(String billLinkId) =>
      '$paymentStatusPrefix$billLinkId';
}

// ════════════════════════════════════════════════════════════════════════════
// ROUTER
// ════════════════════════════════════════════════════════════════════════════
class AppRouter {
  AppRouter._();

  // Dipanggil sekali dari main() — handle redirect Flip saat app pertama load
  // Flip redirect ke: https://app.web.app/#/payment/status/BILL_ID
  // Flutter Web membaca hash untuk menentukan initialRoute
  static String get initialRoute {
    final hash = html.window.location.hash; // contoh: '#/payment/status/abc123'
    final path = hash.startsWith('#') ? hash.substring(1) : hash;
    if (path.startsWith(AppRoutes.paymentStatusPrefix)) return path;
    return AppRoutes.splash;
  }

  static Route<dynamic> generateRoute(RouteSettings s) {
    final args = s.arguments as Map<String, dynamic>? ?? {};

    // ── /payment/status/:billLinkId ─────────────────────────────────────────
    // Bisa masuk dari 2 jalur:
    //   1. Push dalam app   → arguments berisi semua data
    //   2. Deep link Flip   → arguments kosong, data dibaca dari Firestore
    final name = s.name ?? '';
    if (name.startsWith(AppRoutes.paymentStatusPrefix)) {
      final billLinkId = name.substring(AppRoutes.paymentStatusPrefix.length);
      if (billLinkId.isEmpty) return _fallback(s);
      return _page(
        s,
        PaymentStatusScreen(
          billLinkId:   billLinkId,
          // Kalau dari deep link, field ini kosong string —
          // PaymentStatusScreen harus baca dari Firestore sendiri
          tryoutId:     args['tryoutId']    as String? ?? '',
          tryoutTitle:  args['tryoutTitle'] as String? ?? '',
          amount:       args['amount']      as int?    ?? 0,
        ),
      );
    }

    switch (name) {
      case AppRoutes.login:
        return _page(s, const LoginScreen());

      case AppRoutes.goalSetting:
        return _page(s, const GoalSettingScreen());

      case AppRoutes.main:
        return _page(s, const MainNavigationScreen());

      case AppRoutes.profile:
        return _page(s, const ProfileScreen());

      case AppRoutes.myTryout:
        return _page(s, const MyTryoutsScreen());

      case AppRoutes.purchaseTryout:
        return _page(s, const TryoutMarketplaceScreen());

      case AppRoutes.tryoutDetail:
        final id = args['tryoutId'] as String? ?? '';
        if (id.isEmpty) return _fallback(s);
        return _page(s, TryoutDetailScreen(tryoutId: id));

      case AppRoutes.examReview:
        final resultId = args['resultId'] as String? ?? '';
        if (resultId.isEmpty) return _fallback(s);
        return _page(s, ExamReviewScreen(resultId: resultId));

      case AppRoutes.adminMain:
        return _page(s, const AdminMainNavigationScreen());

      case AppRoutes.adminCreateTO:
        return _page(s, const CreateTryoutScreen());

      case AppRoutes.adminViewTO:
        return _page(s, const ViewTryoutScreen());

      case AppRoutes.adminVerificationTO:
        return _page(s, const PromotionVerificationScreen());

      case AppRoutes.notFound:
      default:
        return _page(s, const NotFoundScreen());
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings s) =>
      _page(s, const NotFoundScreen());

  static MaterialPageRoute<dynamic> _page(RouteSettings s, Widget w) =>
      MaterialPageRoute(settings: s, builder: (_) => w);

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
