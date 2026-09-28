// import 'package:sentry_flutter/sentry_flutter.dart'; // Temporairement désactivé - problème de compatibilité Kotlin

/// Service de monitoring Sentry pour le crash reporting
/// Configuré uniquement en mode release pour éviter l'impact sur les performances
/// Temporairement désactivé à cause d'un problème de compatibilité Kotlin avec sentry_flutter 8.14.2
class SentryService {
  static final SentryService _instance = SentryService._internal();

  factory SentryService() => _instance;

  SentryService._internal();

  /// Initialise Sentry
  ///
  /// Le DSN doit être configuré via flutter_dotenv ou une variable d'environnement
  /// Pour l'instant, cette méthode ne fait rien en mode debug
  Future<void> initialize() async {
    // TODO: Utiliser kReleaseMode ou flutter_dotenv pour conditionner l'activation
    // Pour l'instant, ne pas initialiser Sentry en dev
    return;
  }

  /// Capture une exception manuellement
  Future<void> captureException(
    dynamic exception, [
    StackTrace? stackTrace,
  ]) async {
    // TODO: Utiliser kReleaseMode ou flutter_dotenv pour conditionner
    // Pour l'instant, ne pas capturer en dev
    return;
  }

  /// Capture un message manuellement
  Future<void> captureMessage(
    String message, {
    dynamic level, // SentryLevel level = SentryLevel.info,
  }) async {
    // TODO: Utiliser kReleaseMode ou flutter_dotenv pour conditionner
    // Pour l'instant, ne pas capturer en dev
    return;
  }

  /// Capture un événement personnalisé
  Future<void> captureEvent(
    dynamic event, // SentryEvent event
  ) async {
    // TODO: Utiliser kReleaseMode ou flutter_dotenv pour conditionner
    // Pour l'instant, ne pas capturer en dev
    return;
  }

  /// Ajoute un contexte personnalisé
  void setContext(String key, dynamic value) {
    // TODO: Utiliser kReleaseMode ou flutter_dotenv pour conditionner
    // Pour l'instant, ne pas définir en dev
    return;
  }

  /// Ajoute des données supplémentaires
  void setExtra(String key, dynamic value) {
    // TODO: Utiliser kReleaseMode ou flutter_dotenv pour conditionner
    // Pour l'instant, ne pas définir en dev
    return;
  }

  /// Ajoute un utilisateur personnalisé
  void setUser(
    dynamic user, // SentryUser user
  ) {
    // TODO: Utiliser kReleaseMode ou flutter_dotenv pour conditionner
    // Pour l'instant, ne pas définir en dev
    return;
  }

  /// Ajoute un tag personnalisé
  void setTag(String key, String value) {
    // TODO: Utiliser kReleaseMode ou flutter_dotenv pour conditionner
    // Pour l'instant, ne pas définir en dev
    return;
  }
}
