import 'package:cloud_firestore/cloud_firestore.dart';

enum ServiceRequestStatus { pending, accepted, inProgress, completed, cancelled }

class ServiceRequest {
  final String id;
  final String clientId;
  final String? proId;
  final String categoryId;
  final String description;
  final List<String> photos;
  final ServiceRequestStatus status;
  final double? price;
  final String address;
  final DateTime? scheduledDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceRequest({
    required this.id,
    required this.clientId,
    this.proId,
    required this.categoryId,
    required this.description,
    this.photos = const [],
    this.status = ServiceRequestStatus.pending,
    this.price,
    required this.address,
    this.scheduledDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceRequest(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      proId: data['proId'],
      categoryId: data['categoryId'] ?? '',
      description: data['description'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      status: ServiceRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ServiceRequestStatus.pending,
      ),
      price: data['price']?.toDouble(),
      address: data['address'] ?? '',
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'proId': proId,
      'categoryId': categoryId,
      'description': description,
      'photos': photos,
      'status': status.name,
      'price': price,
      'address': address,
      'scheduledDate':
          scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ServiceRequest copyWith({
    String? proId,
    String? description,
    List<String>? photos,
    ServiceRequestStatus? status,
    double? price,
    String? address,
    DateTime? scheduledDate,
  }) {
    return ServiceRequest(
      id: id,
      clientId: clientId,
      proId: proId ?? this.proId,
      categoryId: categoryId,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      status: status ?? this.status,
      price: price ?? this.price,
      address: address ?? this.address,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
