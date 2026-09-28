import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/config/firebase_options.dart';
import 'core/logging/logger_service.dart';
// import 'core/monitoring/sentry_service.dart'; // Temporairement désactivé
import 'features/notifications/data/push_service.dart';
import 'services/review_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le service de logging
  final logger = LoggerService();
  logger.info('Démarrage de l\'application MAASGA Mobile');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialiser Firebase Analytics
  final analytics = FirebaseAnalytics.instance;
  await analytics.setAnalyticsCollectionEnabled(true);
  logger.info('Firebase Analytics initialisé');

  // Doit être enregistré avant runApp, sur l'isolate principal : c'est le seul
  // moment où Firebase peut brancher l'isolate de fond. Sinon les pushs reçus
  // app fermée ne déclenchent aucun code Dart.
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Initialiser le service de demandes d'avis
  final reviewService = ReviewService();
  await reviewService.initialize();
  logger.info('Service de demandes d\'avis initialisé');

  // Initialiser Sentry (seulement en mode release) - Temporairement désactivé
  // final sentryService = SentryService();
  // await sentryService.initialize();
  // logger.info('Service Sentry initialisé');

  await initializeDateFormatting('fr_FR', null);

  runApp(const ProviderScope(child: MaasgaMobileApp()));
}
