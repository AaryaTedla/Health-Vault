import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'services/firebase_service.dart';
import 'services/medicine_autofill_service.dart';
import 'services/notification_service.dart';
import 'services/localization_service.dart';
import 'utils/app_theme.dart';
import 'screens/auth_screens.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Optional in demo mode; app can still run with dart-define fallback.
  }

  await FirebaseService.init();
  MedicineAutofillService.unawaitedSafeInit();
  await NotificationService.init();

  // Initialize localization
  await localization.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const HealthVaultApp(),
    ),
  );
}

class HealthVaultApp extends StatelessWidget {
  const HealthVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _RootScreen(),
    );
  }
}

class _RootScreen extends StatelessWidget {
  const _RootScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.isLoggedIn) return const MainShell();
    return const LoginScreen();
  }
}
