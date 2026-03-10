// lib/main.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'app/routes.dart';
import 'app/theme.dart';
import 'core/services/storage_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Initialize storage
  await StorageService.instance.initialize();

  // ✅ Setup Firebase Functions emulator untuk development
  if (!kIsWeb && const bool.fromEnvironment('dart.vm.product') == false) {
    // Gunakan emulator hanya untuk non-web di development
    // Untuk web, emulator tidak support dengan baik
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

      home: const AuthGate(),
      onGenerateRoute: AppRouter.generateRoute, // ✅ Route generator
      onUnknownRoute:
          AppRouter.onUnknownRoute, // ✅ Fallback untuk route tidak dikenal
    );
  }
}
