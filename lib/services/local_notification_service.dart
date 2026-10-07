import 'dart:convert';

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

  /// Displays an app-opened notification (new unread Firestore notification
  /// while the app is in the foreground — no Cloud Functions involved).
  /// [id] : identifiant LOCAL de la notification — utiliser un hash stable
  /// (ex. [NotificationTapRouter.stableId] de l'id Firestore) pour qu'un
  /// rappel du même événement remplace la notification au lieu d'en créer une.
  Future<void> showAppNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    if (title.isEmpty && body.isEmpty) return;

    await _plugin.show(
      id: id ?? (title + body).hashCode,
      title: title.isEmpty ? channelName : title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription:
              'Notifications FixNow (messages, demandes de service)',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
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
      payload: message.data.isEmpty
          ? null
          : NotificationTapRouter.encodePayload(message.data),
    );
  }

  /// Foreground tap → same routing as a background notification tap.
  void _onTap(NotificationResponse response) {
    final data = NotificationTapRouter.decodePayload(response.payload);
    if (data.isEmpty) return;
    try {
      NotificationTapRouter.route(data);
    } catch (_) {
      debugPrint('notification tap routing failed');
    }
  }
}

/// Indirection so the local-notification tap callback can reach the global
/// [NotificationService.handleNotificationTap] without a dependency cycle.
///
/// Le payload des notifications locales est du **JSON** (`jsonEncode` côté
/// émetteur, `jsonDecode` côté tap) — l'ancien format « map Dart en texte »
/// était fragile (clés corrompues par `substring`).
class NotificationTapRouter {
  static void Function(Map<String, dynamic> data)? handler;

  static void route(Map<String, dynamic> data) => handler?.call(data);

  /// Sérialise un payload de routage en JSON ; renvoie null si les valeurs
  /// ne sont pas encodables (les données FCM sont des chaînes).
  static String? encodePayload(Map<String, dynamic> data) {
    try {
      return jsonEncode(data);
    } catch (e) {
      debugPrint('notification payload encode failed: $e');
      return null;
    }
  }

  /// Décode un payload JSON ; renvoie une map vide si malformé (jamais
  /// d'exception — un tap ne doit jamais crasher l'app).
  static Map<String, dynamic> decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return const {};
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (e) {
      debugPrint('notification payload decode failed: $e');
    }
    return const {};
  }

  /// Hash stable (FNV-1a 32 bits, borné positif) — identifiant de
  /// notification locale déterministe dérivé de l'id Firestore.
  static int stableId(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
