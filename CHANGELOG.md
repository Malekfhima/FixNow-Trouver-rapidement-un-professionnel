# CHANGELOG — FixNow

Format : **Faille / bug** → **Cause** → **Correctif** → **Test associé**.
Chaque ligne renvoie au fichier modifié.

---

## PARTIE 1 — Backend : `firestore.rules`

| # | Faille / bug | Cause | Correctif | Test (`firestore.rules.test.js`) |
|---|---|---|---|---|
| 1 | Un pro pouvait **s'auto-approuver** à la création de son profil (`status: 'approved'`) et créer un profil avec des notes inventées | `create` n'exigeait que `isOwner && isPro` | `create` exige `status == 'pending'`, `ratingAvg == 0`, `ratingCount == 0`, `lastRatingReviewId == ''` (les démos `demo-*` de l'admin restent possibles) — `firestore.rules` (match `professionals`) | `faille 1 : …` (2 tests refusés + 1 accepté) |
| 2 | Création de demande **libre** : statut libre, auto-cible, devis/prix pré-remplis, cible non approuvée | `create` ne vérifiait que `clientId == appelant` | `status == 'pending'`, `proId != appelant`, absence de `quotePrice`/`quoteNote`/`price`, `get(professionals/{proId}).status == 'approved'` | `faille 2 : serviceRequests création verrouillée` (5 refusés + 1 accepté) |
| 3 | **Clés immuables modifiables** (`clientId`, `proId`, `categoryId`, `createdAt`) et empiètement des champs entre acteurs (client → devis, pro → description) | Une édition « sans changement de statut » passait tant que l'acteur était participant | `diff().affectedKeys()` : `hasAny([...immuables])` interdit + `hasOnly([...])` par acteur (client : status/description/photos/address/scheduledDate ; pro : status/quotePrice/quoteNote/price), `updatedAt` technique accepté | `faille 3 : les clés … sont immuables` + `FAILLE (faille 3) : chaque acteur ne modifie QUE ses propres champs` |
| 4 | **« Mes demandes » ne pouvait pas envoyer de devis** : la transition `pending -> quoted` n'existait nulle part, alors que l'app l'écrivait déjà | Machine à états incomplète côté règles ET côté Dart | Ajout `pending -> quoted (pro)` dans `firestore.rules` **et** `lib/models/service_request_state_machine.dart` ; `sendQuote` du contrôleur conditionné sur cette transition | Matrice exhaustive (ajout `pending>quoted`) + `faille 4 : machine à états pending -> quoted (pro)` + `test/service_request_state_machine_test.dart` |
| 5 | Avis **sans validation** : rating 0/6/décimal, commentaire illimité, `proId` falsifiable (viser un autre pro que celui de la demande) | Seuls `clientId`, statut `completed` et l'unicité étaient vérifiés | `rating is int && 1..5`, `comment is string && <= 1000`, `review.proId == serviceRequests/{id}.proId` | `faille 5 : reviews — rating, commentaire et pro assigné` |
| 6 | **N'importe quel utilisateur pouvait écrire `ratingAvg`/`ratingCount`** de n'importe quel pro (auto-évaluation, fraude) | Règle « n'importe quel authentifié hors propriétaire peut écrire les 2 champs » | Supprimée. Remplacée par : mise à jour autorisée **seulement** dans le même batch que la création de l'avis prouvée par `getAfter()` + `lastRatingReviewId`, `ratingCount + 1` exact, `ratingAvg` = moyenne induite par la note (donc bornée 1..5), avis inexistant avant le batch. `FirestoreService.createReview` écrit désormais **un batch** avis+compteurs ; `recomputeProRating` (écriture nue) supprimé | `professionals : agrégation des notes (batch avis + compteurs)` — test « faille 6 » refusé avant/passé après, + tests de cohérence (`+2`, moyenne incohérente, hors bornes) |
| 7 | **`users/{uid}` lisible par tout connecté** : email, téléphone, fcmToken exposés (chat, avis, annuaires) | `allow read: if isAuth()` | Lecture restreinte au propriétaire + admin. Nouvelle collection **`publicProfiles/{uid}`** (`name`, `avatarUrl`, `role`) lisible par les connectés ; écriture par le propriétaire (création/miroir séquentiel dans `createUser`/`updateUser`) ; `AppUser.fromPublicProfile` + `getPublicProfile` ; `userByIdProvider` (chat) migré | `faille 7 : users privé + publicProfiles` (lecture tiers refusée, écriture tiers refusée, admin OK) |
| 8 | Conversation **réassignable** (`clientId`/`proId` modifiables), **texte de message modifiable** après coup, messages > 2000 signés par autrui | Règles `update` trop larges sur `chats` et `messages` | `chats` : `hasAny(['clientId','proId'])` interdit. `messages` : `create` exige `senderId == appelant`, `text` string ≤ 2000 ; `update` limité à `hasOnly(['read'])` | `faille 8 : chats immuables + messages verrouillés` |
| 9 | **Notifications spoofables** : type arbitraire, textes illimités, aucun lien réel actor↔destinataire | `create` ne vérifiait que `actorId == appelant` | Liste blanche des types (9), `title ≤ 200`, `body ≤ 2000`, et lien réel prouvé par `get()/exists()` : **chat** partagé, **serviceRequest** partagée, ou validation d'un pro (`proApproved`/`proRejected` avec `relatedId == uid` et appelant admin). `update` limité à `read`. `AdminController._notifyPro` envoie désormais `relatedId: pro.uid` | `faille 9 : notifications — type, taille et lien réel` (6 tests) |
| 10 | `isAdmin()` relisait `users/{uid}` à **chaque évaluation** de règle | Rôle stocké uniquement en base | `isAdmin()` priorise le **custom claim** `request.auth.token.admin` (sans `get()`), le rôle legacy reste accepté pour ne casser aucun compte. Procédure complète + script Admin SDK : **`tool/set_custom_claims.js`** (`npm run tool:claims`) | `faille 10 : rôles — migration vers les custom claims` |

**Application adaptée (Partie 1) :**
`lib/services/firestore_service.dart` (batch avis, publicProfiles, suppression de `recomputeProRating`),
`lib/models/service_request_state_machine.dart`, `lib/models/service_request_model.dart`
(nouveau champ `budget` côté client — `price` reste réservé au pro),
`lib/models/user_model.dart` (`AppUser.fromPublicProfile`),
`lib/features/pro_dashboard/pro_requests_controller.dart` (`sendQuote` via `pending -> quoted`),
`lib/features/booking/*` (budget envoyé, plus aucun `price` à la création ni à l'acceptation du devis),
`lib/features/client_dashboard/orders_screen.dart` (affichage prix convenu / budget),
`lib/features/chat/chat_controller.dart` (profils publics),
`lib/features/admin/admin_controller.dart` (notification liée),
`test/service_request_state_machine_test.dart`.

**Reste à faire / décision attendue (Partie 1) :**
- Migration **Cloud Functions** (plan Blaze) pour : agrégation des notes, notifications,
  et suppression des `get()` de vérification de lien — documenté dans `firestore.rules`.
- Backfill des comptes existants : `npm run tool:public-profiles`
  (`tool/backfill_public_profiles.js`, Admin SDK, idempotent).
- Basculer `isAdmin()` en 100 % custom claims après migration des admins
  (`npm run tool:claims`, puis échange de `isAdmin()` — voir commentaire dans les règles).

---

## PARTIE 2 — Backend : `storage.rules`

| # | Faille / bug | Cause | Correctif | Test |
|---|---|---|---|---|
| 1 | Les règles utilisaient `request.resource` (null en lecture/suppression) et mélangeaient `allow read, write` | Bloc unique `allow read, write` avec validations d'écriture | Séparation stricte **`allow read` / `allow create, update` / `allow delete`** ; `request.resource` (contentType, size) **uniquement** en `create/update` | Vérification manuelle (le socle `npm run test:rules` ne pilote que l'émulateur Firestore — voir « reste à faire ») |
| 2 | `requests/{id}` et `chats/{id}` ouverts à **tout authentifié** (lecture ET écriture) | Aucun contrôle d'appartenance | Lecture/écriture/suppression réservées au client+pro de la `serviceRequests/{requestId}` et aux participants du `chats/{chatId}`, via **`firestore.get(/databases/(default)/documents/…)`** | idem |
| 3 | `delete` des avatars/galerie non corrigé (règle `write` unique, `request.resource` potentiellement null) | Mélange read/write | `delete` = **propriétaire uniquement**, sans `request.resource` ; `create/update` conservent `image/*` et `< 5 Mo` | idem |

**Reste à faire / décision attendue (Partie 2) :**
- Ajouter `storage.rules` à la suite automatisée : `firebase emulators:exec --only storage`
  avec des tests dédiés (`@firebase/rules-unit-testing` ne couvre pas Storage dans la version utilisée).

---

## PARTIE 3 — Application Flutter (backend côté client)

| # | Bug / risque | Cause | Correctif | Fichier |
|---|---|---|---|---|
| 1 | L'app pouvait écrire des champs refusés par les nouvelles règles (création avec `price`, acceptation de devis écrivant `price`, recompute de notes hors batch) | Le client suivait l'ancien contrat des règles | `FirestoreService` conforme : batch avis+compteurs, `budget` séparé de `price`, `acceptQuote` n'écrit plus que `status`, miroir `publicProfiles` séquentiel | `lib/services/firestore_service.dart`, `lib/features/booking/*`, `lib/models/service_request_model.dart` |
| 2 | Erreurs `FirebaseException` parfois brutes (`e.toString()`), codes Storage non mappés | `ErrorMapper` incomplet + 3 écrans contournant le mapper | Messages FR pour `permission-denied`, `unavailable`, `image-too-large`, `unauthorized`, `quota-exceeded` ; les 3 écrans passent par `ErrorMapper` (aucun écran blanc, aucune exception non gérée) | `lib/core/services/error_mapper.dart`, `lib/features/review/review_screen.dart`, `lib/features/professional_profile/pro_profile_controller.dart`, `lib/features/pro_dashboard/pro_profile_edit_screen.dart` |
| 3 | App Check **déclaré mais jamais activé** (le package était dans pubspec sans code) | Activation absente | Activation dans `main()` : **Play Integrity + DeviceCheck en release**, **provider debug en dev**, jeton lisible via `--dart-define=APP_CHECK_DEBUG_TOKEN=…`, `try/catch` pour ne jamais bloquer le démarrage. Aucun secret commité (`.gitignore` : `tool/serviceAccount*.json`, `.env*`) | `lib/main.dart`, `.gitignore` |
| 4 | La recherche par catégorie pouvait échouer (index composite manquant) — et les requêtes pros doivent toutes filtrer `status == 'approved'` sous peine d'être refusées par les règles | Index composites incomplets | `searchProfessionals` filtre bien `where('status','==','approved')` (+ `arrayContains`) vérifié ; index composite `professionals (status ASC, categories ARRAY_CONTAINS)` ajouté | `firestore.indexes.json`, `lib/services/firestore_service.dart` |
| 5 | Upload > 5 Mo refusé par les règles Storage avec un message obscur | Pas de garde côté client | Contrainte 5 Mo miroir + message français avant l'upload | `lib/services/storage_service.dart` |

**Reste à faire / décision attendue (Partie 3) :**
- **Enregistrer le jeton App Check debug** dans la Console Firebase (App Check → débogueurs)
  après le premier lancement en dev ; activer App Check en console pour le Play Integrity.
- Compétition : si la console App Check est activée en mode « enforcement », tester les
  anciens appareils (DeviceCheck/Play Integrity échec rare).

---

## PARTIE 4 — Design / UI (Material 3)

| # | Bug / problème | Cause | Correctif | Fichier(s) |
|---|---|---|---|---|
| 1 | Couleurs et tailles **codées en dur** dans les écrans (pas de source unique) | Styles locaux `Color(0x…)` / `EdgeInsets` magic numbers dispersés | Un seul `ColorScheme` Material 3 (`useMaterial3`), typographie via `AppTextStyles`, espacements/rayons via `AppSpacing`/`AppRadius` ; écrans migrés | `lib/core/theme/app_theme.dart`, `lib/features/home/home_screen.dart`, `lib/features/search/search_screen.dart`, `lib/features/chat/chat_list_screen.dart`, `lib/features/client_dashboard/orders_screen.dart`, `lib/features/pro_dashboard/pro_requests_screen.dart`, `lib/core/widgets/pro_card.dart` |
| 2 | **Contraste insuffisant (WCAG AA)** en clair et en sombre : bannières « Hors ligne » et toasts illisibles sur `inverseSurface` | `SemanticColors` identique clair/sombre ; bannière texte blanc sur fond clair | Palette `success/warning/accent` recalibrée AA (clair : vert 0xFF15803D, ambre 0xFFB45309, orange 0xFFC2410C) ; bannières/toasts : **palette opposée selon `brightness`**, texte choisi selon la luminance | `lib/core/theme/app_theme.dart`, `lib/core/widgets/app_alerts.dart` |
| 3 | Écrans à données Firestore **sans état vide ni erreur** (page blanche ou silencieuse) | Seul le loading existait (parfois aussi absent) | `EmptyState` (illustration + message + action) et `ErrorState` (message FR + bouton **Réessayer**) déployés : accueil, recherche, commandes, demandes pro, notifications, chat, profil pro. Skeletons corrigés (plus de overflow) | `lib/core/widgets/app_alerts.dart` (`EmptyState`/`ErrorState` + `_centeredScrollable`), `lib/core/widgets/skeleton.dart`, `lib/features/home/home_screen.dart`, `lib/features/search/search_screen.dart`, `lib/features/client_dashboard/orders_screen.dart`, `lib/features/pro_dashboard/pro_requests_screen.dart`, `lib/features/notifications/notifications_screen.dart`, `lib/features/professional_profile/pro_profile_screen.dart` |
| 4 | **RenderFlex overflow à 320 dp** (carte pro, grille d'accueil, section populaire) et pas de contrainte largeur sur web | Hauteurs/largeurs fixes, `Row` non bornées | Grille `childAspectRatio 0.65`, carte pro `ConstrainedBox(maxWidth: 116)` + `FittedBox`, section populaire `Flexible` + `height 196`, titre en `Flexible` ; **max-width 600** centré sur web/desktop via `LayoutBuilder` | `lib/core/widgets/pro_card.dart`, `lib/core/widgets/skeleton.dart`, `lib/features/home/home_screen.dart`, `lib/main.dart` |
| 5 | Zones tactiles **< 48 dp**, icônes sans `Semantics`/tooltip, crash `GoRouter` hors route dans la recherche | `IconButton` compacts sans tooltip, `context.go` direct | Boutons/outils ≥ 48 dp (`OutlineButton` borné à 48), tooltips ajoutés (cloche « Voir les notifications », effacer recherche, étoiles d'avis), `Semantics(button)` sur les items de chat, `GoRouter.maybeOf` anti-crash, badge **99+** | `lib/core/widgets/outline_button.dart`, `lib/features/home/home_screen.dart`, `lib/features/search/search_screen.dart`, `lib/features/chat/chat_list_screen.dart`, `lib/features/review/review_screen.dart` |
| 6 | Boutons d'envoi **ré- cliquables** pendant la requête (double réservation) | Pas d'état `isLoading` local | `OutlineButton(isLoading:)` : libellé masqué, indicateur affiché, `onPressed` neutralisé pendant l'envoi | `lib/core/widgets/outline_button.dart` |
| 7 | Images réseau **sans placeholder ni fallback** (avatars vides, flash blanc) | `Image.network` direct | Composant **`AppAvatar`** (initiales par défaut, `cached_network_image` pour l'URL) + `CachedNetworkImage` (placeholder/errorWidget) pour la galerie de profils | `lib/core/widgets/app_avatar.dart` (nouveau), `lib/features/professional_profile/pro_profile_screen.dart`, `lib/features/pro_dashboard/pro_profile_edit_screen.dart`, + tous les écrans listés en 8 |
| 8 | Barre de navigation **sans badge** messages non lus ; écrans chat/profil/admin sans avatar commun | Compteur absent | `unreadMessagesCountProvider` (stream fusionné des conversations) branché sur le badge de l'onglet Messages ; `AppAvatar` généralisé (chat, avis, profil, admin, pro) | `lib/core/widgets/bottom_nav_bar.dart`, `lib/features/chat/chat_controller.dart`, `lib/features/chat/chat_list_screen.dart`, `lib/features/chat/chat_detail_screen.dart`, `lib/features/profile/profile_screen.dart`, `lib/features/admin/admin_screen.dart`, `lib/features/review/review_screen.dart` |
| 9 | **Race condition** : « Mes demandes » du pro et la liste de chat restaient vides au premier lancement | Les contrôleurs chargeaient avant la résolution de la session (`authStateChanges` async) | Listener `_ref.listen(currentUserProvider.select(…))` qui **recharge dès qu'un utilisateur apparaît** | `lib/features/chat/chat_controller.dart`, `lib/features/pro_dashboard/pro_requests_controller.dart` |
| 10 | Budget/prix affichés indifféremment (le champ `price` est réservé au pro) | Libellé unique « Prix » | Séparateur `budget` (client, avant devis) / `price` (pro, après acceptation) | `lib/features/client_dashboard/orders_screen.dart` |
| 11 | Aucun **widget test** sur les écrans critiques | Absence de tests d'UI | `test/critical_screens_test.dart` : 8 tests — accueil (nominal / vide / erreur), recherche (nominal / vide), réservation (validation FR + budget), chat (badge non lus + vide) ; tous à **320 dp × 1.5** avec `tester.takeException()` = null (anti-overflow) | `test/critical_screens_test.dart` (nouveau) |

**Vérifications Partie 4 :** `flutter analyze` → 0 erreur ; `flutter test` → **27/27** ;
`npm run test:rules` → **216/216**.

**Reste à faire / décision attendue (Partie 4) :**
- Passer les écrans restants (paramètres, aide, onboarding) en `EmptyState`/`ErrorState`
  si des flux Firestore y sont ajoutés.
- Test golden (`.png` de référence) pour figer le rendu clair/sombre — décision : à faire
  uniquement si une CI est mise en place.
- Vérifier `textScaleFactor` 1.5 sur tablette (au-delà de 2.0 non testé).

---

## PARTIE 5 — Fonctions manquantes complétées (9 tâches)

| # | Tâche | Correctif | Fichier(s) |
|---|---|---|---|
| 1 | **Navigation au tap sur notification push** | `getInitialMessage()` + `onMessageOpenedApp` → route `/orders/{requestId}` (`newRequest`) ou `/chat/{chatId}` (`newMessage`) via GoRouter global (`bindNotificationRouter` dans `main.dart`) ; si l'utilisateur n'est pas connecté au tap, destination gardée en `pendingNavigation` et re-jouée après login ; nouvelle route `/orders/:requestId` + écran `OrdersDetailScreen` (devis, accepter/annuler selon la machine à états) | `lib/services/notification_service.dart`, `lib/core/widgets/app_bindings.dart`, `lib/main.dart`, `lib/routing/app_router.dart`, `lib/features/client_dashboard/order_detail_screen.dart` (nouveau), `lib/services/firestore_service.dart` (`requestStream`) |
| 2 | **Canal Android `fixnow_default`** | Dépendance `flutter_local_notifications` ; canal haute importance créé au démarrage ; `FirebaseMessaging.onMessage` affiché localement en foreground (FCM ne l'affiche pas) ; tap sur notif locale → même routage ; icône `@mipmap/ic_launcher` | `pubspec.yaml`, `lib/services/local_notification_service.dart` (nouveau), `lib/core/widgets/app_bindings.dart` |
| 3 | **Filtre « disponible »** | `availableOnly` dans `SearchState` ; filtre client `availability['days']` non vide (structure vérifiée : `pro_profile_edit_screen.dart`) appliqué dans `_filterAndSort` à côté de minRating/maxPrice ; `FilterChip` « Disponible » dans la barre de filtres + réinitialisé avec les autres | `lib/features/search/search_controller.dart`, `lib/features/search/search_screen.dart` |
| 4 | **Onglet Statistiques admin** | 5ᵉ onglet du `TabController` ; `platformStatsProvider` (3 snapshots combinés par un `combineLatest3` local — pas de rxdart) : clients, pros, pros en attente, demandes par statut (6), note moyenne pondérée ; cartes `Card`+`Text` (pas de lib de graphes) | `lib/features/admin/admin_screen.dart`, `lib/features/admin/admin_controller.dart` |
| 5 | **Tests règles Storage** | `storage.rules.test.js` : avatars (upload propre dossier, refus dossier d'autrui, refus anonyme, non-image/>5 Mo refusés, delete propriétaire), galerie pro, photos de demande (participant vs tiers, demande inexistante), images de chat ; script `npm run test:storage-rules` (émulateurs firestore+storage) ; émulateur storage ajouté à `firebase.json` | `storage.rules.test.js` (nouveau), `package.json`, `firebase.json` |
| 6 | **App Check** | Code déjà complet dans `main.dart` (Play Integrity/DeviceCheck release, debug en dev, jeton `--dart-define`) — complété par la doc : récupération du jeton, enregistrement console, activation enforcement progressif sans casser l'app | `lib/main.dart` (vérifié), `docs/APP_CHECK_SETUP.md` (nouveau) |
| 7 | **Migration custom claims admin** | Fallback legacy `role() == 'admin'` retiré de `isAdmin()` (validé par l'utilisateur : script `tool:claims` exécuté partout) ; test ajouté : un `role: 'admin'` Firestore sans custom claim n'a plus aucun droit (pro, users, categories refusés) | `firestore.rules`, `firestore.rules.test.js` |
| 8 | **Keystore release** | `build.gradle.kts` lit `android/key.properties` (keyAlias/keyPassword/storeFile/storePassword) → `signingConfigs.release`, repli debug si absent ; doc README « Signature release » (génération keystore vers `docs/FIREBASE_SETUP.md` §1.2) ; `key.properties`/`*.jks` déjà ignorés par git | `android/app/build.gradle.kts`, `README.md` |
| 9 | **Vérification Functions** | `node --check` OK, 2 triggers exportés (`onServiceRequestCreated`, `onChatMessageCreated`), dépendances v2 présentes (`firebase-functions ^7`, `firebase-admin ^13`, node 24) — prêt pour `firebase deploy --only functions` (région par défaut us-central1) | `functions/index.js` (lecture seule) |

**Vérifications Partie 5 :** `flutter analyze` → **0 problème** ; `flutter test` → **33/33**.
`npm run test:rules` / `test:storage-rules` non exécutés sur cette machine
(Java absent pour l'émulateur Firebase) — à lancer où Java est disponible
avant déploiement des règles.

---

## SYNTHÈSE FINALE — Reste à faire / Décisions attendues

| # | Sujet | Type | Détail |
|---|---|---|---|
| 1 | **Cloud Functions (plan Blaze)** | Décision budget | Remplacer les `get()` de vérification de lien (notifications, agrégation des notes) par des fonctions serveur ; supprimer le miroir séquentiel `publicProfiles` — documenté dans `firestore.rules` |
| 2 | **Backfill `publicProfiles`** | Action | `npm run tool:public-profiles` (Admin SDK, idempotent) pour les comptes créés avant la faille 7 |
| 3 | **Migration des admins vers custom claims** | Action | `npm run tool:claims` puis bascule de `isAdmin()` en 100 % `request.auth.token.admin` (le fallback legacy reste actif d'ici là) |
| 4 | **Tests automatisés `storage.rules`** | Action | Le socle `npm run test:rules` ne couvre que Firestore ; ajouter `firebase emulators:exec --only storage` + dédié |
| 5 | **Jeton App Check debug** | Action | Enregistrer le jeton (`--dart-define=APP_CHECK_DEBUG_TOKEN`) dans la Console Firebase → App Check → débogueurs, puis activer l'enforcement Play Integrity |
| 6 | **Index composites** | Action | `firestore.indexes.json` livré → déployer (`firebase deploy --only firestore:indexes`) et vérifier l'absence d'index manquants dans la console |
| 7 | CI (analyze + test + rules) | Décision | Recommandé : GitHub Actions lançant les 3 commandes de vérification à chaque push |
