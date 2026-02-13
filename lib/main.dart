// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/routes.dart';
import 'app/theme.dart';
import 'core/services/storage_service.dart';
import 'features/exam/screens/ad_interstitial_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Initialize storage
  await StorageService.instance.initialize();

  // ✅ Initialize AdMob (TAMBAHKAN INI)
  await AdService.initialize();

  runApp(const LulusASNApp());
}

class LulusASNApp extends StatelessWidget {
  const LulusASNApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LulusASN',
      debugShowCheckedModeBanner: false,
      theme: duolingoTheme,

      home: const AuthGate(),
      onGenerateRoute: AppRouter.generateRoute, // ✅ Route generator
      onUnknownRoute:
          AppRouter.onUnknownRoute, // ✅ Fallback untuk route tidak dikenal
    );
  }
}
