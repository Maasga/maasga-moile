// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: subtype_of_sealed_class

/// Unit Tests — AuthController: clearSessionCookies call ordering
///
/// Validates: Requirements 2.2, 3.2, 3.3
///
/// Tests:
///   1. login() calls deleteAll BEFORE repo.login()
///   2. loginWithGoogle() calls deleteAll BEFORE repo.loginWithGoogle()
///   3. loginWithGoogleTokens() calls deleteAll BEFORE repo.signInWithGoogleTokens()
///   4. register() calls deleteAll BEFORE repo.register()
///   5. logout() calls deleteAll AND repo.logout()
///   6. Exception in clearSessionCookies is absorbed — login() still AsyncData(true)
///   7. build() with active session does NOT call deleteAll

import 'dart:async';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:app/core/network/api_client.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/shared/services/user_prefs_service.dart';
import 'auth_controller_pbt_test.mocks.dart';

class _FakeDio extends Fake implements Dio {
  @override
  Future<Response<T>> post<T>(String path,
      {Object? data, Map<String, dynamic>? queryParameters, Options? options,
       CancelToken? cancelToken, void Function(int, int)? onSendProgress,
       void Function(int, int)? onReceiveProgress}) async =>
      Response<T>(data: null, statusCode: 200, requestOptions: RequestOptions(path: path));

  @override
  Future<Response<T>> get<T>(String path,
      {Object? data, Map<String, dynamic>? queryParameters, Options? options,
       CancelToken? cancelToken, void Function(int, int)? onReceiveProgress}) async =>
      Response<T>(data: null, statusCode: 200, requestOptions: RequestOptions(path: path));

  @override
  Future<Response<T>> delete<T>(String path,
      {Object? data, Map<String, dynamic>? queryParameters, Options? options,
       CancelToken? cancelToken}) async =>
      Response<T>(data: null, statusCode: 200, requestOptions: RequestOptions(path: path));
}

class _TrackingJar implements CookieJar {
  final List<String> log;
  bool ignoreExpires = false;
  _TrackingJar(this.log);

  @override Future<List<Cookie>> loadForRequest(Uri uri) async => [];
  @override Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {}
  @override Future<void> deleteAll() async => log.add('deleteAll');
  @override Future<void> delete(Uri uri, [bool withDomainSharedCookies = false]) async {}
}

class _ThrowingJar implements CookieJar {
  bool ignoreExpires = false;
  @override Future<List<Cookie>> loadForRequest(Uri uri) async => [];
  @override Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {}
  @override Future<void> deleteAll() async => throw Exception('jar failure');
  @override Future<void> delete(Uri uri, [bool withDomainSharedCookies = false]) async {}
}

class _FakePrefs extends Fake implements UserPrefsService {
  @override Future<void> clear() async {}
}

class _LoggingRepo extends Fake implements AuthRepository {
  final MockAuthRepository _d;
  final List<String> log;
  _LoggingRepo(this._d, this.log);

  @override Future<bool> hasActiveSession() => _d.hasActiveSession();
  @override Future<String?> getIdToken() => _d.getIdToken();
  @override Future<Map<String, dynamic>?> getProfile() => _d.getProfile();
  @override Future<void> sendPasswordReset(String id) => _d.sendPasswordReset(id);
  @override Future<void> syncSession(Dio dio) async {}
  @override Future<Map<String, dynamic>?> fetchBackendProfile(Dio dio) async => null;
  @override Future<bool> syncProfile({required Dio dio, String? name, String? phone, String? quartier, String? route = '/api/mobile/register'}) async => true;

  @override Future<void> login({required String identifier, required String password}) async {
    log.add('login');
    return _d.login(identifier: identifier, password: password);
  }

  @override Future<void> register({required String name, required String phone, required String email, required String quartier, required String password}) async {
    log.add('register');
    return _d.register(name: name, phone: phone, email: email, quartier: quartier, password: password);
  }

  @override Future<void> loginWithGoogle() async {
    log.add('loginWithGoogle');
    return _d.loginWithGoogle();
  }

  @override Future<void> signInWithGoogleTokens({String? idToken, String? accessToken}) async {
    log.add('signInWithGoogleTokens');
    return _d.signInWithGoogleTokens(idToken: idToken, accessToken: accessToken);
  }

  @override Future<void> logout() async {
    log.add('repoLogout');
    return _d.logout();
  }
}

ProviderContainer _container({required CookieJar jar, required AuthRepository repo}) =>
    ProviderContainer(overrides: [
      cookieJarProvider.overrideWith((_) async => jar),
      authRepositoryProvider.overrideWithValue(repo),
      dioProvider.overrideWith((_) async => _FakeDio()),
      userPrefsServiceProvider.overrideWith((_) async => _FakePrefs()),
    ]);

