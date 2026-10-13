# Sprint 2 — Résultats de vérification

Date : 2026-12-10

## `flutter analyze` — résultats

### Analyse par groupes de fichiers (analyse complète trop lente sur cette machine)

| Groupe | Commande | Résultat |
|---|---|---|
| Nouveaux widgets partagés | `flutter analyze lib/shared/widgets/main_bottom_nav.dart lib/shared/widgets/maasga_app_bar.dart lib/shared/widgets/quartier_picker.dart lib/shared/utils/price_formatter.dart lib/app/router/app_router.dart` | **No issues found** (30.8s) |
| Features cart + catalog + rdv | `flutter analyze lib/features/cart/ lib/features/catalog/presentation/product_list_card.dart lib/features/catalog/presentation/product_detail_screen.dart lib/features/rdv/presentation/widgets/rdv_form_step.dart lib/features/home/presentation/home_screen.dart` | **No issues found** (19.3s) |
| Écrans restants mis à jour | `flutter analyze lib/shared/widgets/maasga_shell.dart lib/features/simulator/ lib/features/rdv/presentation/rdv_screen.dart lib/features/catalog/presentation/catalog_screen.dart lib/features/client_space/ lib/features/notifications/ lib/features/support/ lib/features/home/presentation/search_screen.dart lib/features/maintenance/` | **No issues found** (20.6s) |

Note : `flutter analyze lib/` complet dépasse 5 minutes sur cette machine et time-out. L'analyse par groupe couvre tous les fichiers modifiés.

## Vérifications grep

| Vérification | Résultat |
|---|---|
| Absence de `MainBottomNav(currentPath:` dans `/lib` | ✅ Aucun résultat |
| Présence de `PriceFormatter.format` dans les fichiers cibles | ✅ Présent dans `home_screen.dart`, `product_list_card.dart`, `product_detail_screen.dart`, `checkout_screen.dart`, `cart_screen.dart`, `cart_item_card.dart` |
| Absence de `_QuartierSearchDialog` dans `checkout_screen.dart` | ✅ Aucun résultat |
| Absence de `_QuartierSearchDialog` dans `rdv_form_step.dart` | ✅ Aucun résultat |

## Tâches implémentées

- **Tâche 2.1+2.2** : `MainBottomNav` réduit à 5 onglets, `currentPath` supprimé, lecture auto via `GoRouterState`, converti en `StatelessWidget`. Tous les 10+ appelants mis à jour.
- **Tâche 2.4** : `PriceFormatter` créé dans `lib/shared/utils/price_formatter.dart`. Remplace les 5 implémentations locales `_formatPrice`.
- **Tâche 2.5** : `onDecrement` dans `cart_screen.dart` — suppression directe + SnackBar avec action « Annuler » (`cartNotifier.add`). `_showDeleteDialog` conservée pour le `Dismissible`.
- **Tâche 2.9** : `QuartierSearchBottomSheet` créé dans `lib/shared/widgets/quartier_picker.dart`. Remplace les deux `_QuartierSearchDialog` dans `checkout_screen.dart` et `rdv_form_step.dart`.
- **Tâche 2.8 (routeur)** : `/catalogue`, `/rendez-vous`, `/espace-client` convertis en redirections GoRouter vers `/catalog`, `/rdv`, `/client-space`.
- **Tâche 2.5 (AppBar)** : `MaasgaAppBar` reçoit `cartCount` nullable, calcule depuis `cartProvider` si non fourni. Badge panier visible dans la barre d'app.

## Commit

`d35962e` — feat: Sprint 2 — nav 5 onglets, PriceFormatter, QuartierPicker, SnackBar undo, cart badge AppBar
