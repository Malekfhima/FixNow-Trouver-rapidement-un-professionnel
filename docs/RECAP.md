# Récapitulatif — remarques & informations manquantes

> État au **26/09/2026** — branche `main`, projet Firebase `fixnow-dd022`.
> Ce document résume les derniers changements en attente de commit, les
> remarques d'attention et **tout ce qui manque** avant une mise en
> production sereine. Il complète `CHANGELOG.md` (parties 1-4) et
> `docs/FIREBASE_SETUP.md`.

---

## 1. Modifications en attente de commit

### 1.1 Rebranding `com.example.fixnow` → `com.fixnow.app`
Identifiant application harmonisé sur **toutes les plateformes** :

| Plateforme | Fichier | Champ |
|---|---|---|
| Android | `android/app/build.gradle.kts` | `namespace` + `applicationId` |
| Android | `android/app/google-services.json` | `package_name` |
| iOS | `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` (+ `.RunnerTests`) |
| macOS | `macos/Runner.xcodeproj/project.pbxproj`, `Runner/Configs/AppInfo.xcconfig` | idem |
| Linux | `linux/CMakeLists.txt` | `APPLICATION_ID` |
| Dart | `lib/firebase_options.dart` | `iosBundleId` |
| Kotlin | `MainActivity.kt` déplacé vers `com/fixnow/app/` | package |

### 1.2 Google Sign-In (Android) — erreurs explicites
- `lib/services/firebase_auth_service.dart` : nouvelle exception
  `GoogleSignInAbortedException` (annulation utilisateur ≠ échec) et jeton
  manquant converti en `FirebaseAuthException(code: 'google-missing-token')`.
- `lib/core/services/error_mapper.dart` : message FR pour l'annulation et pour
  `google-missing-token` (SHA-1/SHA-256 manquant dans la console Firebase).

### 1.3 Notifications — SANS Cloud Functions (plan Spark)
> **Fait (partie 7+8).** Les notifications push FCM via Cloud Functions ne
> sont **pas déployées** : le plan gratuit Spark ne les autorise pas.
> Équivalent en place :
> - notifications **in-app** écrites côté client dans Firestore
>   (`notification_helpers.dart`, conformes aux règles — liste blanche de
>   types + lien réel actor↔destinataire) ;
> - notification **locale** (canal `fixnow_default`, flutter_local_notifications)
>   quand l'app est ouverte et qu'une notif non lue arrive ; payload JSON +
>   table de routage par type (message → chat, demande → détail ou
>   écran pro, avis → Mes avis) ;
> - le dossier `functions/` reste en **option documentée** pour une migration
>   future vers Blaze (voir `functions/README.md`).

### 1.4 Pagination de la recherche (50 par page)
- `lib/services/firestore_service.dart` : `searchProfessionalsPage()` —
  `orderBy(FieldPath.documentId)` (index simple toujours présent, pas
  d'index composite à déployer), `limit + 1` pour détecter `hasMore`,
  curseur `startAfterDocument`.
- `lib/features/search/search_controller.dart` : `loadMore()` idempotent
  (pas de double requête concurrente, no-op en fin de liste), re-tri global
  des résultats cumulés.
- `lib/features/search/search_screen.dart` : scroll infini (~300 px avant la
  fin) + spinner de pied de liste.
- `test/search_pagination_test.dart` : **6 tests** (première page, curseur,
  fin de liste, concurrence, tri fusionné, erreur de page).

### 1.5 CI GitHub Actions (`.github/workflows/ci.yml`)
- job `flutter` : `flutter analyze` + `flutter test` sur `ubuntu-latest`
  (Flutter 3.44.9 stable) ;
- job `firestore-rules` : Node 20 + Java 17 + `npm ci` + `npm run test:rules`
  sur l'émulateur Firestore (tests des règles, dont les champs d'acompte) —
  Java n'étant pas disponible en local, ce job est le seul endroit où ces
  tests s'exécutent ;
- déclenché sur push `main`/`develop` et PR, annulation des runs obsolètes.

### 1.6 Vérifications locales effectuées
- `flutter analyze` → **0 problème**.
- `flutter test` → **77/77 réussis** (dont les 9 tests d'écrans à 320 dp /
  ×1.5 de `quality_screens_test.dart`, les 8 tests de routage de
  notification, les 5 aller-retours de payload JSON et les 8 tests Storage).

---

## 2. Remarques importantes

1. **`oauth_client` est encore vide** dans `android/app/google-services.json`
   (`"oauth_client": []`). Tant qu'aucune empreinte SHA-1/SHA-256 n'est
   déclarée dans la console Firebase, Google Sign-In restera inopérant
   (aucun compte proposé / `DEVELOPER_ERROR`). Voir `docs/FIREBASE_SETUP.md` §1.
