// lib/features/main_navigation/main_navigation.dart
// ignore_for_file: deprecated_member_use, unused_element

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lulusasn/app/routes.dart';
import 'package:lulusasn/core/services/storage_service.dart';
import 'package:lulusasn/users/TO/owned_tryout_screen.dart';
import 'package:lulusasn/users/TO/tryout_marketplace_screen.dart';
import 'package:lulusasn/users/home/screens/ProfileScreen.dart';
import 'package:lulusasn/users/home/screens/UserDashboard.dart';

import '../../admin/pages/AdminDashboard.dart';
import '../../admin/pages/CreateTO.dart';
import '../../admin/pages/contentmanagement.dart';
import '../../admin/pages/promotion_verification_screen.dart';
import '../../admin/pages/userManagement.dart';
import '../../app/theme.dart';
import '../../core/services/firebase_service.dart';

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
  _NavItem(
    '/userdashboard',
    Icons.home_outlined,
    Icons.home_rounded,
    'Beranda',
  ),
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
  _NavItem('/profile', Icons.person_outline, Icons.person_rounded, 'Profil'),
];

const _adminDesktop = [
  _NavItem(
    '/dashboardAdmin',
    Icons.dashboard_outlined,
    Icons.dashboard_rounded,
    'Dashboard',
  ),
  _NavItem(
    '/create-to',
    Icons.add_circle_outline,
    Icons.add_circle_rounded,
    'Buat TO',
  ),
  _NavItem(
    '/contentManagement',
    Icons.dashboard_outlined,
    Icons.dashboard_rounded,
    'Content Management',
  ),
  _NavItem(
    '/userManagement',
    Icons.dashboard_outlined,
    Icons.dashboard_rounded,
    'User Management',
  ),
  _NavItem(
    '/verification',
    Icons.verified_outlined,
    Icons.verified_rounded,
    'Verifikasi',
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
// ENTRY POINTS
// ─────────────────────────────────────────────
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  String _route = '/home';
  bool _collapsed = false;
  @override
  Widget build(BuildContext context) => _Shell(
    route: _route,
    mobileItems: _userMobile,
    desktopItems: _userDesktop,
    isAdmin: false,
    collapsed: _collapsed,
    onCollapse: () => setState(() => _collapsed = !_collapsed),
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
  String _route = '/dashboardAdmin';
  bool _collapsed = false;
  @override
  Widget build(BuildContext context) => _Shell(
    route: _route,
    mobileItems: _adminMobile,
    desktopItems: _adminDesktop,
    isAdmin: true,
    collapsed: _collapsed,
    onCollapse: () => setState(() => _collapsed = !_collapsed),
    onNav: (r) => setState(() => _route = r),
    onLogout: () => _logout(context),
  );
}

// ─────────────────────────────────────────────
// SHELL  (single widget, responsive)
// ─────────────────────────────────────────────
// Ganti class _Shell dari StatelessWidget → StatefulWidget
// agar bisa fetch + hold goal state

class _Shell extends StatefulWidget {
  final String route;
  final List<_NavItem> mobileItems, desktopItems;
  final bool isAdmin;
  final bool collapsed;
  final ValueChanged<String> onNav;
  final VoidCallback onLogout;
  final VoidCallback onCollapse;

  const _Shell({
    required this.route,
    required this.mobileItems,
    required this.desktopItems,
    required this.isAdmin,
    required this.collapsed,
    required this.onCollapse,
    required this.onNav,
    required this.onLogout,
  });

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  String? _currentGoal;

  @override
  void initState() {
    super.initState();
    _fetchGoal();
  }

  Future<void> _fetchGoal() async {
    try {
      final uid = FirebaseService.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final goal = (doc.data()?['goal'] as String?)?.toLowerCase();
      if (mounted) setState(() => _currentGoal = goal);
    } catch (_) {}
  }

  void _onGoalChanged(String? newGoal) {
    if (newGoal != null) setState(() => _currentGoal = newGoal.toLowerCase());
  }

  Widget _resolveScreen(String route) => switch (route) {
    '/userdashboard' => const HomeScreen(),
    '/my-tryout' => const MyTryoutsScreen(),
    '/purchase-tryout' => TryoutMarketplaceScreen(currentGoal: _currentGoal),
    '/profile' => const ProfileScreen(),
    '/create-to' => const CreateTryoutScreen(),
    '/view-to' => const Placeholder(),
    '/verification' => const PromotionVerificationScreen(),
    '/dashboardAdmin' => const AdminDashboardScreen(),
    '/userManagement' => const UserManagementScreen(),
    '/contentManagement' => const ContentManagementScreen(),
    _ => const HomeScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: TopBar(
            route: widget.route,
            currentGoal: _currentGoal,
            onGoalChanged: _onGoalChanged,
          ),
        ),
        body: _resolveScreen(widget.route),
        bottomNavigationBar: _BottomBar(
          items: widget.mobileItems,
          route: widget.route,
          onNav: widget.onNav,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            width: widget.collapsed ? 64 : 220,
            child: _Sidebar(
              items: widget.desktopItems,
              route: widget.route,
              onNav: widget.onNav,
              onLogout: widget.onLogout,
              isAdmin: widget.isAdmin,
              collapsed: widget.collapsed,
              onCollapse: widget.onCollapse,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                TopBar(
                  route: widget.route,
                  currentGoal: _currentGoal,
                  onGoalChanged: _onGoalChanged,
                ),
                Expanded(child: _resolveScreen(widget.route)),
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
  final bool collapsed;
  final VoidCallback onCollapse;
  const _Sidebar({
    required this.items,
    required this.route,
    required this.onNav,
    required this.onLogout,
    required this.isAdmin,
    required this.collapsed,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final c = collapsed;
    return ClipRect(
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppGradient.navy,
          border: Border(right: BorderSide(color: Color(0x18FFFFFF))),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Brand + collapse toggle ──
            SizedBox(
              height: 34,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                    if (!c) ...[
                      AppSpacing.hsm,
                      Expanded(
                        child: Text(
                          'LULUZZZ',
                          style: AppText.h3.copyWith(
                            color: AppColors.white,
                            letterSpacing: 1,
                          ),
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Admin badge ──
            if (isAdmin) ...[
              AppSpacing.vsm,
              c
                  ? Tooltip(
                      message: 'Admin Panel',
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 16,
                        color: AppColors.error,
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.12),
                        borderRadius: AppRadius.bSm,
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
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
                padding: EdgeInsets.symmetric(horizontal: c ? 6 : 10),
                children: items.map((item) {
                  final active = route == item.route;
                  final iconWidget = Icon(
                    active ? item.activeIcon : item.icon,
                    size: 20,
                    color: active
                        ? AppColors.gold
                        : AppColors.white.withOpacity(0.55),
                  );

                  final tile = AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: EdgeInsets.symmetric(
                      horizontal: c ? 0 : 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.white.withOpacity(0.10)
                          : Colors.transparent,
                      borderRadius: AppRadius.bMd,
                      border: active
                          ? Border.all(color: AppColors.gold.withOpacity(0.25))
                          : null,
                    ),
                    child: c
                        ? Center(child: iconWidget)
                        : Row(
                            children: [
                              iconWidget,
                              AppSpacing.hsm,
                              Expanded(
                                child: Text(
                                  item.label,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
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
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Tooltip(
                      message: c ? item.label : '',
                      preferBelow: false,
                      child: InkWell(
                        onTap: () => onNav(item.route),
                        borderRadius: AppRadius.bMd,
                        child: tile,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Logout ──
            Divider(height: 1, color: AppColors.white.withOpacity(0.08)),
            Tooltip(
              message: c ? 'Keluar' : '',
              child: InkWell(
                onTap: onLogout,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: c ? 0 : 22,
                    vertical: 14,
                  ),
                  child: c
                      ? Center(
                          child: Icon(
                            Icons.logout_rounded,
                            size: 18,
                            color: AppColors.error.withOpacity(0.8),
                          ),
                        )
                      : Row(
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
            ),

            // ── Collapse toggle ──
            Divider(height: 1, color: AppColors.white.withOpacity(0.05)),
            Tooltip(
              message: c ? 'Perluas sidebar' : '',
              child: InkWell(
                onTap: onCollapse,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: c ? 0 : 22,
                    vertical: 12,
                  ),
                  child: c
                      ? Center(
                          child: Icon(
                            Icons.keyboard_double_arrow_right_rounded,
                            size: 16,
                            color: AppColors.white.withOpacity(0.3),
                          ),
                        )
                      : Row(
                          children: [
                            Icon(
                              Icons.keyboard_double_arrow_left_rounded,
                              size: 16,
                              color: AppColors.white.withOpacity(0.3),
                            ),
                            AppSpacing.hsm,
                            Text(
                              'Ciutkan',
                              style: AppText.caption.copyWith(
                                color: AppColors.white.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _Goal {
  final String key; // name.toLowerCase() — dipakai sebagai identifier
  final String name; // display name: 'LPDP', 'CPNS', dll
  final String description;
  final List<String> categories;
  final int order;

  const _Goal({
    required this.key,
    required this.name,
    required this.description,
    required this.categories,
    required this.order,
  });

  factory _Goal.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final name = d['name'] as String? ?? '';
    return _Goal(
      key: name.toLowerCase(), // ← identifier = name lowercase
      name: name,
      description: d['description'] as String? ?? '',
      categories: List<String>.from(d['categories'] ?? []),
      order: d['order'] as int? ?? 99,
    );
  }

  IconData get icon => switch (key) {
    'cpns' => LineIcons.userTie,
    'lpdp' => LineIcons.graduationCap,
    'bumn' => LineIcons.building,
    'pcpm' => LineIcons.university,
    _ => LineIcons.bullseye,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// STREAM  — realtime dari Firestore
// ─────────────────────────────────────────────────────────────────────────────

Stream<List<_Goal>> _goalsStream() => FirebaseFirestore.instance
    .collection('exam_types')
    .where('isActive', isEqualTo: true)
    .orderBy('order')
    .snapshots()
    .map((snap) => snap.docs.map(_Goal.fromDoc).toList());

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR  (goal-aware)
// ─────────────────────────────────────────────────────────────────────────────

class TopBar extends StatelessWidget {
  final String route;
  final String? currentGoal;
  final ValueChanged<String?>? onGoalChanged;

  const TopBar({
    super.key,
    required this.route,
    this.currentGoal,
    this.onGoalChanged,
  });

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
  Widget build(BuildContext context) {
    return Container(
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
          if (currentGoal != null)
            StreamBuilder<List<_Goal>>(
              stream: _goalsStream(),
              builder: (context, snap) {
                final goal = (snap.data ?? [])
                    .where((g) => g.key == currentGoal!.toLowerCase())
                    .firstOrNull;
                if (goal == null) return const SizedBox.shrink();
                return _GoalChip(
                  goal: goal,
                  onTap: () => _showGoalSheet(context),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showGoalSheet(BuildContext context) async {
    final newGoal = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GoalPickerSheet(),
    );
    if (newGoal != null) onGoalChanged?.call(newGoal);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOAL CHIP  (di TopBar)
// ─────────────────────────────────────────────────────────────────────────────

class _GoalChip extends StatefulWidget {
  final _Goal goal;
  final VoidCallback onTap;
  const _GoalChip({required this.goal, required this.onTap});

  @override
  State<_GoalChip> createState() => _GoalChipState();
}

class _GoalChipState extends State<_GoalChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.primary.withOpacity(0.08)
                : AppColors.surfaceAlt,
            borderRadius: AppRadius.bFull,
            border: Border.all(
              color: _hovered ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.goal.icon, size: 14, color: AppColors.primary),
              AppSpacing.hxs,
              Text(
                widget.goal.name,
                style: AppText.label.copyWith(color: AppColors.primary),
              ),
              AppSpacing.hxs,
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOAL PICKER SHEET  — realtime
// ─────────────────────────────────────────────────────────────────────────────
//==============================================================================
class _GoalPickerSheet extends StatefulWidget {
  const _GoalPickerSheet();

  @override
  State<_GoalPickerSheet> createState() => _GoalPickerSheetState();
}

class _GoalPickerSheetState extends State<_GoalPickerSheet> {
  String? _selected;
  String? _saved;
  bool _loadingUser = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initSaved();
  }

  Future<void> _initSaved() async {
    try {
      final uid = FirebaseService.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final goal = (doc.data()?['goal'] as String?)?.toLowerCase();
      if (mounted) {
        setState(() {
          _selected = goal;
          _saved = goal;
          _loadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _save() async {
    if (_selected == null || _selected == _saved) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    try {
      final uid = FirebaseService.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not found');
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'goal': _selected,
      });
      if (!mounted) return;
      Navigator.pop(context, _selected);
      context.showSuccess('Tujuan berhasil diperbarui!');
    } catch (e) {
      if (!mounted) return;
      context.showError('Gagal menyimpan: ${e.toString()}');
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.bFull,
              ),
            ),
          ),
          AppSpacing.vmd,
          Text('Ubah Tujuan', style: AppText.h2),
          AppSpacing.vsm,
          Text('Pilih jalur yang ingin kamu persiapkan', style: AppText.bodySm),
          AppSpacing.vmd,

          if (_loadingUser)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            StreamBuilder<List<_Goal>>(
              stream: _goalsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                final goals = snap.data ?? [];
                if (goals.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada tujuan tersedia',
                      style: AppText.bodySm,
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: goals
                      .map(
                        (g) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _GoalCard(
                            goal: g,
                            isSelected: _selected == g.key,
                            isSaved: _saved == g.key,
                            onTap: () => setState(() => _selected = g.key),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),

          AppSpacing.vmd,
          _SaveButton(
            hasChanges: _selected != _saved,
            isSaving: _saving,
            onPressed: _save,
            label: _selected == _saved
                ? 'Tidak Ada Perubahan'
                : 'Simpan Perubahan',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 6. GOAL CARD
// ═══════════════════════════════════════════════════════════════════

class _GoalCard extends StatefulWidget {
  final _Goal goal;
  final bool isSelected;
  final bool isSaved;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.isSelected,
    required this.isSaved,
    required this.onTap,
  });

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.isSelected;
    final g = widget.goal;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: sel
                ? AppColors.primary.withOpacity(0.04)
                : AppColors.surface,
            borderRadius: AppRadius.bLg,
            border: Border.all(
              color: sel ? AppColors.primary : AppColors.border,
              width: sel ? 2 : 1,
            ),
            boxShadow: (_hovered || sel) ? AppShadow.md : AppShadow.sm,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: sel ? AppGradient.navy : null,
                  color: sel ? null : AppColors.surfaceAlt,
                  borderRadius: AppRadius.bMd,
                ),
                child: Icon(
                  g.icon,
                  size: 22,
                  color: sel ? AppColors.white : AppColors.textSecondary,
                ),
              ),
              AppSpacing.hmd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          g.name,
                          style: AppText.h3.copyWith(
                            color: sel
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (widget.isSaved && !sel) ...[
                          AppSpacing.hsm,
                          _Badge(label: 'Aktif', color: AppColors.success),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(g.description, style: AppText.bodySm),
                    if (g.categories.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: g.categories
                            .map(
                              (c) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: AppRadius.bFull,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  c,
                                  style: AppText.caption.copyWith(fontSize: 9),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: sel
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// 7. _ShellState — HAPUS top-level _resolveScreen, pakai ini
// ═══════════════════════════════════════════════════════════════════

//=============================================================================
// ─────────────────────────────────────────────────────────────────────────────
// GOAL CARD  — pakai field dari model baru
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// SAVE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _SaveButton extends StatefulWidget {
  final bool hasChanges;
  final bool isSaving;
  final VoidCallback onPressed;
  final String? label;

  const _SaveButton({
    required this.hasChanges,
    required this.isSaving,
    required this.onPressed,
    this.label,
  });

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.hasChanges && !widget.isSaving;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: active ? AppGradient.navy : null,
          color: active ? null : AppColors.surfaceAlt,
          borderRadius: AppRadius.bMd,
          boxShadow: active && _hovered ? AppShadow.lg : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.bMd,
            onTap: active ? widget.onPressed : null,
            child: Center(
              child: widget.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label ??
                              (widget.hasChanges
                                  ? 'Simpan Perubahan'
                                  : 'Tidak Ada Perubahan'),
                          style: AppText.btnLg.copyWith(
                            color: active
                                ? AppColors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (active) ...[
                          AppSpacing.hsm,
                          const Icon(
                            Icons.check_rounded,
                            color: AppColors.white,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color? color;
  const _Badge({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: c == null ? AppGradient.gold : null,
        color: c != null ? AppColors.softBg(c) : null,
        borderRadius: AppRadius.bFull,
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: c ?? AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
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
