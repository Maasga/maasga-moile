import 'dart:convert';
import 'dart:typed_data';

import 'package:app/core/network/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adaptateur HTTP factice : répond le statut fourni par [statusFor] et
/// mémorise l'en-tête Authorization de chaque appel.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statusFor);

  final int Function(int callIndex) statusFor;
  final List<String?> authHeaders = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authHeaders.add(options.headers['Authorization'] as String?);
    final status = statusFor(authHeaders.length - 1);
    return ResponseBody.fromString(
      jsonEncode({'status': status}),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_FakeAdapter adapter, IdTokenProvider tokens) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = adapter;
  dio.interceptors.add(FirebaseAuthInterceptor(dio, tokens));
  return dio;
}

void main() {
  group('FirebaseAuthInterceptor', () {
    test('pose le token Firebase en Bearer', () async {
      final adapter = _FakeAdapter((_) => 200);
      final dio = _dio(adapter, ({bool forceRefresh = false}) async => 'T1');
      await dio.get<dynamic>('/x');
      expect(adapter.authHeaders, ['Bearer T1']);
    });

    test('401 puis 200 : rafraîchit le token et rejoue une fois', () async {
      final adapter = _FakeAdapter((i) => i == 0 ? 401 : 200);
      final dio = _dio(
        adapter,
        ({bool forceRefresh = false}) async => forceRefresh ? 'FRESH' : 'OLD',
      );
      final res = await dio.get<dynamic>('/x');
      expect(res.statusCode, 200);
      expect(adapter.authHeaders, ['Bearer OLD', 'Bearer FRESH']);
    });

    test('401 persistant : un seul rejeu, pas de boucle infinie', () async {
      final adapter = _FakeAdapter((_) => 401);
      var refreshCount = 0;
      final dio = _dio(adapter, ({bool forceRefresh = false}) async {
        if (forceRefresh) refreshCount++;
        return 'T';
      });
      await expectLater(
        dio.get<dynamic>('/x'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );
      expect(adapter.authHeaders.length, 2);
      expect(refreshCount, 1);
    });

    test('utilisateur déconnecté : pas de header ni de rejeu', () async {
      final adapter = _FakeAdapter((_) => 401);
      final dio = _dio(adapter, ({bool forceRefresh = false}) async => null);
      await expectLater(dio.get<dynamic>('/x'), throwsA(isA<DioException>()));
      expect(adapter.authHeaders, [null]);
    });
  });
}
