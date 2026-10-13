# Implementation Plan

- [x] 1. Write bug condition exploration test — session périmée (Bug 2)
  - **Property 1: Bug Condition** - Stale Cookie Session Data
  - **CRITICAL** : Ce test DOIT ÉCHOUER sur le code non corrigé (commit `4e966dc`) — l'échec confirme que le bug existe
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE** : Ce test encode le comportement attendu — il validera le correctif une fois qu'il passera après l'implémentation
  - **GOAL** : Faire apparaître des contre-exemples qui démontrent que le cookie jar périmé pollue la session suivante
  - **Scoped PBT Approach** : Scoper la propriété au cas concret déterministe — `cookieJarHasPreviousSession=true` + `userJustSignedIn=true` — pour garantir la reproductibilité
  - Créer le fichier `test/features/auth/auth_controller_pbt_test.dart`
  - Configurer un `ProviderContainer` avec un `cookieJarProvider` mocké pré-chargé avec un cookie de session appartenant à `uid_A`
  - Appeler `AuthController.loginWithGoogle()` avec un mock `AuthRepository` qui complète sans erreur et qui retourne `uid_B` comme `currentUser`
  - Sur le code NON corrigé (sans `_startCleanSession`), vérifier que `cookieJar.loadForRequest(Uri.parse(Env.apiBaseUrl))` contient encore le cookie de la session A après le login
  - Le test doit ÉCHOUER sur `4e966dc` (le cookie de A est toujours présent = contre-exemple trouvé)
  - Documenter le contre-exemple : `"loginWithGoogle() appelé avec uid_B : cookieJar contient encore le cookie de uid_A — backend répondrait avec les données de A"`
  - Marquer la tâche complète quand le test est écrit, exécuté et l'échec documenté
  - _Requirements: 1.2_

- [ ] 2. Write preservation property tests — comportements non affectés (BEFORE implementing fix)
  - **Property 2: Preservation** - Non-Buggy Sign-in Flows Unchanged
  - **IMPORTANT** : Suivre la méthodologie observation-first
  - Créer `test/features/auth/auth_controller_preservation_test.dart`
  - Observer sur le code NON corrigé : `login()` avec jar vide → `clearSessionCookies` n'est PAS appelé mais le flux se termine sans erreur
  - Observer sur le code NON corrigé : `logout()` → `clearSessionCookies` est appelé (déjà implémenté)
  - Observer sur le code NON corrigé : `loginWithGoogleTokens()` avec jar vide → la connexion se termine sans erreur
  - **Property 2a** : Pour tout appel `login(identifier, password)` avec un jar vide, le résultat est `AsyncData(true)` et Firebase `currentUser != null`
  - **Property 2b** : Pour tout appel `logout()`, `clearSessionCookies` est invoqué et Firebase `signOut()` est invoqué
  - **Property 2c** : Pour tout appel `loginWithGoogleTokens(idToken, accessToken)`, le flux se termine avec `AsyncData(true)` quel que soit l'état initial du jar
  - **Property 2d** : Si `clearSessionCookies` lève une exception, le flux de connexion se poursuit sans bloquer (`_startCleanSession` absorbe les erreurs)
  - Vérifier que les tests passent sur le code NON corrigé (baseline confirmée)
  - Marquer la tâche complète quand les tests sont écrits, exécutés et passent sur le code non corrigé
  - _Requirements: 3.2, 3.3, 3.4_

