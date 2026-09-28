import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session_providers.dart';
import '../../../shared/services/activity_read_tracker_service.dart';

class UserActivity {
  UserActivity({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    this.notes,
    this.totalPrice,
    this.read = false,
  });

  final int id;
  final String type; // 'rdv' or 'order'
  final String status;
  final String createdAt;
  final String? notes;
  final int? totalPrice;
  final bool read; // Whether this activity has been read by the user

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['_type'] as String? ?? 'rdv',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String? ?? '',
      notes: json['notes'] as String?,
      totalPrice: (json['total_price'] as num?)?.toInt(),
      read: false, // Default to unread; will be updated based on local storage
    );
  }
}

class ActivityRepository {
  ActivityRepository(this._dio, this._readTrackerService);
  final Dio _dio;
  final ActivityReadTrackerService _readTrackerService;

  Future<List<UserActivity>> fetchActivity() async {
    try {
      final response = await _dio.get('/api/mobile/activity');
      final list = response.data as List<dynamic>? ?? [];
      final activities = list.map((e) => UserActivity.fromJson(e)).toList();

      // Create a new list with correct read status
      final updatedActivities = <UserActivity>[];
      for (final activity in activities) {
        final isRead = await _readTrackerService.isRead(activity.id);
        updatedActivities.add(
          UserActivity(
            id: activity.id,
            type: activity.type,
            status: activity.status,
            createdAt: activity.createdAt,
            notes: activity.notes,
            totalPrice: activity.totalPrice,
            read: isRead,
          ),
        );
      }

      return updatedActivities;
    } catch (e) {
      return [];
    }
  }
}

final activityRepositoryProvider = FutureProvider<ActivityRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  final readTrackerService = await ref.watch(
    activityReadTrackerServiceProvider.future,
  );
  return ActivityRepository(dio, readTrackerService);
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
final unreadNotificationCountProvider = Provider<int>((ref) {
  final asyncActivities = ref.watch(userActivityProvider);

  // Retourne 0 tant que les données ne sont pas chargées
  final activities = asyncActivities.value ?? [];
  return activities.where((activity) => !activity.read).length;
});
