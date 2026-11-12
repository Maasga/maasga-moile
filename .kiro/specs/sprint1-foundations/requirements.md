# Document de Spécifications — Sprint 1 : Foundations

## Introduction

Ce sprint traite six chantiers de nettoyage et de dette technique dans l'application Flutter Android MAASGA (catalogue de climatiseurs, Burkina Faso). Les travaux portent sur : la suppression des `debugPrint` de production, l'unification de la couleur hardcodée `0xFF1B3A8D`, la conformité dark mode des surfaces, l'unification de la typographie, la migration `GestureDetector → InkWell`, et la suppression du wrapper `_isMounted()`. Aucune fonctionnalité nouvelle n'est introduite ; toutes les modifications sont internes à la présentation et n'altèrent ni les contrats API, ni les providers Riverpod existants.

---

## Glossaire

- **MaasgaPalette** : ThemeExtension enregistrée dans `AppTheme.light()` et `AppTheme.dark()` ; accessible via `context.maasga`.
- **MaasgaTokens** : classe de constantes de couleurs et d'espacements indépendantes du thème (ex. `MaasgaTokens.blue900 = Color(0xFF0B3F8A)`).
- **context.maasga** : raccourci d'extension `BuildContext.maasga` retournant la `MaasgaPalette` courante.
- **palette.accent** : couleur interactive de marque — bleu en clair (`0xFF0077B6`), cyan en sombre (`0xFF6FD3E8`).
- **debugPrint** : fonction Flutter affichant des messages en console ; ne doit pas s'exécuter en mode release.
- **kDebugMode** : constante booléenne Flutter valant `true` uniquement en mode debug.
- **GestureDetector** : widget de bas niveau sans retour visuel d'interaction (splash/ripple).
- **InkWell** : widget Material avec retour visuel d'interaction conforme au Material Design.
- **MaasgaShell** : widget racine partagé appliquant le dégradé `pageGradient` en fond de page.
- **mounted** : propriété native d'un `State` Flutter indiquant si le widget est toujours dans l'arbre.
- **Écrans cibles** : `catalog_screen.dart`, `product_list_card.dart`, `product_detail_screen.dart`, `cart_screen.dart`, `checkout_screen.dart`, `rdv_screen.dart`, `simulator_screen.dart`, `client_space_screen.dart`.

---

## Exigences

### Exigence 1 — Suppression des debugPrint de production (tâche 1.1)

**User Story :** En tant que développeur, je veux que les logs de débogage ne s'exécutent pas en mode release, afin d'éviter la sérialisation répétée de données lourdes à chaque rebuild en production.

#### Critères d'acceptation

1. THE Système SHALL supprimer ou conditionner dans un bloc `if (kDebugMode)` chaque appel `debugPrint` présent dans `catalog_screen.dart`.
2. WHEN l'application est compilée en mode release (`flutter build apk --release`), THE Système SHALL ne produire aucune trace `debugPrint` issue de `catalog_screen.dart`.
3. WHEN `kDebugMode` est `true`, THE Système SHALL exécuter les blocs `debugPrint` conditionnels sans erreur de compilation ni d'exécution.
4. THE Système SHALL ne modifier aucun fichier autre que `catalog_screen.dart` pour cette exigence.

---

### Exigence 2 — Unification de la couleur hardcodée 0xFF1B3A8D (tâche 1.2)

**User Story :** En tant que développeur, je veux que la couleur `0xFF1B3A8D` soit remplacée par les tokens de design, afin que la charte graphique soit gérée en un seul endroit et que l'application reste cohérente en dark mode.

#### Critères d'acceptation

1. THE Système SHALL remplacer chaque occurrence de `const Color(0xFF1B3A8D)` utilisée comme couleur de surface, d'accent ou de texte dans les widgets avec `BuildContext` par `context.maasga.accent`.
2. THE Système SHALL remplacer chaque occurrence de `const Color(0xFF1B3A8D)` utilisée dans des styles statiques (sans `BuildContext`) par `MaasgaTokens.blue900`.
3. THE Système SHALL effectuer ces remplacements dans les fichiers suivants uniquement : `product_list_card.dart`, `product_detail_screen.dart`, `rdv_screen.dart`, `checkout_screen.dart`, `simulator_screen.dart`, `client_space_screen.dart`, `cart_screen.dart`.
4. THE Système SHALL ne modifier ni `app_theme.dart` ni `maasga_tokens.dart`.
5. AFTER le remplacement, THE Système SHALL ne contenir aucune occurrence de `Color(0xFF1B3A8D)` dans les fichiers cibles.

---

### Exigence 3 — Dark mode sur les écrans non conformes (tâche 1.3)

**User Story :** En tant qu'utilisateur, je veux que tous les écrans soient lisibles en mode sombre, afin de ne pas voir de fonds blancs ou gris clairs figés qui brisent l'expérience visuelle.

#### Critères d'acceptation

