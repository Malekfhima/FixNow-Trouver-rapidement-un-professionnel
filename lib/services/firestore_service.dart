import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/models/user_model.dart';
import 'package:fixnow/models/professional_model.dart';
import 'package:fixnow/models/service_request_model.dart';
import 'package:fixnow/models/category_model.dart';
import 'package:fixnow/models/review_model.dart';
import 'package:fixnow/models/chat_model.dart';
import 'package:fixnow/models/notification_model.dart';

/// Central service for all Firestore read/write operations.
class FirestoreService {
  // Lazy access so constructing the service never requires an initialized
  // Firebase app (e.g. in widget tests or when Firebase is not configured).
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── Users ────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<void> createUser(AppUser user) async {
    await _userDoc(user.uid).set(user.toFirestore());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Stream<AppUser?> userStream(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _userDoc(uid).update(data);
  }

  /// Creates the user profile if missing (phone auth / Google first login).
  Future<void> ensureUser(AppUser user) async {
    final doc = await _userDoc(user.uid).get();
    if (!doc.exists) {
      await _userDoc(user.uid).set(user.toFirestore());
    }
  }

  // ── Professionals ────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _proDoc(String uid) =>
      _db.collection('professionals').doc(uid);

  Future<void> createProfessional(Professional pro) async {
    await _proDoc(pro.uid).set(pro.toFirestore());
  }

  Future<Professional?> getProfessional(String uid) async {
    final doc = await _proDoc(uid).get();
    if (!doc.exists) return null;
    return Professional.fromFirestore(doc);
  }

  Stream<Professional?> professionalStream(String uid) {
    return _proDoc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Professional.fromFirestore(doc);
    });
  }

  Future<void> updateProfessional(String uid, Map<String, dynamic> data) async {
    await _proDoc(uid).update(data);
  }

  /// List approved professionals, optionally filtered by category.
  Future<List<Professional>> searchProfessionals({
    String? category,
    double? maxDistance,
    GeoPoint? userLocation,
  }) async {
    Query query = _db
        .collection('professionals')
        .where('status', isEqualTo: 'approved');

    if (category != null && category.isNotEmpty) {
      query = query.where('categories', arrayContains: category);
    }

    final snapshot = await query.limit(50).get();
    return snapshot.docs.map((doc) => Professional.fromFirestore(doc)).toList();
  }

  // ── Service Requests ─────────────────────────────────────────────

  Future<String> createServiceRequest(ServiceRequest request) async {
    final ref = await _db.collection('serviceRequests').add(request.toFirestore());
    return ref.id;
  }

  /// Fetches a single service request (null if missing).
  Future<ServiceRequest?> getRequest(String requestId) async {
    final doc = await _db.collection('serviceRequests').doc(requestId).get();
    if (!doc.exists) return null;
    return ServiceRequest.fromFirestore(doc);
  }

  Stream<List<ServiceRequest>> clientRequestsStream(String clientId) {
    return _db
        .collection('serviceRequests')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ServiceRequest.fromFirestore(doc)).toList());
  }

  Stream<List<ServiceRequest>> proRequestsStream(String proId) {
    return _db
        .collection('serviceRequests')
        .where('proId', isEqualTo: proId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ServiceRequest.fromFirestore(doc)).toList());
  }

  Future<void> updateRequestStatus(String requestId, ServiceRequestStatus status) async {
    await _db.collection('serviceRequests').doc(requestId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Partial update of a service request (status transitions, quote…).
  Future<void> updateServiceRequest(String requestId, Map<String, dynamic> data) async {
    await _db.collection('serviceRequests').doc(requestId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Reports (moderation) ─────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> openReportsStream() {
    return _db
        .collection('reports')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> resolveReport(String reportId, String outcome) async {
    await _db.collection('reports').doc(reportId).update({
      'status': outcome, // 'resolved' | 'dismissed'
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Categories ───────────────────────────────────────────────────

  Future<List<ServiceCategory>> getCategories() async {
    final snapshot = await _db.collection('categories').get();
    return snapshot.docs
        .map((doc) => ServiceCategory.fromFirestore(doc))
        .toList();
  }

  Stream<List<ServiceCategory>> categoriesStream() {
    return _db.collection('categories').snapshots().map((snap) =>
        snap.docs.map((doc) => ServiceCategory.fromFirestore(doc)).toList());
  }

  // ── Notifications (in-app) ───────────────────────────────────────

  Stream<List<NotificationItem>> notificationsStream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => NotificationItem.fromFirestore(doc)).toList());
  }

  /// Number of unread notifications for the badge.
  Stream<int> unreadNotificationsStream(String userId) {
    return notificationsStream(userId)
        .map((list) => list.where((n) => !n.read).length);
  }

  Future<void> createNotification(NotificationItem notification) async {
    // Timeout : une notification est best-effort — elle ne doit jamais
    // bloquer l'action qui l'accompagne (envoi de réservation, de message…).
    await _db
        .collection('notifications')
        .doc()
        .set(notification.toFirestore())
        .timeout(const Duration(seconds: 8));
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'read': true});
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }

  // ── Reviews ──────────────────────────────────────────────────────

  Future<List<Review>> getProReviews(String proId) async {
    final snapshot = await _db
        .collection('reviews')
        .where('proId', isEqualTo: proId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
  }

  /// Creates a review. The document id MUST be the requestId (uniqueness
  /// enforced by the Firestore rules: one review per completed request).
  Future<void> createReview(Review review) async {
    await _db
        .collection('reviews')
        .doc(review.requestId)
        .set(review.toFirestore());
  }

  /// Whether a review already exists for a given service request.
  Future<bool> hasReview(String requestId) async {
    final doc = await _db.collection('reviews').doc(requestId).get();
    return doc.exists;
  }

  // ── Pro rating aggregation ───────────────────────────────────────

  /// Recomputes a pro's ratingAvg / ratingCount from all their reviews.
  /// Called after a new review; also refreshes profile completeness.
  Future<void> recomputeProRating(String proId) async {
    final snapshot = await _db
        .collection('reviews')
        .where('proId', isEqualTo: proId)
        .get();
    final count = snapshot.docs.length;
    final avg = count == 0
        ? 0.0
        : snapshot.docs
                .map((doc) => (doc.data()['rating'] ?? 0) as num)
                .reduce((a, b) => a + b) /
            count;
    await _proDoc(proId).update({
      'ratingAvg': avg,
      'ratingCount': count,
    });
  }

  // ── Chats ────────────────────────────────────────────────────────

  /// Real-time stream of every conversation where [userId] is a participant.
  ///
  /// Chat documents store `clientId` / `proId` (no `participants` array),
  /// so we merge two queries — one per side — client-side.
  Stream<List<Chat>> userChatsStream(String userId) {
    final asClient = _db
        .collection('chats')
        .where('clientId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Chat.fromFirestore(doc)).toList());

    final asPro = _db
        .collection('chats')
        .where('proId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Chat.fromFirestore(doc)).toList());

    return _mergeChatStreams([asClient, asPro]);
  }

  /// Merges several chat streams, deduplicates by id and keeps them sorted
  /// by most recent message first.
  Stream<List<Chat>> _mergeChatStreams(List<Stream<List<Chat>>> streams) {
    late StreamController<List<Chat>> controller;
    final subscriptions = <StreamSubscription<List<Chat>>>[];
    final latest = List<List<Chat>?>.filled(streams.length, null);

    void emit() {
      final byId = <String, Chat>{};
      for (final list in latest) {
        if (list == null) continue;
        for (final chat in list) {
          byId[chat.id] = chat;
        }
      }
      final merged = byId.values.toList()
        ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      if (!controller.isClosed) controller.add(merged);
    }

    controller = StreamController<List<Chat>>(
      onListen: () {
        for (var i = 0; i < streams.length; i++) {
          subscriptions.add(
            streams[i].listen(
              (list) {
                latest[i] = list;
                emit();
              },
              onError: (Object e) {
                if (!controller.isClosed) controller.addError(e);
              },
            ),
          );
        }
      },
      onCancel: () async {
        for (final sub in subscriptions) {
          await sub.cancel();
        }
      },
    );

    return controller.stream;
  }

  Stream<List<ChatMessage>> messagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  /// Sends a message atomically: writes the message and updates the chat
  /// metadata (last message, unread counter for the OTHER participant).
  Future<void> sendMessage(
    String chatId,
    ChatMessage message, {
    required String senderId,
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);

    await _db.runTransaction((tx) async {
      final chatDoc = await tx.get(chatRef);
      final data = chatDoc.data();
      // The recipient is the participant who is NOT the sender.
      final otherField = data?['clientId'] == senderId ? 'proId' : 'clientId';
      final currentUnread = data?['unread${otherField == 'proId' ? 'Pro' : 'Client'}'] ?? 0;

      final msgRef = chatRef.collection('messages').doc();
      tx.set(msgRef, message.toFirestore());
      tx.update(chatRef, {
        'lastMessage': message.text.isNotEmpty
            ? message.text
            : (message.imageUrl != null ? '📷 Photo' : ''),
        'lastMessageAt': FieldValue.serverTimestamp(),
        // Per-side unread counters (recipient side is incremented).
        'unread${otherField == 'proId' ? 'Pro' : 'Client'}': currentUnread + 1,
      });
    });
  }

  /// Marks all messages of a chat as read for [userId] and resets their
  /// unread counter. Called when opening a conversation.
  Future<void> markChatRead(String chatId, String userId) async {
    final chatRef = _db.collection('chats').doc(chatId);

    await _db.runTransaction((tx) async {
      final chatDoc = await tx.get(chatRef);
      final data = chatDoc.data();
      final unreadField = data?['clientId'] == userId ? 'unreadClient' : 'unreadPro';
      if ((data?[unreadField] ?? 0) == 0) return; // nothing to do

      final unread = await chatRef
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      for (final doc in unread.docs) {
        tx.update(doc.reference, {'read': true});
      }
      tx.update(chatRef, {unreadField: 0});
    });
  }
}

/// Riverpod provider for FirestoreService.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
