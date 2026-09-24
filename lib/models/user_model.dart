import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { client, pro, admin }

/// An account can be a client AND a professional at the same time:
/// - [isPro] enables the pro capabilities (dashboard, profile, services).
/// - Clients can book services (true for everyone, pro included).
/// - [role] == admin is an extra, additive moderation privilege.
class AppUser {
  final String uid;
  final UserRole role;

  /// True when this account also acts as a professional.
  /// Derived from [role] == pro for legacy accounts.
  final bool isPro;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? fcmToken;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    this.role = UserRole.client,
    this.isPro = false,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.fcmToken,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final role = UserRole.values.firstWhere(
      (e) => e.name == data['role'],
      orElse: () => UserRole.client,
    );
    return AppUser(
      uid: doc.id,
      role: role,
      // Legacy accounts may still use role == 'pro'.
      isPro: data['isPro'] == true || role == UserRole.pro,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      avatarUrl: data['avatarUrl'],
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Lit un profil PUBLIC (publicProfiles/{uid}) : nom, avatar et rôle.
  ///
  /// C'est la seule source autorisée pour afficher UN AUTRE utilisateur
  /// (chat, avis…) depuis la restriction de `users/{uid}` aux propriétaires
  /// et admins. Les champs privés (email, téléphone, fcmToken) restent vides.
  factory AppUser.fromPublicProfile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final role = UserRole.values.firstWhere(
      (e) => e.name == data['role'],
      orElse: () => UserRole.client,
    );
    return AppUser(
      uid: doc.id,
      role: role,
      isPro: role == UserRole.pro,
      name: data['name'] ?? '',
      email: '',
      avatarUrl: data['avatarUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'role': role.name,
      'isPro': isPro,
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
    bool? isPro,
  }) {
    return AppUser(
      uid: uid,
      role: role ?? this.role,
      isPro: isPro ?? this.isPro,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
