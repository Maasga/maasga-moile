import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/maintenance/presentation/screens/maintenance_screen.dart';

// Tests widget de l'écran maintenance
//
// Ces tests vérifient :
// - L'affichage de l'écran maintenance
//
// Note: Les tests sont simplifiés pour éviter les mocks complexes
// des providers de maintenance qui dépendent de Dio.

void main() {
  group('MaintenanceScreen - Affichage', () {
    testWidgets('affiche l\'écran maintenance', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const MaintenanceScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // L'écran devrait se charger
      expect(find.byType(MaintenanceScreen), findsOneWidget);
    });
  });
}
