# Configuration Firebase — FixNow

Ce document couvre la configuration **Google Sign-In** (Android) et
**Firebase iOS**. Il complète la section « Installation » du README.

- Projet Firebase : `fixnow-dd022`
- Package Android : `com.fixnow.app`
- Bundle iOS : `com.fixnow.app`

> Les identifiants Firebase **client** (apiKey, appId, senderId…) ne sont pas
> des secrets : la sécurité repose sur les règles Firestore/Storage + App Check.

---

## 1. Google Sign-In (Android) — SHA-1 / SHA-256

Sur Android, Google Sign-In n'échoue **silencieusement** (liste de comptes vide
ou erreur `DEVELOPER_ERROR`) que si l'empreinte du certificat de signature de
l'APK n'est pas déclarée dans Firebase. Il faut donc déclarer l'empreinte
**debug** (développement) **et release** (Play Store / build signé).

### 1.1 Keystore debug

Le keystore debug est créé par le SDK Android et se trouve par défaut dans :

| OS | Emplacement |
|---|---|
| Windows | `%USERPROFILE%\.android\debug.keystore` |
| macOS / Linux | `~/.android/debug.keystore` |

Mot de passe par défaut : `android` — alias : `androiddebugkey`.

```bash
# Windows — depuis un terminal Git Bash (le chemin Windows est accepté par keytool)
keytool -list -v \
  -alias androiddebugkey \
  -keystore "$USERPROFILE/.android/debug.keystore" \
  -storepass android -keypass android

# macOS / Linux
keytool -list -v \
  -alias androiddebugkey \
  -keystore ~/.android/debug.keystore \
  -storepass android -keypass android
```

Repérer les lignes :

```
Certificate fingerprints:
     SHA1: XX:XX:...
     SHA256: XX:XX:...
```

> Variante fiable (évite les erreurs de chemin), depuis `android/` :
> ```bash
> cd android && ./gradlew signingReport
> ```
> La task `signingReport` affiche directement SHA-1 et SHA-256 pour **tous**
> les variants (debug, release).

### 1.2 Keystore release

Le build release utilise actuellement `signingConfigs.getByName("debug")`
(placeholder, voir `android/app/build.gradle.kts`). Pour publier, il faut un
**keystore release** :

```bash
keytool -genkey -v \
  -keystore fixnow-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias fixnow
```

Puis récupérer son empreinte :

```bash
keytool -list -v -keystore fixnow-release.jks -alias fixnow
```

⚠️ **Ne commitez jamais** `fixnow-release.jks` ni les mots de passe. Placez le
fichier hors du dépôt et injectez-les via `key.properties` (ajouté à
`.gitignore`) ou les secrets CI.

### 1.3 Déclarer les empreintes dans Firebase

1. Console Firebase → ⚙️ **Paramètres du projet** → onglet **Général**.
2. Section **Vos applications** → app Android `com.fixnow.app`.
3. **Ajouter une empreinte digitale** : coller SHA-1, puis répéter avec SHA-256.
   (Déclarer les 4 : debug SHA-1, debug SHA-256, release SHA-1, release SHA-256.)
4. **Télécharger à nouveau `google-services.json`** et remplacer
   `android/app/google-services.json`.

C'est cette étape qui **peuple `oauth_client`** : sans empreinte déclarée, le
bloc reste vide (`"oauth_client": []`) et Google Sign-In ne propose aucun
compte. Après ré-ajout des empreintes :

```json
"oauth_client": [
  {
    "client_id": "1042678564340-xxxxxxxx.apps.googleusercontent.com",
    "client_type": 3
  },
  {
    "client_id": "1042678564340-yyyyyyyy.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": { "package_name": "com.fixnow.app", "certificate_hash": "..." }
  }
]
```

Il **n'y a rien à faire côté code** : le plugin `google_sign_in` lit ce fichier
au build. Vérifiez simplement qu'après une modification de
`android/app/build.gradle.kts` (`applicationId`/`namespace`) ou de la signature,
vous re-téléchargez le JSON.

> 💡 L'erreur « DEVELOPER_ERROR » / « Connexion Google impossible » après
> `signInWithGoogle()` renvoie désormais un message explicite grâce à
> `ErrorMapper` (code `google-missing-token`).

---

## 2. Configuration iOS — `GoogleService-Info.plist`

Le fichier `ios/Runner/GoogleService-Info.plist` est **absent** du dépôt. Il faut
le générer (il dépend du bundle id `com.fixnow.app`).

### 2.1 Générer le fichier

```bash
# Depuis la racine du projet
firebase login
dart pub global activate flutterfire_cli

# Configure toutes les plateformes + génère lib/firebase_options.dart,
# android/app/google-services.json et ios/Runner/GoogleService-Info.plist
flutterfire configure --project=fixnow-dd022
```

Aux questions du CLI :
- sélectionner la plateforme **ios** (et android) ;
- saisir l'identifiant de bundle **`com.fixnow.app`** pour iOS si demandé
  (création d'une nouvelle app iOS dans le projet Firebase).

### 2.2 Vérifier l'intégration dans `ios/Runner`

`flutterfire configure` doit avoir :

1. créé `ios/Runner/GoogleService-Info.plist` ;
2. **ajouté ce fichier au target `Runner`** dans `ios/Runner.xcodeproj` (il doit
   apparaître dans `Copy Bundle Resources`). Si besoin, l'ajouter à la main :
   Xcode → target `Runner` → *Build Phases* → *Copy Bundle Resources* → **+**.
3. mis à jour `ios/Runner/Info.plist` avec l'URL scheme Google Sign-In :

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- = REVERSED_CLIENT_ID de GoogleService-Info.plist
           (ex. com.googleusercontent.apps.1042678564340-xxxxxxxx) -->
      <string>REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

`REVERSED_CLIENT_ID` se lit dans `GoogleService-Info.plist` (clé
`REVERSED_CLIENT_ID`).

### 2.3 Vérifications finales iOS

- `ios/Runner/AppDelegate.swift` : déjà conforme (enregistrement des plugins via
  `GeneratedPluginRegistrant`). Rien à modifier.
- `PRODUCT_BUNDLE_IDENTIFIER` doit valoir `com.fixnow.app` (voir point 5).
- Dans Xcode, activer les capacités **Push Notifications** et **Background Modes
  → Remote notifications** (nécessaire pour FCM si iOS est ciblé).
- Activer `GoogleService-Info.plist` dans les modèles de configuration si votre
  setup Xcode utilise des `.xcconfig`.

> Sans Firebase CLI connecté, on peut aussi télécharger `GoogleService-Info.plist`
> depuis Console Firebase → Paramètres du projet → votre app iOS → **Télécharger
> le fichier de configuration**, puis le déposer dans `ios/Runner/`.
