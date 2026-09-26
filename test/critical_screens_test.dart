import 'package:cloud_firestore/cloud_firestore.dart'
    show GeoPoint, DocumentSnapshot;
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/features/booking/booking_screen.dart';
import 'package:fixnow/features/chat/chat_list_screen.dart';
import 'package:fixnow/features/home/home_screen.dart';
import 'package:fixnow/features/search/search_screen.dart';
import 'package:fixnow/models/category_model.dart';
import 'package:fixnow/models/chat_model.dart';
import 'package:fixnow/models/notification_model.dart';
import 'package:fixnow/models/professional_model.dart';
import 'package:fixnow/models/service_request_model.dart';
import 'package:fixnow/models/user_model.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/services/firestore_service.dart';

// ━━━ Fakes ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Sous-classe de FirestoreService : seules les méthodes utilisées par les
// écrans testés sont redéfinies (aucun accès Firebase réel en test).

class _FakeFirestoreService extends FirestoreService {
  _FakeFirestoreService({
    this.pros = const [],
    this.chats = const [],
    this.publicProfile,
    this.failSearch = false,
  });

  final List<Professional> pros;
  final List<Chat> chats;
  final AppUser? publicProfile;
  final bool failSearch;

  @override
  Future<List<Professional>> searchProfessionals({
    String? category,
    double? maxDistance,
    GeoPoint? userLocation,
  }) async {
    if (failSearch) throw Exception('réseau indisponible');
    if (category == null || category == 'Tous') return pros;
    return pros.where((p) => p.categories.contains(category)).toList();
  }

