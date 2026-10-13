# Document de Conception — Sprint 1 : Foundations

## Vue d'ensemble

Le Sprint 1 est un sprint de résorption de dette technique pure. Il n'introduit aucun nouveau provider, aucune nouvelle route, et aucun nouveau service. Les six tâches agissent exclusivement sur la couche **présentation** (`lib/features/*/presentation/`) en appliquant des règles homogènes :

1. Conditionner les logs de débogage avec `kDebugMode`
2. Remplacer la couleur hardcodée `0xFF1B3A8D` par les tokens de design
3. Corriger les surfaces figées en blanc/gris pour le dark mode
4. Éliminer les appels directs à `GoogleFonts.poppins()` dans les widgets
5. Migrer les `GestureDetector` vers `InkWell` pour le retour visuel
6. Supprimer le wrapper `_isMounted()` superflu

Aucune modification d'API, de modèle de données, de provider Riverpod ou de configuration de route n'est requise.

---

## Architecture existante (rappel)

```
lib/
├── app/
│   └── theme/
│       └── app_theme.dart          # AppTheme.light() / AppTheme.dark()
├── shared/
│   └── design_tokens/
│       └── maasga_tokens.dart      # MaasgaTokens (constantes) + MaasgaPalette (ThemeExtension)
└── features/
    ├── catalog/presentation/
    │   ├── catalog_screen.dart
    │   ├── product_list_card.dart
    │   └── product_detail_screen.dart
    ├── cart/presentation/
    │   ├── cart_screen.dart
    │   └── checkout_screen.dart
    ├── rdv/presentation/
    │   └── rdv_screen.dart
    ├── simulator/presentation/
    │   └── simulator_screen.dart
    └── client_space/presentation/
        └── client_space_screen.dart
```

Règle fondamentale du projet : tout token de couleur dépendant du thème passe par `context.maasga` (MaasgaPalette). Les constantes indépendantes du thème (couleurs de marque) passent par `MaasgaTokens`.

---

## Tâche 1.1 — Suppression des debugPrint de production

### Problème

`catalog_screen.dart` contient trois appels `debugPrint` non conditionnels dans la méthode `build()` :

```dart
debugPrint('📦 État produitsAsync: $productsAsync');
debugPrint('📦 Nombre total produits: ${allProducts.length}');
debugPrint('📦 Catégorie sélectionnée: $_selectedCategory');
// ... plus bas ...
debugPrint('📦 Produits filtrés: ${filteredProducts.length}');
```

Ces appels sérialisent des objets potentiellement volumineux à chaque rebuild, ce qui dégrade les performances en production.

### Solution

Envelopper chaque `debugPrint` dans un bloc `if (kDebugMode)`. L'import `package:flutter/foundation.dart` est déjà disponible via `package:flutter/material.dart`.

```dart
if (kDebugMode) {
  debugPrint('📦 État produitsAsync: $productsAsync');
  debugPrint('📦 Nombre total produits: ${allProducts.length}');
  debugPrint('📦 Catégorie sélectionnée: $_selectedCategory');
}
// ...
if (kDebugMode) {
  debugPrint('📦 Produits filtrés: ${filteredProducts.length}');
}
```

**Contrainte :** ne toucher qu'à `catalog_screen.dart`.

---

## Tâche 1.2 — Unification de la couleur hardcodée 0xFF1B3A8D

### Problème

La couleur `const Color(0xFF1B3A8D)` est dupliquée ~40 fois dans 7 fichiers de présentation. Elle ne s'adapte pas au dark mode (où `palette.accent` bascule sur le cyan `0xFF6FD3E8`).

### Règle de remplacement

| Contexte | Remplacement |
|----------|-------------|
| Widget avec `BuildContext` disponible (méthodes `build`, `_buildXxx(BuildContext context, ...)`) | `context.maasga.accent` |
| Style statique sans `BuildContext` (constante de classe, paramètre par défaut) | `MaasgaTokens.blue900` |

### Détail par fichier

**`product_list_card.dart`** — `build(BuildContext context)` disponible :
- Puce bullet `BoxDecoration(color: const Color(0xFF1B3A8D))` → `color: palette.accent`
- Prix `color: const Color(0xFF1B3A8D)` → `color: palette.accent`
- Bouton `backgroundColor: const Color(0xFF1B3A8D)` → `backgroundColor: palette.accent`

**`rdv_screen.dart`** — remplacer `static const _primaryBlue = Color(0xFF1B3A8D)` par `MaasgaTokens.blue900` (constante statique) ; les usages dans `build` qui ont un contexte peuvent directement utiliser `context.maasga.accent`.

