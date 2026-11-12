# Tâche 4.2 — Activation de Sentry

**Statut :** ✅ Complété

## Résumé

Sentry Flutter a été activé dans l'application MAASGA Mobile.

## Modifications effectuées

### `pubspec.yaml`
- Ligne commentée `# sentry_flutter: ^8.0.0 # Temporairement désactivé - problème de compatibilité Kotlin` remplacée par :
  ```yaml
  sentry_flutter: ^9.30.1
  ```

### `lib/main.dart`
- Ajout de l'import : `import 'package:sentry_flutter/sentry_flutter.dart';`
- Suppression du commentaire de l'ancien import `sentry_service.dart`
- Remplacement du bloc Sentry commenté + `runApp(...)` séparé par :
  ```dart
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
      options.tracesSampleRate = kDebugMode ? 0.0 : 0.1;
      options.environment = kDebugMode ? 'debug' : 'release';
    },
    appRunner: () => runApp(const ProviderScope(child: MaasgaMobileApp())),
  );
  ```

## Version installée

- `sentry_flutter: 9.30.1` (dernière version stable compatible Dart ≥ 3.5.0)
- Version 10.0.0 non utilisée car elle requiert Dart ≥ 3.12.0 (au-dessus de `sdk: ^3.9.2` du projet)

## Vérification

- `flutter pub get` : ✅ succès, 7 dépendances ajoutées/modifiées
- `flutter analyze lib/` : ✅ aucune erreur

## Configuration DSN

Le DSN Sentry est lu depuis la variable d'environnement de build `SENTRY_DSN` via `const String.fromEnvironment(...)`.

Pour l'injecter à la compilation :
```bash
flutter build apk --dart-define=SENTRY_DSN=https://xxx@sentry.io/yyy
```

En l'absence de DSN (valeur vide), Sentry fonctionne en mode silencieux sans transmettre de données.

## Notes

- `tracesSampleRate` est à `0.0` en debug (pas de collecte de perf en dev) et `0.1` en release (10 % des transactions).
- `kDebugMode` est déjà disponible via `package:flutter/foundation.dart` importé dans `main.dart`.
- Aucun fichier `app_theme.dart`, `maasga_tokens.dart` ni fichier auth n'a été modifié.
