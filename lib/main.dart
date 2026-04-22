// lib/main.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:lulusasn/users/auth/screens/login_screen.dart';
import 'app/routes.dart';
import 'app/theme.dart';
import 'core/services/storage_service.dart';
import 'firebase_options.dart';
import 'dart:html' as html;

late final String _initialRoute;
late final bool _isDeepLink;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await StorageService.instance.initialize();

  _initialRoute = AppRouter.initialRoute;
  _isDeepLink = _initialRoute.startsWith(AppRoutes.paymentStatusPrefix);

  debugPrint('🚀 initialRoute: $_initialRoute | isDeepLink: $_isDeepLink');
  debugPrint('🔍 href   : ${html.window.location.href}');
  debugPrint('🔍 hash   : ${html.window.location.hash}');
  debugPrint('🔍 pathname: ${html.window.location.pathname}');

  if (!kIsWeb && const bool.fromEnvironment('dart.vm.product') == false) {
    try {
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    } catch (e) {
      debugPrint('Emulator not available: $e');
    }
  }

  runApp(const LulusASNApp());
}

class LulusASNApp extends StatelessWidget {
  const LulusASNApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LULUZZZ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      // ✅ Deep link → splash screen saat Flutter Web boot
      // ✅ Normal → home: LoginScreen langsung
      home: _isDeepLink
          ? const _DeepLinkSplashScreen() // ✅ SPLASH UNTUK DEEP LINK FLOW
          : const LoginScreen(),
      initialRoute: _isDeepLink ? _initialRoute : null,

      onGenerateRoute: AppRouter.generateRoute,
      onUnknownRoute: AppRouter.onUnknownRoute,
    );
  }
}

// ✅ SPLASH SCREEN: Ditampilkan saat Flutter Web boot dari deep link
// Memberi feedback visual sementara Flutter loading
class _DeepLinkSplashScreen extends StatelessWidget {
  const _DeepLinkSplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Brand
            Text(
              'LULUZZZ',
              style: AppText.display.copyWith(
                letterSpacing: 2,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppColors.gold),
            const SizedBox(height: 24),
            Text(
              'Memuat halaman pembayaran...',
              style: AppText.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Mohon tunggu sebentar',
              style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
