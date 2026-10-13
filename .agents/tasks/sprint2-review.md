# Sprint 2 MAASGA Mobile — Navigation, formatage prix, sélecteur de quartier

Ce sprint consolide cinq améliorations transverses : réduction de la barre de navigation à 5 onglets avec détection automatique de la route active, extraction d'un `PriceFormatter` centralisé, remplacement du dialog `AlertDialog` de suppression panier par un SnackBar undo, centralisation du sélecteur de quartier en `QuartierSearchBottomSheet`, et ajout d'un badge panier dans la `MaasgaAppBar`. `flutter analyze` ne relève aucune erreur sur l'ensemble des fichiers modifiés.

Watch for: **confirmed** — `checkout_screen.dart` et `rdv_form_step.dart` conservent de nombreuses couleurs `Color(0xFF...)` hardcodées malgré l'objectif de suppression. **confirmed** — le code promo `DROPSYEARAND` est en clair dans `cart_screen.dart` côté client. **confirmed** — `_InnovationsSection` déclare `String Function(int)` alors que `PriceFormatter.format` accepte `num` ; l'appel fonctionne par sous-typage implicite mais l'interface est trompeuse. **confirmed** — la cloche de notifications affiche toujours un badge rouge même quand le compte est 0.

**Verdict** : NEEDS_CHANGES

---

## Vue d'ensemble

`MainBottomNav` passe de `StatefulWidget` avec `currentPath` transmis en paramètre à un `StatelessWidget` sans état explicite : l'index actif est calculé à la volée via `GoRouterState.of(context).uri.path`. La correspondance route → index couvre les alias legacy (`/catalogue`, `/rendez-vous`, `/espace-client`), cohérente avec les redirections GoRouter ajoutées en parallèle.

`PriceFormatter` est une classe utilitaire pure (constructeur privé, méthode statique) qui s'appuie sur `intl/NumberFormat` avec locale `fr_FR` et symbole `FCFA`. Elle remplace les cinq implémentations locales dispersées dans les écrans. L'interface de passage en callback dans `_InnovationsSection` (`String Function(int)`) est plus restrictive que la signature réelle (`num`), créant une friction si un prix décimal apparaît dans le catalogue.

`QuartierSearchBottomSheet` centralise la sélection de quartier dans un bottom sheet à 75 % de hauteur, avec champ de recherche filtrante et état de sélection visuel. Les deux anciens `_QuartierSearchDialog` dans `checkout_screen.dart` et `rdv_form_step.dart` ont bien été supprimés. Le widget est entièrement thémé via `context.maasga`, mais les deux fichiers consommateurs (`checkout_screen.dart` et `rdv_form_step.dart`) n'ont pas été nettoyés de leurs couleurs hardcodées dans le reste du fichier — ce qui représente l'essentiel des couleurs résiduelles du sprint.

Le SnackBar undo dans `cart_screen.dart` couvre uniquement le cas où `quantity == 1` ; au-delà d'une unité, `remove()` décrémente silencieusement. La `_showDeleteDialog` (AlertDialog) est conservée — à raison — pour le swipe `Dismissible`, qui représente une suppression totale de la ligne. La dichotomie est correcte.

---

<details>
<summary>Issues (5)</summary>

1. **Couleurs hardcodées persistantes dans checkout_screen** — `checkout_screen.dart` contient une vingtaine d'occurrences `Color(0xFF...)` nouvelles dans les champs texte, `_buildInputDecoration`, le bloc info et le step-by-step. Migrer vers `palette.*` ou les constantes `MaasgaTokens`.
2. **Couleurs hardcodées persistantes dans rdv_form_step** — `rdv_form_step.dart` contient `primaryBlue`, `Color(0xFF1A1A1A)`, `Color(0xFFD8EAFB)`, `Color(0xFF9E9E9E)` etc. dans l'ensemble du formulaire. Même correction requise.
3. **Code promo en clair côté client** — `_validPromoCode = 'DROPSYEARAND'` est compilé dans le binaire. N'importe qui peut l'extraire. Le code promo doit être validé côté serveur uniquement.
4. **Type callback `String Function(int)` vs `PriceFormatter.format(num)`** — `_InnovationsSection.formatPrice` est typé `String Function(int)`, mais `PriceFormatter.format` accepte `num`. L'appel `formatPrice(p.price)` fonctionne si `price` est `int`, mais l'interface promet moins que ce qu'elle reçoit. Aligner sur `String Function(num)` pour refléter la réalité.
5. **Badge notifications toujours visible à 0** — `MaasgaAppBar` affiche le badge rouge sur la cloche indépendamment de `notificationsCount`. Ajouter `if (notificationsCount > 0)` en symétrie avec le guard déjà présent sur le badge panier.

</details>

<details>
<summary>Détails</summary>

### Couleurs hardcodées dans checkout_screen et rdv_form_step

L'objectif du sprint était de supprimer les `Color(0xFF...)` hardcodées des fichiers modifiés. `QuartierSearchBottomSheet` est bien entièrement thémé via `context.maasga`. En revanche, les deux fichiers consommateurs n'ont reçu que la suppression du `_QuartierSearchDialog` — le reste du formulaire (textes, bordures, icônes, backgrounds) reste câblé en dur. **confirmed** par grep.

