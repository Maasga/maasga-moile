import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session_providers.dart';

class UserActivity {
  UserActivity({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    this.notes,
    this.totalPrice,
  });

  final int id;
  final String type; // 'rdv' or 'order'
  final String status;
  final String createdAt;
  final String? notes;
  final int? totalPrice;

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['_type'] as String? ?? 'rdv',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String? ?? '',
      notes: json['notes'] as String?,
      totalPrice: (json['total_price'] as num?)?.toInt(),
    );
  }
}

class ActivityRepository {
  ActivityRepository(this._dio);
  final Dio _dio;

  Future<List<UserActivity>> fetchActivity() async {
    try {
      final response = await _dio.get('/api/mobile/activity');
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) => UserActivity.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}

final activityRepositoryProvider = FutureProvider<ActivityRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  return ActivityRepository(dio);
});

/// Activité (commandes + rendez-vous) du compte connecté.
///
/// Voir `clientDashboardProvider` : le `watch` de l'UID est ce qui empêche
/// l'activité d'un compte de rester affichée après un changement d'utilisateur.
final userActivityProvider = FutureProvider<List<UserActivity>>((ref) async {
  ref.watch(currentUserIdProvider);
  final repo = await ref.watch(activityRepositoryProvider.future);
  return repo.fetchActivity();
});

/// Nombre d'activités non lues (notifications).
///
/// NOTE: Pour l'instant, nous considérons toutes les activités comme non lues.
/// Une amélioration future pourrait filtrer par un statut "lu" si l'API le fournit.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final asyncActivities = ref.watch(userActivityProvider);

  // Retourne 0 tant que les données ne sont pas chargées
  return asyncActivities.when(
    data: (activities) => activities.length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});
