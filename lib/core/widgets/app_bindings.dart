import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/core/config/app_runtime.dart';
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

  @override
  void initState() {
    super.initState();
    ref.listenManual(authStateProvider, (_, next) {
      _syncFcm(next.valueOrNull);
    }, fireImmediately: true);
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
