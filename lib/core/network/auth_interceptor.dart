import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Fournit le token Firebase ID (forceRefresh = true pour le renouveler).
typedef IdTokenProvider = Future<String?> Function({bool forceRefresh});

/// Injecte le token Firebase en Bearer et, sur 401, rafraîchit le token puis
/// rejoue la requête **une seule fois**.
///
/// Le flag [retriedKey] dans `requestOptions.extra` évite la boucle infinie :
/// le rejeu repasse par ce même intercepteur, et un 401 persistant (compte
/// supprimé, rôle révoqué…) relançait auparavant le cycle sans fin.
class FirebaseAuthInterceptor extends Interceptor {
  FirebaseAuthInterceptor(this._dio, this._tokenProvider);

  static const retriedKey = 'maasgaAuthRetried';

  final Dio _dio;
  final IdTokenProvider _tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Rejeu après 401 : le token rafraîchi est déjà posé, ne pas l'écraser.
    if (options.extra[retriedKey] == true) return handler.next(options);
    try {
      final token = await _tokenProvider(forceRefresh: false);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      if (kDebugMode) debugPrint('API — token Firebase indisponible: $e');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final opts = err.requestOptions;
    if (err.response?.statusCode != 401 || opts.extra[retriedKey] == true) {
      return handler.next(err);
    }
    try {
      final refreshed = await _tokenProvider(forceRefresh: true);
      if (refreshed == null || refreshed.isEmpty) return handler.next(err);
      opts.extra[retriedKey] = true;
      opts.headers['Authorization'] = 'Bearer $refreshed';
      final response = await _dio.fetch<dynamic>(opts);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    } catch (refreshError) {
      if (kDebugMode) {
        debugPrint(
          'API 401 — échec du rafraîchissement du token: $refreshError',
        );
      }
      return handler.next(err);
    }
  }
}
