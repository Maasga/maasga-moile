# APK Release Auth & API Fix — Bugfix Design

## Overview

Deux régressions n'apparaissent qu'en build release APK (jamais en `flutter run`) :

1. **Authentification Google silencieuse** : le flux OAuth échoue parce que le SHA-1/SHA-256 du keystore de publication n'est pas enregistré dans Firebase Console. Google rejette le handshake OAuth dès que l'empreinte du certificat ne correspond à aucune entrée autorisée du projet Firebase. Le certificat debug (`c884cc...`) est le seul enregistré dans `google-services.json` ; la clé release (`54:C1:F8...`) est absente.

2. **Données de session périmées via PersistCookieJar** : `dio_cookie_manager` persiste les cookies Cloudflare sur le disque. Avant le commit de stabilisation V1.1, `clearSessionCookies()` n'était appelé qu'au `logout` — jamais au `login`. Un utilisateur qui s'authentifie sur l'APK installé repartait donc avec le cookie de la session précédente, et le backend `/api/mobile/*` répondait avec les données de l'ancien compte.

**Stratégie de correction** :

- Bug 1 : action de configuration — enregistrer le SHA-1 et SHA-256 de la clé release dans Firebase Console, puis régénérer et committer le `google-services.json`.
- Bug 2 : correction de code — appeler `clearSessionCookies(ref)` avant chaque `signIn*` dans `AuthController`. Cette correction a été livrée dans le commit `c85daa1` via `_startCleanSession()`.

---

## Glossary

- **Bug_Condition (C)** : condition qui déclenche la régression — deux conditions indépendantes définies comme `C_auth(X)` et `C_session(X)`.
- **Property (P)** : comportement attendu après correction — `P_auth` et `P_session`.
- **Preservation** : comportements existants qui ne doivent pas être altérés par ces corrections (debug, sign-out, flux email/phone).
- **PersistCookieJar** : instance de `cookie_jar` configurée avec `FileStorage` dans `api_client.dart` — écrit les cookies sur le disque de l'appareil entre les sessions.
- **clearSessionCookies(Ref)** : fonction dans `lib/core/network/api_client.dart` qui appelle `jar.deleteAll()` — vide l'intégralité du cookie jar persistant.
- **_startCleanSession()** : méthode privée de `AuthController` ajoutée dans `c85daa1` — appelle `clearSessionCookies` avant chaque méthode de connexion.
- **certificate_hash** : empreinte SHA-1 du certificat de signature, sans les deux-points, en minuscules — format attendu par `google-services.json` sous `android_info`.
- **SHA-1 release** : `54:C1:F8:B2:A6:5A:27:83:8F:70:75:FA:11:AD:F4:55:57:29:8C:2B` (keystore `maasga-upload.jks`, alias `upload`).
- **SHA-256 release** : `B3:9F:69:5A:65:D5:BF:D2:DC:42:9D:8C:9B:14:26:55:CA:0D:8B:C8:2E:8E:EA:1F:B1:02:67:59:01:C9:51:F4` (même keystore).
- **google-services.json** : fichier `android/app/google-services.json` — liste les empreintes autorisées et les `client_id` OAuth pour Android.
- **F** : code avant correction (commit `4e966dc` pour le bug 2 ; état actuel de Firebase Console pour le bug 1).
- **F'** : code après correction.

---

## Bug Details

### Bug Condition — Auth release (`C_auth`)

Le flux Google Sign-In échoue quand l'APK est signé avec le keystore release et que l'empreinte de ce keystore n'est pas enregistrée dans Firebase Console.

```
FUNCTION isBugConditionAuth(X)
  INPUT: X { buildMode: debug|release, signingKeyFingerprint: string }
  OUTPUT: boolean

  RETURN X.buildMode = release
    AND X.signingKeyFingerprint NOT IN registeredFingerprintsInFirebaseConsole()
END FUNCTION
```

**État actuel dans `google-services.json`** :

