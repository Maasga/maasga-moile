# Plan d'implémentation — Sprint 2 MAASGA Mobile

> **Contraintes globales**
> - Ne pas modifier `app_theme.dart`, `maasga_tokens.dart`.
> - Ne pas modifier les fichiers auth (`login_screen.dart`, `register_screen.dart`).
> - Toutes les couleurs via `context.maasga` — zéro `Color(0xFF…)` hardcodé dans les fichiers modifiés.
> - `flutter analyze lib/` doit retourner « No issues found » après chaque item.
>
> **Commandes de vérification**
> - Analyse statique : `flutter analyze lib/`
> - Build debug : `flutter build apk --debug`

---

## État du code avant Sprint 2 (constaté à la lecture)

| Point | Fichier | Observation |
|---|---|---|
| `MainBottomNav` a 7 onglets | `main_bottom_nav.dart` | Accueil, Catalogue, Simul., Services, Contrat, Panier, Profil. Il faut passer à 5 en déplaçant le Panier vers `MaasgaAppBar`. |
| `currentPath` requis | `main_bottom_nav.dart` | Paramètre `required` passé dans 10 écrans. |
| `MaasgaShell` passe déjà la route via `GoRouterState` | `maasga_shell.dart` | `MainBottomNav(currentPath: GoRouterState.of(context).uri.toString())` — modèle à généraliser. |
| `MaasgaAppBar` sans panier | `maasga_app_bar.dart` | Pas de `cartCount`. |
| Formatage de prix local × 4 emplacements | `product_list_card`, `home_screen`, `cart_screen`, `cart_item_card` | Chacun réimplémente `_formatPrice`. `product_detail_screen` utilise `'${price} FCFA'` sans formatage. `checkout_screen` idem (`'$total FCFA'`). |
| Dialog de suppression au décrément | `cart_screen.dart` | `_showDeleteDialog` appelé depuis `onDecrement` quand `quantity == 1`. |
| `_QuartierSearchDialog` dupliquée | `checkout_screen.dart` & `rdv_form_step.dart` | Deux implémentations indépendantes, fond `Colors.white` hardcodé, couleurs hardcodées. |
| Routes à unifier | `app_router.dart` | `/catalogue` et `/catalog` coexistent ; `/rendez-vous` et `/rdv` aussi ; `/espace-client` et `/client-space` aussi. Les alias seront conservés (redirections GoRouter) pour ne pas casser les liens entrants. |

---

- [ ] 1. **Créer `PriceFormatter` dans `lib/shared/utils/price_formatter.dart`**

  Classe utilitaire statique avec une seule méthode :
  ```dart
  /// Formate un prix entier en FCFA avec séparateur de milliers français.
  /// Exemple : 150000 → "150 000 FCFA"
  static String format(int price) {
    return NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    ).format(price);
  }
  ```
  Importer `package:intl/intl.dart`. Ne pas ajouter d'autres méthodes.

  **Fichiers :** `lib/shared/utils/price_formatter.dart` *(créer)*

  **Vérifier :** `flutter analyze lib/shared/utils/price_formatter.dart` — aucune erreur.

---

- [ ] 2. **Remplacer les formatages de prix locaux par `PriceFormatter.format()`**

  Dans chaque fichier ci-dessous, supprimer la méthode locale `_formatPrice` et remplacer tous ses appels par `PriceFormatter.format(…)`. Ajouter l'import `'../../../shared/utils/price_formatter.dart'` (ajuster le chemin relatif selon l'emplacement du fichier).

  Cas particuliers :
  - `cart_screen.dart` : `_formatPrice` accepte un `double` ; le prix est `sousTotal`, `remise`, `total` (tous doubles). Appeler `PriceFormatter.format(price.toInt())`.
  - `checkout_screen.dart` : remplacer le littéral `'$total FCFA'` par `PriceFormatter.format(total)` (total est déjà `int` via `cartTotalProvider`).
  - `product_detail_screen.dart` : remplacer `'${widget.product.price} FCFA'` et `'${widget.product.oldPrice} FCFA'` par `PriceFormatter.format(widget.product.price)` et `PriceFormatter.format(widget.product.oldPrice!)`.
  - `cart_item_card.dart` : supprimer `_formatPrice`, remplacer par `PriceFormatter.format(line.product.price)`.
  - `product_list_card.dart` : supprimer `_formatPrice` + import `intl`, ajouter import `price_formatter.dart`.
  - `home_screen.dart` : supprimer `_formatPrice` + import `intl`, transmettre `PriceFormatter.format` à `_InnovationsSection(formatPrice: PriceFormatter.format)`.

  **Fichiers :**
  - `lib/features/cart/presentation/cart_screen.dart`
  - `lib/features/cart/presentation/cart_item_card.dart`
  - `lib/features/cart/presentation/checkout_screen.dart`
  - `lib/features/catalog/presentation/product_list_card.dart`
  - `lib/features/catalog/presentation/product_detail_screen.dart`
  - `lib/features/home/presentation/home_screen.dart`

  **Vérifier :** `flutter analyze lib/` — aucune erreur. Les prix doivent afficher le séparateur d'espace des milliers (ex. « 150 000 FCFA »).

