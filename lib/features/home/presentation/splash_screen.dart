import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FlutterSplashScreen.fadeIn(
      duration: const Duration(milliseconds: 3000),
      backgroundColor: Colors.white,
      onAnimationEnd: () async {
        // Passe par le contrôleur (et non le dépôt directement) : il absorbe
        // déjà les erreurs de session et reste surchargeable en test.
        bool isLoggedIn = false;
        try {
          isLoggedIn = await ref.read(authControllerProvider.future);
        } catch (_) {
          isLoggedIn = false;
        }

        if (context.mounted) {
          context.go(isLoggedIn ? '/home' : '/onboarding');
        }
      },
      childWidget: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 180, child: Image.asset('assets/logo_maasga.png')),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B3A8D)),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