```json
"android_info": {
  "package_name": "com.maasga.app",
  "certificate_hash": "c884ccfcfe026c600fd5d1149d9b5f9d37f05841"
}
```

Seul le hash debug est enregistré. La clé release (`54c1f8b2a65a27838f7075fa11adf45557298c2b`) est absente.

### Exemples — Bug 1

| Contexte | Comportement observé | Comportement attendu |
|---|---|---|
| `flutter build apk --release` + Google Sign-In | Erreur silencieuse ou `FirebaseAuthException(network-request-failed)` | Authentification réussie, retour d'un `User` Firebase valide |
| `flutter run` (debug) + Google Sign-In | Authentification réussie ✓ | Authentification réussie |
| APK release + connexion email/password | Fonctionne ✓ (ne dépend pas du certificat) | Inchangé |

---

### Bug Condition — Session périmée (`C_session`)

```
FUNCTION isBugConditionSession(X)
  INPUT: X { cookieJarHasPreviousSession: boolean, userJustSignedIn: boolean, loginMethodCalled: string }
  OUTPUT: boolean

  RETURN X.cookieJarHasPreviousSession = true
    AND X.userJustSignedIn = true
    AND X.loginMethodCalled IN ['login', 'loginWithGoogle', 'loginWithGoogleTokens', 'register']
END FUNCTION
```

**État dans le code AVANT correction** (commit `4e966dc`) :

```dart
// AuthController.loginWithGoogle — aucun clearSessionCookies
Future<void> loginWithGoogle() async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.loginWithGoogle();     // ← cookie périmé toujours présent
    await _registerForPush();
    return true;
  });
}
```

### Exemples — Bug 2

| Contexte | Comportement observé | Comportement attendu |
|---|---|---|
| Compte A connecté → sign-out → compte B connecté via Google (APK installé) | `/api/mobile/profile` retourne le profil du compte A | Profil du compte B |
| Compte A connecté → app tuée → compte B connecté | Commandes et RDV appartenant au compte A | Données du compte B |
| Première installation (cookie jar vide) | Données correctes ✓ | Inchangé |

---

## Expected Behavior

### Preservation Requirements

**Comportements inchangés après correction :**

- 3.1 La connexion Google Sign-In en mode debug (`flutter run`) continue de fonctionner exactement comme avant.
- 3.2 La connexion email/téléphone (`login`, `register`) fonctionne identiquement en debug et release.
- 3.3 Le `logout` appelle toujours `clearSessionCookies` comme c'est déjà implémenté — aucune régression sur la déconnexion.
- 3.4 Le token Firebase ID expire → l'interceptor Dio le rafraîchit automatiquement et rejoue la requête sans erreur visible.
- 3.5 Les 47 produits `/api/mobile/products` sont normalisés correctement après la correction.
- 3.6 La protection contre la réutilisation silencieuse du compte Google (`google.disconnect()` avant `authenticate()`) reste en place.

**Périmètre :**
Tous les inputs qui ne satisfont ni `C_auth` ni `C_session` ne doivent être aucunement affectés par ces corrections.

---

## Hypothesized Root Cause

### Bug 1 — Authentification Google

**Cause racine confirmée** : seul le SHA-1 du certificat debug SDK Android (`c884cc...`) est enregistré dans Firebase Console et reflété dans `google-services.json`. Lors de la génération du keystore release (`maasga-upload.jks`) documentée dans `KEYSTORE_GUIDE.md`, l'empreinte n'a pas été ajoutée à Firebase Console, et `google-services.json` n'a pas été re-téléchargé.

Le flux OAuth Android de Google Sign-In vérifie l'empreinte de l'APK appelant contre les empreintes enregistrées dans le projet Google Cloud / Firebase. Si l'empreinte est inconnue, Google refuse d'émettre un `idToken` — le résultat est soit une erreur silencieuse, soit un `FirebaseAuthException`.

