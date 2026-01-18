// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/routes.dart';
import 'app/theme.dart';
import 'core/services/storage_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ HANYA initialize Firebase SEKALI di sini
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Initialize storage (tanpa re-init Firebase)
  await StorageService.instance.initialize();

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

      initialRoute: AppRoutes.splash, // ✅ Route awal
      onGenerateRoute: AppRouter.generateRoute, // ✅ Route generator
      onUnknownRoute:
          AppRouter.onUnknownRoute, // ✅ Fallback untuk route tidak dikenal
    );
  }
}
