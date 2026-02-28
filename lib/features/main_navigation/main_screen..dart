// lib/features/main_navigation/main_navigation.dart
// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lulusasn/app/routes.dart';
import 'package:lulusasn/core/services/storage_service.dart';
import 'package:lulusasn/features/TO/owned_tryout_screen.dart';
import 'package:lulusasn/features/TO/tryout_marketplace_screen.dart';
import 'package:lulusasn/features/exam/screens/exam_list_screen.dart';
import 'package:lulusasn/features/home/screens/ProfileScreen.dart';
import 'package:lulusasn/features/home/screens/home_screen.dart';
import 'package:lulusasn/features/home/screens/leaderboard_screen.dart';

import '../../admin/pages/CreateTO.dart';
import '../../admin/pages/contentmanagement.dart';
import '../../admin/pages/promotion_verification_screen.dart';
import '../../admin/pages/userManagement.dart';
import '../../app/theme.dart';

// ─────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────
class _NavItem {
  final String route, label;
  final IconData icon, activeIcon;
  const _NavItem(this.route, this.icon, this.activeIcon, this.label);
}

// ─────────────────────────────────────────────
// NAV DEFINITIONS  ← edit di sini saja
// ─────────────────────────────────────────────
const _userMobile = [
  _NavItem('/home', Icons.home_outlined, Icons.home_rounded, 'Beranda'),
  _NavItem('/my-tryout', Icons.quiz_outlined, Icons.quiz_rounded, 'Tryout'),
  _NavItem(
    '/purchase-tryout',
    Icons.store_outlined,
    Icons.store_rounded,
    'Beli',
  ),
  _NavItem('/profile', Icons.person_outline, Icons.person_rounded, 'Profil'),
];
const _userDesktop = [
  _NavItem('/home', Icons.home_outlined, Icons.home_rounded, 'Beranda'),
  _NavItem(
    '/my-tryout',
    Icons.quiz_outlined,
    Icons.quiz_rounded,
    'Tryout Saya',
  ),
  _NavItem(
    '/purchase-tryout',
    Icons.store_outlined,
    Icons.store_rounded,
    'Beli Tryout',
  ),
  _NavItem(
    '/leaderboard',
    Icons.emoji_events_outlined,
    Icons.emoji_events_rounded,
    'Peringkat',
  ),
  _NavItem('/profile', Icons.person_outline, Icons.person_rounded, 'Profil'),
];
const _adminDesktop = [
  _NavItem(
    '/create-to',
    Icons.add_circle_outline,
    Icons.add_circle_rounded,
    'Buat TO',
  ),
  _NavItem(
    '/view-to',
    Icons.list_alt_outlined,
    Icons.list_alt_rounded,
    'Lihat TO',
  ),
  _NavItem(
    '/verification',
    Icons.verified_outlined,
    Icons.verified_rounded,
    'Verifikasi',
  ),
  _NavItem(
    '/dashboard',
    Icons.dashboard_outlined,
    Icons.dashboard_rounded,
    'Dashboard',
  ),
  _NavItem(
    '/userManagement',
    Icons.dashboard_outlined,
    Icons.dashboard_rounded,
    'User Management',
  ),
  _NavItem(
    '/contentManagement',
    Icons.dashboard_outlined,
    Icons.dashboard_rounded,
    'Content Management',
  ),
];
const _adminMobile = [
  _NavItem(
    '/create-to',
    Icons.add_circle_outline,
    Icons.add_circle_rounded,
    'Buat TO',
  ),
  _NavItem(
    '/view-to',
    Icons.list_alt_outlined,
    Icons.list_alt_rounded,
    'Lihat TO',
  ),
  _NavItem(
    '/dashboard',
    Icons.dashboard_outlined,
    Icons.dashboard_rounded,
    'Dashboard',
  ),
];

// ─────────────────────────────────────────────
// SCREEN RESOLVER
// ─────────────────────────────────────────────
Widget _resolveScreen(String route) => switch (route) {
  '/home' => const HomeScreen(),
  '/learn' => const ExamListScreen(),
  '/my-tryout' => const MyTryoutsScreen(),
  '/purchase-tryout' => const TryoutMarketplaceScreen(),
  '/leaderboard' => const LeaderboardScreen(),
  '/profile' => const ProfileScreen(),
  '/create-to' => const CreateTryoutScreen(),
  '/view-to' => const Placeholder(),
  '/verification' => const PromotionVerificationScreen(),
  '/dashboard' => const Placeholder(),
  '/userManagement' => const UserManagementScreen(),
  '/contentManagement' => const ContentManagementScreen(),
  _ => const HomeScreen(),
};

// ─────────────────────────────────────────────
// ENTRY POINTS
// ─────────────────────────────────────────────
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  String _route = '/home';
  @override
  Widget build(BuildContext context) => _Shell(
    route: _route,
    mobileItems: _userMobile,
    desktopItems: _userDesktop,
    isAdmin: false,
    onNav: (r) => setState(() => _route = r),
    onLogout: () => _logout(context),
  );
}

class AdminMainNavigationScreen extends StatefulWidget {
  const AdminMainNavigationScreen({super.key});
  @override
  State<AdminMainNavigationScreen> createState() =>
      _AdminMainNavigationScreenState();
}

