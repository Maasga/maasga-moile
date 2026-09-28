import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app/features/cart/presentation/cart_screen.dart';
import 'package:app/features/cart/presentation/cart_state.dart';
import 'package:app/features/catalog/domain/product.dart';
import 'package:app/features/cart/presentation/cart_item_card.dart';

// Tests widget de l'écran panier
//
// Ces tests vérifient :
// - L'affichage du panier vide
// - L'affichage du panier avec produits
// - Les interactions (incrément, décrément, suppression)
// - Le code promo
// - Le calcul des prix

class TestCartNotifier extends CartNotifier {
  TestCartNotifier(this.initialItems);

  final List<CartLine> initialItems;

  @override
  List<CartLine> build() => initialItems;
}

void main() {
  group('CartScreen - Panier vide', () {
    testWidgets('affiche le message panier vide', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
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

      await tester.pumpAndSettle();

      expect(find.text('Votre panier est vide'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });
  });

  group('CartScreen - Panier avec produits', () {
    testWidgets('affiche les produits dans le panier', (tester) async {
      final product = Product(
        id: 1,
        name: 'Climatiseur 9000 BTU',
        brand: 'Samsung',
        price: 280000,
        stock: 5,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

      await tester.pumpAndSettle();

      expect(find.text('Climatiseur 9000 BTU'), findsOneWidget);
      expect(find.text('Panier'), findsWidgets);
    });

    testWidgets('affiche le bouton Valider la commande', (tester) async {
      final product = Product(
        id: 1,
        name: 'Climatiseur 9000 BTU',
        brand: 'Samsung',
        price: 280000,
        stock: 5,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

      await tester.pumpAndSettle();

      expect(find.text('Valider la commande'), findsOneWidget);
    });
  });

  group('CartItemCard - Widget produit', () {
    testWidgets('affiche le nom du produit', (tester) async {
      final product = Product(
        id: 1,
        name: 'Climatiseur 9000 BTU',
        brand: 'Samsung',
        price: 280000,
        stock: 5,
      );

      final line = CartLine(product: product, quantity: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemCard(
              line: line,
              onIncrement: () {},
              onDecrement: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Climatiseur 9000 BTU'), findsOneWidget);
    });

    testWidgets('affiche la quantité', (tester) async {
      final product = Product(
        id: 1,
        name: 'Climatiseur 9000 BTU',
        brand: 'Samsung',
        price: 280000,
        stock: 5,
      );

      final line = CartLine(product: product, quantity: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemCard(
              line: line,
              onIncrement: () {},
              onDecrement: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('déclenche onIncrement au tap sur +', (tester) async {
      final product = Product(
        id: 1,
        name: 'Climatiseur 9000 BTU',
        brand: 'Samsung',
        price: 280000,
        stock: 5,
      );

      final line = CartLine(product: product, quantity: 1);
      var incrementCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemCard(
              line: line,
              onIncrement: () => incrementCalled = true,
              onDecrement: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      expect(incrementCalled, isTrue);
    });

    testWidgets('déclenche onDecrement au tap sur -', (tester) async {
      final product = Product(
        id: 1,
        name: 'Climatiseur 9000 BTU',
        brand: 'Samsung',
        price: 280000,
        stock: 5,
      );

      final line = CartLine(product: product, quantity: 1);
      var decrementCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemCard(
              line: line,
              onIncrement: () {},
              onDecrement: () => decrementCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.remove));
      expect(decrementCalled, isTrue);
    });
  });

  group('CartScreen - Code promo', () {
    testWidgets('affiche le champ code promo', (tester) async {
      final product = Product(
        id: 1,
        name: 'Climatiseur 9000 BTU',
        brand: 'Samsung',
        price: 280000,
        stock: 5,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

      await tester.pumpAndSettle();

      expect(find.text('Avez-vous un code promo ?'), findsOneWidget);
      expect(find.text('Entrez votre code'), findsOneWidget);
      expect(find.text('Appliquer'), findsOneWidget);
    });
  });

  group('CartScreen - Calcul des prix', () {
    testWidgets('affiche le sous-total correct', (tester) async {
      final product = Product(
        id: 1,
        name: 'Climatiseur 9000 BTU',
        brand: 'Samsung',
        price: 280000,
        stock: 5,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

      await tester.pumpAndSettle();

      expect(find.text('Sous-total'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });
  });
}
