import 'package:cloud_firestore/cloud_firestore.dart'
    show DocumentSnapshot;
import 'package:flutter_test/flutter_test.dart';

import 'package:fixnow/features/search/search_controller.dart';
import 'package:fixnow/models/professional_model.dart';
import 'package:fixnow/services/firestore_service.dart';

// ━━━ Doubles de test ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Aucun accès Firebase réel : seuls le curseur et le nombre de pages
// importent pour la pagination.

// Snapshot factice — sert uniquement de curseur opaque (`startAfter`).
// `DocumentSnapshot` est `sealed` (non implémentable hors de sa librairie),
// mais ce fake n'est jamais déréférencé : il ne fait que transiter par
// `ProfessionalPage.lastDocument` puis revenir comme `startAfter`.
// ignore: subtype_of_sealed_class
class _FakeDocumentSnapshot
    implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeDocumentSnapshot(this.id);

  @override
  final String id;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// `FirestoreService` factice qui sert [pages] une par une.
class _PagedFirestoreService extends FirestoreService {
  _PagedFirestoreService({required this.pages, this.failOnPage});

  /// Contenu de chaque page, dans l'ordre de chargement.
  final List<List<Professional>> pages;

  /// Index (1-based) de l'appel qui doit échouer — null = jamais.
  final int? failOnPage;

  int callCount = 0;

  /// Curseur reçu à chaque appel (`startAfter`).
  final List<DocumentSnapshot?> startAfterArgs = [];

  /// `limit` reçu à chaque appel.
  final List<int> limitArgs = [];

  @override
  Future<ProfessionalPage> searchProfessionalsPage({
    String? category,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    callCount++;
    startAfterArgs.add(startAfter);
    limitArgs.add(limit);

    if (failOnPage != null && callCount == failOnPage) {
      throw Exception('réseau indisponible');
    }

    final index = callCount - 1;
    final items = index < pages.length ? pages[index] : const <Professional>[];
    final hasMore = index < pages.length - 1;
    final lastDocument =
        items.isEmpty ? startAfter : _FakeDocumentSnapshot('doc-$index');

    return ProfessionalPage(
      items: items,
      lastDocument: lastDocument,
      hasMore: hasMore,
    );
  }
}

Professional _pro(
  String uid, {
  double rating = 4.0,
  String name = 'Pro',
}) {
  return Professional(
    uid: uid,
    name: name,
    categories: const ['Plomberie'],
    bio: 'Artisan',
    hourlyRate: 40,
    ratingAvg: rating,
    ratingCount: 5,
    status: ProStatus.approved,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('SearchController — pagination (limit + startAfter)', () {
    test('search() charge la première page, sans curseur, avec limit=20',
        () async {
      final service = _PagedFirestoreService(pages: [
        [_pro('p1', rating: 4.5), _pro('p2', rating: 4.0)],
        [_pro('p3', rating: 3.5)],
      ]);
      final controller = SearchController(service);

      await controller.search(category: 'Tous');

      expect(service.callCount, 1);
      expect(service.startAfterArgs.single, isNull,
          reason: 'la première page ne doit pas passer de startAfter');
      expect(service.limitArgs.single, 20, reason: 'taille de page Firestore');
      expect(controller.state.results.map((p) => p.uid), ['p1', 'p2']);
      expect(controller.state.hasMore, isTrue);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isLoadingMore, isFalse);
      expect(controller.state.error, isNull);
    });

    test('loadMore() ajoute la page suivante et transmet le curseur startAfter',
        () async {
      final service = _PagedFirestoreService(pages: [
        [_pro('p1', rating: 4.5), _pro('p2', rating: 4.0)],
        [_pro('p3', rating: 3.5), _pro('p4', rating: 3.0)],
      ]);
      final controller = SearchController(service);

      await controller.search(category: 'Tous');
      await controller.loadMore();

      expect(service.callCount, 2);
      expect(service.startAfterArgs[0], isNull);
      expect(service.startAfterArgs[1], isNotNull,
          reason: 'la 2e requête doit reprendre le curseur de la 1re page');
      expect(service.limitArgs, [20, 20]);
      expect(controller.state.results.map((p) => p.uid),
          ['p1', 'p2', 'p3', 'p4']);
      expect(controller.state.hasMore, isFalse,
          reason: 'plus de pages après la dernière');
      expect(controller.state.isLoadingMore, isFalse);
    });

    test('loadMore() est un no-op quand la dernière page est atteinte',
        () async {
      final service = _PagedFirestoreService(pages: [
        [_pro('p1')],
      ]);
      final controller = SearchController(service);

      await controller.search(category: 'Tous');
      expect(controller.state.hasMore, isFalse);

      await controller.loadMore();
      await controller.loadMore();

      expect(service.callCount, 1,
          reason: 'hasMore == false : aucune requête supplémentaire');
    });

    test('loadMore() ne lance pas deux requêtes concurrentes', () async {
      final service = _PagedFirestoreService(pages: [
        [_pro('p1')],
        [_pro('p2')],
        [_pro('p3')],
      ]);
      final controller = SearchController(service);

      await controller.search(category: 'Tous');

      // Les deux appels partent avant que la 1re requête ne soit terminée.
      final first = controller.loadMore();
      final second = controller.loadMore();
      await Future.wait([first, second]);

      expect(service.callCount, 2,
          reason: 'une seule page supplémentaire malgré 2 appels');
      expect(controller.state.results.length, 2);
      expect(controller.state.hasMore, isTrue);
    });

    test('les résultats cumulés sont re-tries par note décroissante',
        () async {
      final service = _PagedFirestoreService(pages: [
        [_pro('p1', rating: 4.2), _pro('p2', rating: 3.5)],
        [_pro('p3', rating: 4.9), _pro('p4', rating: 4.8)],
      ]);
      final controller = SearchController(service);

      await controller.search(category: 'Tous');
      await controller.loadMore();

      expect(
        controller.state.results.map((p) => p.ratingAvg),
        [4.9, 4.8, 4.2, 3.5],
        reason: 'le tri s\'applique à la liste fusionnée, pas page par page',
      );
    });

    test('une erreur de page renseigne error et préserve les résultats',
        () async {
      final service = _PagedFirestoreService(
        pages: [
          [_pro('p1', rating: 4.5)],
          [_pro('p2', rating: 3.0)],
        ],
        failOnPage: 2,
      );
      final controller = SearchController(service);

      await controller.search(category: 'Tous');
      await controller.loadMore();

      expect(controller.state.error, isNotNull);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.isLoadingMore, isFalse);
      expect(controller.state.results.map((p) => p.uid), ['p1'],
          reason: 'les résultats de la première page sont conservés');
      expect(controller.state.hasMore, isTrue,
          reason: 'on peut réessayer de charger la page suivante');
    });
  });
}
