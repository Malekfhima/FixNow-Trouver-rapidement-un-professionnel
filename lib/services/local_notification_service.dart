import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Local notifications: creates the Android channel `fixnow_default`
/// (referenced by the Cloud Functions) and displays notifications received
/// in FOREGROUND — FCM does not display them natively.
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Channel id — must match `channelId: "fixnow_default"` in
  /// `functions/index.js` (Android notification payload).
  static const String channelId = 'fixnow_default';
  static const String channelName = 'FixNow';

  /// Idempotent init: creates the high-importance Android channel and wires
  /// the foreground tap callback to the push notification tap handler.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onTap,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      // High importance: heads-up display + sound on Android 8+.
      const channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Notifications FixNow (messages, demandes de service)',
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Displays a foreground FCM message using the `fixnow_default` channel.
  Future<void> showForeground(RemoteMessage message) async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    final notification = message.notification;
    if (notification == null) return;

    await _plugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription:
              'Notifications FixNow (messages, demandes de service)',
          importance: Importance.high,
          priority: Priority.high,
          // Reuse the app icon — no dedicated small icon asset required.
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }

  /// Foreground tap → same routing as a background notification tap.
  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      // Payload written by [showForeground] as Dart map string.
      final data = <String, dynamic>{};
      final inner = payload.substring(1, payload.length - 1);
      for (final pair in inner.split(', ')) {
        final idx = pair.indexOf(': ');
        if (idx <= 0) continue;
        data[pair.substring(0, idx)] = pair.substring(idx + 2);
      }
      NotificationTapRouter.route(data);
    } catch (_) {
      // Malformed payload: ignore.
    }
  }
}

/// Indirection so the local-notification tap callback can reach the global
/// [NotificationService.handleNotificationTap] without a dependency cycle.
class NotificationTapRouter {
  static void Function(Map<String, dynamic> data)? handler;

  static void route(Map<String, dynamic> data) => handler?.call(data);
}
