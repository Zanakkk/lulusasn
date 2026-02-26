// lib/features/main_navigation/widgets/navigation_rail.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// Professional Collapsible Navigation Rail - Duolingo-Inspired
///
/// Features:
/// - Auto-collapse on smaller screens (900-1200px)
/// - Smooth expand/collapse animation
/// - Persistent brand identity
/// - Professional hover states
/// - Optimized spacing for both states
class DuolingoNavigationRail extends StatefulWidget {
  final String currentRoute;
  final Function(String) onNavigate;
  final VoidCallback? onLogout;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const DuolingoNavigationRail({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    this.onLogout,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  State<DuolingoNavigationRail> createState() => _DuolingoNavigationRailState();
}

class _DuolingoNavigationRailState extends State<DuolingoNavigationRail>
    with SingleTickerProviderStateMixin {
  String? _hoveredRoute;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(DuolingoNavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCollapsed != widget.isCollapsed) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    _widthAnimation = Tween<double>(
      begin: widget.isCollapsed ? 240.0 : 72.0,
      end: widget.isCollapsed ? 72.0 : 240.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    if (widget.isCollapsed) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        final width = widget.isCollapsed ? 72.0 : 240.0;

        return Container(
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Brand Header
              _buildBrandHeader(),

              const SizedBox(height: 24),

              // Navigation Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isCollapsed ? 12 : 16,
                  ),
                  children: NavigationItems.desktopItems.map((item) {
                    return _buildNavItem(item);
                  }).toList(),
                ),
              ),

              // Collapse Toggle (Desktop only)
              if (widget.onToggleCollapse != null) _buildCollapseToggle(),

              // Bottom Actions
              _buildBottomActions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        widget.isCollapsed ? 16 : 20,
        28,
        widget.isCollapsed ? 16 : 20,
        0,
      ),
      child: widget.isCollapsed
          ? _buildCollapsedLogo()
          : _buildExpandedLogo(),
    );
  }

  Widget _buildCollapsedLogo() {
    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1CB0F6), Color(0xFF1899D6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1CB0F6).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'L',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedLogo() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1CB0F6), Color(0xFF1899D6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1CB0F6).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'L',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'LULUZZZ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1899D6),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(NavItem item) {
    final isActive = widget.currentRoute == item.route;
    final isHovered = _hoveredRoute == item.route;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredRoute = item.route),
        onExit: (_) => setState(() => _hoveredRoute = null),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => widget.onNavigate(item.route),
          child: Tooltip(
            message: widget.isCollapsed ? item.label : '',
            preferBelow: false,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed ? 0 : 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFDDF4FF)
                    : isHovered
                    ? const Color(0xFFF7F7F7)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isActive
                    ? Border.all(
                  color: const Color(0xFF1CB0F6).withOpacity(0.2),
                  width: 1,
                )
                    : null,
              ),
              child: widget.isCollapsed
                  ? _buildCollapsedNavItem(item, isActive)
                  : _buildExpandedNavItem(item, isActive),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedNavItem(NavItem item, bool isActive) {
    return Center(
      child: Icon(
        isActive ? (item.activeIcon ?? item.icon) : item.icon,
        color: isActive
            ? const Color(0xFF1CB0F6)
            : Colors.grey.shade600,
        size: 24,
      ),
    );
  }

  Widget _buildExpandedNavItem(NavItem item, bool isActive) {
    return Row(
      children: [
        Icon(
          isActive ? (item.activeIcon ?? item.icon) : item.icon,
          color: isActive
              ? const Color(0xFF1CB0F6)
              : Colors.grey.shade600,
          size: 22,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            item.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive
                  ? const Color(0xFF1CB0F6)
                  : Colors.grey.shade700,
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (isActive)
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF1CB0F6),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _buildCollapseToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onToggleCollapse,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Icon(
                widget.isCollapsed
                    ? Icons.chevron_right_rounded
                    : Icons.chevron_left_rounded,
                size: 24,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(widget.isCollapsed ? 12 : 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.settings_outlined,
            label: 'Pengaturan',
            onTap: () {},
          ),
          const SizedBox(height: 4),
          _buildActionButton(
            icon: Icons.logout_rounded,
            label: 'Keluar',
            onTap: widget.onLogout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: widget.isCollapsed ? label : '',
          preferBelow: false,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 0 : 14,
              vertical: 12,
            ),
            child: widget.isCollapsed
                ? Center(
              child: Icon(
                icon,
                size: 20,
                color: isDestructive
                    ? const Color(0xFFFF4B4B)
                    : Colors.grey.shade600,
              ),
            )
                : Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isDestructive
                      ? const Color(0xFFFF4B4B)
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDestructive
                        ? const Color(0xFFFF4B4B)
                        : Colors.grey.shade700,
                    letterSpacing: 0.1,
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

/// Professional Admin Navigation Rail with Collapsible Support
class AdminNavigationRail extends StatefulWidget {
  final String currentRoute;
  final Function(String) onNavigate;
  final VoidCallback? onLogout;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const AdminNavigationRail({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    this.onLogout,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  State<AdminNavigationRail> createState() => _AdminNavigationRailState();
}

class _AdminNavigationRailState extends State<AdminNavigationRail>
    with SingleTickerProviderStateMixin {
  String? _hoveredRoute;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.isCollapsed ? 72.0 : 240.0;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBrandHeader(),
          const SizedBox(height: 20),
          if (!widget.isCollapsed) _buildAdminBadge(),
          if (!widget.isCollapsed) const SizedBox(height: 24),
          if (widget.isCollapsed) const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed ? 12 : 16,
              ),
              children: NavigationItems.adminDesktopItems.map((item) {
                return _buildNavItem(item);
              }).toList(),
            ),
          ),
          if (widget.onToggleCollapse != null) _buildCollapseToggle(),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        widget.isCollapsed ? 16 : 20,
        28,
        widget.isCollapsed ? 16 : 20,
        0,
      ),
      child: widget.isCollapsed
          ? _buildCollapsedLogo()
          : _buildExpandedLogo(),
    );
  }

  Widget _buildCollapsedLogo() {
    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1CB0F6), Color(0xFF1899D6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1CB0F6).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'L',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedLogo() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1CB0F6), Color(0xFF1899D6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1CB0F6).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'L',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'LULUZZZ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1899D6),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF4B4B).withOpacity(0.1),
            const Color(0xFFFF6B6B).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFF4B4B).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4B4B).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 16,
              color: Color(0xFFFF4B4B),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Admin Panel',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF4B4B),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(NavItem item) {
    final isActive = widget.currentRoute == item.route;
    final isHovered = _hoveredRoute == item.route;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredRoute = item.route),
        onExit: (_) => setState(() => _hoveredRoute = null),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => widget.onNavigate(item.route),
          child: Tooltip(
            message: widget.isCollapsed ? item.label : '',
            preferBelow: false,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed ? 0 : 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFDDF4FF)
                    : isHovered
                    ? const Color(0xFFF7F7F7)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isActive
                    ? Border.all(
                  color: const Color(0xFF1CB0F6).withOpacity(0.2),
                  width: 1,
                )
                    : null,
              ),
              child: widget.isCollapsed
                  ? Center(
                child: Icon(
                  isActive ? (item.activeIcon ?? item.icon) : item.icon,
                  color: isActive
                      ? const Color(0xFF1CB0F6)
                      : Colors.grey.shade600,
                  size: 24,
                ),
              )
                  : Row(
                children: [
                  Icon(
                    isActive ? (item.activeIcon ?? item.icon) : item.icon,
                    color: isActive
                        ? const Color(0xFF1CB0F6)
                        : Colors.grey.shade600,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                        color: isActive
                            ? const Color(0xFF1CB0F6)
                            : Colors.grey.shade700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1CB0F6),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onToggleCollapse,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Icon(
                widget.isCollapsed
                    ? Icons.chevron_right_rounded
                    : Icons.chevron_left_rounded,
                size: 24,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(widget.isCollapsed ? 12 : 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.settings_outlined,
            label: 'Pengaturan',
            onTap: () {

            },
          ),
          const SizedBox(height: 4),
          _buildActionButton(
            icon: Icons.logout_rounded,
            label: 'Keluar',
            onTap: widget.onLogout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: widget.isCollapsed ? label : '',
          preferBelow: false,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 0 : 14,
              vertical: 12,
            ),
            child: widget.isCollapsed
                ? Center(
              child: Icon(
                icon,
                size: 20,
                color: isDestructive
                    ? const Color(0xFFFF4B4B)
                    : Colors.grey.shade600,
              ),
            )
                : Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isDestructive
                      ? const Color(0xFFFF4B4B)
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDestructive
                        ? const Color(0xFFFF4B4B)
                        : Colors.grey.shade700,
                    letterSpacing: 0.1,
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

// Navigation Item Model (unchanged)
class NavItem {
  final String route;
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const NavItem({
    required this.route,
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class NavigationItems {
  static const List<NavItem> mobileItems = [
    NavItem(
      route: '/home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    NavItem(
      route: '/learn',
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      label: 'Belajar',
    ),
    NavItem(
      route: '/profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  static const List<NavItem> desktopItems = [
    NavItem(
      route: '/home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    NavItem(
      route: '/learn',
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      label: 'Belajar',
    ),
    NavItem(
      route: '/my-tryout',
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz_rounded,
      label: 'Owned Tryout',
    ),
    NavItem(
      route: '/purchase-tryout',
      icon: Icons.quiz_outlined,
      activeIcon: Icons.quiz_rounded,
      label: 'Purchase Tryout',
    ),
    NavItem(
      route: '/leaderboard',
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events_rounded,
      label: 'Peringkat',
    ),
    NavItem(
      route: '/profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  static const List<NavItem> adminDesktopItems = [
    NavItem(
      route: '/create-to',
      icon: Icons.add_circle_outline,
      activeIcon: Icons.add_circle_rounded,
      label: 'Buat TO',
    ),
    NavItem(
      route: '/view-to',
      icon: Icons.list_alt_outlined,
      activeIcon: Icons.list_alt_rounded,
      label: 'Lihat TO',
    ),
    NavItem(
      route: '/verification',
      icon: Icons.add_circle_outline,
      activeIcon: Icons.add_circle_rounded,
      label: 'Verifikasi',
    ),
    NavItem(
      route: '/dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
  ];

  static const List<NavItem> adminMobileItems = [
    NavItem(
      route: '/create-to',
      icon: Icons.add_circle_outline,
      activeIcon: Icons.add_circle_rounded,
      label: 'Buat TO',
    ),
    NavItem(
      route: '/view-to',
      icon: Icons.list_alt_outlined,
      activeIcon: Icons.list_alt_rounded,
      label: 'Lihat TO',
    ),
    NavItem(
      route: '/dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
  ];
}