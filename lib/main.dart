// lib/main.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lulusasn/features/home/screens/home_screen.dart';

import 'app/theme.dart';
import 'app/routes.dart'; // ← Import dari app/, bukan core/
import 'core/services/firebase_service.dart';
import 'core/services/storage_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _initializeServices();

  runApp(const LulusASNApp());
}

/// Initialize all core services before app starts
Future<void> _initializeServices() async {
  // 1. Initialize Firebase
  await FirebaseService.instance.initialize();

  // 2. Initialize Storage
  await StorageService.instance.initialize();

  // Add more service initializations here as needed
}

class LulusASNApp extends StatelessWidget {
  const LulusASNApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LulusASN',
      debugShowCheckedModeBanner: false,
      theme: neobrutTheme,

      // ==================== ROUTING ====================
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.generateRoute,
      onUnknownRoute: AppRouter.onUnknownRoute,
    );
  }
}

// ============================================================================
// AUTH GATE (Native StreamBuilder - No external state management)
// ============================================================================
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
                color: Colors.black,
              ),
            ),
          );
        }

        // Check if user is logged in
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Not logged in
        return const LoginScreen();
      },
    );
  }
}
