import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/models/user_model.dart';
import 'package:fixnow/models/professional_model.dart';
import 'package:fixnow/models/service_request_model.dart';
import 'package:fixnow/models/category_model.dart';
import 'package:fixnow/models/review_model.dart';
import 'package:fixnow/models/chat_model.dart';

/// Central service for all Firestore read/write operations.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  // ── Reviews ──────────────────────────────────────────────────────

  Future<List<Review>> getProReviews(String proId) async {
    final snapshot = await _db
        .collection('reviews')
        .where('proId', isEqualTo: proId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
  }

  Future<void> createReview(Review review) async {
    await _db.collection('reviews').add(review.toFirestore());
  }

  // ── Chats ────────────────────────────────────────────────────────

  Stream<List<Chat>> userChatsStream(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Chat.fromFirestore(doc)).toList());
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

  Future<void> sendMessage(String chatId, ChatMessage message) async {
    final batch = _db.batch();

    // Add the message
    final msgRef = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    batch.set(msgRef, message.toFirestore());

    // Update chat metadata
    batch.update(_db.collection('chats').doc(chatId), {
      'lastMessage': message.text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}

/// Riverpod provider for FirestoreService.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
