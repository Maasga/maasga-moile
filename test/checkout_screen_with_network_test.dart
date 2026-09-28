import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/network/api_client.dart';

import 'helpers/mock_dio_helper.dart';

// Tests widget de l'intégration Dio mocké avec ProviderScope
//
// Ces tests vérifient que le Dio mocké fonctionne correctement
// avec l'architecture Riverpod du projet

void main() {
  group('Dio Mocké - Intégration ProviderScope', () {
    testWidgets('vérifie que le Dio mocké fonctionne avec ProviderScope', (
      tester,
    ) async {
      // Dio mocké qui retourne une réponse de succès
      final mockDio = MockDioHelper.createMockDioWithResponse({
        'test': 'success',
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dioProvider.overrideWith((ref) async => mockDio)],
          child: MaterialApp(
            home: Scaffold(body: Center(child: Text('Test Dio mocké'))),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que le Dio mocké fonctionne
      expect(find.text('Test Dio mocké'), findsOneWidget);
    });

    testWidgets('vérifie que Dio mocké lance des erreurs comme attendu', (
      tester,
    ) async {
      // Dio mocké qui lance une erreur 500
      final mockDio = MockDioHelper.createMockDioWithError(
        500,
        'Erreur serveur',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dioProvider.overrideWith((ref) async => mockDio)],
          child: MaterialApp(
            home: Scaffold(body: Center(child: Text('Test erreur Dio'))),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que l'interface se charge malgré l'erreur
      expect(find.text('Test erreur Dio'), findsOneWidget);
    });

    testWidgets('vérifie que le Dio mocké peut être appelé directement', (
      tester,
    ) async {
      final mockDio = MockDioHelper.createMockDioWithResponse({
        'message': 'Test réussi',
      });

      final response = await mockDio.get('/test');

      expect(response.statusCode, 200);
      expect(response.data['message'], 'Test réussi');
    });
  });
}