**Ce qui n'est PAS la cause** :
- Les règles ProGuard/R8 : `proguard-rules.pro` protège déjà `com.google.android.gms.auth.**`, `com.google.firebase.**` et `com.google.android.gms.common.**`.
- Le `serverClientId` dans `Env.googleWebClientId` : il correspond au `client_type: 3` web present dans `google-services.json`.

### Bug 2 — Données périmées

**Cause racine confirmée** : dans le code avant `c85daa1`, `clearSessionCookies` n'était appelé que dans `logout`. Les méthodes `login`, `loginWithGoogle`, `loginWithGoogleTokens` et `register` n'appelaient pas `clearSessionCookies`. Un cookie de session Cloudflare persisté sur le disque identifie une session serveur indépendante du token Firebase — le backend l'honore et répond avec les données de la session précédente.

---

## Correctness Properties

Property 1: Bug Condition — Google Sign-In fonctionne en release

_For any_ build release signé avec le keystore `maasga-upload.jks` (SHA-1 `54:C1:F8...`) où l'utilisateur déclenche `loginWithGoogle()`, la fonction `AuthController.loginWithGoogle` corrigée SHALL compléter le flux OAuth et retourner un `FirebaseAuth.currentUser != null` avec un `idToken` valide — identiquement au comportement observé en mode debug.

**Validates: Requirements 2.1**

---

Property 2: Bug Condition — Cookie jar vidé avant sign-in

_For any_ appel à `login`, `loginWithGoogle`, `loginWithGoogleTokens` ou `register` dans `AuthController`, quelle que soit l'histoire de la session précédente (cookie sur disque ou jar vide), la fonction corrigée SHALL appeler `clearSessionCookies(ref)` avant d'invoquer la méthode Firebase, de sorte que le premier appel `/api/mobile/*` émis après authentification retourne exclusivement les données du `currentUser.uid` courant.

**Validates: Requirements 2.2**

---

Property 3: Preservation — Comportements non affectés

_For any_ input qui ne satisfait ni `isBugConditionAuth` ni `isBugConditionSession` (debug build, email/phone login, logout, token refresh, appels API en session active), la fonction corrigée SHALL produire exactement le même résultat que la fonction originale — aucune régression sur les flux existants.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**

---

## Fix Implementation

### Fix 1 — Enregistrer le certificat release dans Firebase Console

**Type de correction** : configuration externe (Firebase Console + fichier régénéré)

**Fichiers impactés** :
- `android/app/google-services.json` — à remplacer par la version re-téléchargée depuis Firebase Console

**Étapes** :

1. **Firebase Console** → projet `maasga-83b35` → ⚙️ Project settings → Votre application Android (`com.maasga.app`).
2. Sous "Empreintes digitales du certificat SHA", cliquer **Ajouter une empreinte**.
3. Ajouter le SHA-1 release :
   ```
   54:C1:F8:B2:A6:5A:27:83:8F:70:75:FA:11:AD:F4:55:57:29:8C:2B
   ```
4. Ajouter le SHA-256 release :
   ```
   B3:9F:69:5A:65:D5:BF:D2:DC:42:9D:8C:9B:14:26:55:CA:0D:8B:C8:2E:8E:EA:1F:B1:02:67:59:01:C9:51:F4
   ```
5. Sauvegarder.
6. Télécharger le nouveau `google-services.json` et remplacer `android/app/google-services.json`.
7. Vérifier que le nouveau fichier contient deux entrées `oauth_client` de `client_type: 1` — une pour le hash debug, une pour le hash release.
8. Committer `android/app/google-services.json`.

**Format attendu dans `google-services.json` après correction :**
```json
"oauth_client": [
  {
    "client_id": "80812184966-<debug_client_id>.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "com.maasga.app",
      "certificate_hash": "c884ccfcfe026c600fd5d1149d9b5f9d37f05841"
    }
  },
  {
    "client_id": "80812184966-<release_client_id>.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "com.maasga.app",
      "certificate_hash": "54c1f8b2a65a27838f7075fa11adf45557298c2b"
    }
  },
  ...
]
```

