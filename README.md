# FixNow – Trouver rapidement un professionnel

Application mobile de mise en relation entre **clients** et **professionnels de services**
(plombier, électricien, menuisier, mécanicien, etc.) : recherche rapide, demande de service,
devis, suivi de réservation, messagerie et avis.

> ⚠️ Projet en cours de développement — voir la [Roadmap](#-roadmap) pour l'état exact des fonctionnalités.

---

## 🧱 Stack technique

| Couche | Technologie |
|---|---|
| Application | Flutter 3.16+ (Dart 3.2), Material 3 |
| Gestion d'état | Riverpod 2 (`StateNotifier`, `StreamProvider`) |
| Navigation | go_router 14 (ShellRoute + barre de navigation, redirections par rôle) |
| Backend | Firebase (BaaS) |
| Base de données | Cloud Firestore (temps réel) |
| Authentification | Firebase Auth — email/mot de passe, Google Sign-In, téléphone (SMS) |
| Stockage fichiers | Firebase Storage (avatars, galeries, photos de demandes) |
| Notifications | Firebase Cloud Messaging (FCM) |
| Sécurité | Règles Firestore par rôle (`client` / `pro` / `admin`) + tests d'émulateur |

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

# 3. Dépendances Node (tests des règles Firestore)
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
> sur les règles Firestore/Storage et l'activation d'**App Check** (recommandé en production).

---

## 🚀 Lancement

```bash
# Lister les appareils disponibles
flutter devices

# Lancer sur Android / iOS / Windows / Web
flutter run -d <device-id>

# Build release
flutter build apk        # Android
flutter build web        # Web
```

L'application démarre même **sans Firebase configuré** (mode dégradé local,
voir `main.dart` et `lib/core/config/app_runtime.dart`) — utile pour travailler
sur l'UI sans backend ; les redirections d'auth sont alors désactivées.

---

## 👥 Flux utilisateurs

### Client
1. Inscription / connexion (email, Google, téléphone)
2. Accueil → recherche par catégorie / texte → profil professionnel
3. Réservation : description, adresse, date, budget → demande envoyée
4. Suivi « Mes commandes » : statuts temps réel, devis reçus
5. Messagerie avec le pro, avis après prestation (P1)

### Professionnel
1. Inscription avec le rôle **Professionnel** → profil créé *en attente de validation*
2. Édition du profil : métiers, zone, tarif horaire, présentation, disponibilités
3. Validation par un **admin** (statut `approved`) avant visibilité publique
4. « Mes demandes » : accepter / refuser / proposer un devis / démarrer / terminer

---

## 🗂️ Architecture du code

```
lib/
├── main.dart                     # Point d'entrée (init Firebase + ProviderScope)
├── routing/
│   └── app_router.dart           # GoRouter : routes, redirections d'auth par rôle
├── core/
│   ├── config/app_runtime.dart   # Flags runtime (Firebase initialisé ?)
│   ├── constants/app_constants.dart   # Noms de collections, limites, chemins Storage
│   ├── theme/app_theme.dart       # Design system (couleurs, espacements, textes)
│   ├── utils/validators.dart      # Validateurs de formulaires (FR)
│   └── widgets/                   # Composants réutilisables (ProCard, boutons…)
├── models/                        # Modèles Firestore (from/toFirestore)
│   ├── user_model.dart            # AppUser (rôles : client / pro / admin)
│   ├── professional_model.dart    # Professional (statut : pending / approved / rejected)
│   ├── service_request_model.dart # ServiceRequest (statuts + devis)
│   ├── chat_model.dart            # Chat + ChatMessage
│   ├── review_model.dart          # Review
│   └── category_model.dart        # ServiceCategory
├── services/
│   ├── firebase_auth_service.dart # Auth (email, Google, téléphone)
│   ├── firestore_service.dart     # Accès données centralisé
│   ├── storage_service.dart       # Upload d'images
│   ├── notification_service.dart  # FCM (tokens en Firestore)
│   └── seed_service.dart          # Seed de données de démo (DEV)
└── features/                      # Un dossier par domaine fonctionnel
    ├── auth/                      # Login, inscription, mot de passe oublié, téléphone
    ├── onboarding/
    ├── home/                      # Accueil client + shell de navigation
    ├── search/                    # Recherche + filtres par catégorie + tri distance
    ├── professional_profile/      # Profil public d'un pro + avis
    ├── booking/                   # Demande de service
    ├── chat/                      # Messagerie client ↔ pro
    ├── client_dashboard/          # Suivi des demandes (« Mes commandes »)
    ├── pro_dashboard/             # Espace pro : demandes + édition de profil
    ├── profile/                   # Profil utilisateur + seed debug (DEV)
    └── debug_seed_screen.dart     # (dans profile/) écran de seed, kDebugMode
```

