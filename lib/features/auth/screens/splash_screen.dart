// lib/features/auth/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../app/routes.dart';

/// Splash screen that handles auth state checking
/// Redirects to appropriate screen based on auth status
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted) return;

      if (user != null) {
        // User is logged in
        if (user.emailVerified) {
          // Email verified - go to home
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          // Email not verified - logout and go to login
          FirebaseAuth.instance.signOut();
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } else {
        // Not logged in - go to login
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black),
      ),
    );
  }
}
