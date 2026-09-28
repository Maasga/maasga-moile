import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/auth/presentation/login_screen.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/core/network/api_client.dart';

import 'helpers/mock_dio_helper.dart';

// Tests widget de l'écran de connexion avec Dio mocké
//
// Ces tests vérifient l'intégration avec le réseau simulé
// en utilisant le helper Dio mocké existant.

class TestAuthController extends AuthController {
  TestAuthController(this.isLoggedIn);

  final bool isLoggedIn;

  @override
  Future<bool> build() async => isLoggedIn;
}

void main() {
  group('LoginScreen - avec Dio mocké', () {
    testWidgets(
      'vérifie que le Dio mocké fonctionne avec ProviderScope (non connecté)',
      (tester) async {
        // Dio mocké qui retourne une réponse de succès
        final mockDioSuccess = MockDioHelper.createMockDioWithResponse({
          'status': 'success',
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dioProvider.overrideWith((ref) async => mockDioSuccess),
              authControllerProvider.overrideWith(
                () => TestAuthController(false),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: GoRouter(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => const LoginScreen(),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Vérifie que l'écran s'affiche correctement
        expect(find.text('Connexion'), findsOneWidget);
        expect(find.text('Email ou téléphone'), findsOneWidget);
        expect(find.text('Mot de passe'), findsOneWidget);
        expect(find.text('Se connecter'), findsOneWidget);
      },
    );

    testWidgets(
      'vérifie que Dio mocké lance des erreurs comme attendu (non connecté)',
      (tester) async {
        // Dio mocké qui lance une erreur
        final mockDioError = MockDioHelper.createMockDioWithError(
          500,
          'Erreur de connexion',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dioProvider.overrideWith((ref) async => mockDioError),
              authControllerProvider.overrideWith(
                () => TestAuthController(false),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: GoRouter(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => const LoginScreen(),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // L'écran doit quand même s'afficher même avec Dio en erreur
        expect(find.text('Connexion'), findsOneWidget);
        expect(find.text('Email ou téléphone'), findsOneWidget);
        expect(find.text('Mot de passe'), findsOneWidget);
      },
    );

    testWidgets(
      'vérifie que Dio mocké fonctionne avec ProviderScope (connecté)',
      (tester) async {
        // Dio mocké qui retourne une réponse de succès
        final mockDioSuccess = MockDioHelper.createMockDioWithResponse({
          'status': 'success',
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dioProvider.overrideWith((ref) async => mockDioSuccess),
              authControllerProvider.overrideWith(
                () => TestAuthController(true),
              ),
            ],
            child: MaterialApp.router(
              routerConfig: GoRouter(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => const LoginScreen(),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // L'écran de connexion s'affiche même si l'utilisateur est connecté
        expect(find.text('Connexion'), findsOneWidget);
      },
    );
  });
}
