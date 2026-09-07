import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message (e.g. log analytics, update local state)
}

/// Service that wraps Firebase Cloud Messaging (FCM).
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
