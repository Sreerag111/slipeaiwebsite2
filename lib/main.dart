import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:plagiarism_checker/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'core/bindings/app_binding.dart';
import 'core/ads/admob_service.dart';
import 'core/error/global_error_controller.dart';
import 'core/network/network_blocking_overlay.dart';
import 'core/network/network_controller.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/chat/presentation/pages/home_screen.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/chat/domain/services/image_preset_service.dart';
import 'core/navigation/app_route_observer.dart';
import 'core/version/app_version_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Keep diagnostic output (which may contain private API details) out of
    // release builds, including callers that forget their own debug guard.
    debugPrint = (String? message, {int? wrapWidth}) {
      if (kDebugMode) {
        debugPrintSynchronously(message, wrapWidth: wrapWidth);
      }
    };

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
      unawaited(ImagePresetService.instance.fetchPresets());
      unawaited(AppVersionService.instance.initialize());
    } catch (e) {
      debugPrint('Warning: Firebase init failed: $e');
    }

    // Consent and ad SDK setup run without delaying app startup. Ads are
    // still gated by the signed-in user's entitlement in the UI.
    unawaited(AdMobService.instance.initialize());

    FlutterError.onError = (details) {
      if (kDebugMode) FlutterError.dumpErrorToConsole(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      try {
        final controller = GlobalErrorController.instance;
        controller.reportError(details.exception, details.stack);
        controller.showError(_userFriendlyMessage(details.exception));
      } catch (_) {}
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: true,
      );
      try {
        final controller = GlobalErrorController.instance;
        controller.reportError(error, stack);
        controller.showError(_userFriendlyMessage(error));
      } catch (_) {}
      return true;
    };

    final sharedPreferences = await SharedPreferences.getInstance();
    Get.put<SharedPreferences>(sharedPreferences, permanent: true);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.primary,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    runApp(const PlagiarismCheckerApp());
  }, (error, stack) {
    debugPrint('[Unhandled] $error\n$stack');
    final controller = Get.isRegistered<GlobalErrorController>()
        ? GlobalErrorController.instance
        : null;
    controller?.showError(_userFriendlyMessage(error));
  });
}

String _userFriendlyMessage(dynamic error) {
  final msg = error.toString();
  if (msg.contains('SocketException') || msg.contains('Connection refused')) {
    return 'No internet connection. Please check your network.';
  }
  if (msg.contains('TimeoutException')) {
    return 'Request timed out. Please try again.';
  }
  if (msg.contains('FormatException')) {
    return 'Something went wrong. Please try again.';
  }
  if (msg.contains('PlatformException')) {
    return 'A system error occurred. Please restart the app.';
  }
  return 'Something went wrong. Please try again.';
}

class PlagiarismCheckerApp extends StatelessWidget {
  const PlagiarismCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (details) {
      final controller = Get.isRegistered<GlobalErrorController>()
          ? GlobalErrorController.instance
          : null;
      controller?.reportError(details.exception, details.stack);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller?.showError('Something went wrong rendering the page.');
      });
      return const SizedBox.shrink();
    };

    final themecontroller = Get.isRegistered<ThemeController>()
        ? ThemeController.instance
        : Get.put(ThemeController(), permanent: true);
    if (!Get.isRegistered<NetworkController>()) {
      Get.put(NetworkController(), permanent: true);
    }

    return Obx(
      () => GetMaterialApp(
        title: 'Slipe AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themecontroller.themeMode,
        initialBinding: AppBinding(),
        home: const SplashScreen(),
        navigatorObservers: [appRouteObserver],
        builder: (context, child) => NetworkBlockingOverlay(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 700);

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  bool _hasStartedBootstrap = false;
  bool _isCompanionLaunchLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasStartedBootstrap) {
        return;
      }
      _hasStartedBootstrap = true;
      _startSplashFlow();
    });
  }

  Future<void> _startSplashFlow() async {
    bool skip = false;
    try {
      const channel = MethodChannel('com.blide.ai/floating_bubble');
      skip = await channel.invokeMethod<bool>('shouldSkipSplash') ?? false;
    } catch (error) {
      debugPrint('Error checking skip splash: $error');
    }

    if (skip && mounted) {
      _controller.value = 1;
      setState(() {
        _isCompanionLaunchLoading = true;
      });
      try {
        await Get.find<AuthController>().bootstrap().timeout(
              const Duration(seconds: 2),
              onTimeout: () => debugPrint('[Splash] Companion auth timed out'),
            );
      } catch (error) {
        debugPrint('[Splash] Error during companion bootstrap: $error');
      }
      if (!mounted) {
        return;
      }
      _openAuthGate();
      return;
    }

    try {
      // Warm up version control in background without delaying splash dismissal
      unawaited(AppVersionService.instance.checkUpdateStatus());

      await Future.wait<void>([
        _controller.forward(from: 0),
        Get.find<AuthController>().bootstrap().timeout(
              const Duration(seconds: 2),
              onTimeout: () => debugPrint('[Splash] Auth bootstrap timed out'),
            ),
      ]).timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () => [null, null],
      );
    } catch (error) {
      debugPrint('[Splash] Startup bootstrap error: $error');
    }

    if (!mounted) {
      return;
    }

    _openAuthGate();
  }

  void _openAuthGate() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const AuthGate(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isCompanionLaunchLoading
              ? Column(
                  key: const ValueKey('companion-launch-loading'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo/new_logo.png',
                      width: MediaQuery.of(context).size.width * 0.30,
                      height: MediaQuery.of(context).size.width * 0.30,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Opening Slipe AI',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                )
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo/new_logo.png',
                          width: MediaQuery.of(context).size.width * 0.35,
                          height: MediaQuery.of(context).size.width * 0.35,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      if (auth.isLoggedIn) {
        return const HomeScreen();
      }
      return const LoginScreen();
    });
  }
}
