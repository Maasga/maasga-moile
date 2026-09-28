import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/auth/presentation/login_screen.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';

// Tests widget des écrans d'authentification
//
// Ces tests vérifient :
// - L'écran login
// - Les champs de formulaire
// - Les boutons et navigation
//
// Note: Les tests sont simplifiés pour éviter les problèmes de timers
// avec flutter_animate. Les tests couvrent l'UI de base.

class TestAuthController extends AuthController {
  TestAuthController(this.isLoggedIn);

  final bool isLoggedIn;

  @override
  Future<bool> build() async => isLoggedIn;
}

void main() {
  group('LoginScreen - Affichage', () {
    testWidgets('affiche le titre Connexion', (tester) async {
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
                  builder: (context, state) => const LoginScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Connexion'), findsOneWidget);
    });

    testWidgets('affiche les champs de formulaire', (tester) async {
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
                  builder: (context, state) => const LoginScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Email ou téléphone'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
    });

    testWidgets('affiche le bouton Se connecter', (tester) async {
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
                  builder: (context, state) => const LoginScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('affiche le lien Mot de passe oublié', (tester) async {
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
                  builder: (context, state) => const LoginScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    });

    testWidgets('affiche le lien Créer un compte', (tester) async {
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
                  builder: (context, state) => const LoginScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Pas encore de compte ? Créer un compte'),
        findsOneWidget,
      );
    });
  });

  group('LoginScreen - Interactions', () {
    testWidgets('affiche l\'icône de visibilité du mot de passe', (
      tester,
    ) async {
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
                  builder: (context, state) => const LoginScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
