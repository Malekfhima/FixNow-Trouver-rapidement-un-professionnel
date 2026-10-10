import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thrown when the user closes the Google account sheet without choosing
/// an account — not an error worth showing as a failure.
class GoogleSignInAbortedException implements Exception {
  const GoogleSignInAbortedException();

  @override
  String toString() => 'google sign-in aborted';
}

/// Provides the current auth state stream.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provides the current Firebase User (or null).
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Service that wraps Firebase Authentication methods.
///
/// [auth] and [google] are injectable for tests (mocks); they default to
/// the real Firebase/Google instances.
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth, GoogleSignIn? google})
      : _auth = auth ?? FirebaseAuth.instance,
        _google = google ?? (kIsWeb ? null : GoogleSignIn());

  final FirebaseAuth _auth;
  final GoogleSignIn? _google;

  /// Current signed-in user.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Email / Password ─────────────────────────────────────────────

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ── Google Sign-In ───────────────────────────────────────────────

  /// Sign-in via Google.
  ///
  /// Throws [GoogleSignInAbortedException] when the user closes the Google
  /// sheet. Any other failure (misconfiguration, missing SHA-1, missing
  /// `oauth_client` in google-services.json) surfaces as a
  /// [FirebaseAuthException] / [PlatformException] the caller can report.
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      try {
        return await _auth.signInWithPopup(GoogleAuthProvider());
      } on FirebaseAuthException catch (error) {
        if (error.code == 'popup-closed-by-user' ||
            error.code == 'cancelled-popup-request') {
          throw const GoogleSignInAbortedException();
        }
        rethrow;
      }
    }

    final google = _google;
    if (google == null) {
      throw StateError('Google Sign-In is unavailable on this platform.');
    }
    final GoogleSignInAccount? googleUser = await google.signIn();
    if (googleUser == null) {
      throw const GoogleSignInAbortedException();
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;
    if (idToken == null && accessToken == null) {
      throw FirebaseAuthException(
        code: 'google-missing-token',
        message:
            'Google n\'a renvoy\u00e9 aucun jeton. V\u00e9rifiez le SHA-1/SHA-256 de '
            'l\'application dans la console Firebase (oauth_client).',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  // ── Phone / OTP ──────────────────────────────────────────────────

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential credential) onCompleted,
    required void Function(FirebaseAuthException error) onFailed,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String verificationId) onAutoRetrieval,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onCompleted,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onAutoRetrieval,
      forceResendingToken: resendToken,
    );
  }

  /// Signs in with an ALREADY-BUILT phone credential (auto-retrieval
  /// path of `verifyPhoneNumber`, where Firebase hands over a credential
  /// instead of a verificationId).
  Future<UserCredential> signInWithPhone(PhoneAuthCredential credential) {
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  // ── General ──────────────────────────────────────────────────────

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  Future<void> updatePhotoURL(String url) async {
    await _auth.currentUser?.updatePhotoURL(url);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Un compte créé via Google n'a pas de mot de passe : Firebase
      // répond invalid-credential — on give un message explicite.
      if (e.code == 'invalid-credential' || e.code == 'missing-password') {
        throw FirebaseAuthException(
          code: 'google-account',
          message: 'Ce compte utilise la connexion Google.',
        );
      }
      rethrow;
    }
  }

  // ── Liaison du numéro de téléphone (reset par SMS) ─────────────

  /// Builds a phone credential WITHOUT signing in — used to LINK the
  /// number to the account that is already signed in (inscription ou
  /// profil), là où [signInWithPhoneCredential] créerait/connecterait à
  /// un autre compte.
  PhoneAuthCredential phoneCredential({
    required String verificationId,
    required String smsCode,
  }) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  /// Links (or replaces) the phone number of the CURRENT user — requires a
  /// fresh session (right after signup or OTP verification).
  ///
  /// C'est cette liaison qui rend possible le « mot de passe oublié par
  /// SMS » : le numéro doit appartenir au compte pour que le code SMS
  /// retrouve le bon compte au lieu d'en créer un nouveau.
  Future<void> linkPhoneNumber(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Aucune session active.',
      );
    }
    await user.updatePhoneNumber(credential);
  }

  /// Changes the password of the currently signed-in user.
  ///
  /// Used by the "mot de passe oublié par téléphone" flow : the user has
  /// just proved ownership of the phone number with an OTP (fresh session,
  /// so Firebase accepts the update). Throws [FirebaseAuthException]
  /// (`no-current-user`) when nobody is signed in — mapped to French by
  /// `ErrorMapper`.
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Aucune session active.',
      );
    }
    await user.updatePassword(newPassword);
  }

  /// Signs the user out. Firebase Auth first (the part that really
  /// matters), then Google Sign-In best-effort: the Google plugin can
  /// fail on some platforms or with an already-expired session, and that
  /// must never block the actual sign-out.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } finally {
      try {
        await _google?.signOut();
      } catch (_) {
        // Google session cleanup is best-effort.
      }
    }
  }
}

/// Riverpod provider for FirebaseAuthService.
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});
