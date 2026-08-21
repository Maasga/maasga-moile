import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../config/env.dart';

final cookieJarProvider = FutureProvider<CookieJar>((ref) async {
  if (kIsWeb) return CookieJar();
  final dir = await getApplicationDocumentsDirectory();
  return PersistCookieJar(
    storage: FileStorage('${dir.path}/.cookies/'),
    ignoreExpires: false,
  );
});

/// Vide le cookie jar persistant.
///
/// À appeler à **chaque déconnexion**. Le worker Cloudflare pose un cookie de
/// session et [PersistCookieJar] l'écrit sur disque : `FirebaseAuth.signOut()`
/// ne l'efface pas. Le compte suivant repartirait donc avec le cookie du
/// précédent, et comme ce cookie identifie une session côté serveur,
/// `/api/mobile/*` peut répondre avec les données de l'ancien utilisateur — d'où
/// un profil, des commandes et des rendez-vous qui ne sont pas ceux du compte
/// qui vient de se connecter.
Future<void> clearSessionCookies(Ref ref) async {
  final jar = await ref.read(cookieJarProvider.future);
  await jar.deleteAll();
}

final dioProvider = FutureProvider<Dio>((ref) async {
  final jar = await ref.watch(cookieJarProvider.future);
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: kIsWeb ? null : const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  if (!kIsWeb) {
    dio.interceptors.add(CookieManager(jar));
  }
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Utilise le token Firebase ID comme Bearer token
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            final token = await user.getIdToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
        }
        return handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          // Token expiré — Firebase le renouvelle automatiquement au prochain appel
          if (kDebugMode) {
            debugPrint('API 401 — token Firebase peut-être expiré');
          }
        }
        return handler.next(e);
      },
    ),
  );
  return dio;
});
