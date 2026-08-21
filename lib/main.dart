import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/config/firebase_options.dart';
import 'features/notifications/data/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Doit être enregistré avant runApp, sur l'isolate principal : c'est le seul
  // moment où Firebase peut brancher l'isolate de fond. Sinon les pushs reçus
  // app fermée ne déclenchent aucun code Dart.
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  await initializeDateFormatting('fr_FR', null);
  runApp(const ProviderScope(child: MaasgaMobileApp()));
}