2. **Canal Android `fixnow_default`** : **créé au démarrage de l'app**
   (`lib/services/local_notification_service.dart`). Les notifs locales
   (app ouverte) l'utilisent ; il servira aussi aux Functions si la
   migration Blaze est un jour décidée.
3. **Tap sur notification** : table de routage partagée
   (`lib/services/notification_routing.dart`) — `newMessage` →
   `/chat/<id>` ; types de demande → `/orders/<id>` (client) ou
   `/pro-dashboard` (pro) ; `reviewReceived` → `/pro-reviews` ;
   `proApproved/proRejected` → `/pro-profile-edit` ou `/pro-dashboard` ;
   type inconnu ignoré. Testée dans `test/notification_routing_test.dart`.
4. **Historique git** : le dernier commit local s'intitule `aa` (non
   descriptif) ; la branche est en avance de 5 commits sur `origin/main` —
   ce push publie l'ensemble.
5. **Fichiers de config Firebase commités** (`google-services.json`,
   `.firebaserc`) : c'est voulu — les identifiants *client* ne sont pas des
   secrets ; la sécurité repose sur les règles Firestore/Storage + App Check
   (voir `docs/FIREBASE_SETUP.md`). Ne jamais commiter en revanche un
   keystore release ou une clé de service Admin.

---

## 3. Informations manquantes / à compléter

### Console Firebase (bloquants fonctionnels)
- [ ] **Fournisseurs d'authentification** : activer **Email/Password**,
      **Google** et **Phone** (Authentication → Sign-in method) — sinon
      `operation-not-allowed` à la connexion/inscription. Google exige en
      outre les empreintes SHA (ci-dessous). Procédure : `docs/FIREBASE_SETUP.md` §3.
- [ ] **Empreintes SHA-1 + SHA-256 debug et release** à déclarer
      (Paramètres du projet → app Android `com.fixnow.app`), puis
      **re-télécharger `google-services.json`** — prérequis absolu pour
      Google Sign-In.
- [ ] **Keystore release** inexistant : le build release utilise encore
      `signingConfigs.getByName("debug")` (placeholder). Générer
      `fixnow-release.jks`, le sortir du dépôt, brancher `key.properties`,
      et déclarer son empreinte dans Firebase.
- [ ] **iOS** : `ios/Runner/GoogleService-Info.plist` absent ; créer l'app
      iOS (bundle `com.fixnow.app`) dans la console, ajouter l'URL scheme
      `REVERSED_CLIENT_ID` dans `Info.plist`, activer les capacités
      **Push Notifications** + **Background Modes → Remote notifications**.
      ⇒ le plus simple : relancer `flutterfire configure --project=fixnow-dd022`.

### Déploiements backend (non prouvés dans le dépôt)
- [ ] **Cloud Functions** : `firebase deploy --only functions`
      (nécessite le **plan Blaze** — décision budget à confirmer).
- [ ] **Index Firestore** : `firebase deploy --only firestore:indexes`
      puis vérifier l'absence d'index manquants dans la console.
- [ ] **App Check** : enregistrer le jeton debug
      (`--dart-define=APP_CHECK_DEBUG_TOKEN`) dans Console → App Check →
      débogueurs, puis activer l'enforcement **Play Integrity**.

### Actions sur les données existantes (outils fournis)
- [ ] **Backfill `publicProfiles`** pour les comptes créés avant la faille 7 :
      `npm run tool:public-profiles` (Admin SDK, idempotent).
- [ ] **Migration des admins vers les custom claims** :
      `npm run tool:claims`, puis basculer `isAdmin()` en 100 %
      `request.auth.token.admin` (le fallback legacy est encore actif).

### Suivi qualité
- [ ] **Tests règles** : `npm run test:rules` (Firestore) est câblé dans le
      **job CI optionnel** (Node 20 + Java 17 + émulateur) — vérifier le
      premier run vert ; Firebase Storage ayant été retiré, plus aucun test
      `storage.rules` à maintenir.
- [ ] **Images** : pas de Firebase Storage (plan Blaze requis) — tout passe
      par **Cloudinary** (unsigned). Configurer le preset : formats images,
      5 Mo max, dossier `fixnow` (voir README §Images).
- [ ] Vérifier la permission notifications **Android 13+** sur appareil réel
      (dialog `requestPermission` FCM) et le texte scale ×1.5 sur tablette.

---

## 4. Après ce push — prochaine étape suggérée

Ordre recommandé : **(1)** SHA-1/SHA-256 + nouveau `google-services.json` →
**(2)** test Google Sign-In sur appareil → **(3)** déploiement Functions +
index (plan Blaze) → **(4)** App Check debug + enforcement → **(5)** keystore
release avant toute diffusion Play Store.
