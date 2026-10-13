# Tâche 4.4 — Nettoyage des `debugPrint` hors catch

## Date
2026-10-13

## Règle appliquée
Les `debugPrint` dans des blocs `catch` sont conservés tels quels (utiles pour le débogage).  
Les `debugPrint` sur le chemin nominal (hors catch) ont été conditionnés avec `if (kDebugMode)`.

## Fichiers inspectés sans modification

| Fichier | Raison |
|---------|--------|
| `lib/features/catalog/data/review_repository.dart` | Tous les `debugPrint` sont dans des blocs `catch` |
| `lib/core/network/api_client.dart` | Tous les `debugPrint` sont déjà sous `if (kDebugMode)` dans `onError` |
| `lib/features/client_space/data/client_dashboard_repository.dart` | `debugPrint` nominaux déjà sous `kDebugMode` ; seul `updateProfile` est dans un `catch` → conservé |
| `lib/features/notifications/data/push_service.dart` | Tous les `debugPrint` déjà sous `if (kDebugMode)` |
| `lib/features/auth/presentation/auth_controller.dart` | Fichier auth — exempté par contrainte |
| `lib/features/auth/presentation/whatsapp_gate.dart` | Fichier auth — exempté par contrainte |
| `lib/features/auth/data/auth_repository.dart` | Fichier auth — exempté par contrainte |

## Fichiers modifiés

### 1. `lib/features/catalog/data/catalog_repository.dart`
- **3 `debugPrint` sur chemin nominal** dans `getProducts()` conditionnés avec `if (kDebugMode)` :
  - `📦 Chargement des produits depuis /api/mobile/products`
  - `📦 Réponse API : ${list.length} produits reçus`
  - `📦 Produits normalisés : ${products.length} produits`

### 2. `lib/features/cart/presentation/checkout_screen.dart`
- Import `package:flutter/foundation.dart` ajouté.
- **2 `debugPrint` sur chemin nominal** dans `_submitOrder()` conditionnés avec `if (kDebugMode)` :
  - `UserPrefsService non disponible, sauvegarde auto-remplissage ignorée`
  - `UserPrefsService non disponible, sauvegarde locale de commande ignorée`

### 3. `lib/features/client_space/presentation/client_space_screen.dart`
- Import `package:flutter/foundation.dart` ajouté.
- **1 `debugPrint` sur chemin nominal** dans `_launchWhatsApp()` conditionné avec `if (kDebugMode)` :
  - `Could not launch $url`

## Vérification
```
flutter analyze lib/
→ No issues found!
```