---

- [ ] 3. **Créer `QuartierSearchBottomSheet` dans `lib/shared/widgets/quartier_picker.dart`**

  Reprendre l'implémentation de `_QuartierSearchDialog` de `rdv_form_step.dart` (la plus complète avec `GoogleFonts.poppins`) en la transformant en widget public `QuartierSearchBottomSheet`.

  Signature exacte :
  ```dart
  class QuartierSearchBottomSheet extends StatefulWidget {
    const QuartierSearchBottomSheet({
      super.key,
      this.currentSelection,
      required this.onSelected,
    });

    final String? currentSelection;
    final void Function(String) onSelected;
  }
  ```

  Appliquer la palette dark mode via `context.maasga` :
  - Fond du container : `palette.card`
  - `fillColor` du champ de recherche : `palette.cardAlt`
  - Drag handle : `palette.divider`
  - Titre et texte des items : `palette.textPrimary`
  - Items non sélectionnés : `palette.textMuted`
  - Item sélectionné (texte + icône `check`) : `palette.accent`
  - `Divider` séparateur : `palette.divider`

  Conserver :
  - La hauteur `MediaQuery.of(context).size.height * 0.75`
  - Le `ListView.separated` avec `ouagaNeighborhoods` (import depuis `'../../features/rdv/domain/neighborhoods.dart'`)
  - La logique de filtre par `_search`

  **Fichiers :** `lib/shared/widgets/quartier_picker.dart` *(créer)*

  **Vérifier :** `flutter analyze lib/shared/widgets/quartier_picker.dart` — aucune erreur.

---

- [ ] 4. **Remplacer `_QuartierSearchDialog` dans `checkout_screen.dart` et `rdv_form_step.dart`**

  Dans les deux fichiers :
  1. Ajouter l'import `'../../../shared/widgets/quartier_picker.dart'` (ajuster chemin pour `rdv_form_step.dart` : `'../../../../shared/widgets/quartier_picker.dart'`).
  2. Remplacer `_QuartierSearchDialog(…)` par `QuartierSearchBottomSheet(…)` en passant les mêmes paramètres.
  3. Supprimer entièrement la classe `_QuartierSearchDialog` et `_QuartierSearchDialogState` du fichier.

  Dans `checkout_screen.dart`, le callback `onSelected` ferme le bottom sheet via `Navigator.pop(ctx)` — conserver ce comportement.

  **Fichiers :**
  - `lib/features/cart/presentation/checkout_screen.dart`
  - `lib/features/rdv/presentation/widgets/rdv_form_step.dart`

  **Vérifier :** `flutter analyze lib/` — aucune erreur. Ouvrir le picker dans les deux écrans ne produit pas d'erreur à l'analyse.

---

