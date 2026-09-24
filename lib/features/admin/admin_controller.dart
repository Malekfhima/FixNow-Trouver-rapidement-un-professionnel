import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixnow/core/services/error_mapper.dart';
import 'package:fixnow/features/notifications/notification_helpers.dart';
import 'package:fixnow/models/notification_model.dart';
import 'package:fixnow/models/professional_model.dart';
import 'package:fixnow/models/category_model.dart';
import 'package:fixnow/services/firestore_service.dart';

/// Basic platform stats for the admin dashboard.
class AdminStats {
  final int pros;
  final int pendingPros;
  final int requests;
  final int users;

  const AdminStats({
    required this.pros,
    required this.pendingPros,
    required this.requests,
    required this.users,
  });
}

class AdminState {
  final List<Professional> pendingPros;
  final List<Professional> allPros;
  final List<ServiceCategory> categories;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.pendingPros = const [],
    this.allPros = const [],
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    List<Professional>? pendingPros,
    List<Professional>? allPros,
    List<ServiceCategory>? categories,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      pendingPros: pendingPros ?? this.pendingPros,
      allPros: allPros ?? this.allPros,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Loads and mutates admin-managed data.
class AdminController extends StateNotifier<AdminState> {
  final Ref _ref;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AdminController(this._ref) : super(const AdminState()) {
    load();
  }

  Ref get _r => _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _db
            .collection('professionals')
            .where('status', isEqualTo: 'pending')
            .get(),
        _db.collection('professionals').get(),
        _r.read(firestoreServiceProvider).getCategories(),
        _db.collection('serviceRequests').count().get(),
        _db.collection('users').count().get(),
      ]);

      final pendingSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final prosSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final categories = results[2] as List<ServiceCategory>;
      final requestsCount =
          (results[3] as AggregateQuerySnapshot).count ?? 0;
      final usersCount = (results[4] as AggregateQuerySnapshot).count ?? 0;

      state = state.copyWith(
        pendingPros: pendingSnap.docs
            .map((d) => Professional.fromFirestore(d))
            .toList(),
        allPros: prosSnap.docs.map((d) => Professional.fromFirestore(d)).toList(),
        categories: categories,
        isLoading: false,
      );
      _stats = AdminStats(
        pros: prosSnap.docs.length,
        pendingPros: pendingSnap.docs.length,
        requests: requestsCount,
        users: usersCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMapper.message(e));
    }
  }

  AdminStats? _stats;
  AdminStats? get stats => _stats;

  /// Approves a pending pro and notifies them.
  Future<void> approvePro(Professional pro) async {
    await _db.collection('professionals').doc(pro.uid).update({
      'status': 'approved',
    });
    await _notifyPro(pro, NotificationType.proApproved);
    await load();
  }

  /// Rejects a pending pro and notifies them.
  Future<void> rejectPro(Professional pro) async {
    await _db.collection('professionals').doc(pro.uid).update({
      'status': 'rejected',
    });
    await _notifyPro(pro, NotificationType.proRejected);
    await load();
  }

  Future<void> _notifyPro(Professional pro, NotificationType type) async {
    try {
      await pushNotification(
        _r,
        userId: pro.uid,
        type: type,
        // Lien réel exigé par les règles : la validation concerne bien
        // le profil professionnel de ce destinataire.
        relatedId: pro.uid,
        title: NotificationCopy.titleFor(type),
        body: type == NotificationType.proApproved
            ? 'Votre profil professionnel est validé. Vous êtes visible par les clients !'
            : "Votre profil professionnel n'a pas été retenu pour le moment.",
      );
    } catch (_) {}
  }

  Future<String?> addCategory(String name) async {
    try {
      await _db.collection('categories').doc().set({
        'name': name,
        'icon': 'build',
        'color': '#2F6BFF',
      });
      await load();
      return null;
    } catch (e) {
      return ErrorMapper.message(e);
    }
  }

  Future<String?> deleteCategory(ServiceCategory category) async {
    try {
      await _db.collection('categories').doc(category.id).delete();
      await load();
      return null;
    } catch (e) {
      return ErrorMapper.message(e);
    }
  }

  // ── Reports (moderation) ─────────────────────────────────────────

  /// Live stream of open reports for the admin tab.
  Stream<List<Map<String, dynamic>>> openReportsStream() {
    return _db
        .collection('reports')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Marks a report as resolved or dismissed.
  Future<String?> resolveReport(String reportId, {required bool valid}) async {
    try {
      await _db.collection('reports').doc(reportId).update({
        'status': valid ? 'resolved' : 'dismissed',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return ErrorMapper.message(e);
    }
  }
}

final adminControllerProvider =
    StateNotifierProvider<AdminController, AdminState>((ref) {
  return AdminController(ref);
});
