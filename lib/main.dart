// lib/main.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'app/routes.dart';
import 'app/theme.dart';
import 'core/services/storage_service.dart';
import 'firebase_options.dart';
import 'dart:html' as html;

// ✅ Dibaca SEKALI saat app start — sebelum runApp()
late final String _initialRoute;
late final bool _isDeepLink;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await StorageService.instance.initialize();

  // ✅ Baca URL hash di sini, bukan di build()
  _initialRoute = AppRouter.initialRoute;
  _isDeepLink = _initialRoute.startsWith(AppRoutes.paymentStatusPrefix);

  debugPrint('🚀 initialRoute: $_initialRoute | isDeepLink: $_isDeepLink');


  // Debug: cek nilai hash mentah
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

      // ✅ Kalau deep link → pakai initialRoute, tidak pakai home
      // Kalau normal → pakai home: AuthGate seperti biasa
      home: _isDeepLink ? null : const AuthGate(),
      initialRoute: _isDeepLink ? _initialRoute : null,

      onGenerateRoute: AppRouter.generateRoute,
      onUnknownRoute: AppRouter.onUnknownRoute,
    );
  }
}