  @override
  Future<ProfessionalPage> searchProfessionalsPage({
    String? category,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    if (failSearch) throw Exception('réseau indisponible');
    final filtered = category == null || category == 'Tous'
        ? pros
        : pros.where((p) => p.categories.contains(category)).toList();
    return ProfessionalPage(items: filtered, hasMore: false);
  }

  @override
  Future<List<ServiceCategory>> getCategories() async => const [];

  @override
  Stream<List<Chat>> userChatsStream(String userId) => Stream.value(chats);

  @override
  Future<AppUser?> getPublicProfile(String uid) async => publicProfile;

  @override
  Stream<AppUser?> userStream(String uid) => Stream.value(null);

  @override
  Stream<List<ServiceRequest>> clientRequestsStream(String clientId) =>
      Stream.value(const []);

  @override
  Stream<List<NotificationItem>> notificationsStream(String userId) =>
      Stream.value(const []);
}

Professional _pro({String uid = 'p1', String name = 'Alice Martin'}) {
  return Professional(
    uid: uid,
    name: name,
    city: 'Paris',
    categories: const ['Plomberie'],
    bio: 'Plombière expérimentée',
    hourlyRate: 45,
    ratingAvg: 4.8,
    ratingCount: 32,
    status: ProStatus.approved,
    createdAt: DateTime(2026, 1, 1),
  );
}

AppUser _publicProfile({String uid = 'p1', String name = 'Alice Martin'}) {
  return AppUser(
    uid: uid,
    name: name,
    email: '',
    role: UserRole.pro,
    createdAt: DateTime(2026, 1, 1),
  );
}

/// Fenêtre étroite (320 dp) + gros texte (1.5×) : deux pièges classiques
/// de RenderFlex overflow, vérifiés pour chaque écran critique.
Future<void> _setSmallPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _wrap(Widget home, FirestoreService fake, {User? user, double scale = 1}) {
  return ProviderScope(
    overrides: [
      firestoreServiceProvider.overrideWithValue(fake),
      authStateProvider.overrideWith(
        (ref) => Stream<User?>.value(user),
      ),
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
  group('Écran critique — Accueil', () {
    testWidgets('rendu nominal sur petit écran + gros texte, sans overflow',
        (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService(pros: [_pro()]);

      await tester.pumpWidget(_wrap(const HomeScreen(), fake, scale: 1.5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Bonjour 👋'), findsOneWidget,
          reason: 'salutation en français');
      expect(find.text('Services les plus réservés'), findsOneWidget);
      expect(find.text('Populaire près de vous'), findsOneWidget);
      expect(find.text('Alice Martin'), findsOneWidget,
          reason: 'pro « populaire » affiché');
      expect(find.byTooltip('Voir les notifications'), findsOneWidget,
          reason: 'cloche à tooltip (accessibilité)');
      expect(tester.takeException(), isNull,
          reason: 'aucun RenderFlex overflow à 320 dp / 1.5×');
    });

    testWidgets('état vide avec illustration, message et action',
        (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService(pros: const []);

      await tester.pumpWidget(_wrap(const HomeScreen(), fake));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Aucun professionnel trouvé'), findsOneWidget);
      expect(
        find.text('Les professionnels disponibles apparaîtront ici.'),
        findsOneWidget,
        reason: 'état vide : illustration + message',
      );
      expect(find.text('Voir tout'), findsWidgets,
          reason: 'action de relance présente');
      expect(tester.takeException(), isNull);
    });

    testWidgets('état d\'erreur : message français + bouton Réessayer',
        (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService(failSearch: true);

      await tester.pumpWidget(_wrap(const HomeScreen(), fake));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.textContaining('erreur'), findsWidgets);

      await tester.tap(find.text('Réessayer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });
  });

  group('Écran critique — Recherche', () {
    testWidgets('barre, onglets catégories et résultat à 320 dp / 1.5×',
        (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService(pros: [_pro()]);

      await tester.pumpWidget(_wrap(const SearchScreen(), fake, scale: 1.5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Rechercher'), findsOneWidget, reason: 'titre AppBar');
      expect(find.text('Plomberie'), findsWidgets, reason: 'onglet catégorie');
      expect(find.text('Alice Martin'), findsOneWidget,
          reason: 'résultat de recherche affiché');
      expect(find.byTooltip('Effacer la recherche'), findsNothing,
          reason: 'pas d\'effacement tant que la champ est vide');
      expect(tester.takeException(), isNull);
    });

    testWidgets('état vide : message + action « Réinitialiser les filtres »',
        (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService(pros: const []);

      await tester.pumpWidget(_wrap(const SearchScreen(), fake));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Aucun professionnel trouvé'), findsOneWidget);
      expect(find.text('Réinitialiser les filtres'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Écran critique — Réservation', () {
    testWidgets('validation en français + budget optionnel, sans crash',
        (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService();

      await tester.pumpWidget(
          _wrap(const BookingScreen(), fake, scale: 1.5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Réserver un service'), findsOneWidget);
      expect(find.text('Budget estimé (optionnel)'), findsOneWidget,
          reason: 'le budget client n\'écrit JAMAIS price (règles)');

      // Soumission à vide : messages de validation en français.
      await tester.ensureVisible(find.text('Envoyer la demande'));
      await tester.tap(find.text('Envoyer la demande'));
      await tester.pump();

      expect(find.textContaining('au moins 10 caractères'), findsOneWidget,
          reason: 'validation FR de la description');
      expect(tester.takeException(), isNull,
          reason: 'aucun accès GoRouter hors route (pas d\'exception)');
    });
  });

  group('Écran critique — Chat', () {
    testWidgets('conversation affichée avec badge de messages non lus',
        (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService(
        chats: [
          Chat(
            id: 'c1',
            clientId: 'me',
            proId: 'p1',
            lastMessage: 'Bonjour, je peux venir demain',
            lastMessageAt: DateTime.now(),
            unreadClient: 3,
          ),
        ],
        publicProfile: _publicProfile(),
      );
      final user = MockUser(uid: 'me');

      await tester.pumpWidget(_wrap(const ChatListScreen(), fake, user: user));
      await tester.pump(); // session résolue (authStateChanges)
      await tester.pump(const Duration(milliseconds: 50)); // liste des chats
      await tester.pump(const Duration(milliseconds: 50)); // rebuild du nom
      await tester.pump(const Duration(milliseconds: 50)); // (profil public async)

      expect(find.text('Alice Martin'), findsOneWidget,
          reason: 'nom via publicProfiles (plus users privé)');
      expect(find.text('Bonjour, je peux venir demain'), findsOneWidget);
      expect(find.text('3'), findsOneWidget, reason: 'badge non lus');
      expect(tester.takeException(), isNull);
    });

    testWidgets('état vide « Aucun message » sans connecté', (tester) async {
      await _setSmallPhone(tester);
      final fake = _FakeFirestoreService();

      await tester.pumpWidget(_wrap(const ChatListScreen(), fake, scale: 1.5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Aucun message'), findsOneWidget);
      expect(find.text('Vos conversations apparaîtront ici'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
