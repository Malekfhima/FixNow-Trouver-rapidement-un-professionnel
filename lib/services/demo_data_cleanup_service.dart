import 'package:cloud_firestore/cloud_firestore.dart';

/// Removes only demo professional documents created by the former debug seeder.
class DemoDataCleanupService {
  final FirebaseFirestore _db;

  DemoDataCleanupService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  static const _demoProfessionalIds = [
    'demo-pro-1',
    'demo-pro-2',
    'demo-pro-3',
    'demo-pro-4',
    'demo-pro-5',
    'demo-pro-6',
  ];

  Future<bool> hasDemoData() async {
    final snapshots = await Future.wait(
      _demoProfessionalIds.map(
        (id) => _db.collection('professionals').doc(id).get(),
      ),
    );
    return snapshots.any((snapshot) => snapshot.exists);
  }

  Future<void> removeDemoProfessionals() async {
    final batch = _db.batch();
    for (final id in _demoProfessionalIds) {
      batch.delete(_db.collection('professionals').doc(id));
    }
    await batch.commit();
  }
}
