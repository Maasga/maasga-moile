import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/product.dart';

const _kRecentProductsKey = 'maasga_recent_products';

class RecentProductsNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRecentProductsKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        state = decoded
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> addRecent(Product product) async {
    final updated = [
      product,
      ...state.where((p) => p.id != product.id),
    ].take(5).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kRecentProductsKey,
      jsonEncode(updated.map(_productToJson).toList()),
    );
  }

  Map<String, dynamic> _productToJson(Product p) {
    return {
      'id': p.id,
      'name': p.name,
      'brand': p.brand,
      'price': p.price,
      'stock': p.stock,
      'category': p.category,
      'power': p.power,
      'specs': p.specs,
      'image': p.image,
      'imageUrl': p.imageUrl,
      'btu': p.btu,
      'images': p.images,
      'old_price': p.oldPrice,
      'description': p.description,
      'techSpecs': p.technicalSpecs,
    };
  }
}

final recentProductsProvider =
    NotifierProvider<RecentProductsNotifier, List<Product>>(
  RecentProductsNotifier.new,
);
