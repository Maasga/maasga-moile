// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: subtype_of_sealed_class

/// Property-Based Exploration Test — Bug Condition: Stale Cookie Session Data
///
/// **Validates: Requirements 1.2**
///
/// Property 1: Bug Condition — Cookie Jar Cleared Before Sign-in
///
/// Scénario déterministe :
///   cookieJarHasPreviousSession = true  (jar pré-chargé avec les cookies de uid_A)
///   userJustSignedIn           = true  (loginWithGoogle() retourne uid_B)
///
/// Comportement attendu (code corrigé, commit c85daa1) :
///   Après loginWithGoogle(), le cookie jar NE contient PLUS les cookies de uid_A.
///
/// Comportement bugué (code non corrigé, commit 4e966dc) :
///   _startCleanSession() est absent — clearSessionCookies() n'est JAMAIS appelé
///   avant loginWithGoogle(). Le cookie de uid_A reste sur le disque. Le backend
///   répond alors avec les données de uid_A pour le compte de uid_B.
///
/// Ce test DOIT ÉCHOUER sur le code non corrigé (commit 4e966dc).
/// Ce test DOIT PASSER sur le code corrigé (commit c85daa1 et suivants).
///
/// Contre-exemple sur code non corrigé :
///   "loginWithGoogle() appelé avec uid_B : cookieJar contient encore le cookie
///   de uid_A — backend répondrait avec les données de uid_A pour uid_B"

import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:app/core/network/api_client.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/core/config/env.dart';

@GenerateMocks([AuthRepository])
import 'auth_controller_pbt_test.mocks.dart';

// ─── FakeDio ──────────────────────────────────────────────────────────────────

