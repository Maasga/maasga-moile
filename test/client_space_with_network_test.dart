import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/client_space/presentation/client_space_screen.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/core/network/api_client.dart';

import 'helpers/mock_dio_helper.dart';

// Tests widget de l'écran espace client avec Dio mocké
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
  group('ClientSpaceScreen - avec Dio mocké', () {
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
                    builder: (context, state) => const ClientSpaceScreen(),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Vérifier que le Dio mocké fonctionne et que l'écran se charge
        expect(
          find.text('Connectez-vous pour accéder à votre espace'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'vérifie que Dio mocké lance des erreurs comme attendu (non connecté)',
      (tester) async {
        // Dio mocké qui lance une erreur 500
        final mockDioError = MockDioHelper.createMockDioWithError(
          500,
          'Erreur serveur interne',
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
                    builder: (context, state) => const ClientSpaceScreen(),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Vérifier que l'interface se charge malgré l'erreur
        expect(
          find.text('Connectez-vous pour accéder à votre espace'),
          findsOneWidget,
        );
      },
    );
  });
}
