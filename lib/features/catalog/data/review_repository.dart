import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/product_review.dart';

class ReviewRepository {
  ReviewRepository(this._dio);
  final Dio _dio;

  Future<List<ProductReview>> getReviews(int productId) async {
    try {
      final response = await _dio.get(
        '/api/mobile/products/$productId/reviews',
      );
      final list = response.data as List<dynamic>? ?? const [];
      return list
          .map((e) => ProductReview.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Le backend peut ne pas avoir cet endpoint : retour silencieux
      debugPrint('ℹ️ Avis non disponibles pour le produit $productId : $e');
      return [];
    }
  }

  Future<void> submitReview(
    int productId,
    int rating,
    String comment,
  ) async {
    try {
      await _dio.post(
        '/api/mobile/products/$productId/reviews',
        data: {'rating': rating, 'comment': comment},
      );
    } catch (e) {
      debugPrint('❌ Erreur envoi avis produit $productId : $e');
    }
  }
}

final reviewRepositoryProvider = FutureProvider<ReviewRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return ReviewRepository(dio);
});

// Riverpod 3 : AsyncNotifierProvider.family — le constructeur reçoit l'argument
class ReviewsNotifier extends AsyncNotifier<List<ProductReview>> {
  ReviewsNotifier(this.productId);
  final int productId;

  @override
  Future<List<ProductReview>> build() async {
    final repo = await ref.read(reviewRepositoryProvider.future);
    return repo.getReviews(productId);
  }

  Future<void> submitReview(int rating, String comment) async {
    final repo = await ref.read(reviewRepositoryProvider.future);
    await repo.submitReview(productId, rating, comment);
    ref.invalidateSelf();
  }
}

final reviewsProvider = AsyncNotifierProvider.family<
    ReviewsNotifier, List<ProductReview>, int>(
  (productId) => ReviewsNotifier(productId),
);

final averageRatingProvider = Provider.family<double, int>((ref, productId) {
  final reviewsAsync = ref.watch(reviewsProvider(productId));
  return reviewsAsync.when(
    data: (reviews) {
      if (reviews.isEmpty) return 0.0;
      final sum = reviews.fold<int>(0, (acc, r) => acc + r.rating);
      return sum / reviews.length;
    },
    loading: () => 0.0,
    error: (_, _) => 0.0,
  );
});
