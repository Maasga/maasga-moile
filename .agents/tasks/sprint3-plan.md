# Plan d'implémentation — Sprint 3 MAASGA Mobile

> Langue : français · Architecture : Riverpod 3, GoRouter 17, Dio 5, feature-first
> Contrainte absolue : NE PAS modifier `app_theme.dart`, `maasga_tokens.dart`, ni aucun fichier `auth`.
> Toutes les couleurs via `context.maasga`. Objectif final : `flutter analyze lib/` → zéro erreur.

---

## Dépendances inter-items

```
3.1-a → 3.1-b → 3.1-c → 3.1-d
3.2-a → 3.2-b → 3.2-c
3.3-a → 3.3-b
3.4 (indépendant, peut se faire en parallèle avec 3.2 et 3.3)
pubspec (item 0) doit être fait EN PREMIER — bloque flutter_rating_bar et share_plus
```

---

## Risques identifiés

| Risque | Détail | Mitigation |
|--------|--------|-----------|
| **Product serialization (Récents)** | `Product` n'a pas de `toJson()`. Sérialiser dans SharedPreferences nécessite de l'écrire manuellement sans oublier les champs `List<String>` et `Map<String,String>`. | Écrire `Product.toJson()` dans `product.dart` en miroir exact de `fromJson`, tester avec un produit réel en débogueur. |
| **FamilyAsyncNotifier (Avis)** | Riverpod 3 remplace `StateNotifierProvider.family` par `AsyncNotifier` + `.family`. Le generics est `AsyncNotifier<T>` avec `Arg` en paramètre de `build(Arg arg)`. Ne pas confondre avec `FamilyAsyncNotifier` (Riverpod < 2). | Utiliser le pattern `AsyncNotifier` + `autoDispose.family` tel que démontré dans `catalogRepositoryProvider`. |
| **ConsumerWidget pour product_list_card** | `ProductListCard` est actuellement `StatelessWidget`. Ajouter l'icône cœur et l'étoile implique de lire des providers → il faut passer en `ConsumerWidget`. La signature du constructeur ne change pas (pas de breaking change pour les appelants). | Changer uniquement `extends StatelessWidget` → `extends ConsumerWidget` et ajouter `WidgetRef ref` au `build`. |
| **flutter_rating_bar API** | L'API v4 utilise `RatingBar.builder` + `RatingBarIndicator` pour la lecture seule. Ne pas utiliser l'ancien `RatingBar()` déprécié. | Vérifier la doc pub.dev v4.0.1 avant l'écriture du BottomSheet. |
| **SharedPreferences clé maasga_favorites vs maasga_recent_products** | Les deux notifiers partagent `SharedPreferences`. Bien utiliser des clés distinctes et non liées à l'UID (les favoris sont locaux, pas compte-liés dans ce sprint). | Déclarer les clés comme constantes privées en haut de chaque notifier. |

---

## Item 0 — Ajouter les packages dans pubspec.yaml

**Quoi :** Ajouter `flutter_rating_bar: ^4.0.1` et `share_plus: ^10.1.4` dans la section `dependencies`.
Ne pas modifier les autres dépendances existantes.

**Fichiers :** `pubspec.yaml`

**Vérification :**
```
flutter pub get
```
Résultat attendu : résolution sans conflit, `pubspec.lock` mis à jour.

---

## Item 1 — Créer le domaine et le dépôt des avis (3.1-a)

**Quoi :** Créer deux fichiers :

1. `lib/features/catalog/domain/product_review.dart` — classe immuable `ProductReview` avec les champs :
   - `final String id`
   - `final int productId`
   - `final String authorName`
   - `final double rating` (1.0–5.0)
   - `final String comment`
   - `final DateTime createdAt`
   - Constructeur `const`, factory `ProductReview.fromJson(Map<String,dynamic>)`, méthode `toJson()`.

2. `lib/features/catalog/data/review_repository.dart` — classe `ReviewRepository(Dio _dio)` avec :
   - `Future<List<ProductReview>> getReviews(int productId)` : GET `/api/mobile/products/$productId/reviews`, fallback silencieux (try/catch retourne `[]`).
   - `Future<void> submitReview(int productId, double rating, String comment)` : POST `/api/mobile/products/$productId/reviews`, fallback silencieux (try/catch loggue sans rethrow).
   - Provider `reviewRepositoryProvider` de type `FutureProvider<ReviewRepository>` qui watch `dioProvider` (même pattern que `catalogRepositoryProvider`).

