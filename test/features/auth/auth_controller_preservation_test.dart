// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: subtype_of_sealed_class

/// Property-Based Preservation Tests — Non-Buggy Sign-in Flows Unchanged
///
/// **Validates: Requirements 3.2, 3.3, 3.4**
///
/// Property 2: Preservation — Non-Buggy Sign-in Flows Unchanged
///
/// These tests confirm that existing sign-in/sign-out flows that do NOT trigger
/// the stale-session bug condition continue to behave correctly both before and
/// after the fix is applied. They establish a baseline and prevent regressions.
///
/// Properties verified:
///   2a — login() with empty jar completes as AsyncData(true)
///   2b — logout() invokes clearSessionCookies AND repo.logout()
///   2c — loginWithGoogleTokens() completes with AsyncData(true) regardless of jar state
///   2d — if clearSessionCookies throws, the sign-in flow is not blocked

import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:app/core/network/api_client.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/features/cart/presentation/cart_state.dart';
import 'package:app/shared/services/user_prefs_service.dart';

// Re-use the mock generated for the PBT test.
import 'auth_controller_pbt_test.mocks.dart';

// ─── FakeDio ─────────────────────────────────────────────────────────────────

/// Minimal Dio stub that accepts POST/GET/DELETE without network access.
/// Prevents _syncBackendSession() and _registerForPush() from failing.
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

  @override
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return Response<T>(
      data: null,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

// ─── FakeCookieJar ────────────────────────────────────────────────────────────

/// In-memory CookieJar that tracks deleteAll() calls.
class FakeCookieJar implements CookieJar {
  final List<Cookie> _storedCookies;
  int deleteAllCallCount = 0;
  bool ignoreExpires = false;

  FakeCookieJar({List<Cookie>? initialCookies})
      : _storedCookies = List<Cookie>.from(initialCookies ?? []);

  @override
  Future<List<Cookie>> loadForRequest(Uri uri) async =>
      List<Cookie>.from(_storedCookies);

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async =>
      _storedCookies.addAll(cookies);

  @override
  Future<void> deleteAll() async {
    deleteAllCallCount++;
    _storedCookies.clear();
  }

  @override
  Future<void> delete(Uri uri, [bool withDomainSharedCookies = false]) async =>
      _storedCookies.clear();
}

// ─── ThrowingCookieJar ────────────────────────────────────────────────────────

/// CookieJar whose deleteAll() always throws — used to verify that
/// _startCleanSession() absorbs errors without blocking the login flow.
class ThrowingCookieJar implements CookieJar {
  bool ignoreExpires = false;

  @override
  Future<List<Cookie>> loadForRequest(Uri uri) async => [];

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {}

  @override
  Future<void> deleteAll() async {
    throw Exception('Simulated cookie jar failure');
  }

  @override
  Future<void> delete(Uri uri, [bool withDomainSharedCookies = false]) async {}
}

// ─── FakeUserPrefsService ─────────────────────────────────────────────────────

/// Minimal UserPrefsService stub so logout() doesn't touch SharedPreferences.
class FakeUserPrefsService extends Fake implements UserPrefsService {
  bool clearCalled = false;

  @override
  Future<void> clear() async {
    clearCalled = true;
  }
}

// ─── Helper ───────────────────────────────────────────────────────────────────

/// Creates a ProviderContainer wired with the given fakes.
///
/// [jar]         — injected for cookieJarProvider
/// [throwingJar] — when true, use ThrowingCookieJar instead (Property 2d)
/// [fakePrefs]   — injected for userPrefsServiceProvider (needed by logout())
ProviderContainer _makeContainer({
  FakeCookieJar? jar,
  bool throwingJar = false,
  FakeUserPrefsService? fakePrefs,
  required MockAuthRepository mockRepo,
}) {
  final CookieJar resolvedJar =
      throwingJar ? ThrowingCookieJar() : (jar ?? FakeCookieJar());
  final prefs = fakePrefs ?? FakeUserPrefsService();

  return ProviderContainer(
    overrides: [
      cookieJarProvider.overrideWith((_) async => resolvedJar),
      authRepositoryProvider.overrideWithValue(mockRepo),
      dioProvider.overrideWith((_) async => FakeDio()),
      userPrefsServiceProvider.overrideWith((_) async => prefs),
    ],
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ────────────────────────────────────────────────────────────────────────────
  // Property 2a — login() with empty jar completes as AsyncData(true)
  // ────────────────────────────────────────────────────────────────────────────
  group(
    'Property 2a: login() with empty jar completes as AsyncData(true) '
    '(Validates: Requirements 3.2)',
    () {
      test(
        'login() avec jar vide se termine en AsyncData(true)',
        () async {
          // ── Arrange ──────────────────────────────────────────────────────
          final emptyJar = FakeCookieJar(); // no pre-existing cookies
          final mockRepo = MockAuthRepository();
          when(mockRepo.hasActiveSession()).thenAnswer((_) async => false);
          when(
            mockRepo.login(
              identifier: anyNamed('identifier'),
              password: anyNamed('password'),
            ),
          ).thenAnswer((_) async {});

          final container = _makeContainer(jar: emptyJar, mockRepo: mockRepo);
          addTearDown(container.dispose);

          // Wait for build() to resolve
          await container.read(authControllerProvider.future);

          // ── Act ──────────────────────────────────────────────────────────
          await container.read(authControllerProvider.notifier).login(
            identifier: 'test@example.com',
            password: 'password123',
          );

          // ── Assert ───────────────────────────────────────────────────────
          final state = container.read(authControllerProvider);
          expect(
            state,
            isA<AsyncData<bool>>(),
            reason: 'login() doit se terminer en AsyncData, pas AsyncError',
          );
          expect(
            state.value,
            isTrue,
            reason: 'login() doit retourner true (session active)',
          );

          // Confirm repo.login was called
          verify(
            mockRepo.login(
              identifier: 'test@example.com',
              password: 'password123',
            ),
          ).called(1);
        },
      );

      test(
        'login() avec jar vide appelle clearSessionCookies (deleteAll) une fois',
        () async {
          // ── Arrange ──────────────────────────────────────────────────────
          final emptyJar = FakeCookieJar();
          final mockRepo = MockAuthRepository();
          when(mockRepo.hasActiveSession()).thenAnswer((_) async => false);
          when(
            mockRepo.login(
              identifier: anyNamed('identifier'),
              password: anyNamed('password'),
            ),
          ).thenAnswer((_) async {});

          final container = _makeContainer(jar: emptyJar, mockRepo: mockRepo);
          addTearDown(container.dispose);

          await container.read(authControllerProvider.future);

          // ── Act ──────────────────────────────────────────────────────────
          await container.read(authControllerProvider.notifier).login(
            identifier: '70000000',
            password: 'password123',
          );

          // ── Assert ───────────────────────────────────────────────────────
          // Preservation: _startCleanSession is called even with an empty jar
          // (no-op in terms of stale cookies, but proves the flow is consistent)
          expect(
            emptyJar.deleteAllCallCount,
            greaterThanOrEqualTo(1),
            reason:
                'clearSessionCookies doit être appelé dans login(), '
                'même avec un jar vide',
          );
        },
      );
    },
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Property 2b — logout() invokes clearSessionCookies AND repo.logout()
  // ────────────────────────────────────────────────────────────────────────────
  group(
    'Property 2b: logout() invoque clearSessionCookies ET repo.logout() '
    '(Validates: Requirements 3.2)',
    () {
      test(
        'logout() appelle deleteAll() sur le cookieJar',
        () async {
          // ── Arrange ──────────────────────────────────────────────────────
          final jar = FakeCookieJar(
            initialCookies: [
              Cookie('__session', 'active_session_token')..path = '/',
            ],
          );
          final mockRepo = MockAuthRepository();
          when(mockRepo.hasActiveSession()).thenAnswer((_) async => true);
          when(mockRepo.logout()).thenAnswer((_) async {});
          when(mockRepo.loginWithGoogle()).thenAnswer((_) async {});

          final container = _makeContainer(jar: jar, mockRepo: mockRepo);
          addTearDown(container.dispose);

          await container.read(authControllerProvider.future);

          // ── Act ──────────────────────────────────────────────────────────
          await container.read(authControllerProvider.notifier).logout();

          // ── Assert ───────────────────────────────────────────────────────
          expect(
            jar.deleteAllCallCount,
            greaterThanOrEqualTo(1),
            reason:
                'logout() doit appeler clearSessionCookies (deleteAll) '
                'pour vider le jar persistant',
          );
        },
      );

      test(
        'logout() appelle repo.logout() (Firebase signOut + Google disconnect)',
        () async {
          // ── Arrange ──────────────────────────────────────────────────────
          final jar = FakeCookieJar();
          final mockRepo = MockAuthRepository();
          when(mockRepo.hasActiveSession()).thenAnswer((_) async => true);
          when(mockRepo.logout()).thenAnswer((_) async {});

          final container = _makeContainer(jar: jar, mockRepo: mockRepo);
          addTearDown(container.dispose);

          await container.read(authControllerProvider.future);

          // ── Act ──────────────────────────────────────────────────────────
          await container.read(authControllerProvider.notifier).logout();

          // ── Assert ───────────────────────────────────────────────────────
          verify(mockRepo.logout()).called(1);
        },
      );

      test(
        'logout() met state à AsyncData(false) après déconnexion',
        () async {
          // ── Arrange ──────────────────────────────────────────────────────
          final jar = FakeCookieJar();
          final mockRepo = MockAuthRepository();
          when(mockRepo.hasActiveSession()).thenAnswer((_) async => true);
          when(mockRepo.logout()).thenAnswer((_) async {});

          final container = _makeContainer(jar: jar, mockRepo: mockRepo);
          addTearDown(container.dispose);

          await container.read(authControllerProvider.future);
          // Confirm we start logged in
          expect(container.read(authControllerProvider).value, isTrue);

          // ── Act ──────────────────────────────────────────────────────────
          await container.read(authControllerProvider.notifier).logout();

          // ── Assert ───────────────────────────────────────────────────────
          final state = container.read(authControllerProvider);
          expect(
            state,
            isA<AsyncData<bool>>(),
            reason: 'logout() doit se terminer en AsyncData',
          );
          expect(
            state.value,
            isFalse,
            reason: 'logout() doit mettre state à false',
          );
        },
      );

      test(
        'logout() vide le panier (cartProvider)',
        () async {
          // ── Arrange ──────────────────────────────────────────────────────
          final jar = FakeCookieJar();
          final mockRepo = MockAuthRepository();
          when(mockRepo.hasActiveSession()).thenAnswer((_) async => true);
          when(mockRepo.logout()).thenAnswer((_) async {});

          final container = _makeContainer(jar: jar, mockRepo: mockRepo);
          addTearDown(container.dispose);

          await container.read(authControllerProvider.future);

          // ── Act ──────────────────────────────────────────────────────────
          await container.read(authControllerProvider.notifier).logout();

          // ── Assert ───────────────────────────────────────────────────────
          final cart = container.read(cartProvider);
          expect(
            cart,
            isEmpty,
            reason: 'logout() doit vider le panier via cartProvider',
          );
        },
      );
    },
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Property 2c — loginWithGoogleTokens() completes regardless of jar state
  // ────────────────────────────────────────────────────────────────────────────
  group(
    'Property 2c: loginWithGoogleTokens() se termine en AsyncData(true) '
    'quel que soit l\'état du jar (Validates: Requirements 3.3)',
    () {
      test(
        'loginWithGoogleTokens() avec jar vide → AsyncData(true)',
        () async {
          // ── Arrange ──────────────────────────────────────────────────────
          final emptyJar = FakeCookieJar();
          final mockRepo = MockAuthRepository();
          when(mockRepo.hasActiveSession()).thenAnswer((_) async => false);
          when(
            mockRepo.signInWithGoogleTokens(
              idToken: anyNamed('idToken'),
              accessToken: anyNamed('accessToken'),
            ),
          ).thenAnswer((_) async {});

          final container = _makeContainer(jar: emptyJar, mockRepo: mockRepo);
          addTearDown(container.dispose);

          await container.read(authControllerProvider.future);

          // ── Act ──────────────────────────────────────────────────────────
          await container
              .read(authControllerProvider.notifier)
              .loginWithGoogleTokens(
                idToken: 'fake_id_token',
                accessToken: 'fake_access_token',
              );

          // ── Assert ───────────────────────────────────────────────────────
          final state = container.read(authControllerProvider);
          expect(
            state,
            isA<AsyncData<bool>>(),
            reason:
                'loginWithGoogleTokens() avec jar vide doit se terminer '
                'en AsyncData',
          );
          expect(state.value, isTrue);
        },
      );

      test(
        'loginWithGoogleTokens() avec jar non vide → AsyncData(true) et jar vidé',
        () async {
          // ── Arrange ──────────────────────────────────────────────────────
          final jar = FakeCookieJar(
            initialCookies: [
              Cookie('__session', 'stale_token')..path = '/',
              Cookie('cf_clearance', 'stale_cf')..path = '/',
            ],
          );
          final mockRepo = MockAuthRepository();
          when(mockRepo.hasActiveSession()).thenAnswer((_) async => false);
          when(
            mockRepo.signInWithGoogleTokens(
              idToken: anyNamed('idToken'),
              accessToken: anyNamed('accessToken'),
            ),
          ).thenAnswer((_) async {});

          final container = _makeContainer(jar: jar, mockRepo: mockRepo);
          addTearDown(container.dispose);

          await container.read(authControllerProvider.future);

          // ── Act ──────────────────────────────────────────────────────────
          await container
              .read(authControllerProvider.notifier)
              .loginWithGoogleTokens(
                idToken: 'fake_id_token',
                accessToken: 'fake_access_token',
              );

          // ── Assert ───────────────────────────────────────────────────────
          // Flow completes successfully
          final state = container.read(authControllerProvider);
          expect(state, isA<AsyncData<bool>>());
          expect(state.value, isTrue);

          // And clearSessionCookies was called (preservation of fix behaviour)
          expect(
            jar.deleteAllCallCount,
            greaterThanOrEqualTo(1),
            reason: 'clearSessionCookies doit être appelé dans loginWithGoogleTokens',
          );
        },
      );

      test(
        'loginWithGoogleTokens() appelle repo.signInWithGoogleTokens()',
        () async {
          // ── Arrange ──────────────────────────────────────────────────────
          final jar = FakeCookieJar();
          final mockRepo = MockAuthRepository();
          when(mockRepo.hasActiveSession()).thenAnswer((_) async => false);
          when(
            mockRepo.signInWithGoogleTokens(
              idToken: anyNamed('idToken'),
              accessToken: anyNamed('accessToken'),
            ),
          ).thenAnswer((_) async {});

          final container = _makeContainer(jar: jar, mockRepo: mockRepo);
          addTearDown(container.dispose);

          await container.read(authControllerProvider.future);

          // ── Act ──────────────────────────────────────────────────────────
          await container
              .read(authControllerProvider.notifier)
              .loginWithGoogleTokens(
                idToken: 'id_token_abc',
                accessToken: 'access_token_xyz',
              );

          // ── Assert ───────────────────────────────────────────────────────
          verify(
            mockRepo.signInWithGoogleTokens(
              idToken: 'id_token_abc',
              accessToken: 'access_token_xyz',
            ),
          ).called(1);
        },
      );
    },
  );

  // ────────────────────────────────────────────────────────────────────────────
  // Property 2d — clearSessionCookies error is absorbed; login is not blocked
  // ────────────────────────────────────────────────────────────────────────────
  group(
    'Property 2d: si clearSessionCookies lève une exception, '
    'le flux de connexion se poursuit (Validates: Requirements 3.2)',
    () {
      test(
        'login() continue en AsyncData(true) même si deleteAll() lève',
        () async {
          // ── Arrange ──────────────────────────────────────────────────────
          final mockRepo = MockAuthRepository();
          when(mockRepo.hasActiveSession()).thenAnswer((_) async => false);
          when(
            mockRepo.login(
              identifier: anyNamed('identifier'),
              password: anyNamed('password'),
            ),
          ).thenAnswer((_) async {});

          // ThrowingCookieJar simulates a failing PersistCookieJar
          final container = _makeContainer(
            throwingJar: true,
            mockRepo: mockRepo,
          );
          addTearDown(container.dispose);

          await container.read(authControllerProvider.future);

          // ── Act ──────────────────────────────────────────────────────────
          await container.read(authControllerProvider.notifier).login(
            identifier: 'test@example.com',
            password: 'password123',
          );

          // ── Assert ───────────────────────────────────────────────────────
          final state = container.read(authControllerProvider);
          expect(
            state,
            isA<AsyncData<bool>>(),
            reason:
                '_startCleanSession doit absorber les exceptions — '
                'login() doit quand même se terminer en AsyncData',
          );
          expect(
            state.value,
            isTrue,
            reason: 'login() doit retourner true même si clearSessionCookies échoue',
          );

          // repo.login was still called despite the cookie jar error
          verify(
            mockRepo.login(
              identifier: 'test@example.com',
              password: 'password123',
            ),
          ).called(1);
        },
      );

      test(
        'loginWithGoogle() continue en AsyncData(true) même si deleteAll() lève',
        () async {
          // ── Arrange ──────────────────────────────────────────────────────
          final mockRepo = MockAuthRepository();
          when(mockRepo.hasActiveSession()).thenAnswer((_) async => false);
          when(mockRepo.loginWithGoogle()).thenAnswer((_) async {});

          final container = _makeContainer(
            throwingJar: true,
            mockRepo: mockRepo,
          );
          addTearDown(container.dispose);

          await container.read(authControllerProvider.future);

          // ── Act ──────────────────────────────────────────────────────────
          await container
              .read(authControllerProvider.notifier)
              .loginWithGoogle();

          // ── Assert ───────────────────────────────────────────────────────
          final state = container.read(authControllerProvider);
          expect(
            state,
            isA<AsyncData<bool>>(),
            reason:
                '_startCleanSession doit absorber les exceptions — '
                'loginWithGoogle() doit quand même se terminer en AsyncData',
          );
          expect(state.value, isTrue);

          verify(mockRepo.loginWithGoogle()).called(1);
        },
      );

      test(
        'loginWithGoogleTokens() continue en AsyncData(true) même si deleteAll() lève',
        () async {
          // ── Arrange ──────────────────────────────────────────────────────
          final mockRepo = MockAuthRepository();
          when(mockRepo.hasActiveSession()).thenAnswer((_) async => false);
          when(
            mockRepo.signInWithGoogleTokens(
              idToken: anyNamed('idToken'),
              accessToken: anyNamed('accessToken'),
            ),
          ).thenAnswer((_) async {});

          final container = _makeContainer(
            throwingJar: true,
            mockRepo: mockRepo,
          );
          addTearDown(container.dispose);

          await container.read(authControllerProvider.future);

          // ── Act ──────────────────────────────────────────────────────────
          await container
              .read(authControllerProvider.notifier)
              .loginWithGoogleTokens(
                idToken: 'id_token',
                accessToken: 'access_token',
              );

          // ── Assert ───────────────────────────────────────────────────────
          final state = container.read(authControllerProvider);
          expect(state, isA<AsyncData<bool>>());
          expect(state.value, isTrue);
        },
      );
    },
  );
}
