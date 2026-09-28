import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/client_space/presentation/client_space_screen.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';

// Tests widget de l'écran espace client
//
// Ces tests vérifient :
// - L'affichage non connecté
// - L'affichage connecté avec loading
//
// Note: Les tests sont simplifiés pour éviter les mocks complexes
// du dashboard client qui dépendent de Dio et Firebase.

class TestAuthController extends AuthController {
  TestAuthController(this.isLoggedIn);

  final bool isLoggedIn;

  @override
  Future<bool> build() async => isLoggedIn;
}

void main() {
  group('ClientSpaceScreen - Non connecté', () {
    testWidgets('affiche le message de connexion', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

      expect(
        find.text('Connectez-vous pour accéder à votre espace'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });
  });

  group('ClientSpaceScreen - Connecté', () {
    testWidgets('affiche le loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => TestAuthController(true)),
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

      // Affiche le loading state car le dashboard n'est pas mocké
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
