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
