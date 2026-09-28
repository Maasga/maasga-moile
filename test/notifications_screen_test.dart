import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/notifications/presentation/notifications_screen.dart';

// Tests widget de l'écran notifications
//
// Ces tests vérifient :
// - L'affichage de l'écran notifications
//
// Note: Les tests sont simplifiés pour éviter les mocks complexes
// des providers de notifications qui dépendent de Dio.

void main() {
  group('NotificationsScreen - Affichage', () {
    testWidgets('affiche l\'écran notifications', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const NotificationsScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // L'écran devrait se charger
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });
  });
}
