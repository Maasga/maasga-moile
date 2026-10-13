# Plan d'implémentation — Sprint 1 : Foundations

## Vue d'ensemble

Six tâches de nettoyage et de résorption de dette technique sur la couche présentation de l'application MAASGA Mobile Flutter. Aucune modification d'API, de provider Riverpod, de routage, ni de fichiers de tokens (`app_theme.dart`, `maasga_tokens.dart`).

---

## Tâches

- [ ] 1. Tâche 1.1 — Conditionner les debugPrint de production dans catalog_screen.dart
  - Ouvrir `lib/features/catalog/presentation/catalog_screen.dart`
  - Identifier les 4 appels `debugPrint` présents dans la méthode `build()` (lignes ~66–69 et ~84)
  - Envelopper les 3 premiers (état, nombre, catégorie) dans un bloc `if (kDebugMode) { ... }` commun
  - Envelopper le 4e (`📦 Produits filtrés`) dans un bloc `if (kDebugMode)` séparé, après le calcul de `filteredProducts`
  - Vérifier que `import 'package:flutter/foundation.dart'` est bien présent (il l'est via `flutter/material.dart`)
  - Ne modifier aucun autre fichier
  - _Exigences : 1.1, 1.2, 1.3, 1.4_

  - [ ]* 1.1 Vérifier l'absence de debugPrint nu via flutter analyze
    - Lancer `flutter analyze lib/features/catalog/presentation/catalog_screen.dart` et s'assurer qu'il ne signale aucun warning
    - _Exigences : 1.1_

- [x] 2. Tâche 1.2 — Remplacer la couleur hardcodée 0xFF1B3A8D dans les 7 fichiers cibles
  - [x] 2.1 Remplacer dans `product_list_card.dart`
    - Déclarer `final palette = context.maasga;` en tête de `build()` (déjà présent — vérifier)
    - Remplacer `const Color(0xFF1B3A8D)` (puce bullet, couleur prix, backgroundColor du bouton) par `palette.accent`
    - Remplacer `const Color(0xFF1A1A1A)` (nom produit) par `palette.textPrimary`
    - Remplacer `const Color(0xFF757575)` (texte spec) par `palette.textMuted`
    - _Exigences : 2.1, 2.2, 2.3_

  - [x] 2.2 Remplacer dans `product_detail_screen.dart`
    - Remplacer toutes les occurrences de `const Color(0xFF1B3A8D)` par `context.maasga.accent` (ou `palette.accent` si `final palette = context.maasga` est déclaré)
    - _Exigences : 2.1, 2.3_

  - [x] 2.3 Remplacer dans `rdv_screen.dart`
    - Remplacer `static const _primaryBlue = Color(0xFF1B3A8D)` par `static const _primaryBlue = MaasgaTokens.blue900` (constante statique — ne pas utiliser `context.maasga` ici)
    - Ou supprimer `_primaryBlue` et remplacer les usages dans `build` par `context.maasga.accent`
    - _Exigences : 2.1, 2.2, 2.3_

  - [x] 2.4 Remplacer dans `checkout_screen.dart`
    - Remplacer `const Color(0xFF1B3A8D)` dans les méthodes ayant accès au `BuildContext` (ex. `_buildSectionHeader`, `_buildStep`, `build`) par `context.maasga.accent` ou `palette.accent`
    - Les méthodes sans `BuildContext` → `MaasgaTokens.blue900`
    - Note : `_buildInputDecoration` est intentionnellement préservée (exigence 3.5)
    - _Exigences : 2.1, 2.2, 2.3_

  - [x] 2.5 Remplacer dans `cart_screen.dart`, `simulator_screen.dart`, `client_space_screen.dart`
    - Appliquer la même règle : `context.maasga.accent` si `BuildContext` disponible, `MaasgaTokens.blue900` sinon
    - _Exigences : 2.1, 2.2, 2.3_

  - [ ]* 2.6 Vérifier l'absence de la constante dans les fichiers cibles
    - **Propriété 2 : Absence de la constante de couleur hardcodée dans les fichiers cibles**
    - Lancer un grep : `grep -rn "0xFF1B3A8D" lib/features/` — aucune occurrence ne doit subsister dans les 7 fichiers cibles
    - **Validates : Exigences 2.1, 2.2, 2.5**

- [~] 3. Checkpoint — Vérifier la compilation après les tâches 1.1 et 1.2
  - Lancer `flutter analyze` sur les fichiers modifiés ; corriger tout warning ou erreur avant de continuer.

- [x] 4. Tâche 1.3 — Corriger le dark mode sur les écrans non conformes
  - [x] 4.1 Corriger `product_detail_screen.dart`
    - Déclarer `final palette = context.maasga;` en tête de `build()`
    - Remplacer `Scaffold(backgroundColor: Colors.white, ...)` par `backgroundColor: palette.pageGradient.colors.first`
    - Remplacer les fonds blancs de Container/Card de la fiche produit par `palette.card` ou `palette.cardAlt`
    - Remplacer `const Color(0xFF1A1A1A)` par `palette.textPrimary`, `const Color(0xFF757575)` par `palette.textMuted`
    - _Exigences : 3.1, 3.2, 3.3, 3.6, 3.7_

  - [x] 4.2 Corriger `cart_screen.dart`
    - Remplacer `Scaffold(backgroundColor: const Color(0xFFF5F5F5), ...)` par `backgroundColor: palette.pageGradient.colors.first`
    - Remplacer le header `Container(color: Colors.white, ...)` par `Container(color: palette.card, ...)`
    - Remplacer les containers de code promo et récapitulatif (`color: Colors.white`) par `palette.card`
    - Remplacer le footer bas (`color: Colors.white`) par `palette.card`
    - Remplacer les textes `const Color(0xFF1A1A1A)` par `palette.textPrimary`
    - _Exigences : 3.1, 3.2, 3.3, 3.6, 3.7_

  - [x] 4.3 Corriger `checkout_screen.dart` (surfaces uniquement)
    - NE PAS toucher à `_buildInputDecoration`
    - Remplacer `Card(color: Colors.white, ...)` (récapitulatif total) par `Card(color: palette.card, ...)`
    - Remplacer le container "Comment ça marche ?" `color: const Color(0xFFF0F4FF)` par `palette.infoSurface`
    - Remplacer le container d'erreur `color: const Color(0xFFFFEBEE)` par `palette.dangerSurface`
    - Remplacer les textes hardcodés `const Color(0xFF1A1A1A)` par `palette.textPrimary`
    - Remplacer les textes `const Color(0xFF475467)` par `palette.textSecondary`
    - _Exigences : 3.2, 3.3, 3.5, 3.6, 3.7_

  - [x] 4.4 Corriger `rdv_screen.dart`
    - Supprimer `static const _bgColor = Color(0xFFF5F5F5)` (et son usage dans Scaffold)
    - Lire `context.maasga.pageGradient.colors.first` directement dans `build()`
    - Remplacer le fond blanc de `_buildFooter` par `palette.card`
    - Remplacer les textes et icônes hardcodés par `palette.textPrimary`, `palette.textSecondary`, `palette.accent`
    - _Exigences : 3.1, 3.2, 3.3, 3.4, 3.6, 3.7_

  - [x] 4.5 Corriger `simulator_screen.dart`
    - Déclarer `final palette = context.maasga;` en tête de `build()`
    - Remplacer les containers de résultat, guides, intro card blancs par `palette.card` ou `palette.cardAlt`
    - Remplacer les textes hardcodés par les tokens de palette appropriés
    - _Exigences : 3.2, 3.3, 3.6, 3.7_

- [~] 5. Checkpoint — Tester le dark mode visuellement
  - Lancer `flutter analyze` ; zéro erreur requis.
  - Tester l'application en mode sombre sur émulateur ou appareil pour les 5 écrans modifiés ; valider qu'aucun fond blanc/gris ne subsiste.

- [x] 6. Tâche 1.4 — Unifier la typographie (supprimer GoogleFonts.poppins directs)
  - [x] 6.1 Nettoyer `product_list_card.dart`
    - Remplacer tous les `GoogleFonts.poppins(fontSize: X, fontWeight: Y, color: Z)` par `TextStyle(fontSize: X, fontWeight: Y, color: Z)` (la famille est héritée du thème)
    - Supprimer l'import `package:google_fonts/google_fonts.dart` si plus aucun appel `GoogleFonts` ne subsiste
    - _Exigences : 4.1, 4.3, 4.4_

  - [x] 6.2 Nettoyer `catalog_screen.dart`
    - Même traitement que 6.1
    - _Exigences : 4.1, 4.3, 4.4_

  - [x] 6.3 Nettoyer `cart_screen.dart`
    - Même traitement — inclure les widgets internes `_QuartierSearchDialog` et méthodes helper
    - _Exigences : 4.1, 4.3, 4.4_

  - [x] 6.4 Nettoyer `checkout_screen.dart`
    - Même traitement — inclure `_buildSectionHeader`, `_buildLabel`, `_buildStep`
    - Note : les `TextStyle` inline des champs `TextField` (`style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A1A))`) doivent également être migrés
    - _Exigences : 4.1, 4.3, 4.4_

  - [ ]* 6.5 Vérifier l'absence d'imports google_fonts dans les fichiers cibles
    - Lancer `grep -rn "google_fonts" lib/features/catalog/presentation/product_list_card.dart lib/features/catalog/presentation/catalog_screen.dart lib/features/cart/presentation/cart_screen.dart lib/features/cart/presentation/checkout_screen.dart`
    - Aucune occurrence ne doit subsister
    - _Exigences : 4.1, 4.3_

- [x] 7. Tâche 1.5 — Migrer GestureDetector → InkWell
  - [x] 7.1 Migrer `product_list_card.dart`
    - Envelopper le `GestureDetector` racine dans un `Material(color: Colors.transparent, borderRadius: BorderRadius.circular(16), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: ...))`
    - Conserver exactement le même `Container` de décoration en enfant de l'`InkWell`
    - _Exigences : 5.1, 5.4_

  - [ ]* 7.2 Écrire un widget test pour ProductListCard (migration InkWell)
    - **Propriété 3 : Comportement onTap préservé après migration InkWell**
    - Créer `test/features/catalog/product_list_card_test.dart`
    - Monter `ProductListCard` avec un produit factice et une callback `onTap` mockée
    - Simuler un `tap` via `tester.tap(find.byType(InkWell).first)`
    - Vérifier que la callback a été appelée exactement une fois
    - Vérifier la présence d'un `InkWell` dans le widget tree (et non d'un `GestureDetector`)
    - **Validates : Exigences 5.1, 5.4**

  - [x] 7.3 Migrer les chips de `simulator_screen.dart`
    - Remplacer les `GestureDetector` des chips de sélection (surface, hauteur, fenêtres, exposition, type pièce) par `InkWell` avec le `borderRadius` du chip correspondant
    - Conserver le même `onTap`
    - _Exigences : 5.2, 5.4_

  - [x] 7.4 Vérifier et migrer `rdv_screen.dart` (ServiceTypeCard)
    - Inspecter `lib/features/rdv/presentation/widgets/service_type_card.dart`
    - Si `GestureDetector` présent → le remplacer par `InkWell` avec le `borderRadius` de la carte
    - Si déjà `InkWell` ou `ElevatedButton` → aucune modification
    - _Exigences : 5.3, 5.4_