- [ ] 3. Fix — APK release auth & stale session

  - [ ] 3.1 Vérifier la configuration Firebase Console (Bug 1)
    - Ouvrir Firebase Console → projet `maasga-83b35` → ⚙️ Project settings → Application Android `com.maasga.app`
    - Sous "Empreintes digitales du certificat SHA", vérifier que les deux empreintes release sont présentes :
      - SHA-1 : `54:C1:F8:B2:A6:5A:27:83:8F:70:75:FA:11:AD:F4:55:57:29:8C:2B`
      - SHA-256 : `B3:9F:69:5A:65:D5:BF:D2:DC:42:9D:8C:9B:14:26:55:CA:0D:8B:C8:2E:8E:EA:1F:B1:02:67:59:01:C9:51:F4`
    - Si absentes : les ajouter et sauvegarder
    - Télécharger le nouveau `google-services.json` et remplacer `android/app/google-services.json`
    - Vérifier que le nouveau fichier contient deux blocs `oauth_client` de `client_type: 1` — un avec le hash debug `c884cc...`, un avec le hash release `54c1f8...`
    - Committer `android/app/google-services.json`
    - _Bug_Condition: isBugConditionAuth(X) où X.buildMode = release AND X.signingKeyFingerprint NOT IN registeredFingerprintsInFirebaseConsole()_
    - _Expected_Behavior: AuthController.loginWithGoogle() complète le flux OAuth et retourne FirebaseAuth.currentUser != null avec idToken valide_
    - _Requirements: 1.1, 2.1_

  - [ ] 3.2 Vérifier le correctif de code `_startCleanSession()` (Bug 2 — commit `c85daa1`)
    - Confirmer que `auth_controller.dart` contient la méthode `_startCleanSession()` qui appelle `clearSessionCookies(ref)` avec absorption des erreurs
    - Confirmer que `_startCleanSession()` est appelé en tête de `login()` AVANT `repo.login()`
    - Confirmer que `_startCleanSession()` est appelé en tête de `loginWithGoogle()` AVANT `repo.loginWithGoogle()`
    - Confirmer que `_startCleanSession()` est appelé en tête de `loginWithGoogleTokens()` AVANT `repo.signInWithGoogleTokens()`
    - Confirmer que `_startCleanSession()` est appelé en tête de `register()` AVANT `repo.register()`
    - Confirmer que `logout()` appelle toujours `clearSessionCookies(ref)` (déjà présent, non régressé)
    - Confirmer que `build()` ne contient PAS d'appel à `_startCleanSession()` (ne pas vider le jar au démarrage d'une session active)
    - _Bug_Condition: isBugConditionSession(X) où X.cookieJarHasPreviousSession=true AND X.userJustSignedIn=true AND X.loginMethodCalled IN ['login', 'loginWithGoogle', 'loginWithGoogleTokens', 'register']_
    - _Expected_Behavior: clearSessionCookies(ref) est appelé avant chaque méthode Firebase de connexion — le premier appel /api/mobile/* retourne les données du currentUser.uid courant_
    - _Preservation: debug build, email/phone login sans session précédente, logout, token refresh, appels API en session active — tous inchangés_
    - _Requirements: 1.2, 2.2, 3.2, 3.3, 3.4, 3.5_

  - [ ] 3.3 Écrire les tests unitaires `auth_controller_test.dart`
    - Créer `test/features/auth/auth_controller_test.dart`
    - Mocker `AuthRepository` avec Mockito (`@GenerateMocks([AuthRepository])`) et `cookieJarProvider` avec un `FakeCookieJar` qui enregistre les appels à `deleteAll()`
    - **Test 1** : `login()` appelle `clearSessionCookies` AVANT `repo.login()` — vérifier l'ordre des appels via `verifyInOrder`
    - **Test 2** : `loginWithGoogle()` appelle `clearSessionCookies` AVANT `repo.loginWithGoogle()`
    - **Test 3** : `loginWithGoogleTokens()` appelle `clearSessionCookies` AVANT `repo.signInWithGoogleTokens()`
    - **Test 4** : `register()` appelle `clearSessionCookies` AVANT `repo.register()`
    - **Test 5** : `logout()` appelle `clearSessionCookies` et Firebase `signOut()` — vérifier que les deux sont invoqués
    - **Test 6** : si `clearSessionCookies` lève une exception, le flux de connexion continue et se termine en `AsyncData(true)` (non bloquant)
    - **Test 7** : `build()` ne déclenche PAS `deleteAll()` sur le cookie jar lors d'une session active
    - Lancer `flutter test test/features/auth/auth_controller_test.dart` — tous les tests doivent passer
    - _Requirements: 2.2, 3.2, 3.3_

  - [ ] 3.4 Vérifier le test Bug Condition (Property 1) passe après correction
    - **Property 1: Expected Behavior** - Cookie Jar Cleared Before Sign-in
    - **IMPORTANT** : Ré-exécuter le MÊME test de la tâche 1 — NE PAS écrire un nouveau test
    - Le test de la tâche 1 encode le comportement attendu
    - Quand ce test passe, cela confirme que le comportement attendu est satisfait
    - Lancer `flutter test test/features/auth/auth_controller_pbt_test.dart`
    - **EXPECTED OUTCOME** : Le test PASSE (confirme que le bug est corrigé)
    - Le cookie jar ne doit plus contenir de cookie de session précédente après un appel à `loginWithGoogle()`
    - _Requirements: 2.2, 2.1 (via configuration Firebase fix)_

  - [ ] 3.5 Vérifier que les tests de préservation passent toujours
    - **Property 2: Preservation** - Non-Buggy Sign-in Flows Unchanged
    - **IMPORTANT** : Ré-exécuter les MÊMES tests de la tâche 2 — NE PAS écrire de nouveaux tests
    - Lancer `flutter test test/features/auth/auth_controller_preservation_test.dart`
    - **EXPECTED OUTCOME** : Les tests PASSENT (aucune régression)
    - Confirmer que `login()`, `logout()`, `loginWithGoogleTokens()`, et la résistance aux exceptions sur `clearSessionCookies` fonctionnent toujours

- [ ] 4. Tests d'intégration manuels sur APK release — checklist

  - [ ] 4.1 Construire et signer l'APK release
    - Lancer `flutter build apk --release` avec le keystore `maasga-upload.jks` (alias `upload`)
    - Vérifier l'absence d'erreurs R8/ProGuard dans la sortie (les règles `proguard-rules.pro` protègent `com.google.android.gms.auth.**`, `com.google.firebase.**`, `com.google.android.gms.common.**`)
    - Installer l'APK sur un appareil physique Android
    - _Requirements: 1.3, 2.3_

  - [ ] 4.2 Tester le flux Google Sign-In en release (Bug 1 — Fix Checking)
    - Sur l'appareil physique avec l'APK release signé `maasga-upload.jks` : taper "Se connecter avec Google"
    - **EXPECTED** : le sélecteur de compte Google s'ouvre, l'authentification complète sans erreur, `FirebaseAuth.currentUser != null`
    - **EXPECTED** : l'écran principal de l'app se charge avec les données de l'utilisateur connecté
    - Si échec : vérifier dans Firebase Console que le SHA-1 `54:C1:F8...` est bien enregistré et que `google-services.json` est à jour
    - _Requirements: 2.1_

  - [ ] 4.3 Tester la rotation de comptes (Bug 2 — Fix Checking)
    - Se connecter avec le compte A (Google ou email) sur l'APK release → naviguer vers l'espace client → vérifier le profil A
    - Se déconnecter (logout)
    - Se reconnecter avec le compte B via Google Sign-In
    - **EXPECTED** : le profil, les commandes et les rendez-vous affichés sont exclusivement ceux du compte B
    - **EXPECTED** : aucune donnée du compte A n'est visible
    - _Requirements: 2.2, 3.5_

  - [ ] 4.4 Tester la session persistée entre tuées (Bug 2 — Fix Checking)
    - Se connecter avec le compte A → forcer la fermeture de l'app (sans logout) → relancer l'app
    - Se connecter avec le compte B
    - **EXPECTED** : les données du compte B sont affichées (pas celles de A)
    - _Requirements: 2.2_

  - [ ] 4.5 Tester la préservation du mode debug (Preservation)
    - Lancer `flutter run` (mode debug)
    - Se connecter avec Google Sign-In → vérifier que l'authentification fonctionne identiquement
    - Vérifier que les 47 produits `/api/mobile/products` se chargent correctement
    - _Requirements: 3.1, 3.3_

  - [ ] 4.6 Tester le rafraîchissement du token Firebase (Preservation)
    - Simuler un 401 sur `/api/mobile/products` (token expiré ou révoqué manuellement)
    - **EXPECTED** : l'interceptor Dio force-refresh le token et rejoue la requête sans demander à l'utilisateur de se reconnecter
    - Vérifier que le produit se charge sans erreur visible
    - _Requirements: 3.4_

- [ ] 5. Checkpoint — Tous les tests passent
  - Lancer la suite complète : `flutter test`
  - Vérifier que `auth_controller_pbt_test.dart`, `auth_controller_preservation_test.dart`, et `auth_controller_test.dart` passent tous
  - Vérifier que les tests existants (`auth_repository_test.dart`, `auth_screens_test.dart`) ne sont pas régressés
  - Vérifier que la checklist manuelle APK release (tâches 4.2 à 4.6) est entièrement cochée
  - En cas de question, demander à l'utilisateur avant de continuer
