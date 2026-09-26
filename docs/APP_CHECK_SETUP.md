# Configuration App Check — FixNow

App Check protège le backend Firebase (Firestore, Storage, Functions) contre
les abus venant de clients non autorisés (app tierce, script, bot).

> Le code d'activation est **déjà en place** dans `lib/main.dart` :
> - **Android** : Play Integrity en release, provider **debug** en dev ;
> - **iOS / macOS** : DeviceCheck en release, provider debug en dev ;
> - le démarrage n'est **jamais bloqué** si App Check échoue (`try/catch`) ;
> - en debug, le jeton est affiché dans la console (`App Check debug token: …`).

---

## 1. Récupérer le jeton de debug (développement)

1. Lancer l'app en debug : `flutter run` (Android ou iOS).
2. Lire le jeton dans les logs :
   ```
   App Check debug token: 6F3A1C…-xxxx-xxxx-xxxx
   ```
   Le même jeton peut être injecté en CI via
   `--dart-define=APP_CHECK_DEBUG_TOKEN=<jeton>`.
3. Le jeton change à la réinstallation de l'app / effacement des données :
   c'est normal, il faut le re-copier.

## 2. Enregistrer le jeton dans la console Firebase

1. Console Firebase → **Exécution de l'app** (App Check) → onglet **Applications**.
2. Carte de l'app concernée (Android `com.fixnow.app`, iOS `com.fixnow.app`) →
   menu ⋮ → **Gérer les jetons de débogage**.
3. Coller le jeton récupéré à l'étape 1 → **Enregistrer**.
4. Relancer l'app : les requêtes Firestore/Storage doivent passer sans
   avertissement « client non valide » dans la console.

## 3. Activer l'enforcement en production (sans casser l'app)

L'enforcement refuse les requêtes sans jeton App Check valide. Procédure
progressive recommandée :

1. **Pré-vérification** : confirmer que tous les utilisateurs sont sur une
   version de l'app **avec App Check activé** (Play Integrity / DeviceCheck).
   Les versions antérieures ne peuvent pas passer l'enforcement.
2. **Mesurer d'abord** : dans la console App Check, surveiller les métriques
   « requêtes vérifiées / non vérifiées » pendant quelques jours. Tant que
   les requêtes vérifiées ne sont pas ≈ 100 % du trafic légitime, ne pas
   activer l'enforcement.
3. **Activer doucement** : Console → App Check → carte de l'app →
   **Enforcement** → activer d'abord **Firestore**, observer 24-48 h, puis
   **Storage**, puis **Cloud Functions** (avec Functions, les appels refusés
   renvoient `failed-precondition`).
4. **Plan de repli** : en cas de blocage généralisé, désactiver l'enforcement
   depuis la console — l'effet est immédiat, aucune ressource à redéployer.

### Pièges connus

- **Play Integrity** exige que l'app soit signée par le certificat déclaré
  dans la console (voir `docs/FIREBASE_SETUP.md` §1 pour les SHA-1/SHA-256).
- Anciens appareils sans Google Play Services : Play Integrity peut échouer ;
  le volume est normalement négligeable — à surveiller dans les métriques.
- Les **émulateurs** et les tests ne passent pas l'enforcement : toujours
  tester l'enforcement sur un build release réel, jamais en dev.
