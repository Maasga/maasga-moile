import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/catalog/domain/product.dart';
import 'package:app/features/catalog/presentation/product_list_card.dart';
import 'package:app/features/catalog/data/review_repository.dart';
import 'package:app/features/catalog/presentation/favorites_notifier.dart';

class _FakeFavoritesNotifier extends FavoritesNotifier {
  @override
  Set<int> build() => {};
}

void main() {
  late Product fakeProduct;

  setUp(() {
    fakeProduct = Product(
      id: 42,
      name: 'Climatiseur Test',
      brand: 'TestBrand',
      price: 150000,
      stock: 3,
      category: 'Mural/Split',
      image: 'assets/products/product_placeholder.png',
      specs: ['12000 BTU', 'Inverter'],
    );
  });

  testWidgets('ProductListCard affiche InkWell et prix FCFA', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoritesProvider.overrideWith(() => _FakeFavoritesNotifier()),
          averageRatingProvider(fakeProduct.id).overrideWith((ref) => 0.0),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProductListCard(
              product: fakeProduct,
              onTap: () => tapped = true,
              onAddToCart: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(InkWell), findsAtLeastNWidgets(1));
    await tester.tap(find.byType(InkWell).first);
    expect(tapped, isTrue);
    expect(find.textContaining('FCFA'), findsAtLeastNWidgets(1));
  });
}
