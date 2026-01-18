// lib/features/main_navigation/widgets/navigation_rail.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lulusasn/features/main_navigation/models/nav_item.dart';

/// Navigation Rail - Duolingo Style (Fixed Sidebar)
///
/// Features:
/// - Fixed width (200px) - never collapses
/// - Icon + label always visible
/// - Smooth hover effects
/// - Logo at top
/// - Settings/Logout at bottom
class DuolingoNavigationRail extends StatefulWidget {
  final String currentRoute;
  final Function(String) onNavigate;
  final VoidCallback? onLogout;

  const DuolingoNavigationRail({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    this.onLogout,
  });

  @override
  State<DuolingoNavigationRail> createState() => _DuolingoNavigationRailState();
}

class _DuolingoNavigationRailState extends State<DuolingoNavigationRail> {
  String? _hoveredRoute;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Brand

          const SizedBox(height: 24),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: NavigationItems.desktopItems.map((item) {
                return _buildNavItem(item);
              }).toList(),
            ),
          ),

          // Bottom Actions
          _buildBottomActions(),
        ],
      ),
    );
  }


  Widget _buildNavItem(NavItem item) {
    final isActive = widget.currentRoute == item.route;
    final isHovered = _hoveredRoute == item.route;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredRoute = item.route),
        onExit: (_) => setState(() => _hoveredRoute = null),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => widget.onNavigate(item.route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFDDF4FF) // Light blue
                  : isHovered
                  ? Colors.grey.shade100
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? (item.activeIcon ?? item.icon) : item.icon,
                  color: isActive
                      ? const Color(0xFF1899D6)
                      : Colors.grey.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF1899D6)
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Divider
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),

          // Settings (Optional)
          _buildActionButton(
            icon: Icons.settings_outlined,
            label: 'Pengaturan',
            onTap: () {
              // Navigate to settings
            },
          ),

          const SizedBox(height: 8),

          // Logout
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? const Color(0xFFFF4B4B) : Colors.grey[700],
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDestructive ? const Color(0xFFFF4B4B) : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}