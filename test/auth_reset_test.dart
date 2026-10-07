import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:fixnow/core/services/error_mapper.dart';
import 'package:fixnow/core/theme/app_theme.dart';
import 'package:fixnow/features/auth/auth_controller.dart';
import 'package:fixnow/features/auth/forgot_password_screen.dart';
import 'package:fixnow/features/auth/register_screen.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/services/firestore_service.dart';

// ━━━ Fakes ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _FakeGoogleSignIn extends GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signIn() async => null;

  @override
  Future<GoogleSignInAccount?> signOut() async => null;
}

/// AuthService dont updatePassword() est piloté par le test (succès ou
/// échec simulé) — aucune instance Firebase réelle n'est construite.
class _FakeAuthService extends FirebaseAuthService {
  _FakeAuthService({this.failUpdate = false})
      : super(auth: MockFirebaseAuth(), google: _FakeGoogleSignIn());

  final bool failUpdate;
  String? updatedPassword;

  @override
  Future<void> updatePassword(String newPassword) async {
    if (failUpdate) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Aucune session active.',
      );
    }
    updatedPassword = newPassword;
  }
}

Widget _wrap(Widget home) {
  return ProviderScope(
    overrides: [
      firebaseAuthServiceProvider.overrideWithValue(
        FirebaseAuthService(
          auth: MockFirebaseAuth(),
          google: _FakeGoogleSignIn(),
        ),
      ),
      firestoreServiceProvider.overrideWithValue(FirestoreService()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: home,
    ),
  );
}

void main() {
  // Grande fenêtre : les formulaires sont longs (champ téléphone + bouton
  // Google sous la ligne de flottaison en 800×600).
  Future<void> tallViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('AuthController.updatePassword (reset par SMS)', () {
    test('succès : le nouveau mot de passe est transmis au service', () async {
      final service = _FakeAuthService();
      final controller = AuthController(service, FirestoreService());

      final ok = await controller.updatePassword('NouveauMdp123!');

      expect(ok, isTrue);
      expect(service.updatedPassword, 'NouveauMdp123!');
      expect(controller.state.error, isNull);
      expect(controller.state.isLoading, isFalse);
    });

    test('échec : message FR mappé dans AuthState.error', () async {
      final service = _FakeAuthService(failUpdate: true);
      final controller = AuthController(service, FirestoreService());

      final ok = await controller.updatePassword('x');

      expect(ok, isFalse);
      expect(service.updatedPassword, isNull);
      expect(controller.state.error, contains('Session expirée'));
      expect(controller.state.isLoading, isFalse);
    });
  });

  group('ErrorMapper — liaisons et fournisseurs', () {
    test('erreurs de liaison du numéro → français', () {
      expect(
        ErrorMapper.message(
          FirebaseAuthException(code: 'phone-number-already-in-use'),
        ),
        contains('déjà associé'),
      );
      expect(
        ErrorMapper.message(
          FirebaseAuthException(code: 'credential-already-in-use'),
        ),
        contains('déjà associé'),
      );
      expect(
        ErrorMapper.message(FirebaseAuthException(code: 'provider-already-linked')),
        contains('déjà lié'),
      );
      expect(
        ErrorMapper.message(FirebaseAuthException(code: 'no-current-user')),
        contains('Session expirée'),
      );
    });

    test('fournisseur non activé → renvoi vers la console Firebase', () {
      expect(
        ErrorMapper.message(FirebaseAuthException(code: 'operation-not-allowed')),
        contains('console Firebase'),
      );
    });
  });

  group('Écran « Mot de passe oublié »', () {
    testWidgets(
        'bascule Email / Téléphone : formulaire SMS + validation du numéro',
        (tester) async {
      await tester.pumpWidget(_wrap(const ForgotPasswordScreen()));
      await tester.pump();

      // Parcours email par défaut.
      expect(find.text('Adresse email'), findsOneWidget);
      expect(find.text('Envoyer le lien'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Téléphone'), findsOneWidget);

      // Passage en mode téléphone.
      await tester.tap(find.text('Téléphone'));
      await tester.pumpAndSettle();

      expect(find.text('Recevoir le code SMS'), findsOneWidget);
      expect(find.textContaining('lié à votre compte'), findsOneWidget);

      // Numéro vide → message de validation, aucun appel réseau.
      await tester.tap(find.text('Recevoir le code SMS'));
      await tester.pump();
      expect(
        find.text('Numéro invalide (ex. +33 6 12 34 56 78)'),
        findsOneWidget,
      );

      // Retour à l'onglet email.
      await tester.tap(find.text('Email'));
      await tester.pumpAndSettle();
      expect(find.text('Adresse email'), findsOneWidget);
      expect(find.text('Envoyer le lien'), findsOneWidget);
    });
  });

  group('Écran d\'inscription', () {
    testWidgets('champ téléphone optionnel + bouton Google présents',
        (tester) async {
      await tallViewport(tester);
      await tester.pumpWidget(_wrap(const RegisterScreen()));
      await tester.pump();

      expect(find.text("S'inscrire"), findsOneWidget);
      expect(find.text('Continuer avec Google'), findsOneWidget);
      expect(find.textContaining('Téléphone (optionnel)'), findsOneWidget);
      expect(find.textContaining('réinitialiser votre mot de passe'), findsOneWidget);
    });

    testWidgets('saisie invalide dans le champ téléphone → refus',
        (tester) async {
      await tallViewport(tester);
      await tester.pumpWidget(_wrap(const RegisterScreen()));
      await tester.pump();

      // Remplir un numéro invalide puis valider le formulaire : le champ
      // téléphone est le dernier des 5 champs de saisie.
      final fields =
          tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
      expect(fields.length, greaterThanOrEqualTo(5),
          reason: 'nom, email, mdp, confirmation, téléphone');
      await tester.enterText(
        find.byType(TextFormField).at(fields.length - 1),
        '12',
      );
      await tester.tap(find.text("S'inscrire"));
      await tester.pump();

      expect(find.text('Numéro invalide (ex. +33 6 12 34 56 78)'),
          findsOneWidget);
    });
  });
}
