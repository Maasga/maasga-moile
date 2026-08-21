import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
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

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
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

  Future<void> logout() async {
    try {
      final dio = await ref.read(dioProvider.future);
      await ref.read(pushServiceProvider).unregisterToken(dio: dio);
    } catch (_) {}
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncData(false);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, bool>(
  AuthController.new,
);
