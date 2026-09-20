import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/models/notification_model.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/services/firebase_auth_service.dart';

/// Real-time stream of the current user's notifications.
final notificationsProvider =
    StreamProvider<List<NotificationItem>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);

  return ref.watch(firestoreServiceProvider).notificationsStream(user.uid);
});

/// Unread count for badges (nav bar, home bell).
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return list.where((n) => !n.read).length;
});

/// Notifier exposing mark-as-read actions.
class NotificationsController extends StateNotifier<int> {
  final Ref _ref;
  NotificationsController(this._ref) : super(0);

  Future<void> markRead(String notificationId) async {
    await _ref.read(firestoreServiceProvider).markNotificationRead(notificationId);
  }

  Future<void> markAllRead() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    await _ref
        .read(firestoreServiceProvider)
        .markAllNotificationsRead(user.uid);
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, int>((ref) {
  return NotificationsController(ref);
});
