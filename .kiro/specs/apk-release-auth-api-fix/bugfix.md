# Bugfix Requirements Document

## Introduction

L'application Flutter Maasga fonctionne correctement en mode debug (`flutter run`) mais présente deux régressions critiques en build APK release :

1. **Authentification impossible** : La connexion Google Sign-In/Firebase échoue silencieusement en release. La cause probable est que le certificat SHA-1/SHA-256 de la clé de signature release n'est pas enregistré dans Firebase Console, ce qui conduit Google à rejeter le flux OAuth.

2. **Données incorrectes retournées par les APIs** : Le `PersistCookieJar` (via `dio_cookie_manager`) persiste les cookies de session Cloudflare sur disque. En mode release, si le cookie jar n'est pas vidé correctement à la connexion, la session côté serveur appartient à un compte précédent et les appels à `/api/mobile/*` (produits, profil, commandes, rendez-vous) retournent des données qui ne correspondent pas à l'utilisateur authentifié.

Ces deux bugs n'apparaissent qu'en release car : (a) la clé de signature change entre debug et release, et (b) le cookie jar persistant s'accumule entre les sessions sur l'APK installé.

---

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN l'application est lancée depuis un APK release signé avec la clé release ET que l'utilisateur tente de se connecter via Google Sign-In THEN le système échoue à compléter l'authentification (erreur silencieuse ou échec du flux OAuth Google)

1.2 WHEN l'application est lancée depuis un APK release ET qu'une session précédente a laissé un cookie de session Cloudflare dans le `PersistCookieJar` THEN le système retourne les données de l'ancienne session (profil, commandes, rendez-vous, produits) au lieu des données de l'utilisateur actuellement connecté

1.3 WHEN l'application est lancée depuis un APK release ET que R8/minification supprime ou renomme des classes utilisées par réflexion (Firebase Auth, Google Sign-In, Dio interceptors) THEN le système peut lever des exceptions à l'exécution absentes en mode debug

### Expected Behavior (Correct)

2.1 WHEN l'application est lancée depuis un APK release signé avec la clé release ET que l'utilisateur tente de se connecter via Google Sign-In THEN le système SHALL compléter le flux OAuth Google et retourner un `User` Firebase valide, identiquement au comportement en mode debug

2.2 WHEN un utilisateur se connecte sur l'APK release THEN le système SHALL vider le `PersistCookieJar` avant d'émettre la première requête authentifiée, de sorte que les appels à `/api/mobile/*` retournent exclusivement les données de la session courante

2.3 WHEN l'APK release est construit avec `isMinifyEnabled = true` THEN le système SHALL conserver toutes les classes nécessaires à Firebase Auth, Google Sign-In, Dio et ses interceptors grâce aux règles ProGuard/R8 adéquates

### Unchanged Behavior (Regression Prevention)

3.1 WHEN l'application est lancée en mode debug (`flutter run`) THEN le système SHALL CONTINUE TO permettre la connexion Google Sign-In et retourner les données correctes de l'utilisateur connecté

3.2 WHEN l'utilisateur se déconnecte (sign-out) en mode release ou debug THEN le système SHALL CONTINUE TO vider le `PersistCookieJar` via `clearSessionCookies()` comme c'est déjà implémenté dans `api_client.dart`

3.3 WHEN l'utilisateur est connecté et effectue des appels à `/api/mobile/products` THEN le système SHALL CONTINUE TO recevoir et normaliser les 47 produits correctement, comme en mode debug

3.4 WHEN le token Firebase ID expire pendant une session THEN le système SHALL CONTINUE TO le rafraîchir automatiquement via l'interceptor Dio existant et rejouer la requête sans erreur visible pour l'utilisateur

3.5 WHEN un utilisateur se connecte avec un second compte après s'être déconnecté THEN le système SHALL CONTINUE TO afficher exclusivement les données (profil, commandes, rendez-vous) du nouveau compte connecté

---

## Bug Condition Pseudocode

### Bug Condition — Authentification release

```pascal
FUNCTION isBugConditionAuth(X)
  INPUT: X de type BuildContext { buildMode: debug | release, signingKey: debug | release }
  OUTPUT: boolean

  RETURN X.buildMode = release AND X.signingKey = release
    AND sha1NotRegisteredInFirebase(X.signingKey)
END FUNCTION
```

```pascal
// Propriété : Fix Checking — Authentification
POUR TOUT X WHERE isBugConditionAuth(X) DO
  result ← signInWithGoogle'(X)
  ASSERT result.user != null AND result.firebaseToken != null
FIN POUR
```

### Bug Condition — Données de session périmées

```pascal
FUNCTION isBugConditionStaleSession(X)
  INPUT: X de type SessionContext { cookieJarHasPreviousSession: boolean, userJustSignedIn: boolean }
  OUTPUT: boolean

  RETURN X.cookieJarHasPreviousSession = true AND X.userJustSignedIn = true
END FUNCTION
```

```pascal
// Propriété : Fix Checking — Cookie jar
POUR TOUT X WHERE isBugConditionStaleSession(X) DO
  result ← fetchApiData'(X)
  ASSERT result.userId = X.currentFirebaseUid
FIN POUR
```

```pascal
// Propriété : Preservation Checking
POUR TOUT X WHERE NOT isBugConditionAuth(X) AND NOT isBugConditionStaleSession(X) DO
  ASSERT F(X) = F'(X)
FIN POUR
```