- [ ] 5. **Modifier `MaasgaAppBar` pour accepter un badge Panier**

  Ajouter un paramètre optionnel `cartCount` :
  ```dart
  final int cartCount;
  ```
  Valeur par défaut : `0` (constructeur : `this.cartCount = 0`).

  Ajouter dans la `Row` des actions (entre le `trailingAction` et la cloche), un `IconButton` avec badge, visible uniquement si `cartCount > 0` **OU** toujours visible (icône panier sans badge si 0) — **choix : toujours visible**, car le panier est maintenant le seul point d'accès au panier depuis les pages principales.

  Implémentation du badge :
  ```dart
  Stack(
    clipBehavior: Clip.none,
    children: [
      IconButton(
        onPressed: () => context.go('/cart'),
        icon: Icon(Icons.shopping_cart_outlined, size: 20),
        color: colorScheme.onSurface,
      ),
      if (cartCount > 0)
        Positioned(
          right: 4,
          top: 4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.danger,
              border: Border.all(color: palette.card, width: 1),
            ),
            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
            alignment: Alignment.center,
            child: Text(
              cartCount > 9 ? '9+' : '$cartCount',
              style: GoogleFonts.poppins(
                fontSize: 8,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
    ],
  )
  ```

  Mettre à jour `preferredSize` si nécessaire (aucun changement de hauteur attendu).

  Remarque : `MaasgaAppBar` est un `ConsumerWidget`. Pour lire `cartProvider`, ajouter `ref.watch(cartProvider)` et calculer `cartCount` localement si `cartCount` n'est pas fourni. **Choix architectural : `MaasgaAppBar` calcule lui-même le `cartCount` depuis `cartProvider` si aucun `cartCount` n'est passé.** Cela évite de modifier tous les appelants.

  Implémentation concrète : rendre `cartCount` nullable (`int? cartCount`), et dans `build` : `final resolvedCartCount = cartCount ?? ref.watch(cartProvider).fold<int>(0, (s, l) => s + l.quantity);`. Utiliser `resolvedCartCount` pour le badge.

  **Fichiers :** `lib/shared/widgets/maasga_app_bar.dart`

  **Vérifier :** `flutter analyze lib/shared/widgets/maasga_app_bar.dart` — aucune erreur.

---

- [ ] 6. **Réduire `MainBottomNav` à 5 onglets et supprimer `currentPath`**

  **6a. Supprimer le paramètre `currentPath`.**
  Remplacer `_indexFromPath()` qui utilisait `currentPath` par une méthode qui lit la route depuis `GoRouterState.of(context).uri.path` :
  ```dart
  int _indexFromPath(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/catalog') || path.startsWith('/catalogue')) return 1;
    if (path.startsWith('/rdv') || path.startsWith('/rendez-vous') ||
        path.startsWith('/service') || path.startsWith('/support')) return 2;
    if (path.startsWith('/simulator') || path.startsWith('/simulateur')) return 3;
    if (path.startsWith('/client-space') || path.startsWith('/espace-client')) return 4;
    return 0; // /home et tout le reste
  }
  ```

  **6b. Réduire à 5 onglets.**
  Supprimer les onglets `Contrat (/maintenance)` et `Panier (/cart)`. La liste des routes cible :
  ```dart
  const routes = ['/home', '/catalog', '/rdv', '/simulator', '/client-space'];
  ```
  Les 5 onglets :
  - Index 0 : `Icons.home_outlined` / `'Accueil'`
  - Index 1 : `Icons.grid_view_outlined` / `'Catalogue'`
  - Index 2 : `Icons.build_outlined` / `'Services'`
  - Index 3 : `Icons.calculate_outlined` / `'Simul.'`
  - Index 4 : `Icons.person_outline` / `'Profil'`

  Supprimer la classe `_CartIcon` et tout le code lié au badge panier dans ce fichier (il est maintenant dans `MaasgaAppBar`).

  **6c. Conserver `ConsumerWidget`** car `cartProvider` n'est plus nécessaire ici. Simplifier en `StatelessWidget` si aucun autre `ref.watch` n'est présent. **Choix : convertir en `StatelessWidget`** pour simplifier.

  **Fichiers :** `lib/shared/widgets/main_bottom_nav.dart`

  **Vérifier :** `flutter analyze lib/shared/widgets/main_bottom_nav.dart` — aucune erreur.

---

- [ ] 7. **Mettre à jour tous les appels `MainBottomNav(currentPath: '...')` → `MainBottomNav()`**

  Remplacer chaque occurrence dans les 10 fichiers ci-dessous. Supprimer également l'import de `cart_state.dart` dans `main_bottom_nav.dart` s'il n'est plus utilisé.

  La `MaasgaShell` (`maasga_shell.dart`) utilise déjà `MainBottomNav(currentPath: GoRouterState.of(context).uri.toString())` — remplacer par `const MainBottomNav()`.

  **Fichiers à modifier** (tous les appels trouvés) :
  - `lib/shared/widgets/maasga_shell.dart`
  - `lib/features/home/presentation/home_screen.dart`
  - `lib/features/catalog/presentation/catalog_screen.dart`
  - `lib/features/cart/presentation/cart_screen.dart`
  - `lib/features/client_space/presentation/client_space_screen.dart`
  - `lib/features/rdv/presentation/rdv_screen.dart`
  - `lib/features/simulator/presentation/simulator_screen.dart`
  - `lib/features/support/presentation/support_screen.dart`
  - `lib/features/notifications/presentation/notifications_screen.dart`
  - `lib/features/maintenance/presentation/screens/maintenance_screen.dart`
  - `lib/features/home/presentation/search_screen.dart`

  **Vérifier :** `flutter analyze lib/` — aucune erreur.

