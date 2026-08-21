# MAASGA Mobile — Backlog d'implémentation

Mis à jour : 21 août 2026. Ce fichier décrit l'état **réel** du code de ce
dépôt, et non le plan initial : les sprints V1 sont terminés, ce qui suit est
la liste de ce qui reste.

## Périmètre technique actuel

- **Auth : Firebase Auth** (e-mail, téléphone `+226` via e-mail synthétique,
  Google Sign-In). Il n'y a plus d'endpoint `/api/login` ni `/api/register`
  côté site. Réinitialisation de mot de passe et vérification d'e-mail en
  place.
- **Réseau** : Dio + cookie jar persistant, token Firebase ID envoyé en
  `Bearer` (`lib/core/network/api_client.dart`).
- **Endpoints consommés** : `/api/mobile/products`, `/api/mobile/banners`,
  `/api/mobile/commandes`, `/api/mobile/rdv`, `/api/mobile/maintenance`,
  `/api/mobile/client-dashboard`, `/api/mobile/order/{id}/devis-action`,
  `/api/mobile/activity`, `/api/simulateur/btu`,
  `/api/maintenance/invoice/{id}`, `/api/client/push-token`.
- **Plateformes** : Android uniquement. `web/` et `windows/` sont des
  scaffolds Flutter jamais testés, il n'y a pas de dossier `ios/`.
- **Paiement en ligne : retiré.** `payment_redirect_screen.dart` et
  `payment_webview_screen.dart` ont été supprimés au profit de
  `order_confirmation_screen.dart` — la commande est enregistrée, le paiement
  se convient hors application.

## Bloquant — compilation depuis un clone neuf

- [ ] Versionner `android/app/google-services.json` et
      `lib/core/config/firebase_options.dart`. Ils ne sont aujourd'hui pas
      suivis par git, alors que `lib/main.dart` importe le second et que
      `android/app/build.gradle.kts` applique `com.google.gms.google-services`
      : sans eux, ni un clone neuf ni le job `build-apk` de la CI ne compile.

## Backend (worker MAASGA — hors de ce dépôt)

- [ ] **Recalculer le total côté serveur** dans `/api/mobile/commandes`. Le
      client envoie `total_price` *et* le détail `items[]` avec les
      `unit_price` : le worker doit ignorer `total_price` et recalculer à
      partir de ses propres prix. Sans ça, un client modifié peut annoncer
      1 FCFA (cf. `lib/features/cart/presentation/checkout_screen.dart`).
- [ ] Confirmer `/api/client/push-token` (POST + DELETE) — seul endpoint hors
      du préfixe `/api/mobile/*`. S'il n'existe pas, aucun token FCM n'est
      enregistré et l'échec est **silencieux** (`push_service.dart` avale
      l'exception).
- [ ] Endpoint d'annulation de commande, requis par « Annuler et rembourser »
      dans l'espace client.
- [ ] Trancher le retour éventuel du paiement en ligne (Orange Money / Moov)
      en V1.1, et prévoir alors le callback (deep link + `intent-filter`).
- [ ] Recherche serveur (`?q=`) sur `/api/mobile/products` : la recherche est
      pour l'instant faite en mémoire côté app, ce qui suffit tant que le
      catalogue reste petit.

## Fonctionnel

- [x] Recherche produit (`/search`) : filtrage plein texte insensible aux
      accents sur le catalogue chargé, suggestions par marque et catégorie,
      barre de recherche de l'accueil branchée dessus.
- [x] Bouton « Découvrir » des bannières promo : navigue vers le
      `target_page` renvoyé par le serveur, filtré par liste blanche (comme
      les routes de notification push).
- [x] Écran Réglages réel : sélecteur de thème auto / clair / sombre, envoi
      d'une notification de test, version affichée. Les tuiles purement
      décoratives ont été retirées, dont « Sécurité — PIN / biométrie
      (bientôt) » qui annonçait une fonctionnalité absente du code.
- [ ] `/address` : `address_selection_screen.dart` est encore un placeholder
      et aucun écran n'y navigue. Soit implémenter la sélection d'adresse
      (le checkout gère déjà GPS + quartier + adresse précise), soit
      supprimer l'écran et sa route.
- [ ] « Annuler et rembourser » une commande : le bouton n'affiche qu'un
      SnackBar « bientôt disponible » (`client_space_screen.dart`).
- [ ] Cloche de notifications : `MaasgaAppBar.notificationsCount` vaut `3` en
      dur — la brancher sur le nombre réel d'éléments non lus
      (`/api/mobile/activity`).

## Sécurité / publication

- [ ] Restreindre la clé Google Maps de `AndroidManifest.xml` au package
      `com.maasga.app` + empreinte SHA-1 dans Google Cloud Console. Elle est
      versionnée en clair, ce qui n'est acceptable *que* si elle est
      restreinte.
- [ ] Générer le keystore de publication et `android/key.properties` (non
      versionné) : sans lui, `flutter build appbundle --release` échoue
      volontairement.
- [ ] QA manuelle d'un APK release réellement signé. R8 est activé et la CI
      compile déjà une release de test, mais une règle ProGuard manquante ne
      se voit qu'à l'exécution.
- [ ] Aucun `intent-filter` de deep link / App Links : les liens web MAASGA
      n'ouvrent pas l'application.

## Qualité

- [ ] Tests : seuls `test/widget_test.dart` (smoke de démarrage) et
      `test/widgets_test.dart` (3 widgets présentationnels) existent.
      Manquent le panier (`cart_state.dart`), le calcul BTU
      (`btu_calculator.dart`), la normalisation `+226`
      (`auth_repository.dart`), les repositories avec Dio mocké, et les
      parcours RDV / checkout.
- [ ] Supprimer `lib/app/bootstrap/bootstrap.dart` — fichier vide qui porte
      lui-même la mention « FICHIER MORT ».
- [ ] `api_client.dart` : sur une 401, se contente d'un `debugPrint`. Forcer
      un `getIdToken(true)` puis rejouer la requête une seule fois.
- [ ] Décider du sort de `web/` et `windows/`, et créer le projet iOS
      (+ config Firebase / Maps / Sign-In) si le multiplateforme est visé.
- [ ] `.vscode/` n'est ni suivi ni ignoré (la ligne `#.vscode/` du
      `.gitignore` est commentée).
