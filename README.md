# FixNow – Trouver rapidement un professionnel

Application mobile de mise en relation entre **clients** et **professionnels de services**
(plombier, électricien, menuisier, mécanicien, etc.) : recherche rapide, demande de service,
devis, suivi de réservation, acompte (paiement simulé), messagerie et avis.

> ✅ **Version finale 1.0.0+1** — toutes les fonctionnalités de la [Roadmap](#-roadmap) sont livrées.
> Historique détaillé des 8 parties de développement : [`CHANGELOG.md`](CHANGELOG.md) ·
> Point d'étape et questions ouvertes : [`docs/RECAP.md`](docs/RECAP.md).

---

## 🧱 Stack technique

| Couche | Technologie |
|---|---|
| Application | Flutter ≥ 3.16 (Dart ≥ 3.2), Material 3 — CI : Flutter 3.44.9 |
| Gestion d'état | Riverpod 2 (`StateNotifier`, `StreamProvider`) |
| Navigation | go_router 14 (ShellRoute + barre de navigation, redirections par rôle) |
| Backend | Firebase (BaaS) — **plan Spark, 100 % gratuit** |
| Base de données | Cloud Firestore (temps réel) |
| Authentification | Firebase Auth — email/mot de passe, Google Sign-In, téléphone (SMS, désactivable) |
| Stockage fichiers | **Cloudinary** (upload *unsigned* + preset) — Firebase Storage retiré (Blaze requis) |
| Notifications | In-app (Firestore) + locales (`flutter_local_notifications`, payload JSON) ; token FCM conservé pour une migration Functions |
| Paiement | Interface `PaymentService` + `FakePaymentService` — **acompte 30 % simulé**, aucun prestataire |
| Sécurité | Règles Firestore par rôle (`client` / `pro` / `admin`) + **76 tests d'émulateur** |
| CI | GitHub Actions : `flutter analyze` + `flutter test` (77 tests), puis `npm run test:rules` (Node 20 + Java 17) |

---

## 📦 Installation

### Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.16
- Node.js ≥ 18 + Java ≥ 17 (émulateur Firebase, p. ex. le JDK d'Android Studio)
- Firebase CLI : `npm install -g firebase-tools`

### Étapes

```bash
# 1. Cloner le dépôt
git clone <url-du-repo>
cd fixnow

# 2. Dépendances Flutter
flutter pub get

# 3. Dépendances Node (tests des règles Firestore — facultatif si CI uniquement)
npm install

# 4. Configurer Firebase (génère lib/firebase_options.dart et google-services.json)
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=<votre-projet-firebase>

# 5. Déployer les règles de sécurité Firestore
firebase deploy --only firestore:rules
```

### Variables / configuration

La configuration Firebase est **embarquée** dans le projet (pas de `.env` serveur) :

- `android/app/google-services.json` — config Android (généré par `flutterfire configure`)
- `lib/firebase_options.dart` — config multi-plateformes (généré, ne pas éditer à la main)
- `firebase.json` — mapping des apps Firebase + émulateur Firestore (port 8081)

> 🔒 Les identifiants Firebase client ne sont **pas des secrets** : la sécurité repose
> sur les règles Firestore et l'activation d'**App Check** (recommandé en production).

### 🖼️ Images : Cloudinary (pas de Firebase Storage)

Firebase Storage exige désormais le plan **Blaze** (carte bancaire) : le projet
reste 100 % gratuit sur le plan **Spark**, les images (avatars, galerie pro,
photos de demande, images de chat) sont donc hébergées sur **Cloudinary**
(offre gratuite, upload *unsigned* via preset).

1. Créer un compte gratuit sur cloudinary.com, relever le **cloud name**.
2. Settings → Upload → **Add upload preset** avec ce réglage :
   - Signing mode : **Unsigned** (l'app n'a pas de secret à signer) ;
   - **Allowed formats** : `jpg, jpeg, png, webp, gif` (images uniquement) ;
   - **Max file size** : `5242880` octets (5 Mo — même garde côté client) ;
   - **Folder** : `fixnow` (dossier imposé, pour circonscrire les uploads) ;
   - c'est un preset public par nature : ne jamais y mettre de secret,
     pas de transformation destructrice, pas de droit d'écriture au-delà
     des images.
3. Lancer l'app avec les deux variables (jamais en dur dans le code) :

```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=votre-cloud \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=votre-preset
```

Gardes client conservées : **5 Mo max**, **images uniquement** ; messages d'erreur
en français via `ErrorMapper`. Sans ces variables, l'app démarre mais l'upload
d'images renvoie une erreur explicite. Chaque upload reçoit un `public_id`
unique (uuid) — Cloudinary en mode unsigned refuse d'écraser un fichier
existant, le suffixe évite donc l'échec au remplacement d'un avatar ou au
renvoi d'une photo.

### 📵 Auth téléphone désactivable

Le quota SMS gratuit de Firebase étant très limité, la connexion par téléphone
demeure codée mais peut être désactivée (email + Google restent le parcours
principal) :

```bash
flutter run --dart-define=ENABLE_PHONE_AUTH=false
```

### 🔐 Fournisseurs d'authentification (console Firebase)

Inscription, connexion et « mot de passe oublié » reposent sur trois
fournisseurs à activer dans **Authentication → Sign-in method** (sinon
erreur `operation-not-allowed`) :

| Fournisseur | Sert à | Prérequis |
|---|---|---|
| **Email/Password** | Création de compte, connexion, **mot de passe oublié par email** | aucun |
| **Google** | « Continuer avec Google » (création + connexion Gmail) | SHA-1/SHA-256 §1.3 de [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md) + `google-services.json` à jour |
| **Phone** | Connexion par SMS, **liaison du numéro à l'inscription**, **mot de passe oublié par SMS** | quotas SMS, `ENABLE_PHONE_AUTH=true` (défaut) |

L'inscription propose un **champ téléphone optionnel** : après vérification
par code SMS, le numéro est **lié au compte** — c'est ce qui rend possible la
réinitialisation par SMS (Firebase ne retrouve un compte que par un numéro
qui lui appartient). Procédure détaillée :
[`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md) §3.

---

## 🚀 Lancement

```bash
# Lister les appareils disponibles
flutter devices

# Lancer sur Android / iOS / Windows / Web
flutter run -d <device-id>

# LANCEMENT COMPLET (images Cloudinary requises pour avatars/photos) :
flutter run -d <device-id> --dart-define=CLOUDINARY_CLOUD_NAME=… --dart-define=CLOUDINARY_UPLOAD_PRESET=…

# Build release
flutter build apk        # Android
flutter build web        # Web
```

L'application démarre même **sans Firebase configuré** (mode dégradé local,
voir `main.dart` et `lib/core/config/app_runtime.dart`) — utile pour travailler
sur l'UI sans backend ; les redirections d'auth sont alors désactivées.

### 🔑 Signature release (Android)

Le build release est signé via `android/key.properties` (non commité, déjà
dans `.gitignore`) : sans ce fichier, le build retombe sur la clé debug
(usage dev uniquement — ne JAMAIS publier un build signé debug).

1. Générer le keystore (une seule fois) — voir aussi
   [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md) §1.2 :
   ```bash
   keytool -genkey -v \
     -keystore fixnow-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias fixnow
   ```
   ⚠️ Conserver le keystore et ses mots de passe HORS du dépôt (sauvegarde
   sécurisée) : perdre le keystore = impossible de mettre à jour l'app sur
   le Play Store.
2. Créer `android/key.properties` :
   ```properties
   storePassword=<mot de passe du keystore>
   keyPassword=<mot de passe de la clé>
   keyAlias=fixnow
   storeFile=../fixnow-release.jks   # chemin relatif à android/app/
   ```
3. `flutter build apk --release` — signé automatiquement.
4. Déclarer l'empreinte SHA-1/SHA-256 du keystore release dans la console
   Firebase (Google Sign-In), puis re-télécharger `google-services.json`
   — procédure dans [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md) §1.3.

---

## 👥 Flux utilisateurs

### Client
1. Inscription / connexion (email, Google, téléphone)
2. Accueil → recherche par catégorie / texte → profil professionnel
3. Réservation : description, adresse, date, budget → demande envoyée
4. Suivi « Mes commandes » : statuts temps réel, devis reçus (accepter / refuser)
5. **Acompte** : bouton « Payer l'acompte » après acceptation du devis (*paiement simulé*, écriture `depositPaid` + `depositId` vérifiée par les règles)
6. Messagerie avec le pro, avis après prestation

### Professionnel
1. Inscription avec le rôle **Professionnel** → profil créé *en attente de validation*
2. Édition du profil : métiers, zone, tarif horaire, présentation, disponibilités
3. Validation par un **admin** (statut `approved`) avant visibilité publique
4. « Mes demandes » : accepter / refuser / proposer un devis / démarrer / terminer
5. « Mes avis » : note moyenne + liste des avis clients

---

## 🗂️ Architecture du code

```
lib/
├── main.dart                     # Point d'entrée (init Firebase + ProviderScope)
├── routing/
│   └── app_router.dart           # GoRouter : routes, redirections d'auth par rôle
├── core/
│   ├── config/app_runtime.dart   # Flags runtime (Firebase initialisé ?, ENABLE_PHONE_AUTH)
│   ├── constants/app_constants.dart   # Noms de collections, limites, chemins
│   ├── services/error_mapper.dart     # Traduction des exceptions en messages FR
│   ├── theme/app_theme.dart       # Design system (couleurs, espacements, textes)
│   ├── utils/validators.dart      # Validateurs de formulaires (FR)
│   └── widgets/                   # Composants réutilisables (ProCard, StarRating, galerie photos…)
├── models/                        # Modèles Firestore (from/toFirestore)
│   ├── user_model.dart            # AppUser (rôles : client / pro / admin)
│   ├── professional_model.dart    # Professional (statut : pending / approved / rejected)
│   ├── service_request_model.dart # ServiceRequest (statuts + devis + acompte)
│   ├── service_request_state_machine.dart  # Transitions de statut autorisées
│   ├── chat_model.dart            # Chat + ChatMessage
│   ├── review_model.dart          # Review
│   ├── notification_model.dart    # Notification in-app (types autorisés)
│   └── category_model.dart        # ServiceCategory
├── services/
│   ├── firebase_auth_service.dart # Auth (email, Google, téléphone)
│   ├── firestore_service.dart     # Accès données centralisé (+ recherche paginée)
│   ├── storage_service.dart       # Upload Cloudinary (public_id unique uuid)
│   ├── notification_service.dart  # FCM (init, tokens en Firestore, routage au tap)
│   ├── notification_routing.dart  # Table pure notif → route (tap local/FCM + liste)
│   ├── local_notification_service.dart  # Notifs locales (canal fixnow_default, payload JSON)
│   ├── payment_service.dart       # Interface PaymentService + FakePaymentService (30 %)
│   └── seed_service.dart          # Seed de données de démo (DEV)
└── features/                      # Un dossier par domaine fonctionnel
    ├── auth/                      # Login, inscription, mot de passe oublié, téléphone
    ├── onboarding/
    ├── home/                      # Accueil client + shell de navigation
    ├── search/                    # Recherche + filtres par catégorie + tri distance
    ├── professional_profile/      # Profil public d'un pro + avis
    ├── booking/                   # Demande de service (+ photos)
    ├── chat/                      # Messagerie client ↔ pro
    ├── client_dashboard/          # Suivi des demandes (« Mes commandes ») + acompte
    ├── pro_dashboard/             # Espace pro : demandes, avis, édition de profil
    ├── notifications/             # Liste des notifications + helpers de création
    ├── review/                    # Saisie d'avis après prestation
    ├── admin/                     # Validation des pros, modération, statistiques
    ├── profile/                   # Profil utilisateur + paramètres/aide
    └── profile/debug_seed_screen.dart  # Écran de seed, kDebugMode
```

**Conventions** : chaque feature possède son écran et, quand il y a de la logique,
un contrôleur `StateNotifier` dédié (`*_controller.dart`). Toutes les chaînes
utilisables sont **en français**.

---

## 🗄️ Modèle de données Firestore

| Collection | Contenu | Clés principales |
|---|---|---|
| `users` | Profil de tout utilisateur (privé) | `role` (client/pro/admin), `isPro`, `name`, `email`, `phone`, `avatarUrl`, `fcmToken` |
| `publicProfiles` | Identité publique (nom/avatar/rôle affichés) | `name`, `avatarUrl`, `role` — jamais d'email/téléphone/fcmToken |
| `professionals` | Profil pro (doc id = uid du user ; `demo-*` = seed) | `name`, `city`, `categories[]`, `bio`, `hourlyRate`, `location` (GeoPoint), `gallery[]`, `availability`, `ratingAvg`, `ratingCount`, `status` (pending/approved/rejected) |
| `serviceRequests` | Demandes de service | `clientId`, `proId`, `categoryId`, `description`, `photos[]`, `address`, `scheduledDate`, `price`, `quotePrice`, `quoteNote`, `depositPaid` (bool), `depositId` (string, écrits **ensemble**), `status` (pending/accepted/declined/quoted/inProgress/completed/cancelled) |
| `chats` | Conversations | `clientId`, `proId`, `lastMessage`, `lastMessageAt`, `unreadCount` |
| `chats/{id}/messages` | Messages d'une conversation | `senderId`, `text`, `imageUrl`, `timestamp`, `read` |
| `reviews` | Avis après prestation (doc id = `requestId`) | `requestId`, `clientId`, `proId`, `rating` (1–5), `comment` |
| `notifications` | Notifications in-app | `userId` (destinataire), `actorId`, `type` (liste blanche), `relatedId`, `title` (≤ 200), `body` (≤ 2000), `read`, `createdAt` |
| `categories` | Catégories de services | `name`, `icon`, `color`, `bgColor` |
| `reports` | Signalements (modération) | `reporterId`, `targetType`, `targetId`, `reason`, `status` (open/resolved/dismissed) |

---

## 🔐 Règles de sécurité

Définies dans [`firestore.rules`](firestore.rules), déployables via
`firebase deploy --only firestore:rules`. Garanties actuelles :

- **Rôle invariant** : personne ne peut modifier son propre `role`
  (l'auto-promotion en admin est impossible) ; promotion réservée aux admins.
- **Statut pro invariant** : un pro ne peut pas toucher à son `status` ni à
  `ratingAvg`/`ratingCount` (validation et notes gérées ailleurs).
- **Chats** : lecture/mise à jour/suppression réservées aux **participants** ;
  la création exige d'être l'un des participants, messages immuables.
- **Demandes** : le client ne peut qu'annuler (+ accepter le devis, écrire
  l'acompte) ; le pro assigné gère statuts/devis ; l'admin peut tout.
- **Acompte (paiement simulé)** : `depositPaid` et `depositId` doivent être
  écrits **ensemble** (bool + string), jamais séparément, et **jamais par le
  pro** — seule la branche client les autorise.
- **Avis** : uniquement le client d'une demande **terminée**, auteur = client de
  la demande, unicité via doc id = `requestId`, immuables.
- **Notifications** : réservées au destinataire ; seul le destinataire coche
  `read` ; `type` dans une liste blanche, textes bornés ; lien **réel**
  actor↔destinataire prouvé par `get()`/`exists()` (chat, demande, ou
  validation de pro par un admin).
- **Identité publique** : `publicProfiles` lisible par tout connecté, champs
  bornés (`name`, `avatarUrl`, `role` uniquement).
- **Catégories** : écriture admin uniquement.
- **Seed** : l'admin peut créer des pros de démonstration uniquement avec des ids
  `demo-*`.

---

## ✅ Tests & qualité

```bash
# Analyse statique (0 erreur attendue)
flutter analyze

# Tests unitaires et widgets (77 tests)
flutter test

# Tests des règles Firestore — 76 tests sur l'émulateur (Node + Java requis)
npm run test:rules
```

**Flutter — 13 fichiers, 77 tests :**

- `test/widget_test.dart` — démarrage de l'app (override d'auth, sans Firebase).
- `test/critical_screens_test.dart` + `test/quality_screens_test.dart` — écrans
  critiques rendus à **320 dp / scale ×1.5** sans overflow : notifications,
  détail commande (photos + acompte), Mes avis, recherche, profil…
- `test/notification_payload_test.dart` / `notification_routing_test.dart` —
  aller-retour du payload JSON et table de routage notif → route (client vs pro,
  type inconnu).
- `test/storage_service_test.dart` — uploads Cloudinary (mock HTTP, `public_id`
  unique, gardes 5 Mo / images).
- `test/search_pagination_test.dart`, `test/booking_photos_test.dart`,
  `test/payment_service_test.dart`, `test/service_request_state_machine_test.dart`,
  `test/star_rating_test.dart`, `test/theme_test.dart`, `test/sign_out_test.dart`.

**Règles Firestore — `firestore.rules.test.js`, 76 tests (19 blocs) :**
invariants rôle/statut, chats réservés aux participants, machine à états des
demandes, **acompte (paire indissociable, types, pro exclu)**, avis, notifications
(lien réel), seed admin, catégories, failles 1→10 corrigées.

- L'émulateur écoute sur le port **8081** (8080 souvent occupé). Sous Windows,
  exporter le JDK si besoin :
  `export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH"`.
- **CI** (`.github/workflows/ci.yml`) : job `flutter` (analyze + test) et job
  `firestore-rules` (Node 20 + Java 17 + émulateur) — ces tests s'exécutent
  donc aussi sur chaque push/PR, y compris là où Java n'est pas installé.

---

## 🌱 Données de démonstration (DEV uniquement)

Un écran de seed, accessible **uniquement en debug** (`kDebugMode`) via
`Profil → Seed démo (debug)` (route `/debug-seed`), permet de :

- **injecter** 8 catégories + 6 professionnels fictifs (identifiés par le préfixe
  `[DÉMO]` et une mention dans la bio, statut *approuvé*, tarifs) ;
- **supprimer** ces données (ids stables → opérations idempotentes).

> ⚠️ Le seed exige un compte **admin** : dans la console Firebase (ou l'émulateur),
> passe `users/<ton-uid>.role` à `"admin"`. Sans cela, les règles de sécurité
> refusent l'écriture (message explicatif affiché dans l'écran).

---

## 🗺️ Roadmap

### P0 – Socle ✅
- [x] Réparation des fichiers cassés (profil pro, recherche, routeur) — `flutter analyze` sans erreur
- [x] Durcissement des règles Firestore (rôle/statut invariants, chats aux participants) + **76 tests émulateur**
- [x] Redirection d'auth par rôle (routes protégées client/pro/admin) + mot de passe oublié
- [x] Flux professionnel : inscription pro, édition de profil, « Mes demandes » (accepter/refuser/devis/démarrer/terminer)
- [x] Seed de démonstration (catégories + pros `[DÉMO]`, bouton debug uniquement)

### P1 – Cœur métier ✅
- [x] Avis : notation après prestation terminée (batch avis + compteurs, « Mes avis » côté pro)
- [x] Notifications in-app + locales (`flutter_local_notifications`, payload JSON, routage par type)
- [x] Upload de photos : Cloudinary (avatars, galerie pro, photos de demande, images de chat)
- [x] Recherche avancée : tri, filtres note/prix/disponibilité, pagination (50 par page, curseur `startAfterDocument`)
- [x] Paiement / acompte derrière une interface `PaymentService` (implémentation simulée `FakePaymentService`, bouton d'acompte branché, sans frais)

### P2 – Administration & options ✅
- [x] Tableau de bord admin (validation des pros, modération, statistiques)
- [x] Paramètres/aide (thème clair/sombre, déconnexion, à propos, contact)

### P3 – Fiabilisation (partie 8) ✅
- [x] Payload de notification en JSON (plus de `substring` sur une map Dart)
- [x] Table de routage notif → route partagée (tap FCM/local + liste in-app)
- [x] `public_id` Cloudinary unique par upload (uuid)
- [x] Acompte simulé branché (UI + règles + tests émulateur)
- [x] Widget tests 320 dp ×1.5 (notifications, détail commande, Mes avis)
- [x] Nettoyage `firebase.json` + CI : job `firestore-rules`

> **Plan Spark (100 % gratuit)** : pas de Firebase Storage (→ Cloudinary), pas de
> Cloud Functions déployées (notifications créées côté client dans Firestore +
> notifications locales). Le dossier `functions/` est optionnel et documenté
> pour une migration future vers Blaze.

---

## 📄 Licence

Projet de démonstration — tous droits réservés aux auteurs respectifs.
