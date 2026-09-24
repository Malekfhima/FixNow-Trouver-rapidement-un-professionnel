import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fixnow/core/config/app_runtime.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/firebase_options.dart';
import 'package:fixnow/routing/app_router.dart';
import 'package:fixnow/core/widgets/app_bindings.dart';
import 'package:fixnow/core/widgets/app_alerts.dart';
import 'package:fixnow/core/theme/theme_mode_controller.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (skip if not configured)
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    firebaseInitialized = true;
  } catch (e) {
    // Firebase not configured — app runs without backend
    firebaseInitialized = false;
    debugPrint('Firebase init skipped: $e');
  }

  // App Check : Play Integrity en release, provider debug en dev.
  // Aucun secret n'est commité :
  //   - provider debug → coller le jeton affiché en console dans
  //     Firebase Console > App Check > Enregistrement des appareils (dev),
  //   - ou passer un jeton CI via --dart-define=APP_CHECK_DEBUG_TOKEN=...
  if (firebaseInitialized) {
    try {
      const debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');
      await FirebaseAppCheck.instance.activate(
        androidProvider: kReleaseMode
            ? AndroidProvider.playIntegrity
            : AndroidProvider.debug,
        appleProvider: kReleaseMode
            ? AppleProvider.deviceCheck
            : AppleProvider.debug,
      );
      if (kDebugMode) {
        // Best-effort : journalise le jeton de debug à enregistrer dans
        // la console Firebase (aucune écriture permanente).
        final token = await FirebaseAppCheck.instance.getToken();
        debugPrint('App Check debug token: $token'
            '${debugToken.isNotEmpty ? ' (déclaré via --dart-define)' : ''}');
      }
    } catch (e) {
      // Jamais d'écran blanc à cause d'App Check (réseau, config…).
      debugPrint('App Check activation skipped: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: FixNowApp(),
    ),
  );
}

/// Root widget of the FixNow application.
class FixNowApp extends ConsumerWidget {
  const FixNowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode =
        ref.watch(themeModeControllerProvider).materialThemeMode;

    return AppBindings(
      child: MaterialApp.router(
        title: 'FixNow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: router,
        builder: (context, child) =>
            OfflineBanner(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
