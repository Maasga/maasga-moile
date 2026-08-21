# MAASGA Mobile

Application mobile Flutter (Android V1) de MAASGA — confort climatique : catalogue
produits, prise de rendez-vous, simulateur BTU, espace client et maintenance,
alignée sur le backend web MAASGA existant. Le paiement en ligne a été retiré :
la commande est enregistrée, le règlement se convient hors application.

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

Sans `android/key.properties`, une build release **échoue volontairement**. Elle ne
retombe pas en silence sur la clé debug : cela produirait un APK refusé par le Play
Store, et surtout installable par-dessus n'importe quelle application signée avec la
clé debug publique du SDK. Pour un artefact jetable (CI, simple test de compilation) :

```bash
MAASGA_ALLOW_DEBUG_SIGNING=true flutter build apk --release
```

L'APK ainsi produit ne doit pas être distribué.

> ⚠️ La clé Google Maps du `AndroidManifest.xml` doit être restreinte
> (package `com.maasga.app` + empreinte SHA-1) dans Google Cloud Console.

## Tests & qualité

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

En local, cibler `lib test` et non `.` : la CI lance bien `dart format .`, mais
depuis un clone neuf — ici ce point d'entrée échoue sur les artefacts périmés de
`build/` (chemin Windows trop long). `flutter analyze` est un gate strict : la CI
casse aussi sur les diagnostics de niveau *info*.

## CI

GitHub Actions (`.github/workflows/ci.yml`) sur chaque push/PR vers `main` :
`dart format` (gate) · `flutter analyze` · `flutter test` · build APK debug
(artefact) **et build APK release**. Cette dernière est la seule à exercer R8,
donc la seule à casser sur une règle ProGuard manquante.

## Backlog / améliorations

`IMPLEMENTATION_BACKLOG.md` tient la liste à jour. En résumé : dépendances à
jour, CI en place, R8/ProGuard déjà actif en release. Restent notamment la QA
d'un APK release signé, la restriction de la clé Google Maps, le recalcul du
total de commande côté worker, et l'élargissement de la couverture de tests.
