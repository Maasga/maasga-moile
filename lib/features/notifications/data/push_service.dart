import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_router.dart';

/// Handler de fond — doit être une fonction top-level (pas une méthode).
///
/// Enregistré depuis `main()` AVANT `runApp`, seul moment où Firebase peut
/// rattacher l'isolate de fond. L'enregistrer depuis [PushService.initialize]
/// (après connexion) était trop tard : les messages reçus app fermée étaient
/// perdus.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('Push background: ${message.notification?.title}');
  }
}

/// Gestionnaire Firebase Cloud Messaging + notifications locales.
///
/// - Demande les permissions et enregistre le token FCM côté serveur
/// - Affiche une bannière in-app pour les notifications foreground
/// - Navigue vers `message.data['route']` à l'ouverture d'une notification
class PushService {
  PushService(this._ref);

  final Ref _ref;

  String? _lastToken;
  Dio? _dio;

  /// Garde d'idempotence : [initialize] est appelé à chaque connexion, mais les
  /// listeners FCM ne doivent être attachés qu'une fois. Sans cela, chaque
  /// nouvelle connexion dans la même session ajoutait un listener
  /// `onMessage` supplémentaire → notifications affichées en double, triple…
  bool _listenersAttached = false;
  bool _initialMessageHandled = false;

  static final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'maasga_default',
    'Notifications MAASGA',
    description: 'Commandes, rendez-vous et actualités MAASGA',
    importance: Importance.high,
    playSound: true,
  );

  /// Destinations autorisées depuis un payload push.
  ///
  /// Le `route` d'une notification vient du serveur : on ne l'injecte pas
  /// aveuglément dans le router. Les routes qui exigent un `extra` typé
  /// (ex. `/catalog/product` attend un `Product`) sont exclues — y aller sans
  /// argument lèverait un cast et crasherait l'app.
  static const Set<String> _allowedRoutes = {
    '/home',
    '/catalogue',
    '/catalog',
    '/rendez-vous',
    '/rdv',
    '/espace-client',
    '/client-space',
    '/simulator',
    '/cart',
    '/notifications',
    '/support',
    '/settings',
    '/search',
    '/maintenance',
  };

  /// Initialise FCM + notifications locales.
  ///
  /// Idempotent : réappeler cette méthode après une nouvelle connexion
  /// réenregistre le token pour le compte courant sans dupliquer les listeners.
  Future<void> initialize({required Dio dio}) async {
    _dio = dio;

    if (!_listenersAttached) {
      await _setupLocalNotifications();
      await _requestPermission();
      _attachListeners();
      _listenersAttached = true;
    }

    // Toujours (re)pousser le token : après un changement de compte, le serveur
    // doit réassocier cet appareil au nouvel utilisateur.
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerToken(dio, token);
      _lastToken = token;
    }

    await _handleInitialMessage();
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifs.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        _navigate(details.payload);
      },
    );

    final android = _localNotifs
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channel);
  }

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      debugPrint('Permissions FCM: ${settings.authorizationStatus}');
    }
  }

  void _attachListeners() {
    final messaging = FirebaseMessaging.instance;

    // Renouvellement automatique du token
    messaging.onTokenRefresh.listen((newToken) async {
      final dio = _dio;
      if (dio == null || newToken == _lastToken) return;
      await _registerToken(dio, newToken);
      _lastToken = newToken;
    });

    // Notification reçue en foreground → afficher une bannière locale
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif == null) return;
      _showLocalNotification(
        title: notif.title ?? 'MAASGA',
        body: notif.body ?? '',
        payload: message.data['route']?.toString(),
      );
    });

    // L'app est ouverte depuis une notification en arrière-plan
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigate(message.data['route']?.toString());
    });
  }

  /// Traite la notification qui a démarré l'app à froid (process terminé).
  Future<void> _handleInitialMessage() async {
    if (_initialMessageHandled) return;
    _initialMessageHandled = true;
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial == null) return;
    _navigate(initial.data['route']?.toString());
  }

  /// Navigue vers une route issue d'un payload push, si elle est autorisée.
  void _navigate(String? route) {
    if (route == null || route.isEmpty) return;
    if (!_allowedRoutes.contains(route)) {
      if (kDebugMode) debugPrint('Route push refusée: $route');
      return;
    }
    try {
      _ref.read(appRouterProvider).go(route);
    } catch (e) {
      if (kDebugMode) debugPrint('Navigation push impossible: $e');
    }
  }

  /// Affiche une notification locale immédiate.
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifs.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Envoie une notification locale de test (utile en développement).
  Future<void> showTestNotification() async {
    await _showLocalNotification(
      title: 'MAASGA',
      body: 'Les notifications fonctionnent correctement ✓',
      payload: '/home',
    );
  }

  /// Invalide le token FCM côté serveur (appeler lors du logout).
  Future<void> unregisterToken({required Dio dio}) async {
    if (_lastToken == null) return;
    try {
      await dio.delete('/api/client/push-token', data: {'token': _lastToken});
    } catch (_) {
    } finally {
      _lastToken = null;
    }
  }

  Future<void> _registerToken(Dio dio, String token) async {
    try {
      await dio.post(
        '/api/client/push-token',
        data: {'token': token, 'platform': 'android', 'appVersion': '1.0.0'},
      );
      if (kDebugMode) debugPrint('FCM token enregistré');
    } catch (_) {}
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));