> Note : le `certificate_hash` dans `google-services.json` est en minuscules et sans deux-points.

---

### Fix 2 — Appeler clearSessionCookies avant chaque sign-in

**Type de correction** : code Dart

**Fichier** : `lib/features/auth/presentation/auth_controller.dart`

**Fonction** : `AuthController`

**État de la correction** : **livrée dans le commit `c85daa1`** via la méthode `_startCleanSession()`. La correction est présente dans `main`.

**Changements apportés (documentés pour traçabilité)** :

1. **Ajout de `_startCleanSession()`** : méthode privée qui appelle `clearSessionCookies(ref)` avec absorption des erreurs. Ne bloque jamais le flux de connexion.

2. **Appel avant chaque sign-in** : `_startCleanSession()` est appelé en tête de `login`, `loginWithGoogle`, `loginWithGoogleTokens`, et `register` — avant tout appel Firebase.

3. **`clearSessionCookies` au logout** : ajouté également dans `logout` (en sus du déjà existant), avec gestion explicite des erreurs.

```dart
// Ajout dans auth_controller.dart (commit c85daa1)
Future<void> _startCleanSession() async {
  try {
    await clearSessionCookies(ref);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('_startCleanSession erreur: $e');
    }
  }
}

// Dans loginWithGoogle (avant la correction, seulement après) :
Future<void> loginWithGoogle() async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() async {
    final repo = ref.read(authRepositoryProvider);
    await _startCleanSession();   // ← ajout
    await repo.loginWithGoogle();
    await _syncBackendSession();
    await _registerForPush();
    return true;
  });
}
```

**Pourquoi c'est sûr** : au moment d'un sign-in, tout cookie présent sur disque appartient à une session révolue. Le serveur Cloudflare posera un nouveau cookie à la prochaine requête authentifiée. Supprimer le cookie existant est donc toujours correct — il n'existe pas de scénario où conserver un cookie de la session précédente est le bon comportement.

---

## Testing Strategy

### Validation Approach

La stratégie suit deux phases : d'abord observer le bug sur le code/configuration non corrigé (exploration), puis vérifier que la correction fonctionne sans régression (fix + preservation checking).

Le bug 1 est une configuration externe — il ne peut pas être testé par des tests unitaires Dart. La validation passe par un test d'intégration manuel sur APK release signé.

Le bug 2 est un bug de code Dart — il peut être testé par des tests unitaires avec mocks.

---

### Exploratory Bug Condition Checking

**Objectif** : confirmer les causes racines avant de valider les corrections.

**Bug 1 — Exploration :**

```
OBSERVATION MANUELLE:
1. Construire un APK release avec le SHA-1 release NON enregistré dans Firebase Console
2. Installer sur appareil physique Android
3. Tenter Google Sign-In
4. Observer : échec silencieux ou FirebaseAuthException
5. Après enregistrement du SHA-1 → mêmes étapes → succès attendu
```

**Bug 2 — Exploration :**

```
FUNCTION exploreSessionBug()
  // Simuler un cookie jar non vide au moment du login
  préparer un PersistCookieJar avec cookies de session pré-existants
  appeler AuthController.loginWithGoogle() sur code NON corrigé (commit 4e966dc)
  observer le premier appel GET /api/mobile/profile
  ASSERT response.userId != currentFirebaseUid  // doit échouer = bug confirmé
END FUNCTION
```

**Contre-exemples attendus :**
- Bug 1 : `FirebaseAuthException` avec code `unknown` ou absence de `idToken` retourné par `google.authenticate()`.
- Bug 2 : `response.data['uid']` ne correspond pas à `FirebaseAuth.instance.currentUser!.uid`.

---

### Fix Checking

**Objectif** : vérifier que pour tous les inputs où la condition de bug tient, la fonction corrigée produit le comportement attendu.

**Fix Checking — Bug 1 :**

