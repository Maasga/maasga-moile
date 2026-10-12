import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kFavoritesKey = 'maasga_favorites';

class FavoritesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    // Démarrer avec un Set vide et charger en async
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFavoritesKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        state = decoded.map((e) => (e as num).toInt()).toSet();
      } catch (_) {
        state = {};
      }
    }
  }

  Future<void> toggle(int productId) async {
    final newSet = Set<int>.from(state);
    if (newSet.contains(productId)) {
      newSet.remove(productId);
    } else {
      newSet.add(productId);
    }
    state = newSet;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFavoritesKey, jsonEncode(newSet.toList()));
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<int>>(FavoritesNotifier.new);
