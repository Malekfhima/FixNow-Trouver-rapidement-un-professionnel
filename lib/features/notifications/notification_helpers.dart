import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/models/notification_model.dart';
import 'package:fixnow/models/service_request_model.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/services/firestore_service.dart';

/// Creates an in-app notification for [userId] (actor = current user).
Future<void> pushNotification(
  Ref ref, {
  required String userId,
  required NotificationType type,
  String? relatedId,
  required String title,
  required String body,
}) async {
  final me = ref.read(currentUserProvider);
  if (me == null || userId == '') return;

  await ref.read(firestoreServiceProvider).createNotification(
        NotificationItem(
          id: '',
          userId: userId,
          actorId: me.uid,
          type: type,
          relatedId: relatedId,
          title: title,
          body: body,
          createdAt: DateTime.now(),
        ),
      );
}

/// French copywriting helpers for each notification type.
class NotificationCopy {
  static String titleFor(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
        return 'Nouveau message';
      case NotificationType.quoteReceived:
        return 'Devis reçu';
      case NotificationType.requestAccepted:
        return 'Demande acceptée';
      case NotificationType.requestDeclined:
        return 'Demande refusée';
      case NotificationType.requestCompleted:
        return 'Prestation terminée';
      case NotificationType.requestCancelled:
        return 'Demande annulée';
      case NotificationType.proApproved:
        return 'Profil validé 🎉';
      case NotificationType.proRejected:
        return 'Profil refusé';
      case NotificationType.generic:
        return 'Notification';
    }
  }

  static String bodyForRequest(ServiceRequestStatus status, String name) {
    switch (status) {
      case ServiceRequestStatus.accepted:
        return '$name a accepté votre demande.';
      case ServiceRequestStatus.declined:
        return '$name a refusé votre demande.';
      case ServiceRequestStatus.completed:
        return 'La prestation est terminée. Notez votre pro !';
      case ServiceRequestStatus.cancelled:
        return 'Le client a annulé la demande.';
      default:
        return '';
    }
  }
}
