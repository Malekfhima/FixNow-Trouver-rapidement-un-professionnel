# CHANGELOG — FixNow

Format : **Faille / bug** → **Cause** → **Correctif** → **Test associé**.
Chaque ligne renvoie au fichier modifié.

---

## PARTIE 10 — Retrait des profils de démo et des paiements fictifs

| # | Tâche | Correctif | Fichier(s) |
|---|---|---|---|
| 1 | **Profils de démo** | Suppression du code d'injection et de l'autorisation Firestore qui permettait à un admin de créer des profils fictifs. L'écran debug ne peut désormais que supprimer les anciens profils connus `demo-pro-*` ; il ne touche pas aux catégories ni aux profils réels | `lib/services/demo_data_cleanup_service.dart`, `lib/features/profile/demo_data_cleanup_screen.dart`, `lib/routing/app_router.dart`, `firestore.rules`, `firestore.rules.test.js` |
| 2 | **Paiement** | Suppression du faux prestataire et du bouton qui enregistrait un acompte sans transaction. L'écran précise que le paiement en ligne n'est pas disponible ; les anciens champs restent lisibles mais les règles interdisent leur création à l'état payé et leur modification | `lib/features/client_dashboard/order_detail_screen.dart`, `lib/models/service_request_model.dart`, `lib/core/services/error_mapper.dart`, `firestore.rules`, `firestore.rules.test.js`, `test/quality_screens_test.dart` |

---

## PARTIE 9 — Auth complète : Google, téléphone, mot de passe oublié (email ou SMS)

| # | Tâche | Correctif | Fichier(s) |
|---|---|---|---|
| 1 | **Création de compte Gmail** | Bouton « Continuer avec Google » ajouté à l'écran d'inscription (profil Firestore créé par le contrôleur, comme à la connexion) — avant : seul l'écran de connexion en avait un | `lib/features/auth/register_screen.dart` |
| 2 | **Numéro lié à l'inscription** | Champ **téléphone optionnel** à l'inscription + étape « Lier votre numéro » (code SMS → `updatePhoneNumber` et NON `signInWithCredential` : on LIE le numéro au compte email au lieu de connecter à un autre compte) ; `users/<uid>.phone` synchronisé en best-effort. C'est cette liaison qui rend le reset SMS possible | `register_screen.dart`, `lib/services/firebase_auth_service.dart` (`phoneCredential`, `linkPhoneNumber`, `signInWithPhone`) |
| 3 | **Mot de passe oublié par SMS** | Onglets **Email / Téléphone** : OTP → contrôles (compte existant ? possède-t-il un mot de passe ?) → nouveau mot de passe (`updatePassword`) → fermeture de la session SMS → retour connexion. Compte créé à l'instant ou compte « téléphone » : message explicite + repli sur l'email. Onglet masqué si `ENABLE_PHONE_AUTH=false` | `forgot_password_screen.dart`, `auth_controller.dart`, `firebase_auth_service.dart` |
| 4 | **Erreurs FR** | `no-current-user`, `phone-number-already-in-use`, `credential-already-in-use`, `provider-already-linked` + `operation-not-allowed` renvoyant vers la console | `lib/core/services/error_mapper.dart` |
| 5 | **Docs console** | Procédure d'activation Email/Password + Google (SHA-1) + Phone (numéros de test, domaines, quotas) et checklist RECAP | `docs/FIREBASE_SETUP.md` §3, `README.md`, `docs/RECAP.md` |
| 6 | **Tests** | 7 tests : contrôleur `updatePassword` (succès / échec FR), erreurs de liaison, onglets Email/Téléphone du reset (validation SMS), inscription (bouton Google + numéro invalide refusé) | `test/auth_reset_test.dart` (nouveau) |

**Vérifications Partie 9 :** `flutter analyze` → **0 problème** ; `flutter test` → **84/84 OK**.

---

## PARTIE 8 — Fiabilisation notifications, uploads, paiement simulé branché

