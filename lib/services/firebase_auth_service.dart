import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the current auth state stream.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provides the current Firebase User (or null).
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Service that wraps Firebase Authentication methods.
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _google = GoogleSignIn();

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

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) throw Exception('Google sign-in aborted');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
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
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }
}

/// Riverpod provider for FirebaseAuthService.
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});
