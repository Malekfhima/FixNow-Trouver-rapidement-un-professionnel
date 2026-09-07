import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceCategory {
  final String id;
  final String name;
  final String iconName;
  final String colorHex;
  final String? bgColorHex;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    this.bgColorHex,
  });

  factory ServiceCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceCategory(
      id: doc.id,
      name: data['name'] ?? '',
      iconName: data['icon'] ?? 'build',
      colorHex: data['color'] ?? '#2F6BFF',
      bgColorHex: data['bgColor'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': iconName,
      'color': colorHex,
      'bgColor': bgColorHex,
    };
  }
}
