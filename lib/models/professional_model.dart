import 'package:cloud_firestore/cloud_firestore.dart';

enum ProStatus { pending, approved, rejected }

class Professional {
  final String uid;
  final String name;
  final String? avatarUrl;
  final String city;
  final List<String> categories;
  final String bio;
  final double hourlyRate;
  final double ratingAvg;
  final int ratingCount;
  final List<String> gallery;
  final GeoPoint? location;
  final String? address;
  final Map<String, dynamic>? availability;
  final ProStatus status;
  final DateTime createdAt;

  const Professional({
    required this.uid,
    this.name = '',
    this.avatarUrl,
    this.city = '',
    required this.categories,
    required this.bio,
    required this.hourlyRate,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.gallery = const [],
    this.location,
    this.address,
    this.availability,
    this.status = ProStatus.pending,
    required this.createdAt,
  });

  factory Professional.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Professional(
      uid: doc.id,
      name: data['name'] ?? '',
      avatarUrl: data['avatarUrl'],
      city: data['city'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      bio: data['bio'] ?? '',
      hourlyRate: (data['hourlyRate'] ?? 0).toDouble(),
      ratingAvg: (data['ratingAvg'] ?? 0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      gallery: List<String>.from(data['gallery'] ?? []),
      location: data['location'],
      address: data['address'],
      availability: data['availability'],
      status: ProStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ProStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'avatarUrl': avatarUrl,
      'city': city,
      'categories': categories,
      'bio': bio,
      'hourlyRate': hourlyRate,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'gallery': gallery,
      'location': location,
      'address': address,
      'availability': availability,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Professional copyWith({
    String? name,
    String? avatarUrl,
    String? city,
    List<String>? categories,
    String? bio,
    double? hourlyRate,
    double? ratingAvg,
    int? ratingCount,
    List<String>? gallery,
    GeoPoint? location,
    String? address,
    Map<String, dynamic>? availability,
    ProStatus? status,
  }) {
    return Professional(
      uid: uid,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      categories: categories ?? this.categories,
      bio: bio ?? this.bio,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      gallery: gallery ?? this.gallery,
      location: location ?? this.location,
      address: address ?? this.address,
      availability: availability ?? this.availability,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
