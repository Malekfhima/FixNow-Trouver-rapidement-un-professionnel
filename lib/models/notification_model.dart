import 'package:cloud_firestore/cloud_firestore.dart';

/// Kind of in-app notification.
enum NotificationType {
  newMessage,
  quoteReceived,
  requestAccepted,
  requestDeclined,
  requestCompleted,
  requestCancelled,
  proApproved,
  proRejected,
  generic,
}

/// In-app notification (Firestore, no Cloud Functions required).
class NotificationItem {
  final String id;

  /// Recipient user id.
  final String userId;

  /// User who triggered the event (used by the security rules).
  final String actorId;

  final NotificationType type;

  /// Related document id (serviceRequest id, chat id…).
  final String? relatedId;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.type,
    this.relatedId,
    required this.title,
    required this.body,
    this.read = false,
    required this.createdAt,
  });

  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      actorId: data['actorId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.generic,
      ),
      relatedId: data['relatedId'],
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      read: data['read'] ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'actorId': actorId,
      'type': type.name,
      'relatedId': relatedId,
      'title': title,
      'body': body,
      'read': read,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  NotificationItem copyWith({bool? read}) {
    return NotificationItem(
      id: id,
      userId: userId,
      actorId: actorId,
      type: type,
      relatedId: relatedId,
      title: title,
      body: body,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}
