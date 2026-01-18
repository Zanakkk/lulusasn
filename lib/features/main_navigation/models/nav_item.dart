// lib/features/main_navigation/models/nav_item.dart

import 'package:flutter/material.dart';

/// Navigation Item Model
/// Digunakan untuk bottom nav bar dan navigation rail
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

/// Daftar navigasi utama
class NavigationItems {
  // Mobile: 3 items
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

  // Tablet/Desktop: 4 items
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
}