**`checkout_screen.dart`** — toutes les occurrences de `Color(0xFF1B3A8D)` dans les méthodes recevant `BuildContext` → `context.maasga.accent` ; dans les méthodes helper sans contexte (`_buildStep`) ou les widgets internes sans contexte → `MaasgaTokens.blue900`.

**`cart_screen.dart`**, **`simulator_screen.dart`**, **`client_space_screen.dart`**, **`product_detail_screen.dart`** — même règle : accès via `context.maasga.accent` si contexte disponible, sinon `MaasgaTokens.blue900`.

---

## Tâche 1.3 — Dark mode sur les écrans non conformes

### Problème

Cinq écrans posent des couleurs de fond figées, rendant l'interface illisible en mode sombre :

| Écran | Problème |
|-------|---------|
| `product_detail_screen.dart` | `Scaffold(backgroundColor: Colors.white)`, containers de fiche blancs |
| `cart_screen.dart` | `Scaffold(backgroundColor: const Color(0xFFF5F5F5))`, header blanc |
| `checkout_screen.dart` | `Card(color: Colors.white)`, containers `color: const Color(0xFFF0F4FF)`, container erreur blanc |
| `rdv_screen.dart` | `static const _bgColor = Color(0xFFF5F5F5)` dans Scaffold, footer blanc |
| `simulator_screen.dart` | containers de résultat, intro card, guides avec `Colors.white` |

### Solution

Déclarer `final palette = context.maasga;` en tête de `build()` et remplacer :

```dart
// AVANT
Scaffold(backgroundColor: Colors.white, ...)
Container(color: Colors.white, ...)
Card(color: Colors.white, ...)

// APRÈS
Scaffold(backgroundColor: palette.pageGradient.colors.first, ...)
Container(color: palette.card, ...)
Card(color: palette.card, ...)
```

**Hiérarchie des tokens de surface :**

| Niveau | Token | Usage |
|--------|-------|-------|
| Fond de page | `palette.pageGradient.colors.first` | Scaffold backgroundColor |
| Carte principale | `palette.card` | Container/Card de premier niveau |
| Carte secondaire | `palette.cardAlt` | Sous-sections, champs, encadrés |
| Info/conseil | `palette.infoSurface` | Encadré bleu informatif (ex. "Comment ça marche ?") |
| Erreur | `palette.dangerSurface` | Container d'erreur |

**Cas particuliers :**
- `checkout_screen.dart` : ne **pas** toucher à `_buildInputDecoration` (déjà propre).
- `rdv_screen.dart` : supprimer `static const _bgColor` et lire `context.maasga.pageGradient.colors.first` directement dans `build`.
- Texte `const Color(0xFF1A1A1A)` → `palette.textPrimary`.
- Texte `const Color(0xFF475467)` → `palette.textSecondary`.
- Texte `const Color(0xFF757575)` → `palette.textMuted`.

---

## Tâche 1.4 — Unification de la typographie

### Problème

Quatre fichiers appellent `GoogleFonts.poppins(fontSize: X, fontWeight: Y, color: Z)` directement. Or `AppTheme.light()` et `AppTheme.dark()` déclarent déjà `fontFamily: GoogleFonts.poppins().fontFamily` — la famille est donc héritée de `Theme`. Ces appels directs créent une dépendance inutile sur le package et empêchent une future migration de police centralisée.

### Solution

Remplacer `GoogleFonts.poppins(...)` par :

```dart
// Option A — quand on veut rester sémantique (corps, légendes, titres)
Theme.of(context).textTheme.bodyMedium?.copyWith(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: palette.textPrimary,
)

// Option B — quand la taille ou la graisse est très spécifique (préférable)
TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: palette.textPrimary,
)
// La famille est héritée du thème — pas besoin de la spécifier.
```

**Fichiers cibles :** `product_list_card.dart`, `catalog_screen.dart`, `cart_screen.dart`, `checkout_screen.dart`.

**À ne pas toucher :** `login_screen.dart`, `register_screen.dart`, et tout fichier qui utilise déjà la palette correctement.

**Import à supprimer** : une fois tous les `GoogleFonts.poppins()` supprimés d'un fichier, supprimer l'import `package:google_fonts/google_fonts.dart`.

---

## Tâche 1.5 — Migration GestureDetector → InkWell

### Problème

Plusieurs cartes et chips utilisent `GestureDetector` qui ne produit aucun retour visuel (splash, highlight), ce qui nuit à l'expérience Material.

### Solution

