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

      // ✅ Deep link → pakai initialRoute (payment flow)
      // ✅ Normal → home: LoginScreen langsung, AuthGate dipakai
      //    HANYA untuk redirect setelah login sukses (dipanggil dari _navigateAfterLogin)
      home: _isDeepLink ? null : const LoginScreen(),
      initialRoute: _isDeepLink ? _initialRoute : null,

      onGenerateRoute: AppRouter.generateRoute,
      onUnknownRoute: AppRouter.onUnknownRoute,
    );
  }
}
