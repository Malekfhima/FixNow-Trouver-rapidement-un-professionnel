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

_(mise à jour à venir)_
