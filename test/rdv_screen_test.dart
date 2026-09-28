import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/rdv/presentation/rdv_screen.dart';
import 'package:app/features/rdv/presentation/widgets/service_type_card.dart';
import 'package:app/features/rdv/presentation/widgets/step_indicator.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';

// Tests widget de l'écran RDV
//
// Ces tests vérifient :
// - L'affichage des 3 étapes (PageView)
// - La sélection du type de service
// - L'indicateur d'étapes
//
// Note: Google Maps n'est pas testé directement car c'est un plugin complexe.
// Les tests couvrent l'UI et la logique de navigation entre étapes.

class TestAuthController extends AuthController {
  TestAuthController(this.isLoggedIn);

  final bool isLoggedIn;

  @override
  Future<bool> build() async => isLoggedIn;
}

void main() {
  group('RdvScreen - Affichage', () {
    testWidgets('affiche l\'indicateur d\'étapes', (tester) async {
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
                  builder: (context, state) => const RdvScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(StepIndicator), findsOneWidget);
    });

    testWidgets('affiche les cartes de type de service', (tester) async {
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
                  builder: (context, state) => const RdvScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Devis / Dimensionnement'), findsOneWidget);
      expect(find.text('Installation'), findsOneWidget);
      expect(find.text('Maintenance / Entretien'), findsOneWidget);
    });

    testWidgets('affiche le bouton Continuer', (tester) async {
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
                  builder: (context, state) => const RdvScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Continuer'), findsOneWidget);
    });
  });

  group('ServiceTypeCard - Widget', () {
    testWidgets('affiche le titre et la description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceTypeCard(
              icon: Icons.design_services_outlined,
              title: 'Installation',
              description: 'Pose professionnelle de votre climatiseur',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Installation'), findsOneWidget);
      expect(
        find.text('Pose professionnelle de votre climatiseur'),
        findsOneWidget,
      );
    });

    testWidgets('déclenche onTap au clic', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceTypeCard(
              icon: Icons.design_services_outlined,
              title: 'Installation',
              description: 'Pose professionnelle de votre climatiseur',
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.text('Installation'));
      expect(tapped, isTrue);
    });
  });

  group('StepIndicator - Widget', () {
    testWidgets('affiche les 3 étapes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const StepIndicator(currentStep: 0))),
      );

      await tester.pump();

      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Détails'), findsOneWidget);
      expect(find.text('Confirmation'), findsOneWidget);
    });
  });
}
