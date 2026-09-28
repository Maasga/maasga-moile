import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/support/presentation/support_screen.dart';

// Tests widget de l'écran support
//
// Ces tests vérifient :
// - L'affichage de l'écran support
//
// Note: Les tests sont simplifiés pour éviter les mocks complexes
// des providers de support.

void main() {
  group('SupportScreen - Affichage', () {
    testWidgets('affiche l\'écran support', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const SupportScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // L'écran devrait se charger
      expect(find.byType(SupportScreen), findsOneWidget);
    });
  });
}
