import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/cart/presentation/cart_state.dart';
import 'package:app/features/catalog/domain/product.dart';

void main() {
  group('CartNotifier', () {
    test('should start with empty cart', () {
      final container = ProviderContainer();
      final cart = container.read(cartProvider);
      expect(cart, isEmpty);
    });

    test('should add product to cart', () {
      final container = ProviderContainer();
      final product = Product(
        id: 1,
        name: 'Climatiseur 12000 BTU',
        brand: 'TestBrand',
        price: 250000,
        stock: 10,
      );

      container.read(cartProvider.notifier).add(product);
      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart[0].product.id, 1);
      expect(cart[0].quantity, 1);
    });

    test('should increase quantity when adding same product', () {
      final container = ProviderContainer();
      final product = Product(
        id: 1,
        name: 'Climatiseur 12000 BTU',
        brand: 'TestBrand',
        price: 250000,
        stock: 10,
      );

      // Add product twice
      container.read(cartProvider.notifier).add(product);
      container.read(cartProvider.notifier).add(product);

      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart[0].quantity, 2);
    });

    test('should remove product from cart when quantity reaches zero', () {
      final container = ProviderContainer();
      final product = Product(
        id: 1,
        name: 'Climatiseur 12000 BTU',
        brand: 'TestBrand',
        price: 250000,
        stock: 10,
      );

      // Add product once
      container.read(cartProvider.notifier).add(product);
      // Remove product once
      container.read(cartProvider.notifier).remove(product);

      final cart = container.read(cartProvider);
      expect(cart.isEmpty, true);
    });

    test('should decrease quantity when removing product', () {
      final container = ProviderContainer();
      final product = Product(
        id: 1,
        name: 'Climatiseur 12000 BTU',
        brand: 'TestBrand',
        price: 250000,
        stock: 10,
      );

      // Add product twice
      container.read(cartProvider.notifier).add(product);
      container.read(cartProvider.notifier).add(product);
      // Remove product once
      container.read(cartProvider.notifier).remove(product);

      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart[0].quantity, 1);
    });

    test('should clear cart', () {
      final container = ProviderContainer();
      final product = Product(
        id: 1,
        name: 'Climatiseur 12000 BTU',
        brand: 'TestBrand',
        price: 250000,
        stock: 10,
      );

      // Add product
      container.read(cartProvider.notifier).add(product);
      expect(container.read(cartProvider).isEmpty, false);

      // Clear cart
      container.read(cartProvider.notifier).clear();
      expect(container.read(cartProvider).isEmpty, true);
    });
  });

  group('CartTotalProvider', () {
    test('should calculate total for single product', () {
      final container = ProviderContainer();
      final product = Product(
        id: 1,
        name: 'Climatiseur 12000 BTU',
        brand: 'TestBrand',
        price: 250000,
        stock: 10,
      );

      // Add 2 quantities of product
      container.read(cartProvider.notifier).add(product);
      container.read(cartProvider.notifier).add(product);

      final total = container.read(cartTotalProvider);
      expect(total, 500000); // 2 * 250000
    });

    test('should calculate total for multiple products', () {
      final container = ProviderContainer();
      final product1 = Product(
        id: 1,
        name: 'Climatiseur 12000 BTU',
        brand: 'TestBrand',
        price: 250000,
        stock: 10,
      );
      final product2 = Product(
        id: 2,
        name: 'Ventilateur',
        brand: 'TestBrand2',
        price: 50000,
        stock: 10,
      );

      // Add 2 quantities of product1 and 1 of product2
      container.read(cartProvider.notifier).add(product1);
      container.read(cartProvider.notifier).add(product1);
      container.read(cartProvider.notifier).add(product2);

      final total = container.read(cartTotalProvider);
      expect(total, 550000); // (2 * 250000) + (1 * 50000)
    });

    test('should return zero for empty cart', () {
      final container = ProviderContainer();
      final total = container.read(cartTotalProvider);
      expect(total, 0);
    });
  });
}