void main() {
  test('Test 1: login() appelle deleteAll AVANT repo.login()', () async {
    final log = <String>[];
    final mock = MockAuthRepository();
    when(mock.hasActiveSession()).thenAnswer((_) async => false);
    when(mock.login(identifier: anyNamed('identifier'), password: anyNamed('password')))
        .thenAnswer((_) async {});
    final c = _container(jar: _TrackingJar(log), repo: _LoggingRepo(mock, log));
    addTearDown(c.dispose);
    await c.read(authControllerProvider.future);
    log.clear();
    await c.read(authControllerProvider.notifier).login(identifier: 'u', password: 'p');
    expect(log, containsAllInOrder(['deleteAll', 'login']));
  });

  test('Test 2: loginWithGoogle() appelle deleteAll AVANT repo.loginWithGoogle()', () async {
    final log = <String>[];
    final mock = MockAuthRepository();
    when(mock.hasActiveSession()).thenAnswer((_) async => false);
    when(mock.loginWithGoogle()).thenAnswer((_) async {});
    final c = _container(jar: _TrackingJar(log), repo: _LoggingRepo(mock, log));
    addTearDown(c.dispose);
    await c.read(authControllerProvider.future);
    log.clear();
    await c.read(authControllerProvider.notifier).loginWithGoogle();
    expect(log, containsAllInOrder(['deleteAll', 'loginWithGoogle']));
  });

  test('Test 3: loginWithGoogleTokens() appelle deleteAll AVANT repo.signInWithGoogleTokens()', () async {
    final log = <String>[];
    final mock = MockAuthRepository();
    when(mock.hasActiveSession()).thenAnswer((_) async => false);
    when(mock.signInWithGoogleTokens(idToken: anyNamed('idToken'), accessToken: anyNamed('accessToken')))
        .thenAnswer((_) async {});
    final c = _container(jar: _TrackingJar(log), repo: _LoggingRepo(mock, log));
    addTearDown(c.dispose);
    await c.read(authControllerProvider.future);
    log.clear();
    await c.read(authControllerProvider.notifier).loginWithGoogleTokens(idToken: 'id', accessToken: 'ac');
    expect(log, containsAllInOrder(['deleteAll', 'signInWithGoogleTokens']));
  });

  test('Test 4: register() appelle deleteAll AVANT repo.register()', () async {
    final log = <String>[];
    final mock = MockAuthRepository();
    when(mock.hasActiveSession()).thenAnswer((_) async => false);
    when(mock.register(name: anyNamed('name'), phone: anyNamed('phone'), email: anyNamed('email'),
        quartier: anyNamed('quartier'), password: anyNamed('password'))).thenAnswer((_) async {});
    final c = _container(jar: _TrackingJar(log), repo: _LoggingRepo(mock, log));
    addTearDown(c.dispose);
    await c.read(authControllerProvider.future);
    log.clear();
    await c.read(authControllerProvider.notifier).register(
        name: 'A', phone: '70', email: 'a@b.com', quartier: 'Q', password: 'pw');
    expect(log, containsAllInOrder(['deleteAll', 'register']));
  });

  test('Test 5: logout() appelle deleteAll ET repo.logout()', () async {
    final log = <String>[];
    final mock = MockAuthRepository();
    when(mock.hasActiveSession()).thenAnswer((_) async => true);
    when(mock.logout()).thenAnswer((_) async {});
    final c = _container(jar: _TrackingJar(log), repo: _LoggingRepo(mock, log));
    addTearDown(c.dispose);
    await c.read(authControllerProvider.future);
    log.clear();
    await c.read(authControllerProvider.notifier).logout();
    expect(log, contains('deleteAll'));
    expect(log, contains('repoLogout'));
  });

  test('Test 6: exception dans clearSessionCookies absorbée — login() AsyncData(true)', () async {
    final mock = MockAuthRepository();
    when(mock.hasActiveSession()).thenAnswer((_) async => false);
    when(mock.login(identifier: anyNamed('identifier'), password: anyNamed('password')))
        .thenAnswer((_) async {});
    final c = _container(jar: _ThrowingJar(), repo: _LoggingRepo(mock, []));
    addTearDown(c.dispose);
    await c.read(authControllerProvider.future);
    await c.read(authControllerProvider.notifier).login(identifier: 'u', password: 'p');
    final state = c.read(authControllerProvider);
    expect(state, isA<AsyncData<bool>>());
    expect(state.value, isTrue);
    verify(mock.login(identifier: 'u', password: 'p')).called(1);
  });

  test('Test 7: build() avec session active ne déclenche PAS deleteAll', () async {
    final log = <String>[];
    final mock = MockAuthRepository();
    when(mock.hasActiveSession()).thenAnswer((_) async => true);
    final c = _container(jar: _TrackingJar(log), repo: mock);
    addTearDown(c.dispose);
    await c.read(authControllerProvider.future);
    expect(log, isNot(contains('deleteAll')));
    expect(c.read(authControllerProvider).value, isTrue);
  });
}