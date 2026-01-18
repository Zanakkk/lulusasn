// lib/features/main_navigation/main_screen.dart

// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:lulusasn/features/home/screens/ProfileScreen.dart';
import 'package:lulusasn/features/main_navigation/widgets/bottom_nav_bar.dart';
import 'package:lulusasn/features/main_navigation/widgets/navigation_rail.dart';
import 'package:lulusasn/features/home/screens/home_screen.dart';
import '../exam/screens/exam_list_screen.dart';
import '../home/screens/leaderboard_screen.dart';
import 'duolingo_app_bar.dart';

/// Main Navigation Screen - Responsive Wrapper
///
/// Responsibilities:
/// - Detect screen size
/// - Show appropriate navigation (bottom bar vs rail)
/// - Handle navigation state
/// - Render current screen with global app bar
class MainNavigationScreen extends StatefulWidget {
  final String? initialRoute;

  const MainNavigationScreen({super.key, this.initialRoute});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late String _currentRoute;

  // Breakpoint
  static const double _tabletBreakpoint = 600;

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.initialRoute ?? '/home';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _tabletBreakpoint;

    return Scaffold(
      // ✅ Global AppBar - digunakan di semua screen
      appBar: const GlobalAppBar(),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      bottomNavigationBar: isDesktop ? null : _buildBottomNavBar(),
    );
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================

  Widget _buildMobileLayout() {
    return _getCurrentScreen();
  }

  // ============================================================================
  // DESKTOP LAYOUT (with Navigation Rail)
  // ============================================================================

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Navigation Rail
        DuolingoNavigationRail(
          currentRoute: _currentRoute,
          onNavigate: _handleNavigation,
          onLogout: _handleLogout,
        ),

        // Main Content
        Expanded(child: _getCurrentScreen()),
      ],
    );
  }

  // ============================================================================
  // BOTTOM NAV BAR
  // ============================================================================

  Widget _buildBottomNavBar() {
    return DuolingoBottomNavBar(
      currentRoute: _currentRoute,
      onNavigate: _handleNavigation,
    );
  }

  // ============================================================================
  // SCREEN ROUTING
  // ============================================================================

  Widget _getCurrentScreen() {
    switch (_currentRoute) {
      case '/home':
      // ✅ HomeScreen tanpa AppBar (sudah ada di Scaffold)
        return const HomeScreen();

      case '/learn':
        return const ExamListScreen();

      case '/leaderboard':
        return const LeaderboardScreen();

      case '/profile':
        return const ProfileScreen();

      default:
        return const HomeScreen();
    }
  }

  // ============================================================================
  // NAVIGATION HANDLER
  // ============================================================================

  void _handleNavigation(String route) {
    if (_currentRoute != route) {
      setState(() {
        _currentRoute = route;
      });
    }
  }

  void _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
    }
  }
}

