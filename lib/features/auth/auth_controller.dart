import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/services/firestore_service.dart';
import 'package:fixnow/models/user_model.dart';
import 'package:fixnow/models/professional_model.dart';

/// State class for AuthController.
class AuthState {
  final bool isLoading;
  final String? error;

  const AuthState({this.isLoading = false, this.error});

  AuthState copyWith({bool? isLoading, String? error}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Controller for Auth screens logic.
class AuthController extends StateNotifier<AuthState> {
  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService;

  AuthController(this._authService, this._firestoreService) : super(const AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signInWithEmail(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    bool asPro = false,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final credential = await _authService.signUpWithEmail(email: email, password: password);
      
      if (credential.user != null) {
        // Everyone is a client; the pro flag adds professional capabilities.
        final newUser = AppUser(
          uid: credential.user!.uid,
          role: UserRole.client,
          isPro: asPro,
          name: name,
          email: email,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUser(newUser);

        // Pros get a (pending) professional profile.
        if (asPro) {
          await _firestoreService.createProfessional(
            Professional(
              uid: credential.user!.uid,
              name: name,
              categories: const [],
              bio: '',
              hourlyRate: 0,
              status: ProStatus.pending,
              createdAt: DateTime.now(),
            ),
          );
        }
        
        // Update Firebase display name
        await _authService.updateDisplayName(name);
      }
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Upgrades the current client account with professional capabilities.
  /// Creates the pending professional profile if needed.
  Future<bool> becomePro() async {
    final user = _authService.currentUser;
    if (user == null) {
      state = state.copyWith(error: 'Vous devez être connecté');
      return false;
    }

    state = state.copyWith(isLoading: true);
    try {
      final profile = await _firestoreService.getUser(user.uid);
      if (profile == null) {
        state = state.copyWith(isLoading: false, error: 'Profil introuvable');
        return false;
      }
      if (!profile.isPro) {
        await _firestoreService.updateUser(user.uid, {
          'isPro': true,
          'role': UserRole.pro.name,
        });
      }

      // Create the pending professional profile if it doesn't exist yet.
      final existingPro = await _firestoreService.getProfessional(user.uid);
      if (existingPro == null) {
        await _firestoreService.createProfessional(
          Professional(
            uid: user.uid,
            name: profile.name,
            categories: const [],
            bio: '',
            hourlyRate: 0,
            status: ProStatus.pending,
            createdAt: DateTime.now(),
          ),
        );
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    try {
      final credential = await _authService.signInWithGoogle();
      
      if (credential.user != null) {
        // Check if user already exists in Firestore
        final existingUser = await _firestoreService.getUser(credential.user!.uid);
        if (existingUser == null) {
          // Create new user profile
          final newUser = AppUser(
            uid: credential.user!.uid,
            role: UserRole.client,
            name: credential.user!.displayName ?? 'User',
            email: credential.user!.email ?? '',
            avatarUrl: credential.user!.photoURL,
            createdAt: DateTime.now(),
          );
          await _firestoreService.createUser(newUser);
        }
      }
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Sends a password reset email. Returns true on success.
  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}

/// Provider for AuthController.
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return AuthController(authService, firestoreService);
});
