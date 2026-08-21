# MAASGA Mobile

Application mobile Flutter (Android V1) de MAASGA — confort climatique : catalogue
produits, prise de rendez-vous, simulateur BTU, espace client, maintenance et
paiement, alignée sur le backend web MAASGA existant.

## Stack

- **Flutter** (Dart, SDK `^3.9.2`) — cible principale **Android**
- **Riverpod** (état), **go_router** (navigation), **Dio** + cookie jar (réseau)
- **Firebase Auth** (session, token ID en `Bearer`), **Firebase Messaging** (push)
- **Google Maps / Geolocator**, **Google Sign-In**, génération **PDF**

## Démarrage

```bash
flutter pub get
flutter run                 # appareil / émulateur Android
```

### Configuration (build)

Les valeurs sensibles/environnement passent par `--dart-define` (voir
`lib/core/config/env.dart`) :

```bash
flutter run \
  --dart-define=API_BASE_URL=https://maasga-website.pages.dev \
  --dart-define=GOOGLE_WEB_CLIENT_ID=... \
  --dart-define=APP_VERSION=1.0.0
```

## Build release signé

1. Générer un keystore :
   ```bash
   keytool -genkey -v -keystore ~/maasga-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Copier `android/key.properties.example` → `android/key.properties` (non versionné)
   et renseigner les valeurs.
3. `flutter build appbundle --release`

Sans `android/key.properties`, les builds release retombent sur les clés **debug**
(dev local uniquement, non publiable sur le Play Store).

> ⚠️ La clé Google Maps du `AndroidManifest.xml` doit être restreinte
> (package `com.maasga.app` + empreinte SHA-1) dans Google Cloud Console.

## Tests & qualité

```bash
flutter analyze
flutter test
```

## CI

GitHub Actions (`.github/workflows/ci.yml`) sur chaque push/PR vers `main` :
`dart format` (gate) · `flutter analyze` · `flutter test` · build APK debug (artefact).

## Backlog / améliorations

`IMPLEMENTATION_BACKLOG.md` tient la liste à jour. En résumé : dépendances à
jour, CI en place, R8/ProGuard déjà actif en release. Restent notamment la QA
d'un APK release signé, la restriction de la clé Google Maps, le recalcul du
total de commande côté worker, et l'élargissement de la couverture de tests.
