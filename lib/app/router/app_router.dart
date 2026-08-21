import 'dart:async';

import 'package:animations/animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/cart/presentation/checkout_screen.dart';
import '../../features/cart/presentation/order_confirmation_screen.dart';
import '../../features/catalog/presentation/catalog_screen.dart';
import '../../features/catalog/presentation/product_detail_screen.dart';
import '../../features/catalog/domain/product.dart';
import '../../features/client_space/presentation/client_space_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/onboarding_screen.dart';
import '../../features/home/presentation/splash_screen.dart';
import '../../features/home/presentation/search_screen.dart';
import '../../features/home/presentation/address_selection_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/rdv/presentation/rdv_screen.dart';
import '../../features/simulator/presentation/simulator_screen.dart';
import '../../features/support/presentation/support_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/maintenance/presentation/screens/maintenance_screen.dart';

/// Routes qui exigent une session Firebase valide.
///
/// `/espace-client` et `/client-space` sont volontairement absents : l'écran
/// affiche déjà lui-même un état « connectez-vous » avec un bouton, ce qui est
/// une meilleure expérience qu'une redirection sèche.
const Set<String> _protectedRoutes = {
  '/checkout',
  '/order-confirmation',
  '/notifications',
  '/settings',
};

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(_authStateChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (!_protectedRoutes.contains(location)) return null;
      if (_currentUser() != null) return null;
      // Mémorise la destination pour y revenir juste après la connexion.
      return Uri(
        path: '/auth/login',
        queryParameters: {'from': location},
      ).toString();
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            _buildPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _buildPage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/auth/login',
        pageBuilder: (context, state) => _buildPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/auth/register',
        pageBuilder: (context, state) =>
            _buildPage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _buildPage(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/catalogue',
        pageBuilder: (context, state) =>
            _buildPage(state, const CatalogScreen()),
      ),
      GoRoute(
        path: '/rendez-vous',
        pageBuilder: (context, state) => _buildPage(state, const RdvScreen()),
      ),
      GoRoute(
        path: '/espace-client',
        pageBuilder: (context, state) =>
            _buildPage(state, const ClientSpaceScreen()),
      ),
      GoRoute(
        path: '/catalog',
        pageBuilder: (context, state) =>
            _buildPage(state, const CatalogScreen()),
      ),
      GoRoute(
        path: '/catalog/product',
        pageBuilder: (context, state) => _buildPage(
          state,
          ProductDetailScreen(product: state.extra as Product),
        ),
      ),
      GoRoute(
        path: '/simulator',
        pageBuilder: (context, state) =>
            _buildPage(state, const SimulatorScreen()),
      ),
      GoRoute(
        path: '/cart',
        pageBuilder: (context, state) => _buildPage(state, const CartScreen()),
      ),
      GoRoute(
        path: '/checkout',
        pageBuilder: (context, state) =>
            _buildPage(state, const CheckoutScreen()),
      ),
      GoRoute(
        path: '/order-confirmation',
        pageBuilder: (context, state) {
          final args = (state.extra as Map<String, dynamic>?) ?? const {};
          return _buildPage(
            state,
            OrderConfirmationScreen(
              orderId: args['orderId'] as String? ?? '',
              clientName: args['clientName'] as String? ?? '',
              clientPhone: args['clientPhone'] as String? ?? '',
              total: (args['total'] as num?)?.toInt() ?? 0,
            ),
          );
        },
      ),
      GoRoute(
        path: '/rdv',
        pageBuilder: (context, state) => _buildPage(state, const RdvScreen()),
      ),
      GoRoute(
        path: '/client-space',
        pageBuilder: (context, state) =>
            _buildPage(state, const ClientSpaceScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) =>
            _buildPage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/support',
        pageBuilder: (context, state) =>
            _buildPage(state, const SupportScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _buildPage(state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) =>
            _buildPage(state, const SearchScreen()),
      ),
      GoRoute(
        path: '/maintenance',
        pageBuilder: (context, state) =>
            _buildPage(state, const MaintenanceScreen()),
      ),
      GoRoute(
        path: '/address',
        pageBuilder: (context, state) =>
            _buildPage(state, const AddressSelectionScreen()),
      ),
    ],
  );
});

/// Accès défensif à Firebase Auth.
///
/// En production, `Firebase.initializeApp()` a toujours été appelé avant
/// `runApp`. En test widget (aucun binding Firebase), l'accès lèverait et
/// empêcherait toute construction du router : on retombe alors sur « pas de
/// session », ce qui est le comportement voulu.
User? _currentUser() {
  try {
    return FirebaseAuth.instance.currentUser;
  } catch (_) {
    return null;
  }
}

Stream<User?> _authStateChanges() {
  try {
    return FirebaseAuth.instance.authStateChanges();
  } catch (_) {
    return Stream<User?>.empty();
  }
}

/// Fait réévaluer `redirect` par GoRouter à chaque changement d'état Firebase
/// (connexion, déconnexion, révocation du token).
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<User?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

CustomTransitionPage _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.horizontal,
        child: child,
      );
    },
  );
}
