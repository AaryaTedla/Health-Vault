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
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _StartupSplashScreen(),
    );
  }
}

class _StartupSplashScreen extends StatefulWidget {
  const _StartupSplashScreen();

  @override
  State<_StartupSplashScreen> createState() => _StartupSplashScreenState();
}

enum _SplashStage { intro, loading }

class _StartupSplashScreenState extends State<_StartupSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _barController;
  late final Animation<double> _introScale;
  late final Animation<double> _opacity;
  _SplashStage _stage = _SplashStage.intro;
  bool _showRoot = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _introScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOut),
    );

    _introController.forward();
    _runSplashFlow();
  }

  Future<void> _runSplashFlow() async {
    await Future<void>.delayed(const Duration(milliseconds: 980));
    if (!mounted) return;
    setState(() => _stage = _SplashStage.loading);
    _barController.repeat();

    await Future<void>.delayed(const Duration(milliseconds: 1650));
    if (!mounted) return;
    setState(() => _showRoot = true);
  }

  @override
  void dispose() {
    _introController.dispose();
    _barController.dispose();
    super.dispose();
  }

  Widget _logoShell({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE6EAF2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D2533).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Image.asset(
          'assets/images/image.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showRoot) return const _RootScreen();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDFEFF), Color(0xFFF4F7FC)],
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_introController, _barController]),
          builder: (_, __) {
            final stageScale = _stage == _SplashStage.intro ? _introScale.value : 1.0;
            final combinedScale = stageScale.clamp(0.86, 1.12).toDouble();
            const trackWidth = 176.0;
            const barWidth = 56.0;
            final barTravel = trackWidth - barWidth;
            final barOffset = barTravel * _barController.value;

            return Stack(
              children: [
                Center(
                  child: Opacity(
                    opacity: _opacity.value,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 620),
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      transitionBuilder: (child, animation) {
                        final scale = Tween<double>(begin: 0.975, end: 1.0).animate(
                          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                        );
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(scale: scale, child: child),
                        );
                      },
                      child: _stage == _SplashStage.intro
                          ? Transform.scale(
                              key: const ValueKey('intro'),
                              scale: combinedScale,
                              child: _logoShell(size: 184),
                            )
                          : Transform.translate(
                              key: const ValueKey('loading'),
                              offset: const Offset(0, -16),
                              child: Transform.scale(
                                scale: combinedScale,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _logoShell(size: 226),
                                    const SizedBox(height: 20),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: SizedBox(
                                        width: trackWidth,
                                        height: 3,
                                        child: Stack(
                                          children: [
                                            Container(color: const Color(0xFFDCE3EE)),
                                            Positioned(
                                              left: barOffset,
                                              top: 0,
                                              bottom: 0,
                                              child: Container(
                                                width: barWidth,
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Color(0xFFAFC3FF),
                                                      Color(0xFF4A6CFF),
                                                      Color(0xFFAFC3FF),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
