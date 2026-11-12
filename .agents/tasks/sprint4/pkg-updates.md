# Tâche 4.1 — Mise à jour des packages `in_app_review` et `image_picker`

## Versions choisies

| Package        | Ancienne version | Nouvelle version | Source                        |
|----------------|-----------------|-----------------|-------------------------------|
| `in_app_review` | `^2.0.0`        | `^2.0.12`       | pub.dev API (publiée 2026-05-15) |
| `image_picker`  | `^1.2.0`        | `^1.2.4`        | pub.dev API (publiée 2026-10-06) |

## Packages NON modifiés (contrainte)

- `firebase_core`, `firebase_auth`, `firebase_messaging`, `firebase_analytics`
- `flutter_riverpod`, `go_router`, `dio`

## Résultat de `flutter pub get`

- Résolution réussie.
- `image_picker` passé de 1.2.3 → **1.2.4** (la lockfile précédente était sur 1.2.3).
- `in_app_review` résolu à **2.0.12**.

## Résultat de `flutter analyze lib/`

```
No issues found! (ran in 77.6s)
```

Zéro erreur, zéro warning.

## Fichiers modifiés

- `pubspec.yaml` : mise à jour des contraintes de version pour `in_app_review` et `image_picker`.
