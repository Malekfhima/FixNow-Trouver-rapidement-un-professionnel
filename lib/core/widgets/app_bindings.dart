import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fixnow/core/config/app_runtime.dart';
import 'package:fixnow/routing/app_router.dart';
import 'package:fixnow/services/local_notification_service.dart';
import 'package:fixnow/services/notification_service.dart';
import 'package:fixnow/services/firebase_auth_service.dart';

/// Watches the signed-in Firebase user and keeps their FCM token in sync:
/// registers the token on login, removes it on logout.
///
/// Mounted once at the app root (see `FixNowApp` in main.dart).
class AppBindings extends ConsumerStatefulWidget {
  final Widget child;
  const AppBindings({super.key, required this.child});

  @override
  ConsumerState<AppBindings> createState() => _AppBindingsState();
}

class _AppBindingsState extends ConsumerState<AppBindings> {
  String? _syncedUid;
  String? _previousUid;
  bool _tapHandlersRegistered = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(authStateProvider, (_, next) {
      _syncFcm(next.valueOrNull);
      _resolvePendingNotification(next.valueOrNull);
    }, fireImmediately: true);
    unawaited(_registerTapHandlers());
  }

  /// Registers the notification tap handlers once, after Firebase init
  /// (cold start via notification + background → foreground tap), creates
  /// the Android notification channel and displays foreground messages.
  Future<void> _registerTapHandlers() async {
    if (_tapHandlersRegistered || !firebaseInitialized) return;
    _tapHandlersRegistered = true;
    try {
      final push = ref.read(notificationServiceProvider);
      // Foreground taps (local notifications) reuse the push tap routing.
      NotificationTapRouter.handler = push.handleNotificationTap;
      push.registerTapHandlers();

      final local = LocalNotificationService();
      await local.init();
      // FCM n'affiche PAS les notifications reçues app au premier plan :
      // affichage local via le canal fixnow_default.
      FirebaseMessaging.onMessage.listen((message) {
        local.showForeground(message);
      });
    } catch (_) {
      // Push setup is best-effort; the app works without it.
    }
  }

  /// Replays a notification tap that happened while the user was logged
  /// out — the redirect is deferred until authentication resolves.
  void _resolvePendingNotification(user) {
    if (user == null) return;
    final service = ref.read(notificationServiceProvider);
    final pending = service.consumePendingNavigation();
    if (pending == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(appRouterProvider).push(pending.location);
      } catch (_) {}
    });
  }

  Future<void> _syncFcm(user) async {
    final uid = user?.uid;

    // Signed out after being signed in: clean up the token.
    if (uid == null && _previousUid != null) {
      try {
        await ref
            .read(notificationServiceProvider)
            .removeToken(_previousUid!);
      } catch (_) {}
      _syncedUid = null;
      _previousUid = null;
      return;
    }

    if (uid == null || !firebaseInitialized) return;
    if (uid == _syncedUid) return;

    // Signed in (or switched account): register the FCM token.
    try {
      // FCM is not supported on every platform (e.g. Windows, Linux).
      final supported = kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS;
      if (supported) {
        await ref.read(notificationServiceProvider).init(uid);
      }
      _syncedUid = uid;
    } catch (_) {
      // Push setup is best-effort; the app works without it.
    }
    _previousUid = uid;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
