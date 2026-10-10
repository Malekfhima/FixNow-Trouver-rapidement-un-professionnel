import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/features/client_dashboard/order_detail_screen.dart';
import 'package:fixnow/features/notifications/notifications_screen.dart';
import 'package:fixnow/features/pro_dashboard/pro_reviews_screen.dart';
import 'package:fixnow/models/notification_model.dart';
import 'package:fixnow/models/review_model.dart';
import 'package:fixnow/models/service_request_model.dart';
import 'package:fixnow/models/user_model.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/services/firestore_service.dart';

// ━━━ Fake Firestore (mêmes principes que critical_screens_test) ━━━━━━━━

class _FakeFirestoreService extends FirestoreService {
  _FakeFirestoreService({
    this.notifications = const [],
    this.failNotifications = false,
    this.request,
    this.reviews = const [],
    this.failReviews = false,
    this.publicProfile,
  });

  final List<NotificationItem> notifications;
  final bool failNotifications;
  final ServiceRequest? request;
  final List<Review> reviews;
  final bool failReviews;
  final AppUser? publicProfile;

  /// Appels d'écriture enregistrés afin de vérifier l'absence de faux paiement.
  final Map<String, Map<String, dynamic>> updatedRequests = {};

  @override
  Stream<List<NotificationItem>> notificationsStream(String userId) {
    if (failNotifications) return Stream.error(Exception('réseau'));
    return Stream.value(notifications);
  }

  @override
  Stream<ServiceRequest?> requestStream(String requestId) {
    return Stream.value(request);
  }

  @override
  Stream<AppUser?> userStream(String uid) => Stream.value(null);

  @override
  Stream<List<ServiceRequest>> clientRequestsStream(String clientId) =>
      Stream.value(const []);

  @override
  Future<List<Review>> getProReviews(String proId) async {
    if (failReviews) throw Exception('réseau indisponible');
    return reviews;
  }

  @override
  Future<AppUser?> getPublicProfile(String uid) async => publicProfile;

  @override
  Future<void> updateServiceRequest(
      String requestId, Map<String, dynamic> data) async {
    updatedRequests[requestId] = data;
  }
}

// ━━━ Données ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NotificationItem _notif({
  String id = 'n1',
  NotificationType type = NotificationType.quoteReceived,
  bool read = false,
}) {
  return NotificationItem(
    id: id,
    userId: 'me',
    actorId: 'p1',
    type: type,
    relatedId: 'req-1',
    title: 'Devis reçu',
    body: 'Un professionnel vous a envoyé un devis.',
    read: read,
    createdAt: DateTime.now(),
  );
}