Dans `checkout_screen.dart` : `Color(0xFF1A1A1A)` pour les champs texte, `Color(0xFFF0F4FF)` / `Color(0xFFD8EAFB)` pour le bloc info, `Color(0xFF1B3A8D)` dans `_buildInputDecoration`, `Colors.white` en `fillColor`.

Dans `rdv_form_step.dart` : `const primaryBlue = Color(0xFF1B3A8D)` recréé localement dans `build()`, `Color(0xFFE8EEFF)` pour la bannière service, `Color(0xFFD8EAFB)` pour les bordures, `Colors.white` en `fillColor`.

Ni `checkout_screen.dart` ni `rdv_form_step.dart` ne sont en mode sombre fonctionnel : tous leurs champs affichent du texte noir sur fond blanc quelle que soit la préférence système.

### Code promo côté client

`cart_screen.dart` définit `static const String _validPromoCode = 'DROPSYEARAND'` et valide localement. La valeur est compilée dans le bundle APK/IPA et peut être extraite par décompilation basique. La remise de 100 FCFA est également calculée côté client et transmise au checkout sans vérification serveur apparente. **confirmed** par lecture directe du fichier.

### Signature de callback `_InnovationsSection`

`home_screen.dart` instancie `_InnovationsSection(formatPrice: PriceFormatter.format)`. Le callback est typé `String Function(int price)` dans la déclaration du widget, alors que `PriceFormatter.format` accepte `num`. Dart accepte cette assignation par covariance/sous-typage mais l'interface est mensongère — quiconque fournit un autre callback doit éviter `double`. **confirmed** : `final String Function(int price) formatPrice` ligne 133, `static String format(num price)` dans price_formatter.dart.

### Badge notifications à zéro

Dans `MaasgaAppBar`, le `Positioned` du badge cloche n'est pas conditionné à `notificationsCount > 0`, contrairement au badge panier qui protège son rendu avec `if (resolvedCartCount > 0)`. Résultat : la cloche affiche toujours un badge rouge « 0 », y compris sur `HomeScreen` qui passe `notificationsCount: 0`. **confirmed** : aucune garde `if (notificationsCount > 0)` dans `maasga_app_bar.dart`.

### MainBottomNav dans CartScreen hors bottomNavigationBar

`CartScreen` place `const MainBottomNav()` comme dernier enfant d'une `Column` dans le `body`, à l'intérieur d'un `SafeArea`. Les autres écrans (`HomeScreen`, `RdvScreen`) utilisent `bottomNavigationBar:` du `Scaffold`. Ce placement incohérent signifie que dans `CartScreen` la barre de navigation n'est pas gérée par le layout système et peut se retrouver sous la barre de geste Android si le `SafeArea` ne couvre pas correctement le bas. **confirmed** par lecture de cart_screen.dart ligne 506.

</details>

---

<details>
<summary>Carte des fichiers</summary>

| Fichier | Ce qui a changé |
|---|---|
| `lib/shared/widgets/main_bottom_nav.dart` | Converti en `StatelessWidget`, `currentPath` supprimé, index calculé via `GoRouterState`, 5 onglets |
| `lib/shared/widgets/maasga_app_bar.dart` | Paramètre `cartCount` nullable ajouté, badge panier conditionnel |
| `lib/shared/utils/price_formatter.dart` | Nouveau — classe utilitaire `PriceFormatter.format(num)` via `intl` |
| `lib/features/catalog/presentation/product_list_card.dart` | `_formatPrice` local remplacé par `PriceFormatter.format` |
| `lib/features/catalog/presentation/product_detail_screen.dart` | `PriceFormatter.format` utilisé pour le prix et le barré |
| `lib/features/cart/presentation/checkout_screen.dart` | `_QuartierSearchDialog` remplacé par `QuartierSearchBottomSheet`, `PriceFormatter.format` pour le total |
| `lib/features/home/presentation/home_screen.dart` | `MainBottomNav()` sans paramètre, `PriceFormatter.format` via callback |
| `lib/features/cart/presentation/cart_screen.dart` | SnackBar undo au décrément à 1, `AlertDialog` maintenu pour `Dismissible`, `PriceFormatter.format` |
| `lib/shared/widgets/quartier_picker.dart` | Nouveau — `QuartierSearchBottomSheet` avec palette `context.maasga` |
| `lib/features/rdv/presentation/widgets/rdv_form_step.dart` | `_QuartierSearchDialog` remplacé par `QuartierSearchBottomSheet` |
| `lib/features/rdv/presentation/rdv_screen.dart` | `MainBottomNav()` sans paramètre |

Diff complet : `git diff main -- lib/shared/widgets/main_bottom_nav.dart lib/shared/widgets/maasga_app_bar.dart lib/shared/utils/price_formatter.dart lib/features/cart/ lib/features/catalog/presentation/product_list_card.dart lib/features/catalog/presentation/product_detail_screen.dart lib/features/home/presentation/home_screen.dart lib/shared/widgets/quartier_picker.dart lib/features/rdv/presentation/widgets/rdv_form_step.dart lib/features/rdv/presentation/rdv_screen.dart`

</details>
