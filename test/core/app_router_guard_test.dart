import 'package:app/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Construit l'app sur le vrai router (sans Firebase : `_currentUser()`
/// renvoie null, donc l'utilisateur est considéré déconnecté).
Future<GoRouter> _pumpRouter(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final router = container.read(appRouterProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  return router;
}

Uri _location(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri;

/// Laisse expirer les minuteurs (splash 3 s, animations) avant le démontage.
Future<void> _flushTimers(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
}

void main() {
  group('Garde du router (utilisateur déconnecté)', () {
    for (final route in ['/settings', '/checkout', '/notifications']) {
      testWidgets('$route redirige vers /auth/login?from=$route', (
        tester,
      ) async {
        final router = await _pumpRouter(tester);
        router.go(route);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        final uri = _location(router);
        expect(uri.path, '/auth/login');
        expect(uri.queryParameters['from'], route);
        await _flushTimers(tester);
      });
    }

    testWidgets('/catalog/product sans Product redirige vers /catalog', (
      tester,
    ) async {
      final router = await _pumpRouter(tester);
      router.go('/catalog/product');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(_location(router).path, '/catalog');
      await _flushTimers(tester);
    });
  });
}