**`product_list_card.dart`** — envelopper dans `Material` + `InkWell` :

```dart
// AVANT
GestureDetector(
  onTap: onTap,
  child: Container(
    decoration: BoxDecoration(
      color: palette.card,
      borderRadius: BorderRadius.circular(16),
      ...
    ),
    child: ...,
  ),
)

// APRÈS
Material(
  color: Colors.transparent,
  borderRadius: BorderRadius.circular(16),
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        ...
      ),
      child: ...,
    ),
  ),
)
```

Le `Material` transparent est nécessaire pour que le ripple `InkWell` s'affiche au-dessus de la couleur de fond du `Container`.

**`simulator_screen.dart`** — les chips de sélection (surface, hauteur, exposition, type pièce) utilisent des `GestureDetector` → remplacer par `InkWell` avec le `borderRadius` correspondant au chip.

**`rdv_screen.dart`** — vérifier `ServiceTypeCard` : si elle encapsule un `GestureDetector`, le remplacer par `InkWell`.

**Règle générale :** conserver exactement la même callback `onTap`, les mêmes dimensions, et le même padding. Ne pas modifier les décorations visuelles.

---

## Tâche 1.6 — Suppression du wrapper _isMounted()

### Problème

`_CheckoutScreenState` déclare :

```dart
bool _isMounted() => mounted;
```

Ce wrapper n'apporte aucune valeur : `mounted` est déjà une propriété publique de `State`. Il ajoute de l'indirection et peut induire en erreur sur les pratiques Flutter modernes (le linter Dart recommande d'utiliser `mounted` directement).

### Solution

1. Supprimer la méthode `_isMounted()`.
2. Remplacer chaque `if (!_isMounted()) return;` et `if (_isMounted())` par `if (!mounted) return;` et `if (mounted)`.
3. Vérifier qu'aucun autre appel à `_isMounted()` ne subsiste.

```dart
// AVANT
if (!_isMounted()) return;
if (_isMounted()) {
  setState(() => _loading = false);
}

// APRÈS
if (!mounted) return;
if (mounted) {
  setState(() => _loading = false);
}
```

---

## Propriétés de Correction

*Une propriété est une caractéristique ou un comportement devant rester vrai pour toutes les exécutions valides du système — c'est-à-dire une spécification formelle de ce que le système doit faire.*

### Propriété 1 : Absence de debugPrint nu en production

*Pour tout appel à `debugPrint` dans `catalog_screen.dart`, cet appel doit être contenu dans un bloc `if (kDebugMode)`, de sorte qu'il ne s'exécute jamais en mode release.*

**Validates : Exigences 1.1, 1.2**

### Propriété 2 : Absence de la constante de couleur hardcodée dans les fichiers cibles

*Pour tout fichier parmi les 7 fichiers cibles de l'exigence 2, aucune occurrence de `Color(0xFF1B3A8D)` ne doit subsister dans le code source après application des modifications.*

**Validates : Exigences 2.1, 2.2, 2.5**

### Propriété 3 : Comportement onTap préservé après migration InkWell

*Pour tout widget migré de `GestureDetector` vers `InkWell`, un appui simulé sur le widget doit déclencher exactement la même callback `onTap` qu'avant la migration.*

**Validates : Exigences 5.1, 5.2, 5.3, 5.4**

### Propriété 4 : Absence du wrapper _isMounted() dans CheckoutScreen

*Pour tout appel à `_isMounted()` qui existait dans `_CheckoutScreenState`, il doit être remplacé par `mounted`, et la méthode `_isMounted()` ne doit plus exister dans la classe.*

**Validates : Exigences 6.1, 6.2, 6.3**

---

## Stratégie de tests

### Tests unitaires et de widgets

- Chaque migration `GestureDetector → InkWell` peut être validée par un widget test vérifiant la présence d'un `InkWell` dans l'arbre et la bonne propagation du `onTap`.
- L'absence des couleurs hardcodées et des imports `google_fonts` peut être vérifiée par `flutter analyze` (lint) ou des tests de fichier.
- La suppression de `_isMounted()` est validée par `flutter analyze` (la méthode non utilisée serait signalée si elle existait encore).

### Tests de compilation (smoke)

- `flutter build apk --release` doit compiler sans erreur.
- `flutter analyze` ne doit signaler aucun warning sur les fichiers modifiés.

### Tests de rendu

- La conformité dark mode ne peut être vérifiée rigoureusement qu'avec des golden tests ou une revue visuelle. Une session de test sur appareil/émulateur en thème sombre est recommandée après chaque tâche 1.3.