- [ ] 8. Tâche 1.6 — Supprimer _isMounted() dans checkout_screen.dart
  - Supprimer la méthode `bool _isMounted() => mounted;` de `_CheckoutScreenState`
  - Remplacer chaque `if (!_isMounted()) return;` par `if (!mounted) return;`
  - Remplacer chaque `if (_isMounted())` par `if (mounted)`
  - Vérifier qu'aucune occurrence de `_isMounted` ne subsiste dans le fichier
  - _Exigences : 6.1, 6.2, 6.3, 6.4_

  - [ ]* 8.1 Vérifier via flutter analyze
    - Lancer `flutter analyze lib/features/cart/presentation/checkout_screen.dart`
    - Zéro warning ou erreur
    - _Exigences : 6.3_

- [x] 9. Checkpoint final — Validation complète du sprint
  - Lancer `flutter analyze` sur le répertoire `lib/` complet ; zéro erreur, zéro warning bloquant.
  - Lancer `flutter test` ; tous les tests doivent passer.
  - Vérifier via grep : `grep -rn "0xFF1B3A8D\|Colors\.white\|GoogleFonts\.poppins\|GestureDetector\|_isMounted\|debugPrint" lib/features/` pour confirmer l'absence des patterns dans les fichiers cibles.
  - Effectuer une revue visuelle en mode clair ET sombre sur les 7 écrans modifiés.

---

## Notes

- Les tâches marquées `*` sont optionnelles et peuvent être ignorées pour un MVP plus rapide.
- Chaque tâche référence les exigences correspondantes pour la traçabilité.
- Les fichiers `app_theme.dart` et `maasga_tokens.dart` ne doivent **jamais** être modifiés dans ce sprint.
- Les écrans auth (`login_screen.dart`, `register_screen.dart`) ne doivent pas être touchés.
- La méthode `_buildInputDecoration` de `checkout_screen.dart` est intentionnellement exclue des modifications de la tâche 1.3.
- Les tâches 1.2 et 1.3 sont partiellement superposées sur les fichiers cibles : combiner les modifications dans un même commit par fichier pour minimiser les conflits.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["2.1", "2.2", "2.3", "2.4", "2.5"] },
    { "id": 2, "tasks": ["2.6"] },
    { "id": 3, "tasks": ["4.1", "4.2", "4.3", "4.4", "4.5"] },
    { "id": 4, "tasks": ["6.1", "6.2", "6.3", "6.4"] },
    { "id": 5, "tasks": ["6.5", "7.1", "7.3", "7.4", "8.1"] },
    { "id": 6, "tasks": ["7.2", "8.1"] }
  ]
}
```