```
POUR TOUT X WHERE isBugConditionAuth(X) = true (build release, SHA-1 enregistré) DO
  result ← AuthController.loginWithGoogle()(X)
  ASSERT result is AsyncData(true)
  ASSERT FirebaseAuth.instance.currentUser != null
  ASSERT FirebaseAuth.instance.currentUser!.getIdToken() != null
FIN POUR
```

**Fix Checking — Bug 2 :**

```
POUR TOUT X WHERE isBugConditionSession(X) = true DO
  // cookie jar contient des cookies de session précédente
  résultat_api ← dio.get('/api/mobile/profile') après loginWithGoogle()(X)
  ASSERT résultat_api.data['uid'] = FirebaseAuth.instance.currentUser!.uid
FIN POUR
```

---

### Preservation Checking

**Objectif** : vérifier que les inputs qui ne satisfont pas la condition de bug produisent exactement le même résultat qu'avant correction.

```
POUR TOUT X WHERE NOT isBugConditionAuth(X) AND NOT isBugConditionSession(X) DO
  ASSERT F(X) = F'(X)
FIN POUR
```

**Testing Approach** : les tests de préservation sur `AuthController` utilisent des mocks (Mockito) pour isoler Firebase Auth et le cookie jar. La préservation est vérifiée sur :

1. **Connexion email/password** : `login()` avec jar vide — comportement inchangé.
2. **Sign-out** : `logout()` appelle toujours `clearSessionCookies` et Firebase `signOut`.
3. **Refresh token 401** : l'interceptor Dio rejoue la requête avec le token rafraîchi.
4. **Connexion en mode debug** : le `PersistCookieJar` fonctionne identiquement (même code, même jar).

---

### Unit Tests

**Fichier cible** : `test/features/auth/auth_controller_test.dart`

- Tester que `login()` appelle `clearSessionCookies` **avant** `FirebaseAuth.signInWithEmailAndPassword`.
- Tester que `loginWithGoogle()` appelle `clearSessionCookies` avant `AuthRepository.loginWithGoogle`.
- Tester que `loginWithGoogleTokens()` appelle `clearSessionCookies` avant `signInWithGoogleTokens`.
- Tester que `register()` appelle `clearSessionCookies` avant `AuthRepository.register`.
- Tester que `logout()` appelle `clearSessionCookies` et `FirebaseAuth.signOut`.
- Tester que si `clearSessionCookies` lève une exception, le flux de connexion continue (non bloquant).
- Tester que `_startCleanSession` n'est pas appelé dans `build()` (éviter de vider le jar au démarrage sur une session active).

### Property-Based Tests

**Fichier cible** : `test/features/auth/auth_controller_pbt_test.dart`

- **Property 2** : générer des états de cookie jar aléatoires (vide, 1 cookie, N cookies appartenant à des UIDs aléatoires). Pour chaque état, appeler `loginWithGoogle()` et vérifier que le premier appel API retourne les données du `currentUser` — pas celles de l'ancien cookie.
- **Property 3** : générer des séquences de connexions/déconnexions aléatoires sur des comptes distincts. Vérifier qu'après chaque connexion, `cookieJar.loadForRequest(apiBaseUri)` ne contient que les cookies posés par la session courante.

### Integration Tests

- **Test manuel APK release (Bug 1)** : installer l'APK signé avec `maasga-upload.jks` sur un appareil physique. Vérifier que Google Sign-In complète avec succès et que `FirebaseAuth.currentUser != null`.
- **Test de rotation de comptes (Bug 2)** : se connecter avec le compte A, naviguer vers l'espace client, se déconnecter, se reconnecter avec le compte B — vérifier que le profil, les commandes et les rendez-vous affichés sont ceux du compte B.
- **Test de session persistée (Bug 2)** : se connecter avec le compte A, forcer la fermeture de l'app (sans logout), relancer l'app, se connecter avec le compte B — vérifier les données du compte B.
- **Test token refresh (Preservation)** : simuler un 401 sur `/api/mobile/products` et vérifier que l'interceptor rejoue la requête avec le token rafraîchi, sans demander à l'utilisateur de se reconnecter.
