import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design_tokens/maasga_tokens.dart';
import 'auth_controller.dart';

/// Bouton Google Sign-In utilisant Firebase Auth directement.
/// Utilisé sur mobile (Android/iOS). La version web est dans google_auth_btn_web.dart.
Widget buildGoogleSignInButton({required void Function(String error) onError}) {
  return _GoogleSignInButton(onError: onError);
}

class _GoogleSignInButton extends ConsumerWidget {
  const _GoogleSignInButton({required this.onError});
  final void Function(String error) onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MaasgaTokens.radiusPill),
        ),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      onPressed: () async {
        try {
          await ref.read(authControllerProvider.notifier).loginWithGoogle();
        } catch (e) {
          onError('Connexion Google impossible : $e');
        }
      },
      icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
      label: const Text(
        'Continuer avec Google',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
