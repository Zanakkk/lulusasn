// lib/features/main_navigation/main_screen.dart

// ignore_for_file: file_names

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lulusasn/features/home/screens/ProfileScreen.dart';
import 'package:lulusasn/features/main_navigation/widgets/bottom_nav_bar.dart';
import 'package:lulusasn/features/main_navigation/widgets/navigation_rail.dart';
import 'package:lulusasn/features/home/screens/home_screen.dart';
import '../../app/routes.dart';
import '../../core/services/storage_service.dart';
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
          onLogout: (){
            handleLogout;
          },
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

  /// Handle logout with proper cleanup and navigation
  Future<void> handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismiss by tapping outside
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: const Color(0xFFFF4B4B),
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Logout',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin keluar?',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 8),
            Text(
              'Data progress Anda akan tetap tersimpan.',
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ],
      ),
    );

    // User confirmed logout
    if (shouldLogout == true && context.mounted) {
      await _performLogout(context);
    }
  }

  /// Perform actual logout with loading indicator
  Future<void> _performLogout(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58CC02)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Logging out...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 1. Clear user-related storage data
      await StorageService.instance.clearUserData();
      debugPrint('✅ User data cleared from storage');

      // 2. Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      debugPrint('✅ Signed out from Firebase');

      // Small delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Close loading dialog
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      // 4. Navigate to login screen (clear all previous routes)
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false, // Remove all previous routes
        );
      }

      debugPrint('✅ Logout completed successfully');
    } catch (e) {
      debugPrint('❌ Logout error: $e');

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show error message
      if (context.mounted) {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  /// Show error dialog if logout fails
  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: const Color(0xFFFF4B4B),
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Logout Failed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'An error occurred while logging out.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Try logout again
              handleLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
