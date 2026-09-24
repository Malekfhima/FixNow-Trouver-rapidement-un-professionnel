import 'package:cloud_firestore/cloud_firestore.dart';

enum ServiceRequestStatus {
  pending,
  accepted,
  declined,
  quoted,
  inProgress,
  completed,
  cancelled,
}

class ServiceRequest {
  final String id;
  final String clientId;
  final String? proId;
  final String categoryId;
  final String description;
  final List<String> photos;
  final ServiceRequestStatus status;

  /// Budget indicatif saisi PAR LE CLIENT à la création.
  /// Le prix convenu, lui, est uniquement [price] (écrit par le pro) :
  /// les règles Firestore interdisent price / quotePrice / quoteNote
  /// sur une création.
  final double? budget;
  final double? price;
  final double? quotePrice;
  final String? quoteNote;
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
    this.budget,
    this.price,
    this.quotePrice,
    this.quoteNote,
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
      budget: data['budget']?.toDouble(),
      price: data['price']?.toDouble(),
      quotePrice: data['quotePrice']?.toDouble(),
      quoteNote: data['quoteNote'],
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
      'budget': budget,
      'price': price,
      'quotePrice': quotePrice,
      'quoteNote': quoteNote,
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
    double? budget,
    double? price,
    double? quotePrice,
    String? quoteNote,
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
      budget: budget ?? this.budget,
      price: price ?? this.price,
      quotePrice: quotePrice ?? this.quotePrice,
      quoteNote: quoteNote ?? this.quoteNote,
      address: address ?? this.address,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