/// Dio factice qui accepte toutes les requêtes et retourne une réponse vide.
///
/// Utilisé pour court-circuiter _syncBackendSession() et _registerForPush()
/// dans les tests unitaires — ces méthodes sont non-bloquantes (try/catch)
/// mais elles attendent dioProvider.future.
class FakeDio extends Fake implements Dio {
  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return Response<T>(
      data: null,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return Response<T>(
      data: null,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

// ─── FakeCookieJar ────────────────────────────────────────────────────────────

/// CookieJar en mémoire instrumenté pour les tests.
///
/// Pré-chargeable avec des cookies appartenant à un UID donné.
/// Trace les appels à [deleteAll] pour vérifier que clearSessionCookies a été
/// invoqué avant le sign-in.
class FakeCookieJar implements CookieJar {
  final List<Cookie> _storedCookies;
  int deleteAllCallCount = 0;
  bool ignoreExpires = false;

  FakeCookieJar({List<Cookie>? initialCookies})
      : _storedCookies = List<Cookie>.from(initialCookies ?? []);

  @override
  Future<List<Cookie>> loadForRequest(Uri uri) async {
    return List<Cookie>.from(_storedCookies);
  }

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {
    // Simule la persistance des nouveaux cookies
    _storedCookies.addAll(cookies);
  }

  @override
  Future<void> deleteAll() async {
    deleteAllCallCount++;
    _storedCookies.clear();
  }

  @override
  Future<void> delete(Uri uri, [bool withDomainSharedCookies = false]) async {
    _storedCookies.clear();
  }
}

// ─── Cookie factory ───────────────────────────────────────────────────────────

/// Construit un cookie de session Cloudflare simulant une session appartenant
/// à [uid].
Cookie _sessionCookieForUid(String uid) {
  final cookie = Cookie(
    '__session_uid',
    'session_token_for_$uid',
  );
  cookie.path = '/';
  cookie.httpOnly = true;
  cookie.secure = true;
  return cookie;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group(
    'Property 1: Bug Condition — Cookie Jar Cleared Before Sign-in '
    '(Validates: Requirements 1.2)',
    () {
      /// Cas déterministe scoped :
      ///   cookieJarHasPreviousSession = true
      ///   userJustSignedIn           = true
      ///   loginMethodCalled          = 'loginWithGoogle'
      test(
        'loginWithGoogle() efface le cookie de uid_A avant de connecter uid_B',
        () async {
          // ── Arrange ────────────────────────────────────────────────────────

          const uidA = 'uid_A_previous_session';
          const uidB = 'uid_B_new_session';

          // Cookie jar pré-chargé : simule une session périmée appartenant à uid_A
          final fakeJar = FakeCookieJar(
            initialCookies: [_sessionCookieForUid(uidA)],
          );

          // Vérification préalable : le jar contient bien le cookie de uid_A
          final apiUri = Uri.parse(Env.apiBaseUrl);
          final cookiesBeforeLogin = await fakeJar.loadForRequest(apiUri);
          expect(
            cookiesBeforeLogin,
            isNotEmpty,
            reason:
                'Précondition : le jar doit contenir les cookies de uid_A '
                'avant le login',
          );
          expect(
            cookiesBeforeLogin.first.value,
            contains(uidA),
            reason: 'Le cookie pré-chargé doit appartenir à uid_A',
          );

          // Mock AuthRepository : loginWithGoogle() réussit sans erreur
          // (simule que uid_B vient de s'authentifier via Firebase)
          final mockRepo = MockAuthRepository();
          when(mockRepo.loginWithGoogle()).thenAnswer((_) async {});
          when(mockRepo.hasActiveSession()).thenAnswer((_) async => true);
          // syncSession et registerForPush ne sont pas déclenchés dans ce test
          // (dioProvider n'est pas résolu en test unitaire)

          // ProviderContainer avec overrides
          final container = ProviderContainer(
            overrides: [
              // Injecte le FakeCookieJar (synchrone, pas de FutureProvider réel)
              cookieJarProvider.overrideWith((_) async => fakeJar),
              // Injecte le MockAuthRepository
              authRepositoryProvider.overrideWithValue(mockRepo),
              // dioProvider : non utilisé dans ce test — loginWithGoogle ne fait
              // pas de requête Dio directe. On le court-circuite pour éviter
              // path_provider en test.
              dioProvider.overrideWith((_) async => FakeDio()),
            ],
          );
          addTearDown(container.dispose);

          // Attendre que authControllerProvider.build() soit résolu
          // (hasActiveSession retourne true → state = AsyncData(true))
          await container.read(authControllerProvider.future);

          // ── Act ────────────────────────────────────────────────────────────

          // Appel de loginWithGoogle() — sur code non corrigé, _startCleanSession
          // est absent : clearSessionCookies/deleteAll() n'est JAMAIS appelé,
          // le cookie de uid_A reste intact.
          // Sur code corrigé, _startCleanSession() appelle clearSessionCookies()
          // qui invoque fakeJar.deleteAll() → le jar est vidé.
          await container
              .read(authControllerProvider.notifier)
              .loginWithGoogle();

          // ── Assert ─────────────────────────────────────────────────────────

          // [EXPECTED BEHAVIOR] : clearSessionCookies doit avoir été invoqué.
          // Sur code NON corrigé (4e966dc) : deleteAllCallCount == 0 → ÉCHEC ✗
          // Sur code corrigé (c85daa1+) : deleteAllCallCount >= 1 → SUCCÈS ✓
          expect(
            fakeJar.deleteAllCallCount,
            greaterThanOrEqualTo(1),
            reason:
                'CONTRE-EXEMPLE (code non corrigé) : '
                'loginWithGoogle() appelé avec uid_B — clearSessionCookies() '
                'n\'a PAS été invoqué (deleteAllCallCount == 0). '
                'Le cookieJar contient encore le cookie de uid_A '
                '("${_sessionCookieForUid(uidA).value}"). '
                'Le backend répondrait avec les données de uid_A pour uid_B.',
          );

          // [EXPECTED BEHAVIOR] : après clearSessionCookies, le jar doit être vide.
          // Sur code NON corrigé : le cookie de uid_A est encore présent → ÉCHEC ✗
          // Sur code corrigé : le jar est vide → SUCCÈS ✓
          final cookiesAfterLogin = await fakeJar.loadForRequest(apiUri);
          expect(
            cookiesAfterLogin,
            isEmpty,
            reason:
                'CONTRE-EXEMPLE (code non corrigé) : '
                'loginWithGoogle() appelé avec uid_B — '
                'cookieJar contient encore le cookie de uid_A '
                '("${_sessionCookieForUid(uidA).value}"). '
                'Le backend répondrait avec les données de uid_A pour uid_B.',
          );

          // Vérifier que loginWithGoogle() a bien été appelé sur le repo
          verify(mockRepo.loginWithGoogle()).called(1);
        },
      );

      /// Variante : même propriété avec un jar contenant PLUSIEURS cookies
      /// de sessions différentes (N cookies appartenant à uid_A).
      test(
        'loginWithGoogle() efface TOUS les cookies du jar périmé '
        '(plusieurs cookies de uid_A)',
        () async {
          // ── Arrange ────────────────────────────────────────────────────────

          const uidA = 'uid_A_previous_session';

          final fakeJar = FakeCookieJar(
            initialCookies: [
              _sessionCookieForUid(uidA),
              Cookie('__cf_bm', 'cloudflare_bot_management_token_for_$uidA')
                ..path = '/'
                ..httpOnly = true,
              Cookie('cf_clearance', 'clearance_for_$uidA')
                ..path = '/'
                ..httpOnly = true,
            ],
          );

          final apiUri = Uri.parse(Env.apiBaseUrl);
          final cookiesBeforeLogin = await fakeJar.loadForRequest(apiUri);
          expect(
            cookiesBeforeLogin,
            hasLength(3),
            reason: 'Précondition : 3 cookies périmés de uid_A',
          );

          final mockRepo = MockAuthRepository();
          when(mockRepo.loginWithGoogle()).thenAnswer((_) async {});
          when(mockRepo.hasActiveSession()).thenAnswer((_) async => true);

          final container = ProviderContainer(
            overrides: [
              cookieJarProvider.overrideWith((_) async => fakeJar),
              authRepositoryProvider.overrideWithValue(mockRepo),
              dioProvider.overrideWith((_) async => FakeDio()),
            ],
          );
          addTearDown(container.dispose);

          await container.read(authControllerProvider.future);

          // ── Act ────────────────────────────────────────────────────────────

          await container
              .read(authControllerProvider.notifier)
              .loginWithGoogle();

          // ── Assert ─────────────────────────────────────────────────────────

          // Sur code NON corrigé : tous les cookies sont encore présents → ÉCHEC ✗
          // Sur code corrigé : jar vide → SUCCÈS ✓
          expect(
            fakeJar.deleteAllCallCount,
            greaterThanOrEqualTo(1),
            reason:
                'CONTRE-EXEMPLE (code non corrigé) : '
                'deleteAll() n\'a pas été invoqué — les 3 cookies de uid_A '
                'sont encore présents après loginWithGoogle().',
          );

          final cookiesAfterLogin = await fakeJar.loadForRequest(apiUri);
          expect(
            cookiesAfterLogin,
            isEmpty,
            reason:
                'CONTRE-EXEMPLE (code non corrigé) : '
                'Le jar contient encore ${cookiesAfterLogin.length} cookie(s) '
                'de uid_A après loginWithGoogle() avec uid_B.',
          );
        },
      );
    },
  );
}