| # | Tâche | Correctif | Fichier(s) |
|---|---|---|---|
| 1 | **Routage des notifications locales (bug)** | L'ancien payload « map Dart en texte » (`substring(1, length-1)` au décodage) corrompait les clés. Remplacé par du **JSON** (`jsonEncode`/`jsonDecode`) des deux côtés — y compris pour `showForeground` FCM — avec try/catch : payload malformé → map vide, jamais d'exception | `lib/core/widgets/app_bindings.dart` (`_localPayloadFor` → JSON + id stable), `lib/services/local_notification_service.dart` (`NotificationTapRouter.encodePayload/decodePayload/stableId`), test `test/notification_payload_test.dart` (aller-retour newRequest/newMessage) |
| 2 | **Routage par type** | Table partagée et pure `resolveNotificationLocation` : `newMessage` → `/chat/<id>` ; types de demande → `/orders/<id>` (client) ou `/pro-dashboard` (pro) ; `reviewReceived` → `/pro-reviews` ; `proApproved/proRejected` → `/pro-profile-edit` ou `/pro-dashboard` ; type inconnu/generic ignoré. Appliquée au tap local/FCM **et** à la liste in-app (avant : request* → `/orders` liste, proApproved → `/profile`). Id local : hash FNV-1a stable de l'id Firestore (plus `title+body.hashCode`) | `lib/services/notification_routing.dart` (nouveau), `lib/services/notification_service.dart`, `lib/features/notifications/notifications_screen.dart`, test `test/notification_routing_test.dart` (client vs pro + type inconnu) |
| 3 | **public_id unique Cloudinary** | En mode unsigned Cloudinary refuse d'écraser un `public_id` existant (erreur 400). Suffixe uuid (8 car.) ajouté à chaque upload — évite l'échec au remplacement d'avatar / renvoi de photo. Doc preset étendue (unsigned, formats images, 5 Mo, dossier `fixnow`) | `lib/services/storage_service.dart`, `test/storage_service_test.dart` (préfixes + unicité + 2 uploads distincts), `README.md` |
| 4 | **Paiement simulé branché** | Bouton « Payer l'acompte (30,00 €) — Paiement simulé » après acceptation du devis, chargement + succès/erreur via `ErrorMapper` (`PaymentException` mappé), enregistrement `depositPaid` + `depositId` **écrits ensemble** (règles : paire indissociable, types bool+string, pro exclu). Bandeau « Acompte réglé · Paiement simulé » une fois payé ; après acceptation du devis on reste sur l'écran (avant : retour liste immédiat) | `firestore.rules` (`clientKeysOk` + `depositKeysOk`), `firestore.rules.test.js` (4 tests émulateur : paire/indissociable/types/pro exclu), `lib/models/service_request_model.dart` (depositPaid/depositId), `lib/features/client_dashboard/order_detail_screen.dart`, `lib/core/services/error_mapper.dart`, test `test/quality_screens_test.dart` (tap → écriture vérifiée) |
| 5 | **Qualité / widget tests** | Assertion `ListTile` corrigée dans la liste de notifications (`tileColor`+`shape` au lieu d'un Container décoré qui masquait le fond). 9 tests à 320 dp ×1.5 sans overflow : notifications (vide/nominal/erreur), détail commande (photos+acompte, déja payé, introuvable), Mes avis (vide/nominal/erreur). États chat déjà conformes (chargement/erreur FR/Réessayer/état vide) | `lib/features/notifications/notifications_screen.dart`, test `test/quality_screens_test.dart` (nouveau) |
| 6 | **Nettoyage & docs** | Bloc `functions` retiré de `firebase.json` (dossier `functions/` reste optionnel, documented). `docs/RECAP.md` mis à jour (plus de Storage/Functions : Cloudinary + notifications client). README : commande de lancement complète `--dart-define` | `firebase.json`, `docs/RECAP.md`, `README.md`, `CHANGELOG.md` |
| 7 | **CI : tests des règles** | Job `firestore-rules` ajouté (Node 20 + Java 17 + `npm ci` + `npm run test:rules` sur émulateur) — Java absent en local, la CI devient le seul endroit où les règles sont testées | `.github/workflows/ci.yml` |

**Vérifications Partie 8 :** `flutter analyze` → **0 problème** ; `flutter test` → **77/77 OK**.

---

## PARTIE 7 — 100 % gratuit (plan Spark) : Cloudinary, photos, notifications, finitions

| # | Tâche | Correctif | Fichier(s) |
|---|---|---|---|
| 1 | **Firebase Storage → Cloudinary** | Storage exige Blaze → interdit. Upload HTTP multipart *unsigned* vers `api.cloudinary.com/v1_1/<cloud>/image/upload` avec `upload_preset`, retour `secure_url` ; config via `--dart-define` (`CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_UPLOAD_PRESET`), jamais en dur ; gardes conservées (5 Mo max, images uniquement) + messages FR via `ErrorMapper` ; même API publique (avatars, galerie pro, photos de demande, images de chat) ; suppression `firebase_storage`, `storage.rules(.test.js)`, bloc storage de `firebase.json`, script `test:storage-rules` ; dépendance `http` | `lib/services/storage_service.dart`, `pubspec.yaml`, `firebase.json`, `package.json`, `storage.rules` (supprimé), `storage.rules.test.js` (supprimé) |
| 2 | **Photos dans la demande** | Sélection 1..`AppConstants.maxPhotosPerRequest` via `image_picker`, aperçu + suppression, upload AVANT création de la demande (échec photo ⇒ pas de demande créée), champ `photos[]` écrit par le client (autorisé par les règles, cf. faille 3 Partie 1) ; affichage des photos dans le détail commande (client) et côté pro | `lib/features/booking/booking_screen.dart`, `lib/features/booking/booking_controller.dart`, `lib/core/widgets/request_photo_gallery.dart` (nouveau), `lib/features/client_dashboard/order_detail_screen.dart`, `lib/features/pro_dashboard/pro_requests_screen.dart` |
| 3 | **Notifications sans Cloud Functions** | Chaque événement clé crée une notification Firestore côté client (`notification_helpers`, conforme aux règles — liste blanche + lien réel) ; notification LOCALE quand l'app est ouverte et qu'une notif non lue arrive ; `cloud_functions` retiré du `pubspec.yaml` ; dossier `functions/` conservé avec README « optionnel (plan Blaze) » | `lib/features/notifications/notification_helpers.dart`, `lib/models/notification_model.dart`, `lib/services/local_notification_service.dart`, `pubspec.yaml`, `functions/README.md` (nouveau) |
| 4 | **Auth téléphone désactivable** | Flag `ENABLE_PHONE_AUTH` (défaut `true`) via `--dart-define` : onglet téléphone masqué à l'écran de connexion + redirection de la route `/phone-auth` quand désactivé (quota SMS gratuit limité) ; mot de passe oublié + redirection par rôle vérifiés | `lib/core/config/app_runtime.dart`, `lib/features/auth/login_screen.dart`, `lib/routing/app_router.dart` |
| 5 | **Finitions produit** | « Mes avis » pro (note moyenne + liste) ; note moyenne sur le profil (`StarRating`) ; annulation/modification de demande selon la machine à états ; paramètres/aide (thème, déconnexion, à propos, contact) dans le profil | `lib/features/pro_dashboard/pro_reviews_screen.dart` (nouveau), `lib/core/widgets/star_rating.dart`, `lib/features/client_dashboard/order_detail_screen.dart`, `lib/features/profile/profile_screen.dart` |
| 6 | **Paiement simulé** | Interface `PaymentService` + `FakePaymentService` (acompte 30 %, latence simulée, id déterministe, validation des montants) — aucun vrai prestataire | `lib/services/payment_service.dart` (nouveau) |
| 7 | **Tests** | `StorageService` (mock HTTP : URL/preset/public_id, >5 Mo refusé avant réseau, non-image refusé, erreurs Cloudinary → FR) ; garde photos du `BookingController` (limite + non-connecté, aucun accès distant) ; `FakePaymentService` ; machine à états (existant) | `test/storage_service_test.dart`, `test/booking_photos_test.dart`, `test/payment_service_test.dart`, `test/service_request_state_machine_test.dart` |

**Vérifications Partie 7 :** `flutter analyze` → **0 problème** ; `flutter test` → **tous OK**.

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
