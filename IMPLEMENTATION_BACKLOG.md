# MAASGA Mobile — Backlog d'implémentation

Mis à jour : **6 septembre 2026**. Ce fichier décrit l'état **réel** du code de
ce dépôt. Les sprints V1 et V1.1 de stabilisation sont terminés.

---

## Périmètre technique actuel

- **Auth** : Firebase Auth (e-mail, téléphone `+226` via e-mail synthétique,
  Google Sign-In). Réinitialisation de mot de passe et vérification d'e-mail
  en place.
- **Réseau** : Dio + cookie jar persistant, token Firebase ID en `Bearer`,
  un seul rejeu sur 401 après rafraîchissement du token
  (`lib/core/network/auth_interceptor.dart`).
- **Endpoints consommés** : `/api/mobile/products`, `/api/mobile/banners`,
  `/api/mobile/commandes`, `/api/mobile/commandes/{id}/annuler`,
  `/api/mobile/rdv`, `/api/mobile/maintenance`,
  `/api/mobile/client-dashboard`, `/api/mobile/order/{id}/devis-action`,
  `/api/mobile/activity`, `/api/mobile/register`, `/api/simulateur/btu`,
  `/api/maintenance/invoice/{id}`, `/api/client/push-token` (POST + DELETE).
- **Plateformes** : Android uniquement. `web/` et `windows/` sont des
  scaffolds Flutter jamais testés, pas de dossier `ios/`.
- **Paiement en ligne : retiré** — décision V1.1 en attente.

---

## ✅ Accompli — Audit sécurité (11 nov. 2026)

Rapport complet : `../AUDIT_2026-11-11.md`.

- [x] Boucle infinie sur 401 persistant : `FirebaseAuthInterceptor` rejoue une
  seule fois (flag `extra`) sans écraser le token rafraîchi — testé
  (`test/core/auth_interceptor_test.dart`)
- [x] `/catalog/product` sans `Product` en `extra` → redirection `/catalog`
  au lieu d'un crash de cast — testé (`test/core/app_router_guard_test.dart`)
- [x] `debugPrint` de `auth_controller.dart` limités au mode debug
- [x] Clé Google Maps inutilisée et permissions de localisation retirées du
  manifeste (la clé reste à supprimer dans Google Cloud Console)
- [ ] Reste : Sentry à brancher, `catch (_) {}` silencieux, `debugPrint` non gardés dans
  les repositories, gate `dart format` en échec sur 39 fichiers

---

## ✅ Accompli — Sprint stabilisation (6 sept. 2026)

### Compilation / CI
- [x] Typo `flutter_riverbot` → `flutter_riverpod` dans `app_router.dart`
- [x] Import fantôme `address_selection_screen.dart` supprimé du router
- [x] Import `flutter/foundation.dart` ajouté dans `auth_controller.dart`
- [x] Lint `unnecessary_underscores` corrigé dans `activity_repository.dart`
- [x] Syntaxe lambda `Provider` corrigée dans `push_service.dart`
- [x] `print()` → `debugPrint()` dans `auth_controller.dart` (avoid_print)
- [x] `handler.request()` → `dio.fetch() + handler.resolve()` dans `api_client.dart`
- [x] Import `dart:developer` inutilisé supprimé dans `api_client.dart`
- [x] Tests `auth_repository_test.dart` corrigés (méthodes privées inaccessibles)
- [x] **`flutter analyze` : No issues found**

### Backend (worker maasga-code)
- [x] `/api/client/push-token` POST + DELETE implémentés (table `push_tokens`)
- [x] `/api/mobile/register` confirmé présent
- [x] `/api/mobile/commandes/{id}/annuler` POST implémenté (mobileAuth)
- [x] Recalcul du `total_price` côté serveur dans `/api/mobile/commandes`
      (ignoré du client, recalculé depuis `products.price × quantity` en D1)
- [x] Migration D1 `0040_push_tokens.sql` créée

### Publication Android
- [x] Keystore de publication généré : `~/maasga-upload.jks`
      alias=`upload`, RSA 2048, validité 10 000 jours
      SHA-1 : `54:C1:F8:B2:A6:5A:27:83:8F:70:75:FA:11:AD:F4:55:57:29:8C:2B`
      SHA-256 : `B3:9F:69:5A:65:D5:BF:D2:DC:42:9D:8C:9B:14:26:55:CA:0D:8B:C8:2E:8E:EA:1F:B1:02:67:59:01:C9:51:F4`
- [x] `android/key.properties` mis à jour (pointe sur le vrai keystore)
- [x] `proguard-rules.pro` complété : Google Sign-In, OkHttp/Dio, cookie_jar,
      path_provider, flutter_local_notifications
- [x] `android:autoVerify="true"` ajouté sur l'intent-filter deep link
- [x] `assetlinks.json` créé dans `docs/` (mobile) et `public/.well-known/`
      (maasga-code) — déployé automatiquement via `npm run build`
