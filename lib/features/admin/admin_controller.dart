import 'dart:async';

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

/// Agrégats affichés dans l'onglet « Statistiques » du dashboard admin.
class PlatformStats {
  final int clients;
  final int pros;
  final int pendingPros;
  final int requestsTotal;
  final Map<String, int> requests;

  /// Note moyenne globale, pondérée par le nombre d'avis de chaque pro.
  final double avgRating;

  const PlatformStats({
    required this.clients,
    required this.pros,
    required this.pendingPros,
    required this.requestsTotal,
    required this.requests,
    required this.avgRating,
  });
}

/// Streams the platform aggregates for the admin « Statistiques » tab:
/// clients / pros / pros en attente, demandes par statut et note moyenne.
final platformStatsProvider = StreamProvider.autoDispose<PlatformStats>((ref) {
  final db = FirebaseFirestore.instance;

  final usersSnap = db.collection('users').snapshots();
  final prosSnap = db.collection('professionals').snapshots();
  final requestsSnap = db.collection('serviceRequests').snapshots();

  return combineLatest3<QuerySnapshot<Map<String, dynamic>>,
          QuerySnapshot<Map<String, dynamic>>,
          QuerySnapshot<Map<String, dynamic>>, PlatformStats>(
    usersSnap,
    prosSnap,
    requestsSnap,
    _computeStats,
  );
});

/// Computes [PlatformStats] from the three raw Firestore snapshots.
PlatformStats _computeStats(
  QuerySnapshot<Map<String, dynamic>> users,
  QuerySnapshot<Map<String, dynamic>> pros,
  QuerySnapshot<Map<String, dynamic>> requests,
) {
  var clients = 0;
  var proCount = 0;
  for (final u in users.docs) {
    final role = u.data()['role'];
    if (role == 'pro') {
      proCount++;
    } else if (role == 'client') {
      clients++;
    }
  }

  var pendingPros = 0;
  double ratingSum = 0;
  int ratedCount = 0;
  for (final p in pros.docs) {
    if (p.data()['status'] == 'pending') pendingPros++;
    final avg = (p.data()['ratingAvg'] as num?)?.toDouble() ?? 0;
    final count = (p.data()['ratingCount'] as num?)?.toInt() ?? 0;
    if (count > 0) {
      // Moyenne globale pondérée par le nombre d'avis de chaque pro.
      ratingSum += avg * count;
      ratedCount += count;
    }
  }

  const statuses = [
    'pending', 'accepted', 'quoted',
    'inProgress', 'completed', 'cancelled',
  ];
  final byStatus = <String, int>{
    for (final s in statuses) s: 0,
  };
  for (final r in requests.docs) {
    final s = r.data()['status'] as String?;
    if (s != null && byStatus.containsKey(s)) byStatus[s] = byStatus[s]! + 1;
  }

  return PlatformStats(
    clients: clients,
    pros: proCount,
    pendingPros: pendingPros,
    requestsTotal: requests.docs.length,
    requests: byStatus,
    avgRating: ratedCount == 0 ? 0 : ratingSum / ratedCount,
  );
}

/// Minimal combineLatest for 3 streams (avoids an rxdart dependency):
/// re-emits whenever ANY source stream emits, once all have emitted once.
Stream<R> combineLatest3<A, B, C, R>(
  Stream<A> streamA,
  Stream<B> streamB,
  Stream<C> streamC,
  R Function(A, B, C) combine,
) {
  late StreamController<R> controller;
  A? a;
  B? b;
  C? c;
  var hasA = false, hasB = false, hasC = false;

  void emit() {
    if (hasA && hasB && hasC) {
      controller.add(combine(a as A, b as B, c as C));
    }
  }

  controller = StreamController<R>(
    onListen: () {
      final subs = <StreamSubscription<dynamic>>[
        streamA.listen((v) {
          a = v;
          hasA = true;
          emit();
        }, onError: controller.addError),
        streamB.listen((v) {
          b = v;
          hasB = true;
          emit();
        }, onError: controller.addError),
        streamC.listen((v) {
          c = v;
          hasC = true;
          emit();
        }, onError: controller.addError),
      ];
      controller.onCancel = () async {
        for (final s in subs) {
          await s.cancel();
        }
      };
    },
  );
  return controller.stream;
}
