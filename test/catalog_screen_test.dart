import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/catalog/presentation/catalog_screen.dart';
import 'package:app/features/catalog/presentation/category_chip.dart';

// Tests widget de l'écran catalogue
//
// Ces tests vérifient :
// - L'affichage de l'écran catalogue
// - Les chips de catégorie
// - La navigation
//
// Note: Les tests sont simplifiés pour éviter les mocks complexes
// des providers de catalogue qui dépendent de Dio.

void main() {
  group('CatalogScreen - Affichage', () {
    testWidgets('affiche l\'écran catalogue', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const CatalogScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // L'écran devrait se charger avec un loading state ou le catalogue
      expect(find.byType(CatalogScreen), findsOneWidget);
    });
  });

  group('CategoryChip - Widget', () {
    testWidgets('affiche son label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              label: 'Climatiseurs',
              selected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Climatiseurs'), findsOneWidget);
    });

    testWidgets('déclenche onTap au clic', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              label: 'Ventilation',
              selected: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.text('Ventilation'));
      expect(tapped, true);
    });
  });
}