- [x] `KEYSTORE_GUIDE.md` mis à jour avec empreintes et instructions GCP

---

## 🔴 Actions manuelles requises avant mise en production

### 1 — Appliquer la migration D1
```bash
wrangler d1 migrations apply maasga_db --remote
```
Sans cette commande, les routes `/api/client/push-token` retournent une erreur
D1 `no such table: push_tokens`.

### 2 — Restreindre la clé Google Maps dans GCP
Console → APIs & Services → Credentials → `AIzaSyA7...`
- Application restriction : **Android apps**
- Package : `com.maasga.app`
- SHA-1 : `54:C1:F8:B2:A6:5A:27:83:8F:70:75:FA:11:AD:F4:55:57:29:8C:2B`
- API restriction : **Maps SDK for Android** uniquement

### 3 — QA release sur appareil physique
```bash
flutter build apk --release
# Installer l'APK et tester : login → catalogue → panier → commande → notifications
```
R8 est actif — une règle ProGuard manquante ne se voit qu'à l'exécution sur
un APK release, jamais en debug.

---

## Format de livraison APK — Décision

| Scénario | Commande | Taille | Notes |
|----------|----------|--------|-------|
| **Play Store** | `flutter build appbundle --release` | ~15 Mo (AAB) | Google gère le split ABI côté store |
| **Distribution directe (recommandé)** | `flutter build apk --release --split-per-abi` | ~25 Mo / ABI | Distribuer `arm64-v8a` pour les téléphones récents |
| Distribution directe universelle | `flutter build apk --release` | ~68 Mo | 63 Mo de code natif dupliqué — à éviter |

**Recommandation** : pour la distribution directe (hors Play Store), utiliser
`--split-per-abi` et distribuer uniquement `app-arm64-v8a-release.apk` —
couvre 95 %+ des appareils Android actuels au Burkina Faso. Garder
`app-armeabi-v7a-release.apk` en réserve pour les appareils anciens.

---

## En suspens — Fonctionnel

- [x] `/address` : `address_selection_screen.dart` supprimé (fichier vide,
      aucun écran n'y naviguait).
- [ ] Paiement en ligne V1.1 (Orange Money / Moov) : décision produit en
      attente. Prévoir alors un deep link callback + `intent-filter` dédié.
- [ ] Recherche serveur `?q=` sur `/api/mobile/products` : suffisant en
      mémoire tant que le catalogue reste petit.

## En suspens — Sécurité / Publication

- [ ] **Appliquer migration `0040_push_tokens`** (voir Actions manuelles #1)
- [ ] **Restreindre clé Google Maps dans GCP** (voir Actions manuelles #2)
- [ ] **QA release sur appareil physique** (voir Actions manuelles #3)
- [ ] Tester les App Links sur appareil en build release :
      `adb shell pm get-app-links com.maasga.app`

## En suspens — Qualité

- [x] Tests checkout : `test/checkout_state_test.dart` (10 tests — CartLine,
      total panier, payload items[])
- [x] Tests RDV : `test/rdv_request_test.dart` (12 tests — sérialisation JSON,
      validation téléphone, quartiers)
- [ ] Tests repositories avec Dio mocké (nécessite `mockito` + setup réseau)

## Plateformes — Décisions

### `web/` et `windows/` — À supprimer

Ces deux dossiers sont des **scaffolds Flutter générés automatiquement**, jamais
configurés ni testés. Les retenir représente une dette sans valeur :

- Aucune dépendance plugin n'est configurée pour le web (Firebase Web SDK,
  Google Maps JS, cookie storage) — l'app planterait immédiatement au démarrage
- `windows/` n'a aucune configuration Firebase ni Maps
- Maintenir ces dossiers donne l'illusion d'un support multiplateforme inexistant

**Recommandation : supprimer `web/` et `windows/` via** :
```bash
flutter config --no-enable-web
flutter config --no-enable-windows-desktop
# Puis supprimer manuellement les dossiers
Remove-Item -Recurse -Force web, windows
# Et retirer les entrées correspondantes dans pubspec.yaml si présentes
```

### iOS — Non commencé, à planifier séparément

Créer un projet iOS (si multiplateforme visé) implique :
1. `flutter create --platforms=ios .` depuis un Mac avec Xcode
2. `firebase_options.dart` mis à jour avec les options iOS (FlutterFire CLI)
3. `GoogleService-Info.plist` ajouté dans `ios/Runner/`
4. Clé Google Maps iOS dans `AppDelegate.swift`
5. Google Sign-In configuré dans `Info.plist` (URL scheme)
6. Tests sur simulateur puis appareil physique (TestFlight)

Ce travail ne peut pas se faire depuis Windows — il nécessite un Mac avec
Xcode 15+. À prévoir si la distribution iOS est dans la roadmap.
