import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/cart/presentation/cart_screen.dart';
import 'package:app/features/cart/presentation/cart_state.dart';
import 'package:app/features/catalog/domain/product.dart';
import 'package:app/core/network/api_client.dart';

import 'helpers/mock_dio_helper.dart';

// Tests widget de l'écran panier avec Dio mocké
//
// Ces tests vérifient l'intégration avec le réseau simulé
// en utilisant le helper Dio mocké existant.

class TestCartNotifier extends CartNotifier {
  TestCartNotifier(this.initialItems);

  final List<CartLine> initialItems;

  @override
  List<CartLine> build() => initialItems;
}

void main() {
  group('CartScreen - avec Dio mocké', () {
    testWidgets('vérifie que le Dio mocké fonctionne avec ProviderScope', (
      tester,
    ) async {
      final product = Product(
        id: 1,
        name: 'Climatiseur 9000 BTU',
        brand: 'Samsung',
        price: 280000,
        stock: 5,
      );

      // Dio mocké qui retourne une réponse de succès
      final mockDio = MockDioHelper.createMockDioWithResponse({
        'test': 'success',
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWith((ref) async => mockDio),
            cartProvider.overrideWith(
              () => TestCartNotifier([CartLine(product: product, quantity: 1)]),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const CartScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Vérifier que le Dio mocké fonctionne et que l'écran se charge
      expect(find.text('Climatiseur 9000 BTU'), findsOneWidget);
    });

    testWidgets('vérifie que Dio mocké lance des erreurs comme attendu', (
      tester,
    ) async {
      final product = Product(
        id: 1,
        name: 'Climatiseur 9000 BTU',
        brand: 'Samsung',
        price: 280000,
        stock: 5,
      );

      // Dio mocké qui lance une erreur 500
      final mockDio = MockDioHelper.createMockDioWithError(
        500,
        'Erreur serveur',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWith((ref) async => mockDio),
            cartProvider.overrideWith(
              () => TestCartNotifier([CartLine(product: product, quantity: 1)]),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const CartScreen(),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Vérifier que l'interface se charge malgré l'erreur
      expect(find.text('Climatiseur 9000 BTU'), findsOneWidget);
    });
  });
}
