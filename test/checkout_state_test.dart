import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/cart/presentation/cart_state.dart';
import 'package:app/features/catalog/domain/product.dart';

// Tests unitaires du flux checkout côté logique pure :
// - Calcul du total panier (utilisé par le checkout pour afficher le montant)
// - Comportement du panier avec plusieurs produits et quantités variables
// - Vérification que CartLine.total est bien price × quantity
//
// Note : les tests de l'écran checkout lui-même (réseau, géolocalisation, UI)
// nécessitent un environnement Firebase/Dio mocké — ils sont prévus en V2.

void main() {
  group('CartLine - calcul total', () {
    test('total est price × quantity', () {
      final product = Product(
        id: 1,
        name: 'Climatiseur 9000 BTU',
        brand: 'Samsung',
        price: 280000,
        stock: 5,
      );
      final line = CartLine(product: product, quantity: 3);
      expect(line.total, 840000); // 280000 × 3
    });

    test('total pour quantité 1', () {
      final product = Product(
        id: 2,
        name: 'Climatiseur 12000 BTU',
        brand: 'LG',
        price: 340000,
        stock: 3,
      );
      final line = CartLine(product: product, quantity: 1);
      expect(line.total, 340000);
    });

    test('total pour produit gratuit (prix 0)', () {
      final product = Product(
        id: 3,
        name: 'Produit test',
        brand: 'Test',
        price: 0,
        stock: 1,
      );
      final line = CartLine(product: product, quantity: 5);
      expect(line.total, 0);
    });
  });

  group('Checkout — simulation parcours panier complet', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('total panier vide vaut 0', () {
      expect(container.read(cartTotalProvider), 0);
    });

    test('ajout un produit → total correct', () {
      final produit = Product(
        id: 10,
        name: 'Split Inverter 18000 BTU',
        brand: 'LG',
        price: 480000,
        stock: 2,
      );
      container.read(cartProvider.notifier).add(produit);
      expect(container.read(cartTotalProvider), 480000);
    });

    test('ajout 2 produits différents → total somme des lignes', () {
      final p1 = Product(
        id: 10,
        name: 'Split Inverter 18000 BTU',
        brand: 'LG',
        price: 480000,
        stock: 2,
      );
      final p2 = Product(
        id: 11,
        name: 'Split 9000 BTU Non-Inverter',
        brand: 'Midea',
        price: 175000,
        stock: 8,
      );
      container.read(cartProvider.notifier).add(p1);
      container.read(cartProvider.notifier).add(p1); // qté 2
      container.read(cartProvider.notifier).add(p2);
      // Total : (480000 × 2) + (175000 × 1) = 1 135 000
      expect(container.read(cartTotalProvider), 1135000);
    });

    test('réduction quantité → total décroît correctement', () {
      final produit = Product(
        id: 12,
        name: 'Cassette 18000 BTU',
        brand: 'Daikin',
        price: 720000,
        stock: 2,
      );
      container.read(cartProvider.notifier).add(produit);
      container.read(cartProvider.notifier).add(produit);
      container.read(cartProvider.notifier).remove(produit);
      // 1 unité restante
      expect(container.read(cartTotalProvider), 720000);
    });

    test('vider le panier → total retourne à 0', () {
      final produit = Product(
        id: 13,
        name: 'Split Inverter 24000 BTU',
        brand: 'LG',
        price: 650000,
        stock: 1,
      );
      container.read(cartProvider.notifier).add(produit);
      expect(container.read(cartTotalProvider), greaterThan(0));
      container.read(cartProvider.notifier).clear();
      expect(container.read(cartTotalProvider), 0);
    });

    test('produit avec oldPrice : le total utilise price, pas oldPrice', () {
      final produit = Product(
        id: 14,
        name: 'Promo Split 12000 BTU',
        brand: 'Samsung',
        price: 300000,
        stock: 5,
        oldPrice: 380000, // prix barré
      );
      container.read(cartProvider.notifier).add(produit);
      container.read(cartProvider.notifier).add(produit);
      // Le total doit utiliser price (300000), pas oldPrice (380000)
      expect(container.read(cartTotalProvider), 600000);
    });
  });

  group('Checkout — cohérence avec les champs du payload API', () {
    test('CartLine expose product et quantity pour construire items[]', () {
      final produit = Product(
        id: 20,
        name: 'Climatiseur test',
        brand: 'TestBrand',
        price: 200000,
        stock: 3,
        btu: 12000,
      );
      final container = ProviderContainer();
      container.read(cartProvider.notifier).add(produit);
      container.read(cartProvider.notifier).add(produit);

      final lines = container.read(cartProvider);
      expect(lines.length, 1);
      expect(lines[0].product.id, 20);
      expect(lines[0].quantity, 2);
      expect(lines[0].product.price, 200000);

      // Simuler la construction du payload tel que checkout_screen.dart le fait
      final items = lines
          .map(
            (l) => {
              'product_id': l.product.id,
              'quantity': l.quantity,
              'unit_price': l.product.price, // informatif — ignoré côté serveur
            },
          )
          .toList();

      expect(items[0]['product_id'], 20);
      expect(items[0]['quantity'], 2);
      expect(items[0]['unit_price'], 200000);

      container.dispose();
    });
  });
}