**Fichiers :**
- `lib/features/catalog/domain/product_review.dart` ← créer
- `lib/features/catalog/data/review_repository.dart` ← créer

**Vérification :**
```
flutter analyze lib/features/catalog/
```
Zéro erreur ou warning.

---

## Item 2 — Créer les providers d'avis (3.1-b)

**Quoi :** Créer `lib/features/catalog/presentation/review_providers.dart` avec :

- `reviewsProvider` : `AsyncNotifier<List<ProductReview>>` en `.family(int productId)` (autoDispose).
  - `build(int productId)` appelle `reviewRepositoryProvider` → `getReviews(productId)`.
  - Méthode `submit(double rating, String comment)` : appelle `submitReview`, puis force le rechargement via `ref.invalidateSelf()`.

- `averageRatingProvider` : `Provider.family<double, int>` (autoDispose) qui watch `reviewsProvider(productId)` et calcule la moyenne (retourne 0.0 si vide ou en chargement).

**Décision d'architecture :** On utilise `AsyncNotifier` (et non `FutureProvider`) pour `reviewsProvider` afin de disposer d'une méthode `submit` qui invalide le cache. C'est le pattern recommandé en Riverpod 3 pour les listes mutables.

**Fichiers :**
- `lib/features/catalog/presentation/review_providers.dart` ← créer

**Vérification :**
```
flutter analyze lib/features/catalog/presentation/review_providers.dart
```
Zéro erreur.

---

## Item 3 — Ajouter la serialisation à Product (prérequis Récents — 3.3-prérequis)

**Quoi :** Ajouter la méthode `Map<String, dynamic> toJson()` à la classe `Product` dans `product.dart`.
La méthode doit être le miroir exact de `fromJson` : tous les champs présents, listes encodées telles quelles (pas de jsonEncode intermédiaire — SharedPreferences stockera le JSON de la liste via `jsonEncode(product.toJson())`).

**Décision :** On ajoute `toJson` directement dans la classe domain (pas dans un mixin séparé) pour rester cohérent avec la `fromJson` déjà présente dans le même fichier.

**Fichiers :**
- `lib/features/catalog/domain/product.dart` ← modifier (ajouter méthode `toJson`)

**Vérification :**
```
flutter analyze lib/features/catalog/domain/product.dart
```
Zéro erreur.

---

## Item 4 — Créer le FavoritesNotifier (3.2-a)

**Quoi :** Créer `lib/features/catalog/presentation/favorites_notifier.dart` avec :

- Classe `FavoritesNotifier extends Notifier<List<int>>` (stocke les IDs produits).
  - Clé SharedPreferences : `maasga_favorites`.
  - `build()` : lit synchroniquement `SharedPreferences` via `userPrefsServiceProvider` (pattern synchrone avec `ref.watch` + null-check, ou directement `SharedPreferences.getInstance()` dans `build` via `ref.read`). **Décision :** appel direct `SharedPreferences.getInstance()` dans `build()` via `Notifier.build()` qui peut être async (Riverpod 3 supporte `AsyncNotifier` pour ça) → utiliser `AsyncNotifier<List<int>>` pour la persistance initiale.
  - `toggle(int productId)` : ajoute ou retire l'id, persiste la liste dans SharedPreferences.
  - `contains(int productId)` : bool helper.
  - Provider : `favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, List<int>>(FavoritesNotifier.new)`.

**Note sur la décision AsyncNotifier vs Notifier :** `Notifier.build()` est synchrone. Charger SharedPreferences est async. On utilise donc `AsyncNotifier<List<int>>` pour que l'état initial soit `AsyncValue<List<int>>`. Les widgets gèrent `.when(data:...)` ou utilisent `.valueOrNull ?? []`.

**Fichiers :**
- `lib/features/catalog/presentation/favorites_notifier.dart` ← créer

**Vérification :**
```
flutter analyze lib/features/catalog/presentation/favorites_notifier.dart
```

---

## Item 5 — Créer le RecentProductsNotifier (3.3-a)

**Quoi :** Créer `lib/features/catalog/presentation/recent_products_notifier.dart` avec :

