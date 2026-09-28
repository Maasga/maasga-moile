import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de suivi des activités (notifications) lues.
///
/// Ce service permet de suivre quelles activités (notifications) ont été consultées
/// par l'utilisateur afin d'afficher correctement le compteur de notifications non lues.
class ActivityReadTrackerService {
  static const _keyPrefix = 'maasga_activity_read_';

  final SharedPreferences _prefs;

  ActivityReadTrackerService(this._prefs);

  /// Marque une activité comme lue.
  Future<void> markAsRead(int activityId) async {
    await _prefs.setBool('$_keyPrefix$activityId', true);
  }

  /// Vérifie si une activité a été marquée comme lue.
  Future<bool> isRead(int activityId) async {
    return _prefs.getBool('$_keyPrefix$activityId') ?? false;
  }

  /// Marque toutes les activités comme lues.
  Future<void> markAllAsRead(List<int> activityIds) async {
    for (final id in activityIds) {
      await markAsRead(id);
    }
  }

  /// Efface tout le suivi de lecture (utile pour le débogage ou les tests).
  Future<void> clear() async {
    final keys = _prefs.getKeys();
    final toRemove = keys.where((key) => key.startsWith(_keyPrefix));
    for (final key in toRemove) {
      await _prefs.remove(key);
    }
  }

  /// Retourne le nombre d'activités non lues parmi la liste fournie.
  Future<int> countUnread(List<int> activityIds) async {
    int unreadCount = 0;
    for (final id in activityIds) {
      if (!(await isRead(id))) {
        unreadCount++;
      }
    }
    return unreadCount;
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────

final activityReadTrackerServiceProvider =
    FutureProvider<ActivityReadTrackerService>((ref) async {
      final prefs = await SharedPreferences.getInstance();
      return ActivityReadTrackerService(prefs);
    });

/// Provider synchrone pour les écrans qui utilisent initState
final activityReadTrackerProvider = Provider<ActivityReadTrackerService?>((
  ref,
) {
  final async = ref.watch(activityReadTrackerServiceProvider);
  return async.when(
    data: (service) => service,
    loading: () => null,
    error: (_, _) => null,
  );
});
