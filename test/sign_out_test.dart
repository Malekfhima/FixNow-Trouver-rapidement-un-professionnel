import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fixnow/services/firebase_auth_service.dart';

/// Fake Google Sign-In that behaves like a healthy plugin session.
class _FakeGoogleSignIn extends GoogleSignIn {
  bool signedOut = false;

  @override
  Future<GoogleSignInAccount?> signIn() async => null;

  @override
  Future<GoogleSignInAccount?> signOut() async {
    signedOut = true;
    return null;
  }

  @override
  Future<GoogleSignInAccount?> disconnect() async {
    signedOut = true;
    return null;
  }
}

/// Fake Google Sign-In whose signOut() always throws (expired session,
/// unsupported platform...) — reproduces the original bug.
class _FailingGoogleSignIn extends GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signIn() async => null;

  @override
  Future<GoogleSignInAccount?> signOut() async {
    throw Exception('platform_sign_out_failed');
  }
}

/// Firebase Auth whose signOut() always throws (network/server failure).
class _FailingFirebaseAuth extends MockFirebaseAuth {
  @override
  Future<void> signOut() async {
    throw Exception('firebase_sign_out_failed');
  }
}

void main() {
  group('FirebaseAuthService.signOut — les 3 modes de connexion', () {
    test('déconnexion email/mot de passe : session Firebase terminée',
        () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u-email', email: 'test@fixnow.fr'),
        signedIn: true,
      );
      final service = FirebaseAuthService(auth: auth);

      expect(auth.currentUser, isNotNull);

      await service.signOut();

      expect(auth.currentUser, isNull);
    });

    test('déconnexion Google : session Firebase ET Google terminées',
        () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u-google'),
        signedIn: true,
      );
      final google = _FakeGoogleSignIn();

      final service = FirebaseAuthService(auth: auth, google: google);
      await service.signOut();

      expect(auth.currentUser, isNull);
      expect(google.signedOut, isTrue,
          reason: 'la session Google doit aussi être fermée');
    });

    test('déconnexion téléphone (SMS) : session Firebase terminée', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u-sms', phoneNumber: '+33612345678'),
        signedIn: true,
      );
      final service = FirebaseAuthService(auth: auth);

      await service.signOut();

      expect(auth.currentUser, isNull);
    });

    test(
        'échec du plugin Google NE bloque PLUS la déconnexion Firebase (le bug corrigé)',
        () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u-x'),
        signedIn: true,
      );
      final google = _FailingGoogleSignIn();

      final service = FirebaseAuthService(auth: auth, google: google);

      // Ne doit PAS lever : Firebase doit être déconnecté quand même.
      await expectLater(service.signOut(), completes);

      expect(auth.currentUser, isNull,
          reason: 'Firebase doit être déconnecté même si Google échoue');
    });

    test(
        'échec de Firebase : l\'erreur est propagée (le contrôleur la capture)',
        () async {
      final service = FirebaseAuthService(auth: _FailingFirebaseAuth());

      await expectLater(service.signOut(), throwsA(isA<Exception>()));
    });
  });
}
