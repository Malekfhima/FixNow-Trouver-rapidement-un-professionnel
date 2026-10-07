/// Runtime flags set at app startup.
///
/// Kept out of `main.dart` to avoid circular imports (the router needs to
/// know whether Firebase is available to enable auth redirects).
library;

/// True when `Firebase.initializeApp` succeeded in `main()`.
///
/// When false (Firebase not configured), auth redirects are disabled so the
/// UI remains explorable without a backend.
bool firebaseInitialized = false;

/// Connexion par téléphone (SMS OTP) activée ou non.
///
/// Le quota SMS gratuit de Firebase Auth est très limité : la connexion
/// téléphone est désactivable sans recompiler de logique métier :
///   `flutter run --dart-define=ENABLE_PHONE_AUTH=false`
///
/// Par défaut : ACTIVÉE (le bouton reste visible). Email + Google restent
/// le parcours principal.
const bool phoneAuthEnabled =
    bool.fromEnvironment('ENABLE_PHONE_AUTH', defaultValue: true);
