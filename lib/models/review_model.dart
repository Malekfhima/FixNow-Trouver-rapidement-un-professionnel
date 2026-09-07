import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String requestId;
  final String clientId;
  final String proId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.requestId,
    required this.clientId,
    required this.proId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      clientId: data['clientId'] ?? '',
      proId: data['proId'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'clientId': clientId,
      'proId': proId,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
