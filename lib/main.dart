import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fixnow/core/config/app_runtime.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/firebase_options.dart';
import 'package:fixnow/routing/app_router.dart';
import 'package:fixnow/core/widgets/app_bindings.dart';

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

    return AppBindings(
      child: MaterialApp.router(
        title: 'FixNow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // TODO: darkTheme: AppTheme.dark,
        routerConfig: router,
      ),
    );
  }
}