---

- [ ] 8. **Mettre à jour `app_router.dart` : canonicaliser les routes**

  Les routes `/catalogue`, `/rendez-vous`, `/espace-client` deviennent des redirections vers leurs alias canoniques `/catalog`, `/rdv`, `/client-space` pour que `_indexFromPath` retourne toujours le bon index sans multiplier les conditions.

  Remplacer les `GoRoute` de `/catalogue`, `/rendez-vous`, `/espace-client` par des redirections :
  ```dart
  GoRoute(path: '/catalogue', redirect: (_, __) => '/catalog'),
  GoRoute(path: '/rendez-vous', redirect: (_, __) => '/rdv'),
  GoRoute(path: '/espace-client', redirect: (_, __) => '/client-space'),
  ```

  **Fichiers :** `lib/app/router/app_router.dart`

  **Vérifier :** `flutter analyze lib/app/router/` — aucune erreur.

---

- [ ] 9. **Supprimer la `AlertDialog` de décrément dans `cart_screen.dart` et implémenter le SnackBar undo**

  **9a. Modifier `onDecrement` dans le `CartItemCard`.**
  Remplacer :
  ```dart
  onDecrement: () async {
    if (line.quantity == 1) {
      final confirmed = await _showDeleteDialog(context) ?? false;
      if (confirmed) { cartNotifier.remove(line.product); }
    } else {
      cartNotifier.remove(line.product);
    }
  },
  ```
  Par :
  ```dart
  onDecrement: () {
    if (line.quantity == 1) {
      // Retirer directement + SnackBar avec action Annuler
      cartNotifier.remove(line.product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${line.product.name} retiré'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () => cartNotifier.add(line.product),
          ),
        ),
      );
    } else {
      cartNotifier.remove(line.product);
    }
  },
  ```

  **9b. Supprimer `_showDeleteDialog`.** La méthode est encore utilisée par le `Dismissible` — la **conserver** pour le Dismissible (l'énoncé dit « conserver le Dismissible existant avec sa dialog »). Ne supprimer `_showDeleteDialog` que si elle n'est plus référencée nulle part — ici, elle l'est encore par le `confirmDismiss` du `Dismissible`, donc **la garder**.

  **Fichiers :** `lib/features/cart/presentation/cart_screen.dart`

  **Vérifier :** `flutter analyze lib/features/cart/` — aucune erreur.

---

- [ ] 10. **Vérification finale globale**

  Lancer l'analyse statique complète et le build debug :
  ```bash
  flutter analyze lib/
  flutter build apk --debug
  ```

  S'assurer que :
  - `flutter analyze lib/` retourne `No issues found.`
  - `flutter build apk --debug` se termine sans erreur de compilation.
  - Aucune référence à `currentPath` ne subsiste dans les fichiers hors `main_bottom_nav.dart`.
  - Aucun `Color(0xFF…)` hardcodé n'est présent dans les fichiers nouvellement créés ou modifiés.

  **Fichiers :** aucun fichier supplémentaire. Correction des erreurs résiduelles si trouvées.

  **Vérifier :** `flutter analyze lib/` — `No issues found.`

---

## Résumé des dépendances entre items

```
Item 1 (PriceFormatter créé)
  └─ Item 2 (utilise PriceFormatter)

Item 3 (QuartierSearchBottomSheet créé)
  └─ Item 4 (utilise QuartierSearchBottomSheet)

Item 5 (MaasgaAppBar + badge panier)
  └─ Item 6 (MainBottomNav réduit à 5 sans Panier)
       └─ Item 7 (mise à jour de tous les appelants)
            └─ Item 8 (canonicalisation des routes)

Item 9 (SnackBar undo) — indépendant des autres

Item 10 (vérification finale) — dépend de tous les items précédents
```

Les items 1-2, 3-4, 5-6-7-8, et 9 peuvent être implémentés dans n'importe quel ordre relatif entre groupes, mais chaque groupe doit être complété avant de passer au suivant à l'intérieur du groupe.
