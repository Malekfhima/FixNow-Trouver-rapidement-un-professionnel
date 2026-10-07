# Cloud Functions (OPTIONNEL)

⚠️ **Ce dossier n'est PAS requis pour faire fonctionner FixNow.**

FixNow tourne à 100 % sur le **plan Firebase Spark (gratuit)**. Or le
déploiement de Cloud Functions exige le plan **Blaze** (carte bancaire) —
il est donc **interdit de déployer** ce dossier dans la configuration
gratuite du projet.

## Pourquoi ce dossier existe-t-il ?

Il documente une **migration future** (voir `firestore.rules`, section
`notifications`) : déplacer la création des notifications Firestore vers des
Cloud Functions (déclencheurs `onCreate`), ce qui :

- empêcherait le client d'« inventer » un événement (anti-falsification) ;
- vérifierait le lien acteur ↔ destinataire côté serveur, sans `get()` coûteux.

## État actuel (plan Spark)

Les notifications sont créées **côté client** dans Firestore
(`lib/features/notifications/notification_helpers.dart`) et respectent les
règles `firestore.rules` (liste blanche de types, lien réel prouvé par
`get()`). Les notifications locales (app ouverte) sont gérées par
`lib/services/local_notification_service.dart`.

## Si un jour vous passez au plan Blaze

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

Ne committez jamais de clé de service account (`serviceAccountKey.json`,
variables d'environnement secrètes) : le dépôt doit rester exempt de secrets.
