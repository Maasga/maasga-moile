import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/services/user_prefs_service.dart';
import '../../cart/presentation/cart_state.dart';
import '../../notifications/data/push_service.dart';
import '../data/auth_repository.dart';

class AuthController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repo = ref.watch(authRepositoryProvider);
    try {
      final loggedIn = await repo.hasActiveSession();
      if (loggedIn) await _registerForPush();
      return loggedIn;
    } catch (_) {
      return false;
    }
  }

  /// Enregistre l'appareil pour les notifications push.
  ///
  /// [PushService.initialize] est idempotent : on peut l'appeler à chaque
  /// connexion sans empiler les listeners `onMessage` / `onTokenRefresh`.
  /// Les échecs sont volontairement avalés — pas de push ne doit jamais
  /// empêcher une connexion réussie.
  Future<void> _registerForPush() async {
    try {
      final dio = await ref.read(dioProvider.future);
      await ref.read(pushServiceProvider).initialize(dio: dio);
    } catch (_) {}
  }

  /// Jette le cookie de session backend avant d'ouvrir une nouvelle session.
  ///
  /// Complète la purge faite au `logout` et couvre les cas où celui-ci n'a pas
  /// eu lieu : application tuée, session Firebase expirée, ou connexion lancée
  /// depuis `/auth/login` alors qu'un compte était encore actif. Au moment d'un
  /// sign-in, un cookie déjà sur disque appartient forcément à une session
  /// révolue — le serveur en posera un neuf à la requête suivante — donc le
  /// supprimer est toujours sûr, et c'est ce qui empêche le nouveau compte de
  /// lire les données de l'ancien.
  Future<void> _startCleanSession() async {
    try {
      await clearSessionCookies(ref);
    } catch (_) {}
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await _startCleanSession();
      await repo.login(identifier: identifier, password: password);
      await _registerForPush();
      return true;
    });
  }

  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String quartier,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await _startCleanSession();
      await repo.register(
        name: name,
        phone: phone,
        email: email,
        quartier: quartier,
        password: password,
      );
      // Pousse téléphone + quartier vers D1. Non bloquant : le compte Firebase
      // existe déjà, échouer ici ne doit pas casser l'inscription.
      try {
        final dio = await ref.read(dioProvider.future);
        await repo.syncProfile(
          dio: dio,
          name: name,
          phone: phone,
          quartier: quartier,
        );
      } catch (_) {}
      await _registerForPush();
      return true;
    });
  }

  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await _startCleanSession();
      await repo.loginWithGoogle();
      await _registerForPush();
      return true;
    });
  }

  /// Finalise une connexion Google amorcée côté Web (jetons déjà obtenus).
  Future<void> loginWithGoogleTokens({
    String? idToken,
    String? accessToken,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await _startCleanSession();
      await repo.signInWithGoogleTokens(
        idToken: idToken,
        accessToken: accessToken,
      );
      await _registerForPush();
      return true;
    });
  }

  /// Envoie un e-mail de réinitialisation. Ne touche pas à [state] : l'écran
  /// gère son propre indicateur de chargement et affiche l'erreur telle quelle.
  Future<void> sendPasswordReset(String identifier) {
    return ref.read(authRepositoryProvider).sendPasswordReset(identifier);
  }

  /// Déconnexion complète : session Firebase, compte Google, et **tout** ce que
  /// le compte a laissé derrière lui.
  ///
  /// L'ordre importe. Le token FCM doit être révoqué tant que la session est
  /// encore valide ; le cookie de session backend doit partir avant que l'écran
  /// suivant ne déclenche une requête, sinon `/api/mobile/*` continue de
  /// répondre au nom de l'utilisateur sortant.
  ///
  /// Les caches Riverpod de données utilisateur ne sont pas invalidés ici : ils
  /// observent `currentUserIdProvider` et se recalculent d'eux-mêmes. Panier et
  /// préférences d'auto-remplissage, eux, ne sont liés à aucun compte et
  /// doivent être vidés explicitement — sans quoi le client suivant hérite du
  /// panier et des coordonnées du précédent.
  Future<void> logout() async {
    try {
      final dio = await ref.read(dioProvider.future);
      await ref.read(pushServiceProvider).unregisterToken(dio: dio);
    } catch (_) {}

    await ref.read(authRepositoryProvider).logout();

    try {
      await clearSessionCookies(ref);
    } catch (_) {}

    ref.read(cartProvider.notifier).clear();

    try {
      final prefs = await ref.read(userPrefsServiceProvider.future);
      await prefs.clear();
    } catch (_) {}

    state = const AsyncData(false);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, bool>(
  AuthController.new,
);
