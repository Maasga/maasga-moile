import 'package:logger/logger.dart';

/// Service de logging structuré pour l'application MAASGA Mobile
/// Utilise le package logger pour des logs hiérarchiques et exportables
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();

  factory LoggerService() => _instance;

  LoggerService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 50,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: _getLogLevel(),
      filter: _getLogFilter(),
    );
  }

  late final Logger _logger;

  /// Niveau de log basé sur le mode build
  Level _getLogLevel() {
    // TODO: utiliser kDebugMode ou flutter_dotenv
    return Level.debug;
  }

  /// Filter pour éviter les logs en production
  ProductionFilter _getLogFilter() {
    // TODO: utiliser kDebugMode ou flutter_dotenv
    return ProductionFilter(isDebug: true);
  }

  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// Filtre de production pour éviter les logs en mode release
class ProductionFilter extends LogFilter {
  final bool isDebug;

  ProductionFilter({required this.isDebug});

  @override
  bool shouldLog(LogEvent event) {
    // En debug, tout logger
    if (isDebug) return true;

    // En release, logger uniquement les erreurs et fatal
    return event.level.index >= Level.error.index;
  }
}
