// Smoke test: l'app démarre sur le splash puis redirige (session absente).
//
// Le splash utilise un Timer (fadeIn 3 s) et un CircularProgressIndicator.
// Pour éviter les "pending timer" et les dépendances plateforme indisponibles
// en test (path_provider via le cookie jar, Firebase non initialisé), on :
//  - override cookieJarProvider avec un CookieJar en mémoire,
//  - override authControllerProvider pour renvoyer « pas de session » sans
//    jamais toucher à FirebaseAuth,
//  - laisse le Timer du splash se déclencher puis on stabilise.

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/app/app.dart';
import 'package:app/core/network/api_client.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';

/// Contrôleur d'auth de test : aucune session, aucun appel Firebase.
class _LoggedOutAuthController extends AuthController {
  @override
  Future<bool> build() async => false;
}

void main() {
  testWidgets('L\'app démarre sur le splash puis redirige', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cookieJarProvider.overrideWith((ref) async => CookieJar()),
          authControllerProvider.overrideWith(_LoggedOutAuthController.new),
        ],
        child: const MaasgaMobileApp(),
      ),
    );

    // Première frame: le splash est affiché.
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Laisse le Timer du splash (3 s) se déclencher et la redirection se faire.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // On a quitté le splash: plus d'indicateur de chargement.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