- Classe `RecentProductsNotifier extends AsyncNotifier<List<Product>>`.
  - Clé SharedPreferences : `maasga_recent_products`.
  - `build()` : lit SharedPreferences, désérialise la liste JSON de `Product` via `Product.fromJson` (dépend de l'item 3).
  - `addRecent(Product product)` : insère en tête de liste, supprime les doublons (par `id`), tronque à 5 éléments max, persiste via `jsonEncode(list.map((p) => p.toJson()).toList())`.
  - Provider : `recentProductsProvider = AsyncNotifierProvider<RecentProductsNotifier, List<Product>>(RecentProductsNotifier.new)`.

**Fichiers :**
- `lib/features/catalog/presentation/recent_products_notifier.dart` ← créer

**Vérification :**
```
flutter analyze lib/features/catalog/presentation/recent_products_notifier.dart
```

---

## Item 6 — Mettre à jour product_list_card.dart (3.1-d + 3.2-c)

**Quoi :** Passer `ProductListCard` de `StatelessWidget` à `ConsumerWidget` (ajouter `WidgetRef ref` au `build`). Ajouter dans la zone "Infos (droite)" :

1. **Icône cœur :** En haut à droite de la colonne droite, `IconButton` de taille 20, icône `Icons.favorite` / `Icons.favorite_border`, couleur `palette.danger` si favori sinon `palette.textMuted`. Appelle `ref.read(favoritesProvider.notifier).toggle(product.id)`. Gère l'état async avec `.when(data: (ids) => ids.contains(product.id), ...)` → `false` par défaut.

2. **Icône étoile + note :** Juste sous le nom du produit, une `Row` avec `Icon(Icons.star, size: 12, color: palette.warning)` + `Text` de la note moyenne. Utilise `ref.watch(averageRatingProvider(product.id))`. Si la note est 0.0, masquer la ligne entièrement (`if (avg > 0)`).

**Fichiers :**
- `lib/features/catalog/presentation/product_list_card.dart` ← modifier

**Vérification :**
```
flutter analyze lib/features/catalog/presentation/product_list_card.dart
```

---

## Item 7 — Mettre à jour product_detail_screen.dart — Favoris, Récents, Partage, Avis (3.1-c + 3.2-b + 3.3-b + 3.4)

**Quoi :** Quatre modifications dans `product_detail_screen.dart` :

### 7-A : Favoris (remplacer `_isFavorite` local)
- Supprimer `bool _isFavorite = false;` et `_toggleFavorite()`.
- Dans `_buildProductInfo()`, lire `ref.watch(favoritesProvider)` → `.when(data: (ids) => ids.contains(widget.product.id), ...)`.
- Le `GestureDetector` du cœur appelle `ref.read(favoritesProvider.notifier).toggle(widget.product.id)`.
- Garder le `SnackBar` existant (message "Ajouté/Retiré des favoris").

### 7-B : Récents (initState)
- Transformer `_ProductDetailScreenState` : dans `initState()`, appeler `ref.read(recentProductsProvider.notifier).addRecent(widget.product)` via `WidgetsBinding.instance.addPostFrameCallback((_) { ... })` pour éviter l'appel pendant le build.

### 7-C : Partage (SliverAppBar actions)
- Dans `_buildAppBar()`, ajouter avant le bouton de comparaison dans `actions` un second `_buildCircleButton` avec `icon: Icons.share_outlined` et `onTap: _shareProduct`.
- Méthode `_shareProduct()` : `Share.share('${widget.product.name} — ${widget.product.brand}\n${PriceFormatter.format(widget.product.price)} FCFA\nDisponible sur MAASGA')`.
- Ajouter l'import `import 'package:share_plus/share_plus.dart';`.

### 7-D : Section Avis (après `_buildTechnicalBrief`)
- Ajouter `_buildReviewsSection()` dans le `CustomScrollView` entre `_buildTechnicalBrief()` et `_buildFullSheetButton()`.
- `_buildReviewsSection()` retourne un `SliverToBoxAdapter` contenant :
  - Titre "AVIS CLIENTS" (même style que "FICHE TECHNIQUE").
  - `ref.watch(reviewsProvider(widget.product.id))`.when(...)` : loading → `CircularProgressIndicator`, error → texte discret "Impossible de charger les avis", data → liste des avis (max 3 affichés) avec pour chaque avis : nom auteur, étoiles via `RatingBarIndicator` (flutter_rating_bar), commentaire, date.
  - Bouton "Laisser un avis" visible uniquement si l'utilisateur est connecté : `ref.watch(authUserProvider).value != null`. Appelle `_showReviewSheet()`.
- Méthode `_showReviewSheet()` : `showModalBottomSheet` avec un formulaire contenant `RatingBar.builder` (initialRating 0, minRating 1, itemCount 5) + `TextField` commentaire + bouton Soumettre qui appelle `ref.read(reviewsProvider(widget.product.id).notifier).submit(rating, comment)`.

**Fichiers :**
- `lib/features/catalog/presentation/product_detail_screen.dart` ← modifier

**Vérification :**
```
flutter analyze lib/features/catalog/presentation/product_detail_screen.dart
```

---

## Item 8 — Mettre à jour home_screen.dart — Favoris et Récents (3.2-c + 3.3-b)

**Quoi :** Ajouter deux sections dans `home_screen.dart` dans `_HomeScreenState.build()`, dans la `Column` du `SingleChildScrollView` :

### Section "Mes Favoris"
- Après `const PromoBanner()` et avant `_InnovationsSection`.
- Widget `_FavoritesSection` (nouveau `ConsumerWidget` privé dans le même fichier).
- Lit `ref.watch(favoritesProvider)` et `ref.watch(productsProvider)` pour croiser les IDs avec les produits disponibles.
- Si `favoritesIds.isEmpty` → ne rien afficher (return `const SizedBox.shrink()`).
- Sinon : titre "Mes Favoris" + `TextButton("Voir tout")` + carrousel horizontal `SizedBox(height: 160)` + `ListView.builder` scrollDirection horizontal avec des `_ProductCard` menant vers `/product/detail` (push avec l'objet produit).

### Section "Récemment consultés"
- Avant `_InnovationsSection` (donc après Favoris).
- Widget `_RecentProductsSection` (nouveau `ConsumerWidget` privé dans le même fichier).
- Lit `ref.watch(recentProductsProvider)`.
- Si la liste est vide → `const SizedBox.shrink()`.
- Sinon : titre "Récemment consultés" + carrousel horizontal identique au widget Favoris.

**Note de navigation :** Les cartes dans ces carrousels doivent utiliser `context.push('/product/${p.id}', extra: p)` ou le pattern GoRouter existant pour ouvrir `product_detail_screen`. Vérifier le router avant d'écrire pour utiliser la bonne route.

**Fichiers :**
- `lib/features/home/presentation/home_screen.dart` ← modifier
- `lib/app/router/app_router.dart` ← lire pour vérifier la route produit existante (ne modifier que si nécessaire)

**Vérification :**
```
flutter analyze lib/features/home/presentation/home_screen.dart
```

---

## Item 9 — Vérification globale finale

**Quoi :** Lancer l'analyse complète du projet et corriger toute erreur résiduelle.

**Fichiers :** Tous les fichiers modifiés ci-dessus.

**Vérification :**
```
flutter analyze lib/
```
Résultat attendu : `No issues found!`

---

## Récapitulatif des fichiers

| Fichier | Action |
|---------|--------|
| `pubspec.yaml` | Modifier — ajouter 2 packages |
| `lib/features/catalog/domain/product.dart` | Modifier — ajouter `toJson()` |
| `lib/features/catalog/domain/product_review.dart` | Créer |
| `lib/features/catalog/data/review_repository.dart` | Créer |
| `lib/features/catalog/presentation/review_providers.dart` | Créer |
| `lib/features/catalog/presentation/favorites_notifier.dart` | Créer |
| `lib/features/catalog/presentation/recent_products_notifier.dart` | Créer |
| `lib/features/catalog/presentation/product_list_card.dart` | Modifier — ConsumerWidget + cœur + étoile |
| `lib/features/catalog/presentation/product_detail_screen.dart` | Modifier — favoris + récents + partage + avis |
| `lib/features/home/presentation/home_screen.dart` | Modifier — sections Favoris + Récents |

**Fichiers à NE PAS toucher :** `app_theme.dart`, `maasga_tokens.dart`, tout fichier sous `features/auth/`.
