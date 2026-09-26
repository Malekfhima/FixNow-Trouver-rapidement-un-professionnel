import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/routing/app_router.dart';
import 'package:fixnow/services/firebase_auth_service.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message (e.g. log analytics, update local state)
}

/// Riverpod container ref used to resolve the GoRouter outside of the
/// widget tree (notification taps happen far from any BuildContext).
ProviderContainer? _routerContainer;

/// Registers the container so [NotificationService] can navigate on tap.
void bindNotificationRouter(ProviderContainer container) {
  _routerContainer = container;
}

/// Service that wraps Firebase Cloud Messaging (FCM).
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<RemoteMessage>? _openedAppSub;

  /// Pending navigation when the user taps a notification while logged out.
  /// Replayed by [AppBindings] once authentication resolves.
  ({String location, DateTime at})? pendingNavigation;

  /// Routes the user according to a notification payload.
  ///
  /// Cloud Functions send `data.type` = `newRequest` (with `requestId`) or
  /// `newMessage` (with `chatId`). Unknown types are ignored. When the user
  /// is not signed in yet, the destination is kept in [pendingNavigation]
  /// for a deferred redirect after login.
  void handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    String? location;
    if (type == 'newRequest') {
      final requestId = data['requestId'];
      if (requestId is String && requestId.isNotEmpty) {
        location = '/orders/$requestId';
      }
    } else if (type == 'newMessage') {
      final chatId = data['chatId'];
      if (chatId is String && chatId.isNotEmpty) {
        location = '/chat/$chatId';
      }
    }
    if (location == null) return;

    try {
      final loggedIn =
          _routerContainer?.read(authStateProvider).valueOrNull != null;
      if (loggedIn) {
        _routerContainer?.read(appRouterProvider).push(location);
      } else {
        pendingNavigation = (location: location, at: DateTime.now());
      }
    } catch (_) {
      // Router not ready yet — keep the destination for after login.
      pendingNavigation = (location: location, at: DateTime.now());
    }
  }

  /// Consumes and clears the deferred navigation (called after login).
  ({String location, DateTime at})? consumePendingNavigation() {
    final pending = pendingNavigation;
    pendingNavigation = null;
    return pending;
  }

  /// Opens the app on the right screen when launched or resumed from a
  /// notification tap (cold start + background → foreground).
  void registerTapHandlers() {
    // App fully closed → opened via notification.
    _messaging.getInitialMessage().then((message) {
      if (message != null) handleNotificationTap(message.data);
    }).catchError((_) {});

    // App in background → brought to foreground by the tap.
    _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleNotificationTap(message.data);
    });
  }

  /// Requests permission and retrieves the FCM token.
  Future<String?> init(String uid) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _messaging.getToken();
      if (token != null && uid.isNotEmpty) {
        await _saveToken(uid, token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _saveToken(uid, newToken);
      });

      return token;
    }
    return null;
  }

  /// Cancels the tap listeners (app teardown / tests).
  Future<void> dispose() async {
    await _openedAppSub?.cancel();
    _openedAppSub = null;
  }

  /// Saves the FCM token to the user's Firestore document.
  Future<void> _saveToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({
      'fcmToken': token,
    });
  }

  /// Subscribes to a topic (e.g. category updates, admin alerts).
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribes from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Removes the FCM token on sign-out.
  Future<void> removeToken(String uid) async {
    await _messaging.deleteToken();
    await _db.collection('users').doc(uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }
}

/// Riverpod provider for NotificationService.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
