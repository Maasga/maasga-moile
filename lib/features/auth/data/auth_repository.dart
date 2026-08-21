import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/env.dart';
import '../../../core/config/maasga_contact.dart';
import '../../../core/session/session_providers.dart';

/// Dépôt d'authentification — délègue tout à Firebase Auth.
///
/// Stratégie d'identifiant :
/// - Email → [FirebaseAuth.signInWithEmailAndPassword]
/// - Téléphone (+226XXXXXXXX) → stocké en [displayName] + email synthétique
///   car Firebase ne supporte pas le SMS OTP hors projet vérifié.
///   L'email synthétique est : `<phone_normalise>@maasga.app`
///
/// ⚠️ Limite connue : un numéro de téléphone n'est PAS vérifié (aucun OTP SMS).
/// Tant que l'OTP n'est pas activé côté console Firebase, un tiers peut créer
/// un compte sur un numéro qui ne lui appartient pas. Les comptes créés par
/// téléphone n'ont pas d'e-mail réel, donc pas de réinitialisation de mot de
/// passe automatique possible (cf. [sendPasswordReset]).
class AuthRepository {
  AuthRepository(this._auth);
  final FirebaseAuth _auth;

  /// Domaine des e-mails synthétiques générés pour les comptes « téléphone ».
  static const String syntheticEmailDomain = '@maasga.app';

  /// Longueur minimale imposée côté app (Firebase n'impose que 6).
  static const int minPasswordLength = 8;

  // ─── Validation d'entrée ─────────────────────────────────────────────────

