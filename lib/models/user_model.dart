import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { client, pro, admin }

class AppUser {
  final String uid;
  final UserRole role;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? fcmToken;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.fcmToken,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.client,
      ),
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      avatarUrl: data['avatarUrl'],
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'role': role.name,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'fcmToken': fcmToken,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? fcmToken,
    UserRole? role,
  }) {
    return AppUser(
      uid: uid,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
