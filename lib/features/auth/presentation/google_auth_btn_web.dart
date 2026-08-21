import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;

import '../../../core/config/env.dart';
import 'auth_controller.dart';

/// Bouton Google Sign-In pour le Web.
///
/// Contrairement au mobile, le flux web est piloté par un évènement : le
/// widget natif rendu par `google_sign_in_web` déclenche
/// `authenticationEvents`. Le widget récupère alors les jetons et ouvre
/// lui-même la session Firebase via [AuthController.loginWithGoogleTokens] —
/// exactement comme le fait le bouton mobile.
class GoogleSignInBtn extends ConsumerStatefulWidget {
  const GoogleSignInBtn({super.key, required this.onError});

  final void Function(String error) onError;

  @override
  ConsumerState<GoogleSignInBtn> createState() => _GoogleSignInBtnState();
}

class _GoogleSignInBtnState extends ConsumerState<GoogleSignInBtn> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _sub;
  static bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initGoogleSignIn();
    _sub = GoogleSignIn.instance.authenticationEvents.listen((event) async {
      if (event is! GoogleSignInAuthenticationEventSignIn) return;
      final account = event.user;
      try {
        final idToken = account.authentication.idToken;

        String? accessToken;
        try {
          final authz = await account.authorizationClient
              .authorizationForScopes(const ['email', 'profile']);
          accessToken = authz?.accessToken;
        } catch (_) {}

        if (idToken == null && accessToken == null) {
          widget.onError('Jetons Google manquants. Réessaie.');
          return;
        }

        await ref
            .read(authControllerProvider.notifier)
            .loginWithGoogleTokens(idToken: idToken, accessToken: accessToken);
      } catch (e) {
        widget.onError('Connexion Google impossible : $e');
      }
    });
  }

  Future<void> _initGoogleSignIn() async {
    if (_initialized) return;
    try {
      await GoogleSignIn.instance.initialize(clientId: Env.googleWebClientId);
      _initialized = true;
    } catch (e) {
      widget.onError('Initialisation Google impossible: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      alignment: Alignment.center,
      child: web_only.renderButton(),
    );
  }
}

Widget buildGoogleSignInButton({required void Function(String error) onError}) {
  return GoogleSignInBtn(onError: onError);
}
