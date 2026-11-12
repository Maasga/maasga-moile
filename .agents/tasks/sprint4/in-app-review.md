# Tâche 4.3 — In-App Review après confirmation de commande

## Ce qui a été fait

- `OrderConfirmationScreen` converti de `StatelessWidget` en `StatefulWidget`
  (paire `OrderConfirmationScreen` / `_OrderConfirmationScreenState`).
- `initState()` ajouté dans `_OrderConfirmationScreenState` : 2 secondes après
  l'affichage de l'écran, la demande d'avis Play Store / App Store est déclenchée
  via `InAppReview.instance`, uniquement si le widget est toujours monté et si
  la fonctionnalité est disponible sur l'appareil.
- Import `package:in_app_review/in_app_review.dart` ajouté en tête de fichier.
- Les références aux champs (`orderId`, `clientName`, `clientPhone`, `total`)
  dans le `build` ont été mises à jour en `widget.*` (obligation liée au passage
  en `StatefulWidget`).
- `_openEmail` et `_openWhatsApp` déplacées dans l'état (`_OrderConfirmationScreenState`).

## Fichier modifié

`lib/features/cart/presentation/order_confirmation_screen.dart`

## Vérification

```
flutter analyze lib/  →  No issues found!
```

## Dépendance

`in_app_review: ^2.0.12` était déjà déclarée dans `pubspec.yaml` — aucune
modification du manifeste nécessaire.
