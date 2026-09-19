import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fixnow/models/category_model.dart';
import 'package:fixnow/models/professional_model.dart';

/// Demo data seeder — DEV ONLY.
///
/// Writes clearly-fictional categories and professionals, all prefixed
/// with "[DÉMO]" and stored under stable ids (idempotent: re-seeding
/// overwrites, `wipeDemoData` removes everything).
///
/// Firestore rules restrict seeding to **admin** accounts, so set your own
/// user's `role` to `admin` in the Firebase console (or the emulator) before
/// running it.
class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<ServiceCategory> demoCategories = [
    ServiceCategory(
        id: 'cat-plomberie',
        name: 'Plomberie',
        iconName: 'plumbing',
        colorHex: '#3B82F6',
        bgColorHex: '#DBEAFE'),
    ServiceCategory(
        id: 'cat-electricite',
        name: 'Électricité',
        iconName: 'electrical_services',
        colorHex: '#FBBF24',
        bgColorHex: '#FEF3C7'),
    ServiceCategory(
        id: 'cat-menuiserie',
        name: 'Menuiserie',
        iconName: 'carpenter',
        colorHex: '#8B5CF6',
        bgColorHex: '#EDE9FE'),
    ServiceCategory(
        id: 'cat-peinture',
        name: 'Peinture',
        iconName: 'format_paint',
        colorHex: '#EC4899',
        bgColorHex: '#FCE7F3'),
    ServiceCategory(
        id: 'cat-maconnerie',
        name: 'Maçonnerie',
        iconName: 'construction',
        colorHex: '#F97316',
        bgColorHex: '#FFF7ED'),
    ServiceCategory(
        id: 'cat-mecanique',
        name: 'Mécanique',
        iconName: 'build',
        colorHex: '#EF4444',
        bgColorHex: '#FEE2E2'),
    ServiceCategory(
        id: 'cat-menage',
        name: 'Ménage',
        iconName: 'cleaning_services',
        colorHex: '#22C55E',
        bgColorHex: '#DCFCE7'),
    ServiceCategory(
        id: 'cat-serrurerie',
        name: 'Serrurerie',
        iconName: 'vpn_key',
        colorHex: '#6366F1',
        bgColorHex: '#E0E7FF'),
  ];

  static final List<Professional> demoPros = [
    Professional(
        uid: 'demo-pro-1',
        name: '[DÉMO] Marc Lefebvre',
        city: 'Paris 11e',
        categories: ['Plomberie'],
        bio:
            'DONNÉES DE DÉMONSTRATION. Plombier certifié (fictif), 8 ans d\'expérience, spécialiste rénovation de salle de bain et dépannage urgent.',
        hourlyRate: 45,
        createdAt: DateTime(2026, 1, 1)),
    Professional(
        uid: 'demo-pro-2',
        name: '[DÉMO] Sophie Durand',
        city: 'Lyon 3e',
        categories: ['Électricité'],
        bio:
            'DONNÉES DE DÉMONSTRATION. Électricienne fictive, mise aux normes, tableaux et dépannage.',
        hourlyRate: 50,
        createdAt: DateTime(2026, 1, 1)),
    Professional(
        uid: 'demo-pro-3',
        name: '[DÉMO] Karim Benali',
        city: 'Marseille',
        categories: ['Menuiserie', 'Serrurerie'],
        bio:
            'DONNÉES DE DÉMONSTRATION. Menuisier-serrurier fictif, portes, fenêtres et serrures.',
        hourlyRate: 40,
        createdAt: DateTime(2026, 1, 1)),
    Professional(
        uid: 'demo-pro-4',
        name: '[DÉMO] Julie Morel',
        city: 'Bordeaux',
        categories: ['Peinture'],
        bio:
            'DONNÉES DE DÉMONSTRATION. Peintre fictive, intérieur/extérieur, finitions soignées.',
        hourlyRate: 35,
        createdAt: DateTime(2026, 1, 1)),
    Professional(
        uid: 'demo-pro-5',
        name: '[DÉMO] Thomas Rossi',
        city: 'Toulouse',
        categories: ['Mécanique'],
        bio:
            'DONNÉES DE DÉMONSTRATION. Mécanicien fictif, diagnostic et réparation automobile à domicile.',
        hourlyRate: 48,
        createdAt: DateTime(2026, 1, 1)),
    Professional(
        uid: 'demo-pro-6',
        name: '[DÉMO] Awa Diallo',
        city: 'Lille',
        categories: ['Ménage', 'Plomberie'],
        bio:
            'DONNÉES DE DÉMONSTRATION. Multi-services fictifs, ménage et petits dépannages plomberie.',
        hourlyRate: 28,
        createdAt: DateTime(2026, 1, 1)),
  ];

  /// Whether the demo data is currently present.
  Future<bool> hasDemoData() async {
    final doc = await _db.collection('professionals').doc('demo-pro-1').get();
    return doc.exists;
  }

  /// Writes categories + demo professionals (idempotent).
  Future<int> seedDemoData() async {
    final batch = _db.batch();

    for (final category in demoCategories) {
      batch.set(_db.collection('categories').doc(category.id),
          category.toFirestore());
    }
    for (final pro in demoPros) {
      batch.set(
          _db.collection('professionals').doc(pro.uid), pro.toFirestore());
    }

    await batch.commit();
    return demoCategories.length + demoPros.length;
  }

  /// Removes every seeded document.
  Future<void> wipeDemoData() async {
    final batch = _db.batch();
    for (final category in demoCategories) {
      batch.delete(_db.collection('categories').doc(category.id));
    }
    for (final pro in demoPros) {
      batch.delete(_db.collection('professionals').doc(pro.uid));
    }
    await batch.commit();
  }

  /// Convenience check: current user is authenticated at all.
  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;
}