1. THE Système SHALL remplacer `backgroundColor: Colors.white` et `backgroundColor: const Color(0xFFF5F5F5)` dans les `Scaffold` des écrans `product_detail_screen.dart`, `cart_screen.dart`, `rdv_screen.dart` par `palette.pageGradient.colors.first` ou un Container avec `palette.pageGradient` en décoration.
2. THE Système SHALL remplacer les fonds `Colors.white` des `Container` et `Card` de surface dans `product_detail_screen.dart`, `cart_screen.dart`, `checkout_screen.dart`, `rdv_screen.dart`, `simulator_screen.dart` par `palette.card` ou `palette.cardAlt` selon le niveau de hiérarchie visuelle.
3. THE Système SHALL remplacer les couleurs de texte hardcodées `const Color(0xFF1A1A1A)` par `palette.textPrimary` dans les écrans cibles de cette exigence.
4. THE Système SHALL remplacer la constante statique `static const _bgColor = Color(0xFFF5F5F5)` dans `rdv_screen.dart` par une lecture dynamique `context.maasga.pageGradient.colors.first` ou supprimer la constante et appliquer la palette directement.
5. THE Système SHALL NE PAS modifier la méthode `_buildInputDecoration` dans `checkout_screen.dart` (déjà conforme).
6. WHEN le thème bascule en mode sombre, THE Système SHALL afficher des surfaces utilisant les tokens `palette.card`, `palette.cardAlt` et `palette.pageGradient` sans aucune couleur blanche ou grise fixe visible.
7. THE Système SHALL appliquer les remplacements en déclarant `final palette = context.maasga;` en tête de la méthode `build` de chaque widget concerné.

---

### Exigence 4 — Unification de la typographie (tâche 1.4)

**User Story :** En tant que développeur, je veux que les widgets n'importent plus `GoogleFonts.poppins(...)` directement, afin que la famille de police soit héritée du thème et que les widgets restent cohérents si la charte typographique évolue.

#### Critères d'acceptation

1. THE Système SHALL remplacer chaque appel `GoogleFonts.poppins(fontSize: X, fontWeight: Y, color: Z)` dans les fichiers cibles (`product_list_card.dart`, `catalog_screen.dart`, `cart_screen.dart`, `checkout_screen.dart`) par `Theme.of(context).textTheme.<style>?.copyWith(...)` ou `TextStyle(fontSize: X, fontWeight: Y, color: Z)`.
2. THE Système SHALL ne pas modifier les écrans auth (`login_screen.dart`, `register_screen.dart`) ni les fichiers qui utilisent déjà la palette correctement.
3. AFTER le remplacement, THE Système SHALL ne contenir aucun import `package:google_fonts/google_fonts.dart` dans les fichiers `product_list_card.dart`, `catalog_screen.dart`, `cart_screen.dart`, `checkout_screen.dart` si plus aucun appel `GoogleFonts` n'y subsiste.
4. THE Système SHALL conserver l'apparence visuelle identique en mode clair (taille, graisse et couleur de police inchangées fonctionnellement).

---

### Exigence 5 — Migration GestureDetector → InkWell (tâche 1.5)

**User Story :** En tant qu'utilisateur, je veux voir un retour visuel (effet ripple) lorsque je touche une carte ou un chip, afin que l'interface soit conforme aux standards Material Design.

#### Critères d'acceptation

1. THE Système SHALL remplacer le `GestureDetector` racine de `ProductListCard` dans `product_list_card.dart` par un `InkWell` avec `borderRadius: BorderRadius.circular(16)`, encapsulé dans un `Material` à `color: Colors.transparent` pour que le ripple s'affiche correctement sur le fond de carte.
2. THE Système SHALL remplacer les `GestureDetector` des chips de sélection (surface, hauteur, exposition, type pièce) dans `simulator_screen.dart` par des `InkWell`.
3. WHEN un widget `ServiceTypeCard` dans `rdv_screen.dart` utilise un `GestureDetector`, THE Système SHALL le remplacer par un `InkWell`.
4. WHEN un `GestureDetector` est remplacé par `InkWell`, THE Système SHALL conserver la même callback `onTap` et les mêmes dimensions visuelles.

---

### Exigence 6 — Suppression du wrapper _isMounted() (tâche 1.6)

**User Story :** En tant que développeur, je veux supprimer le wrapper `_isMounted()` inutile dans `checkout_screen.dart`, afin d'utiliser directement la propriété `mounted` native et de simplifier le code.

#### Critères d'acceptation

1. THE Système SHALL supprimer la méthode `bool _isMounted() => mounted;` de la classe `_CheckoutScreenState` dans `checkout_screen.dart`.
2. THE Système SHALL remplacer chaque appel `_isMounted()` dans `checkout_screen.dart` par `mounted`.
3. AFTER le remplacement, THE Système SHALL compiler `checkout_screen.dart` sans erreur ni warning lié à `_isMounted`.
4. THE Système SHALL ne modifier aucun autre comportement logique de `checkout_screen.dart` dans le cadre de cette exigence.
