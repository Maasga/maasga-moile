# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

MAASGA Mobile — application Flutter **Android** (confort climatique : catalogue,
rendez-vous, simulateur BTU, espace client, maintenance). Le code, les
commentaires, les messages de commit et les chaînes d'interface sont en
**français** — s'y conformer.

## Commandes

```bash
flutter pub get

# Lancer (les valeurs par défaut de Env suffisent en dev)
flutter run

# Les trois gates de la CI, dans l'ordre où elle les exécute
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

**Formatage : utiliser `dart format lib test`, pas `dart format .`** — la CI
lance bien `dart format .` mais depuis un clone neuf ; en local, ce point
d'entrée échoue sur des artefacts périmés de `build/` (chemin Windows trop
long). Le gate est à 80 colonnes.

**`flutter analyze` est un gate strict** : la CI casse aussi sur les
diagnostics de niveau *info* (lints cosmétiques compris). « No issues found »
est le seul résultat acceptable.

Un seul test / un seul cas :

```bash
flutter test test/widgets_test.dart
flutter test --plain-name "affiche son label"
```

Le paquet s'appelle `app` (`pubspec.yaml`), donc les imports absolus depuis les
tests sont `package:app/features/...`.

### Build release

```bash
# Sans keystore : obligatoire, sinon Gradle échoue volontairement
MAASGA_ALLOW_DEBUG_SIGNING=true flutter build apk --release
```

`android/app/build.gradle.kts` **lève une `GradleException`** si
`android/key.properties` est absent, au lieu de retomber en silence sur la clé
debug. `MAASGA_ALLOW_DEBUG_SIGNING=true` est la porte de sortie explicite pour
un artefact jetable (CI, test de compilation) — un tel APK ne doit jamais être
distribué. R8 (`isMinifyEnabled`) est actif en release : c'est le seul build qui
exerce la minification, une règle ProGuard manquante ne se voit pas en debug.

CI : GitHub Actions, Flutter **3.41.7**, Java **21**, sur push/PR vers `main`.

## Architecture

Découpage *feature-first* : `lib/features/<feature>/{data,domain,presentation}`,
avec `lib/core` (config, réseau), `lib/app` (router, thème) et `lib/shared`
(widgets, services, design tokens).

### Chaîne de providers asynchrones (Riverpod 3.x)

Le réseau n'est disponible qu'au terme d'une chaîne de `FutureProvider`, parce
que le cookie jar persistant exige un accès disque :

```
cookieJarProvider → dioProvider → <feature>RepositoryProvider → <données>Provider
```

**Tout nouveau repository doit suivre ce schéma** : un `FutureProvider` qui
`await ref.watch(dioProvider.future)`. Un `Provider` synchrone ne peut pas
obtenir de `Dio`.

### Router (`lib/app/router/app_router.dart`)

Table de routes plate et unique, chaque page passée par `_buildPage` pour une
`SharedAxisTransition` homogène. La garde d'authentification est le couple
`_protectedRoutes` + `redirect`, réévalué par `_AuthRefreshNotifier` à chaque
changement d'état Firebase ; la destination d'origine est conservée en
`?from=`.

Deux pièges :

- **Des routes sont dupliquées en français et en anglais** (`/catalogue` et
  `/catalog`, `/rendez-vous` et `/rdv`, `/espace-client` et `/client-space`).
  Toute liste de routes (protection, liste blanche, navigation basse) doit
  traiter les deux alias.
- `_currentUser()` et `_authStateChanges()` encapsulent Firebase dans un
  `try/catch` **à dessein** : sans ce filet, les tests widget (aucun binding
  Firebase) ne pourraient pas même construire le router.

### Navigation d'origine serveur : liste blanche obligatoire

Une destination fournie par le serveur n'est jamais injectée telle quelle dans
le router. Deux listes blanches appliquent cette règle et doivent rester
cohérentes entre elles :

- `PushService._allowedRoutes` — champ `data['route']` d'un push
- `_PromoBannerState._allowedTargets` — `target_page` de `/api/mobile/banners`

`/catalog/product` en est **volontairement exclu** : cette route attend un
`Product` typé en `extra` et provoquerait un plantage de cast sans argument.
Ajouter une route à l'app implique de décider si elle entre dans ces listes.

### Authentification (Firebase Auth)

E-mail/mot de passe, Google Sign-In, et comptes « téléphone ». Les numéros
burkinabè (`+226`, 8 chiffres) n'utilisent **pas** l'OTP SMS — impossible hors
projet Firebase vérifié — mais un **e-mail synthétique**
`+226XXXXXXXX@maasga.app` (`auth_repository.dart`). Conséquences assumées : le
numéro n'est pas vérifié, et ces comptes n'ont pas de réinitialisation de mot
de passe automatique puisque l'adresse n'a pas de boîte de réception.

### Réseau et backend

`lib/core/network/api_client.dart` : Dio, `baseUrl` = `Env.apiBaseUrl`, cookie
jar persistant, et un intercepteur qui pose le token Firebase ID en
`Authorization: Bearer`.

**Le backend est un worker Cloudflare hors de ce dépôt**
(`maasga-website.pages.dev`). Les endpoints sont sous `/api/mobile/*`, à trois
exceptions près : `/api/client/push-token`, `/api/simulateur/btu`,
`/api/maintenance/invoice/{id}`. Un endpoint manquant ne se remarque pas
toujours — `PushService._registerToken` avale son exception, donc un
`/api/client/push-token` absent signifie zéro token FCM enregistré, sans
erreur visible.

### Configuration de build

Tout passe par `String.fromEnvironment` dans **`lib/core/config/env.dart`**, et
nulle part ailleurs : `API_BASE_URL`, `GOOGLE_WEB_CLIENT_ID`, `APP_VERSION`.
`googleWebClientId` doit rester aligné sur `oauth_client` de
`android/app/google-services.json`, et `appVersion` sur `version:` de
`pubspec.yaml`.

`google-services.json` et `lib/core/config/firebase_options.dart` **sont
versionnés** — sans eux, ni un clone neuf ni le job `build-apk` ne compile. Ils
ne contiennent que des identifiants client, déjà en clair dans tout APK
distribué ; la protection réelle est la restriction des clés côté Google Cloud
Console.

### Push (`lib/features/notifications/data/push_service.dart`)

`firebaseMessagingBackgroundHandler` doit rester une fonction **top-level**
annotée `@pragma('vm:entry-point')`, enregistrée depuis `main()` **avant**
`runApp` : c'est le seul moment où Firebase peut rattacher l'isolate de fond.
Déplacer cet enregistrement fait perdre silencieusement les pushs reçus
application fermée. `PushService.initialize` est idempotent par `_listenersAttached`,
sans quoi chaque reconnexion dupliquerait les notifications affichées.

### Interface

`MaasgaShell` (app bar + dégradé de page + navigation basse déduite de la route
courante) est l'enveloppe standard d'un écran ; passer explicitement
`bottomNavigationBar: MainBottomNav(currentPath: ...)` quand la route ne doit
pas être déduite. Les couleurs et dégradés viennent de
`lib/shared/design_tokens/maasga_tokens.dart`, le thème de
`lib/app/theme/app_theme.dart`, et le mode clair/sombre du
`themeControllerProvider`.

## Règles propres à ce code

- **Ne jamais fabriquer de données produit.** `catalog_repository.dart` ne
  dérive une fiche technique ou un prix barré que de ce que le serveur renvoie
  réellement. Les blocs de repli précédents affirmaient « Gaz R32 », « A+++ »
  ou une remise de −17 % sur *tous* les produits : allégations commerciales
  fausses, et risque juridique sur un devis. Les commentaires du fichier le
  documentent — ne pas réintroduire ce comportement.
- **Le total de commande n'est pas fiable côté client.** `checkout_screen.dart`
  envoie `total_price` *et* le détail `items[]` ; le worker doit ignorer le
  premier et recalculer. À garder en tête pour toute évolution du panier.
- Les commentaires de ce dépôt expliquent le **pourquoi** et les alternatives
  écartées, pas le quoi. Conserver cette densité en modifiant du code annoté.
- **Paiement en ligne : retiré.** La commande est enregistrée, le paiement se
  convient hors application (`order_confirmation_screen.dart`).
- **Android uniquement.** `web/` et `windows/` sont des scaffolds Flutter jamais
  testés ; il n'y a pas de dossier `ios/`.

`IMPLEMENTATION_BACKLOG.md` tient la liste à jour de ce qui reste — le lire
avant de proposer du travail, et le mettre à jour en en traitant un point.