ServiceRequest _request({bool depositPaid = false}) {
  return ServiceRequest(
    id: 'r1',
    clientId: 'me',
    proId: 'p1',
    categoryId: 'Plomberie',
    description: 'Fuite sous lévier de la cuisine.',
    photos: const ['https://res.cloudinary.com/demo/photo.jpg'],
    status: ServiceRequestStatus.accepted,
    price: 100,
    depositPaid: depositPaid,
    depositId: depositPaid ? 'legacy-transaction' : null,
    address: '12 rue des Lilas, Paris',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Review _review(
    {String id = 'rev1',
    int rating = 5,
    String clientId = 'c1',
    String comment = 'Travail impeccable et rapide.'}) {
  return Review(
    id: id,
    requestId: 'r1',
    clientId: clientId,
    proId: 'p1',
    rating: rating,
    comment: comment,
    createdAt: DateTime(2026, 2, 1),
  );
}

AppUser _profile({String name = 'Client Heureux'}) {
  return AppUser(
    uid: 'c1',
    name: name,
    email: '',
    role: UserRole.client,
    createdAt: DateTime(2026, 1, 1),
  );
}

// ━━━ Harnais ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Future<void> _setSmallPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _wrap(Widget home, FirestoreService fake,
    {User? user, double scale = 1}) {
  return ProviderScope(
    overrides: [
      firestoreServiceProvider.overrideWithValue(fake),
      authStateProvider.overrideWith((ref) => Stream<User?>.value(user)),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: home,
    ),
  );
}

void main() {
  final user = MockUser(uid: 'me');

  group('T5 — Notifications (liste in-app)', () {
    testWidgets('état vide à 320 dp / 1.5×, sans overflow', (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService();

      await tester.pumpWidget(
          _wrap(const NotificationsScreen(), fake, user: user, scale: 1.5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Aucune notification'), findsOneWidget);
      expect(find.text('Tout lire'), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'aucun RenderFlex overflow à 320 dp / 1.5×');
    });

    testWidgets('rendu nominal : tuiles avec titre, corps et relatif',
        (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService(
        notifications: [
          _notif(),
          _notif(id: 'n2', type: NotificationType.newMessage, read: true)
        ],
      );

      await tester.pumpWidget(
          _wrap(const NotificationsScreen(), fake, user: user, scale: 1.5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Devis reçu'), findsNWidgets(2));
      expect(find.textContaining('devis'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('état erreur : message français + Réessayer', (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService(failNotifications: true);

      await tester
          .pumpWidget(_wrap(const NotificationsScreen(), fake, user: user));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Réessayer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('T5 — Détail commande (photos + paiement indisponible)', () {
    testWidgets(
        'devis accepté : explique que le paiement en ligne est indisponible',
        (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService(request: _request());

      await tester.pumpWidget(
          _wrap(const OrdersDetailScreen(requestId: 'r1'), fake, user: user));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Fuite sous lévier de la cuisine.'), findsOneWidget);
      // Galerie photos : une image réseau affichée pour la photo de la demande.
      expect(find.byType(CachedNetworkImage), findsOneWidget);

      expect(
        find.textContaining('Le paiement en ligne n’est pas disponible.'),
        findsOneWidget,
      );
      expect(find.textContaining('Payer l'), findsNothing);
      expect(fake.updatedRequests, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un ancien indicateur de paiement ne confirme aucun paiement',
        (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService(request: _request(depositPaid: true));

      await tester.pumpWidget(
          _wrap(const OrdersDetailScreen(requestId: 'r1'), fake, user: user));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.textContaining('Le paiement en ligne n’est pas disponible.'),
        findsOneWidget,
      );
      expect(find.textContaining('Acompte réglé'), findsNothing);
      expect(find.textContaining('Payer l'), findsNothing);
      expect(fake.updatedRequests, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('demande introuvable : message en français', (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService();

      await tester.pumpWidget(
          _wrap(const OrdersDetailScreen(requestId: 'nope'), fake, user: user));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Demande introuvable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('T5 — Mes avis (pro)', () {
    testWidgets('état vide à 320 dp / 1.5×', (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService();

      await tester.pumpWidget(
          _wrap(const ProReviewsScreen(), fake, user: user, scale: 1.5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Aucun avis pour le moment'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nominal : note moyenne, compteur et cartes d’avis',
        (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService(
        reviews: [
          _review(rating: 5),
          _review(id: 'rev2', rating: 4, comment: 'Ponctuelle et soigneuse.'),
        ],
        publicProfile: _profile(),
      );

      await tester.pumpWidget(
          _wrap(const ProReviewsScreen(), fake, user: user, scale: 1.5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('4.5'), findsOneWidget,
          reason: 'note moyenne (5+4)/2 affichée');
      expect(find.text('2 avis de clients'), findsOneWidget);
      expect(find.text('Travail impeccable et rapide.'), findsOneWidget);
      expect(find.text('Ponctuelle et soigneuse.'), findsOneWidget);
      expect(find.text('Client Heureux'), findsNWidgets(2),
          reason: 'nom via publicProfiles pour chaque avis');
      expect(tester.takeException(), isNull);
    });

    testWidgets('état erreur : Réessayer disponible', (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService(failReviews: true);

      await tester
          .pumpWidget(_wrap(const ProReviewsScreen(), fake, user: user));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Réessayer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