  /// Numéro burkinabé : 8 chiffres, éventuellement préfixé `+226` / `226`.
  static bool isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[\s\-.]'), '');
    return RegExp(r'^(\+?226)?[0-9]{8}$').hasMatch(digits);
  }

  static bool isValidEmail(String email) =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email.trim());

  /// `true` si l'adresse est un e-mail synthétique (compte créé par téléphone).
  static bool isSyntheticEmail(String email) =>
      email.toLowerCase().endsWith(syntheticEmailDomain);

  // ─── Connexion email ou téléphone ────────────────────────────────────────

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    final clean = identifier.trim().replaceAll(' ', '');
    final email = _toEmail(clean);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('AUTH LOGIN ERROR: ${e.code}');
      throw _friendlyException(e);
    }
  }

  // ─── Inscription ─────────────────────────────────────────────────────────

  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String quartier,
    required String password,
  }) async {
    final rawPhone = phone.trim().replaceAll(' ', '');
    if (!isValidPhone(rawPhone)) {
      throw Exception(
        'Numéro de téléphone invalide : 8 chiffres attendus (ex. 70 12 34 56).',
      );
    }
    final trimmedEmail = email.trim();
    if (trimmedEmail.isNotEmpty && !isValidEmail(trimmedEmail)) {
      throw Exception('Adresse e-mail invalide (ex. nom@exemple.com).');
    }
    if (password.length < minPasswordLength) {
      throw Exception(
        'Mot de passe trop court ($minPasswordLength caractères minimum).',
      );
    }

    final cleanPhone = _normalizePhone(rawPhone);
    final firebaseEmail = trimmedEmail.isNotEmpty
        ? trimmedEmail
        : '$cleanPhone$syntheticEmailDomain';
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: firebaseEmail,
        password: password,
      );
      await cred.user?.updateDisplayName(name);

      // Envoi du mail de vérification uniquement si l'adresse est réelle :
      // un e-mail synthétique @maasga.app n'a pas de boîte de réception.
      if (!isSyntheticEmail(firebaseEmail)) {
        try {
          await cred.user?.sendEmailVerification();
        } catch (e) {
          if (kDebugMode) debugPrint('Envoi vérification e-mail échoué: $e');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('AUTH REGISTER ERROR: ${e.code}');
      throw _friendlyException(e);
    }
  }

  // ─── Réinitialisation du mot de passe ────────────────────────────────────

  /// Envoie un e-mail de réinitialisation.
  ///
  /// Lève une exception explicite pour les comptes créés par téléphone :
  /// leur e-mail synthétique n'existe pas, donc aucun lien ne peut leur être
  /// envoyé — le déblocage passe obligatoirement par le support.
  Future<void> sendPasswordReset(String identifier) async {
    final clean = identifier.trim().replaceAll(' ', '');
    if (clean.isEmpty) {
      throw Exception('Saisis ton e-mail ou ton téléphone d\'abord.');
    }
    final email = _toEmail(clean);
    if (isSyntheticEmail(email)) {
      throw Exception(
        'Ce compte est lié à un numéro de téléphone, sans adresse e-mail : '
        'la réinitialisation automatique est impossible. Contacte le support '
        'MAASGA au ${MaasgaContact.phoneInternational}.',
      );
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('AUTH RESET ERROR: ${e.code}');
      throw _friendlyException(e);
    }
  }

  // ─── Connexion Google ─────────────────────────────────────────────────────

  /// `initialize()` ne doit être appelé qu'une fois par cycle de vie : chaque
  /// appel réabonne le plugin au flux d'événements de la plateforme, ce qui
  /// dupliquerait les événements de connexion. Le bouton Web applique la même
  /// garde de son côté.
  static bool _googleInitialized = false;

  Future<GoogleSignIn> _initializedGoogle() async {
    final google = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await google.initialize(serverClientId: Env.googleWebClientId);
      _googleInitialized = true;
    }
    return google;
  }

  Future<void> loginWithGoogle() async {
    try {
      final google = await _initializedGoogle();

      // Révoque l'autorisation encore accordée au compte précédent avant
      // d'ouvrir le sélecteur. Sans cela, Credential Manager (Android) peut
      // resservir ce compte sans afficher de choix : impossible de basculer sur
      // un autre compte Google depuis l'app, on est reconnecté sur l'ancien.
      // Échec sans conséquence : aucun compte n'était autorisé.
      try {
        await google.disconnect();
      } catch (_) {}

      final account = await google.authenticate();

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw Exception('Token Google manquant. Réessaie.');
      }

      String? accessToken;
      try {
        final authz =
            await account.authorizationClient.authorizationForScopes([
              'email',
              'profile',
              'openid',
            ]) ??
            await account.authorizationClient.authorizeScopes([
              'email',
              'profile',
              'openid',
            ]);
        accessToken = authz.accessToken;
      } catch (_) {}

      await signInWithGoogleTokens(idToken: idToken, accessToken: accessToken);
    } on FirebaseAuthException catch (e) {
      throw _friendlyException(e);
    } catch (e) {
      if (kDebugMode) debugPrint('Google sign-in error: $e');
      rethrow;
    }
  }

  /// Échange des jetons Google contre une session Firebase.
  ///
  /// Utilisé par le flux mobile ([loginWithGoogle]) **et** par le bouton Web,
  /// qui obtient ses jetons via `GoogleSignIn.authenticationEvents`. Au moins
  /// un des deux jetons doit être fourni.
  Future<void> signInWithGoogleTokens({
    String? idToken,
    String? accessToken,
  }) async {
    final hasId = idToken != null && idToken.isNotEmpty;
    final hasAccess = accessToken != null && accessToken.isNotEmpty;
    if (!hasId && !hasAccess) {
      throw Exception('Jetons Google manquants. Réessaie.');
    }
    final credential = GoogleAuthProvider.credential(
      idToken: hasId ? idToken : null,
      accessToken: hasAccess ? accessToken : null,
    );
    try {
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) debugPrint('AUTH GOOGLE ERROR: ${e.code}');
      throw _friendlyException(e);
    }
  }

  // ─── Session active ───────────────────────────────────────────────────────

  /// Indique si une session Firebase utilisable existe.
  ///
  /// N'utilise volontairement PAS `getIdToken(true)` : le refresh forcé exige
  /// le réseau et faisait passer un utilisateur connecté pour un inconnu au
  /// moindre démarrage hors ligne. Seuls les codes d'erreur signifiant une
  /// révocation côté serveur invalident la session locale.
  Future<bool> hasActiveSession() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.getIdToken();
      return true;
    } on FirebaseAuthException catch (e) {
      const revoked = {
        'user-disabled',
        'user-not-found',
        'user-token-expired',
        'user-token-revoked',
        'invalid-user-token',
      };
      return !revoked.contains(e.code);
    } catch (_) {
      // Erreur réseau ou plateforme : on conserve la session persistée.
      return true;
    }
  }

  // ─── Token Firebase (pour les appels API backend) ─────────────────────────

  Future<String?> getIdToken() async {
    return _auth.currentUser?.getIdToken();
  }

  // ─── Profil utilisateur ───────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return {
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'phone': user.phoneNumber ?? '',
      'photoUrl': user.photoURL ?? '',
      'emailVerified': user.emailVerified,
    };
  }

  // ─── Déconnexion ─────────────────────────────────────────────────────────

  /// Ferme la session Firebase **et** révoque le compte Google associé.
  ///
  /// `disconnect()` s'ajoute à `signOut()` : `signOut()` seul se contente
  /// d'oublier la session côté plugin, l'autorisation reste accordée et le
  /// prochain `authenticate()` peut resélectionner le même compte sans afficher
  /// le sélecteur — l'utilisateur ne peut alors plus changer de compte Google.
  ///
  /// Ne purge délibérément que Firebase et Google : le cookie de session
  /// backend, le panier et les caches Riverpod sont l'affaire de
  /// `AuthController.logout`, qui a accès au `Ref`.
  Future<void> logout() async {
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      // Aucun compte Google connecté, ou révocation refusée par la plateforme.
    }
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // ─── Synchronisation backend ─────────────────────────────────────────────

  /// Pousse les champs additionnels (téléphone, quartier) vers D1.
  ///
  /// Passe par le [Dio] applicatif : on hérite ainsi du `baseUrl`, des
  /// timeouts, du cookie jar et de l'interceptor qui pose le Bearer Firebase.
  /// Renvoie `false` en cas d'échec — l'appelant décide quoi en faire plutôt
  /// que de voir l'erreur disparaître silencieusement.
  Future<bool> syncProfile({
    required Dio dio,
    String? name,
    String? phone,
    String? quartier,
    String route = '/api/mobile/register',
  }) async {
    if (_auth.currentUser == null) return false;
    try {
      await dio.post(
        route,
        data: {
          'name': name ?? '',
          'phone': phone ?? '',
          'quartier': quartier ?? '',
        },
      );
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('syncProfile échec (non bloquant): $e');
      return false;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Normalise un numéro burkinabé en +226XXXXXXXX
  String _normalizePhone(String phone) {
    if (phone.startsWith('+226')) return phone;
    if (phone.startsWith('226')) return '+$phone';
    return '+226$phone';
  }

  /// Convertit un identifiant (email ou téléphone) en email Firebase
  String _toEmail(String identifier) {
    if (identifier.contains('@')) return identifier;
    return '${_normalizePhone(identifier)}$syntheticEmailDomain';
  }

  /// Traduit les codes Firebase en messages lisibles
  Exception _friendlyException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return Exception('Identifiants incorrects. Vérifie et réessaie.');
      case 'wrong-password':
        return Exception('Mot de passe incorrect.');
      case 'invalid-email':
        return Exception('Adresse e-mail ou numéro invalide.');
      case 'email-already-in-use':
        return Exception('Ce compte existe déjà. Connecte-toi plutôt.');
      case 'weak-password':
        return Exception(
          'Mot de passe trop faible ($minPasswordLength caractères minimum).',
        );
      case 'too-many-requests':
        return Exception('Trop de tentatives. Réessaie dans quelques minutes.');
      case 'network-request-failed':
        return Exception('Connexion internet indisponible.');
      case 'user-disabled':
        return Exception('Ce compte a été désactivé. Contacte le support.');
      case 'account-exists-with-different-credential':
        return Exception(
          'Un compte existe déjà avec cette adresse via un autre mode de '
          'connexion. Connecte-toi avec ton mot de passe.',
        );
      default:
        return Exception('Authentification impossible (${e.code}).');
    }
  }
}

// ─── Providers Riverpod ───────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance);
});

/// Profil issu de Firebase Auth (nom, e-mail, photo du compte courant).
///
/// `watch(currentUserIdProvider)` est indispensable : sans lui ce provider est
/// calculé une seule fois et continue de servir le profil du compte précédent
/// après un changement d'utilisateur.
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.watch(currentUserIdProvider);
  final repo = ref.watch(authRepositoryProvider);
  return repo.getProfile();
});
