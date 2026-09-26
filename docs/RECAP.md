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

### 1.3 Notifications push FCM — `functions/index.js`
Remplacement du squelette par **2 triggers Firestore v2** (`onDocumentCreated`) :
- `serviceRequests/{id}` onCreate → notifie le pro (`proId`) ;
- `chats/{chatId}/messages/{id}` onCreate → notifie l'autre participant.

Inclus : lecture de `users/{uid}.fcmToken` (Admin SDK), nettoyage automatique
des jetons invalides (`registration-token-not-registered`…), troncature du
corps à 120 caractères, `maxInstances: 10`. Déploiement : `firebase deploy --only functions` (**plan Blaze requis**).

### 1.4 Pagination de la recherche (20 par page)
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
`flutter analyze` + `flutter test` sur `ubuntu-latest` (Flutter 3.44.9 stable),
déclenché sur push `main`/`develop` et PR, avec annulation des runs obsolètes.

### 1.6 Vérifications locales effectuées
- `flutter analyze` → **0 problème**.
- `flutter test` → **33/33 réussis** (dont les 8 tests d'écrans critiques
  à 320 dp / ×1.5 et les 6 tests de pagination).

---

## 2. Remarques importantes

1. **`oauth_client` est encore vide** dans `android/app/google-services.json`
   (`"oauth_client": []`). Tant qu'aucune empreinte SHA-1/SHA-256 n'est
   déclarée dans la console Firebase, Google Sign-In restera inopérant
   (aucun compte proposé / `DEVELOPER_ERROR`). Voir `docs/FIREBASE_SETUP.md` §1.
2. **Canal Android `fixnow_default`** : les notifications envoyées par les
   Functions référencent ce canal, mais **aucun code côté app ne le crée**
   (pas de `flutter_local_notifications` dans le projet). Android 8+ retombera
   sur le canal de repli FCM (« Miscellaneous ») — acceptable en dev, à
   arbitrer si l'on veut un canal dédié/paramétrable.
3. **Tap sur notification** : les Functions envoient `data.type`
   (`newRequest` / `newMessage`) mais la gestion du tap (navigation vers la
   demande ou la conversation via `getInitialMessage` /
   `onMessageOpenedApp`) n'est pas visible côté app — à vérifier/implémenter.
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
- [ ] **Tests `storage.rules`** : `npm run test:rules` ne couvre que
      Firestore ; ajouter `firebase emulators:exec --only storage`.
- [ ] **CI** : vérifier le premier run GitHub Actions (Vert) après ce push ;
      décider si l'on y ajoute `npm run test:rules` (émulateurs).
- [ ] Vérifier la permission notifications **Android 13+** sur appareil réel
      (dialog `requestPermission` FCM) et le texte scale ×1.5 sur tablette.

---

## 4. Après ce push — prochaine étape suggérée

Ordre recommandé : **(1)** SHA-1/SHA-256 + nouveau `google-services.json` →
**(2)** test Google Sign-In sur appareil → **(3)** déploiement Functions +
index (plan Blaze) → **(4)** App Check debug + enforcement → **(5)** keystore
release avant toute diffusion Play Store.