**Conventions** : chaque feature possède son écran et, quand il y a de la logique,
un contrôleur `StateNotifier` dédié (`*_controller.dart`). Toutes les chaînes
utilisables sont **en français**.

---

## 🗄️ Modèle de données Firestore

| Collection | Contenu | Clés principales |
|---|---|---|
| `users` | Profil de tout utilisateur | `role` (client/pro/admin), `name`, `email`, `phone`, `avatarUrl`, `fcmToken` |
| `professionals` | Profil pro (doc id = uid du user ; `demo-*` = seed) | `name`, `city`, `categories[]`, `bio`, `hourlyRate`, `location` (GeoPoint), `gallery[]`, `availability`, `ratingAvg`, `ratingCount`, `status` (pending/approved/rejected) |
| `serviceRequests` | Demandes de service | `clientId`, `proId`, `categoryId`, `description`, `photos[]`, `address`, `scheduledDate`, `price`, `quotePrice`, `quoteNote`, `status` (pending/accepted/declined/quoted/inProgress/completed/cancelled) |
| `chats` | Conversations | `clientId`, `proId`, `lastMessage`, `lastMessageAt`, `unreadCount` |
| `chats/{id}/messages` | Messages d'une conversation | `senderId`, `text`, `imageUrl`, `timestamp`, `read` |
| `reviews` | Avis après prestation (doc id = `requestId`) | `requestId`, `clientId`, `proId`, `rating` (1–5), `comment` |
| `categories` | Catégories de services | `name`, `icon`, `color`, `bgColor` |
| `reports` | Signalements (modération) | `reporterId`, `targetType`, `targetId`, `reason`, `status` |

---

## 🔐 Règles de sécurité

Définies dans [`firestore.rules`](firestore.rules), déployables via
`firebase deploy --only firestore:rules`. Garanties actuelles :

- **Rôle invariant** : personne ne peut modifier son propre `role`
  (l'auto-promotion en admin est impossible) ; promotion réservée aux admins.
- **Statut pro invariant** : un pro ne peut pas toucher à son `status` ni à
  `ratingAvg`/`ratingCount` (validation et notes gérées ailleurs).
- **Chats** : lecture/mise à jour/suppression réservées aux **participants** ;
  la création exige d'être l'un des participants.
- **Demandes** : le client ne peut qu'annuler ; le pro assigné gère statuts/devis ;
  l'admin peut tout.
- **Avis** : uniquement le client d'une demande **terminée**, auteur = client de
  la demande, unicité via doc id = `requestId`, immuables.
- **Catégories** : écriture admin uniquement.
- **Seed** : l'admin peut créer des pros de démonstration uniquement avec des ids
  `demo-*`.

---

## ✅ Tests & qualité

```bash
# Analyse statique (0 erreur attendue)
flutter analyze

# Tests unitaires et widgets
flutter test

# Tests des règles Firestore (émulateur requis : Node + Java)
npm run test:rules
```

- `test/widget_test.dart` — démarrage de l'app (override d'auth, sans Firebase).
- `firestore.rules.test.js` — 16 tests des règles de sécurité sur l'émulateur :
  invariants rôle/statut, restriction des chats aux participants, conditions des
  avis, seed admin, gestion des catégories.
- L'émulateur écoute sur le port **8081** (8080 souvent occupé). Sous Windows,
  exporter le JDK si besoin :
  `export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH"`.

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
- [x] Durcissement des règles Firestore (rôle/statut invariants, chats aux participants) + 16 tests émulateur
- [x] Redirection d'auth par rôle (routes protégées client/pro/admin) + mot de passe oublié
- [x] Flux professionnel : inscription pro, édition de profil, « Mes demandes » (accepter/refuser/devis/démarrer/terminer)
- [x] Seed de démonstration (catégories + pros `[DÉMO]`, bouton debug uniquement)

### P1 – Cœur métier
- [ ] Avis : notation après prestation terminée (1 avis / prestation)
- [ ] Notifications (in-app d'abord ; FCM push ensuite — voir note Cloud Functions)
- [ ] Upload de photos (demandes, galerie pro)
- [ ] Recherche avancée : tri, filtres note/prix/disponibilité, pagination

### P2 – Administration & options
- [ ] Tableau de bord admin (validation des pros, modération, catégories, statistiques)
- [ ] Paiement / acompte derrière une interface `PaymentService` (stub au départ)

> **Notifications push (FCM)** : les Cloud Functions nécessitent le plan Blaze.
> Une alternative sans coût (notifications in-app/locales via Firestore + flux temps réel)
> est étudiée en priorité ; l'option Cloud Functions fera l'objet d'une validation séparée.

---

## 📄 Licence

Projet de démonstration — tous droits réservés aux auteurs respectifs.
