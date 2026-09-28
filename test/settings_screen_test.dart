import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/settings/presentation/settings_screen.dart';

// Tests widget de l'écran réglages
//
// Ces tests vérifient :
// - L'affichage de l'écran réglages
//
// Note: Les tests sont simplifiés pour éviter les mocks complexes
// des providers de settings.

void main() {
  group('SettingsScreen - Affichage', () {
    testWidgets('affiche l\'écran réglages', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // L'écran devrait se charger
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
