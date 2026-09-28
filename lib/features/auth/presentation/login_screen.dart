import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_tokens/maasga_tokens.dart';
import '../../../shared/widgets/maasga_primary_button.dart';
import 'auth_controller.dart';
import 'google_auth_btn.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _sendingReset = false;
  String? _error;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Envoie le lien de réinitialisation sur l'identifiant déjà saisi.
  Future<void> _onForgotPassword() async {
    setState(() {
      _error = null;
      _sendingReset = true;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendPasswordReset(_identifierCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Si ce compte existe, un lien de réinitialisation vient de partir '
            'par e-mail.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Le message du dépôt est déjà rédigé pour l'utilisateur (cas du compte
      // téléphone sans e-mail notamment) : on l'affiche tel quel.
      setState(() => _error = '$e'.replaceFirst(RegExp(r'^Exception:\s*'), ''));
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  String _friendlyError(Object? error) {
    final msg = '$error'.toLowerCase();
    if (msg.contains('identifiants incorrects') ||
        msg.contains('invalid-credential') ||
        msg.contains('user-not-found')) {
      return 'Email/téléphone ou mot de passe incorrect.';
    }
    if (msg.contains('too-many-requests') ||
        msg.contains('trop de tentatives')) {
      return 'Trop de tentatives. Réessaie dans quelques minutes.';
    }
    if (msg.contains('connexion internet') ||
        msg.contains('network-request-failed')) {
      return 'Connexion internet indisponible. Vérifie ton réseau.';
    }
    if (msg.contains('désactivé') || msg.contains('user-disabled')) {
      return 'Ce compte a été désactivé. Contacte le support.';
    }
    return 'Connexion impossible pour le moment. Réessaie plus tard.';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    // Destination mémorisée par le garde du router (ex. /checkout) : on y
    // renvoie l'utilisateur juste après connexion plutôt que sur /home.
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    final target = (from != null && from.startsWith('/')) ? from : '/home';

    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError) {
        setState(() => _error = _friendlyError(next.error));
      } else if (next.value == true) {
        context.go(target);
      }
    });

    final palette = context.maasga;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: palette.pageGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Card(
                  elevation: 0,
                  color: palette.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MaasgaTokens.radiusLg),
                    side: BorderSide(color: palette.cardBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        // Logo
                        Image.asset(
                          'assets/logo_maasga.png',
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Connexion',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Accédez à votre espace MAASGA',
                          style: TextStyle(
                            fontSize: 14,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Identifiant
                        TextField(
                          controller: _identifierCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: palette.inputTextStyle,
                          decoration: InputDecoration(
                            labelText: 'Email ou téléphone',
                            labelStyle: TextStyle(color: palette.textSecondary),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: palette.accent,
                            ),
                            filled: true,
                            fillColor: palette.cardAlt,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Mot de passe
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          style: palette.inputTextStyle,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            labelStyle: TextStyle(color: palette.textSecondary),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: palette.accent,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: palette.textSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            filled: true,
                            fillColor: palette.cardAlt,
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: palette.dangerSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: palette.danger.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: palette.danger,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: palette.danger,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: MaasgaPrimaryButton(
                            label: auth.isLoading
                                ? 'Connexion...'
                                : 'Se connecter',
                            enabled: !auth.isLoading,
                            onPressed: () {
                              setState(() => _error = null);
                              final id = _identifierCtrl.text.trim();
                              final pass = _passwordCtrl.text;
                              if (id.isEmpty || pass.isEmpty) {
                                setState(
                                  () => _error =
                                      'Veuillez saisir vos identifiants.',
                                );
                                return;
                              }
                              ref
                                  .read(authControllerProvider.notifier)
                                  .login(identifier: id, password: pass);
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _sendingReset ? null : _onForgotPassword,
                          child: Text(
                            _sendingReset
                                ? 'Envoi en cours...'
                                : 'Mot de passe oublié ?',
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/auth/register'),
                          child: const Text(
                            'Pas encore de compte ? Créer un compte',
                          ),
                        ),
                        const SizedBox(height: 8),
                        buildGoogleSignInButton(
                          onError: (e) => setState(() => _error = e),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
