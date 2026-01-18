// lib/features/main_navigation/widgets/bottom_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:lulusasn/features/main_navigation/models/nav_item.dart';

/// Bottom Navigation Bar - Duolingo Style
///
/// Features:
/// - Modern minimalist design
/// - Smooth transitions
/// - Icon + label layout
/// - Active state visual feedback
class DuolingoBottomNavBar extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const DuolingoBottomNavBar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: NavigationItems.mobileItems.map((item) {
              return _buildNavItem(context, item);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, NavItem item) {
    final isActive = currentRoute == item.route;
    final color = isActive
        ? const Color(0xFF58CC02) // Duolingo green
        : Colors.grey.shade600;

    return Expanded(
      child: InkWell(
        onTap: () => onNavigate(item.route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with smooth transition
              Icon(
                isActive ? (item.activeIcon ?? item.icon) : item.icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              // Label
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}