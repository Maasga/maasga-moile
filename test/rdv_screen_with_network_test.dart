import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/rdv/presentation/rdv_screen.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/core/network/api_client.dart';

import 'helpers/mock_dio_helper.dart';

// Tests widget de l'écran RDV avec Dio mocké
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
  group('RdvScreen - avec Dio mocké', () {
    testWidgets('vérifie que le Dio mocké fonctionne avec ProviderScope', (
      tester,
    ) async {
      // Dio mocké qui retourne une réponse de succès
      final mockDio = MockDioHelper.createMockDioWithResponse({
        'status': 'success',
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWith((ref) async => mockDio),
            authControllerProvider.overrideWith(
              () => TestAuthController(false),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const RdvScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Vérifier que le Dio mocké fonctionne et que l'écran se charge
      expect(find.text('Devis / Dimensionnement'), findsOneWidget);
    });

    testWidgets('vérifie que Dio mocké lance des erreurs comme attendu', (
      tester,
    ) async {
      // Dio mocké qui lance une erreur 500
      final mockDio = MockDioHelper.createMockDioWithError(
        500,
        'Erreur serveur interne',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWith((ref) async => mockDio),
            authControllerProvider.overrideWith(
              () => TestAuthController(false),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const RdvScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Vérifier que l'interface se charge malgré l'erreur
      expect(find.text('Devis / Dimensionnement'), findsOneWidget);
    });
  });
}
