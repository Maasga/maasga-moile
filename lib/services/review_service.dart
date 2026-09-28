import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logging/logger_service.dart';

/// Service pour demander des avis sur le Play Store
/// Demande automatiquement après un certain nombre de jours d'utilisation
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();

  factory ReviewService() => _instance;

  ReviewService._internal();

  static const _prefKeyDaysInstalled = 'days_installed';
  static const _prefKeyLastRequest = 'last_review_request';
  static const _minDaysBeforeRequest = 7; // 7 jours minimum
  static const _minDaysBetweenRequests = 30; // 30 jours entre demandes

  final InAppReview _inAppReview = InAppReview.instance;
  final LoggerService _logger = LoggerService();

  /// Initialise le compteur de jours installés
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final daysInstalled = prefs.getInt(_prefKeyDaysInstalled) ?? 0;

    // Incrémenter le compteur de jours (une fois par jour)
    final lastDate = prefs.getString('last_date');
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastDate != today) {
      await prefs.setInt(_prefKeyDaysInstalled, daysInstalled + 1);
      await prefs.setString('last_date', today);
    }
  }

  /// Demande un avis si les conditions sont remplies
  Future<void> requestReviewIfEligible() async {
    final prefs = await SharedPreferences.getInstance();

    final daysInstalled = prefs.getInt(_prefKeyDaysInstalled) ?? 0;
    final lastRequest = prefs.getString(_prefKeyLastRequest);

    // Vérifier le nombre minimum de jours
    if (daysInstalled < _minDaysBeforeRequest) {
      return;
    }

    // Vérifier le délai minimum entre demandes
    if (lastRequest != null) {
      final lastRequestDate = DateTime.parse(lastRequest);
      final daysSinceLastRequest = DateTime.now()
          .difference(lastRequestDate)
          .inDays;

      if (daysSinceLastRequest < _minDaysBetweenRequests) {
        return;
      }
    }

    // Demander l'avis
    try {
      final isAvailable = await _inAppReview.isAvailable();

      if (isAvailable) {
        await _inAppReview.requestReview();

        // Enregistrer la date de la demande
        await prefs.setString(
          _prefKeyLastRequest,
          DateTime.now().toIso8601String().split('T')[0],
        );
      }
    } catch (e) {
      // Silencieux si la demande échoue
      _logger.debug('Erreur lors de la demande d\'avis: $e');
    }
  }

  /// Force la demande d'avis (pour les tests ou boutons manuels)
  Future<void> forceRequestReview() async {
    try {
      final isAvailable = await _inAppReview.isAvailable();

      if (isAvailable) {
        await _inAppReview.requestReview();
      }
    } catch (e) {
      _logger.debug('Erreur lors de la demande forcée d\'avis: $e');
    }
  }

  /// Réinitialise les préférences (pour les tests)
  Future<void> resetPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyDaysInstalled);
    await prefs.remove(_prefKeyLastRequest);
    await prefs.remove('last_date');
  }
}