class _AdminMainNavigationScreenState extends State<AdminMainNavigationScreen> {
  String _route = '/create-to';
  @override
  Widget build(BuildContext context) => _Shell(
    route: _route,
    mobileItems: _adminMobile,
    desktopItems: _adminDesktop,
    isAdmin: true,
    onNav: (r) => setState(() => _route = r),
    onLogout: () => _logout(context),
  );
}

// ─────────────────────────────────────────────
// SHELL  (single widget, responsive)
// ─────────────────────────────────────────────
class _Shell extends StatelessWidget {
  final String route;
  final List<_NavItem> mobileItems, desktopItems;
  final bool isAdmin;
  final ValueChanged<String> onNav;
  final VoidCallback onLogout;
  const _Shell({
    required this.route,
    required this.mobileItems,
    required this.desktopItems,
    required this.isAdmin,
    required this.onNav,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);
    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _TopBar(route: route),
        ),
        body: _resolveScreen(route),
        bottomNavigationBar: _BottomBar(
          items: mobileItems,
          route: route,
          onNav: onNav,
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          _Sidebar(
            items: desktopItems,
            route: route,
            onNav: onNav,
            onLogout: onLogout,
            isAdmin: isAdmin,
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(route: route),
                Expanded(child: _resolveScreen(route)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SIDEBAR  — dark navy
// ─────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final String route;
  final ValueChanged<String> onNav;
  final VoidCallback onLogout;
  final bool isAdmin;
  const _Sidebar({
    required this.items,
    required this.route,
    required this.onNav,
    required this.onLogout,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        gradient: AppGradient.navy,
        border: Border(right: BorderSide(color: Color(0x18FFFFFF))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),

          // ── Brand ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Logo mark
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gold, width: 1.5),
                    borderRadius: AppRadius.bSm,
                  ),
                  child: Center(
                    child: Text(
                      'L',
                      style: AppText.h3.copyWith(color: AppColors.gold),
                    ),
                  ),
                ),
                AppSpacing.hsm,
                Text(
                  'LULUZZZ',
                  style: AppText.h3.copyWith(
                    color: AppColors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // ── Admin badge ──
          if (isAdmin) ...[
            AppSpacing.vsm,
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: AppRadius.bSm,
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 13,
                    color: AppColors.error,
                  ),
                  AppSpacing.hxs,
                  Text(
                    'Admin Panel',
                    style: AppText.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          AppSpacing.vmd,

          // ── Nav items ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: items.map((item) {
                final active = route == item.route;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: InkWell(
                    onTap: () => onNav(item.route),
                    borderRadius: AppRadius.bMd,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.white.withOpacity(0.10)
                            : Colors.transparent,
                        borderRadius: AppRadius.bMd,
                        border: active
                            ? Border.all(
                                color: AppColors.gold.withOpacity(0.25),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            active ? item.activeIcon : item.icon,
                            size: 19,
                            color: active
                                ? AppColors.gold
                                : AppColors.white.withOpacity(0.55),
                          ),
                          AppSpacing.hsm,
                          Expanded(
                            child: Text(
                              item.label,
                              style: AppText.label.copyWith(
                                color: active
                                    ? AppColors.gold
                                    : AppColors.white.withOpacity(0.7),
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (active)
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Logout ──
          Divider(height: 1, color: AppColors.white.withOpacity(0.08)),
          InkWell(
            onTap: onLogout,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: AppColors.error.withOpacity(0.8),
                  ),
                  AppSpacing.hsm,
                  Text(
                    'Keluar',
                    style: AppText.label.copyWith(
                      color: AppColors.error.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TOP BAR  — light surface
// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String route;
  const _TopBar({required this.route});

  String get _title => switch (route) {
    '/home' => 'Beranda',
    '/my-tryout' => 'Tryout Saya',
    '/purchase-tryout' => 'Beli Tryout',
    '/leaderboard' => 'Peringkat',
    '/profile' => 'Profil',
    '/create-to' => 'Buat TO',
    '/view-to' => 'Lihat TO',
    '/verification' => 'Verifikasi',
    '/dashboard' => 'Dashboard',
    _ => 'LULUZZZ',
  };

  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        Text(_title, style: AppText.h3),
        const Spacer(),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
// BOTTOM BAR  — light, gold active indicator
// ─────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final List<_NavItem> items;
  final String route;
  final ValueChanged<String> onNav;
  const _BottomBar({
    required this.items,
    required this.route,
    required this.onNav,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: items.map((item) {
            final active = route == item.route;
            return Expanded(
              child: InkWell(
                onTap: () => onNav(item.route),
                borderRadius: AppRadius.bMd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Active indicator dot
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: active ? 16 : 0,
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: AppRadius.bFull,
                        ),
                      ),
                      Icon(
                        active ? item.activeIcon : item.icon,
                        size: 22,
                        color: active ? AppColors.primary : AppColors.textHint,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: AppText.caption.copyWith(
                          fontSize: 10,
                          color: active
                              ? AppColors.primary
                              : AppColors.textHint,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
// LOGOUT
// ─────────────────────────────────────────────
Future<void> _logout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.bLg),
      title: Text('Logout', style: AppText.h3),
      content: Text('Yakin ingin keluar?', style: AppText.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Batal',
            style: AppText.label.copyWith(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
          ),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await StorageService.instance.clearUserData();
  await FirebaseAuth.instance.signOut();
  if (context.mounted) {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }
}
