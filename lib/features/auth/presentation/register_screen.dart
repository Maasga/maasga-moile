import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_tokens/maasga_tokens.dart';
import '../../../shared/widgets/maasga_primary_button.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';
import 'google_auth_btn.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _quartierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _quartierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _friendlyError(Object? error) {
    final msg = '$error'.toLowerCase();
    if (msg.contains('existe déjà') || msg.contains('email-already-in-use')) {
      return 'Ce compte existe déjà. Connecte-toi plutôt.';
    }
    if (msg.contains('weak-password') ||
        msg.contains('trop faible') ||
        msg.contains('trop court')) {
      return 'Mot de passe trop court '
          '(${AuthRepository.minPasswordLength} caractères minimum).';
    }
    // Erreurs de validation du dépôt : le message est déjà destiné à
    // l'utilisateur et plus précis que n'importe quel repli générique.
    if (msg.contains('invalide')) {
      return '$error'.replaceFirst(RegExp(r'^Exception:\s*'), '');
    }
    if (msg.contains('connexion internet') ||
        msg.contains('network-request-failed')) {
      return 'Connexion internet indisponible.';
    }
    if (msg.contains('too-many-requests') ||
        msg.contains('trop de tentatives')) {
      return 'Trop de tentatives. Réessaie plus tard.';
    }
    return 'Inscription impossible pour le moment. Réessaie.';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError) {
        setState(() => _error = _friendlyError(next.error));
      } else if (next.value == true) {
        context.go('/home');
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: MaasgaTokens.pageGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MaasgaTokens.radiusLg),
                    side: const BorderSide(color: Color(0xFFE1F1FF)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Logo
                        Image.asset(
                          'assets/logo_maasga.png',
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Créer un compte',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Renseignez vos informations pour démarrer',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF475467),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nom
                        TextField(
                          controller: _nameCtrl,
                          style: MaasgaTokens.inputTextStyle,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nom complet *',
                            labelStyle: TextStyle(
                              color: MaasgaTokens.textSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: MaasgaTokens.blue700,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Téléphone
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: MaasgaTokens.inputTextStyle,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone WhatsApp *',
                            hintText: '70 00 00 00',
                            labelStyle: TextStyle(
                              color: MaasgaTokens.textSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: MaasgaTokens.blue700,
                            ),
                            prefixText: '+226 ',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Email
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: MaasgaTokens.inputTextStyle,
                          decoration: const InputDecoration(
                            labelText: 'Email (optionnel)',
                            labelStyle: TextStyle(
                              color: MaasgaTokens.textSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: MaasgaTokens.blue700,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Quartier
                        TextField(
                          controller: _quartierCtrl,
                          style: MaasgaTokens.inputTextStyle,
                          decoration: const InputDecoration(
                            labelText: 'Quartier *',
                            hintText: 'Ex: Ouaga 2000, Pissy...',
                            labelStyle: TextStyle(
                              color: MaasgaTokens.textSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.location_on_outlined,
                              color: MaasgaTokens.blue700,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Mot de passe
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          style: MaasgaTokens.inputTextStyle,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe *',
                            labelStyle: const TextStyle(
                              color: MaasgaTokens.textSecondary,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: MaasgaTokens.blue700,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: MaasgaTokens.textSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        MaasgaPrimaryButton(
                          label: auth.isLoading
                              ? 'Création...'
                              : 'Créer le compte',
                          enabled: !auth.isLoading,
                          onPressed: () {
                            setState(() => _error = null);
                            final name = _nameCtrl.text.trim();
                            final phone = _phoneCtrl.text.trim();
                            final password = _passwordCtrl.text;
                            final quartier = _quartierCtrl.text.trim();

                            if (name.isEmpty) {
                              setState(
                                () => _error = 'Le nom est obligatoire.',
                              );
                              return;
                            }
                            if (phone.isEmpty) {
                              setState(
                                () => _error = 'Le téléphone est obligatoire.',
                              );
                              return;
                            }
                            if (!AuthRepository.isValidPhone(phone)) {
                              setState(
                                () => _error =
                                    'Numéro invalide : 8 chiffres attendus '
                                    '(ex. 70 12 34 56).',
                              );
                              return;
                            }
                            final email = _emailCtrl.text.trim();
                            if (email.isNotEmpty &&
                                !AuthRepository.isValidEmail(email)) {
                              setState(
                                () => _error =
                                    'Adresse e-mail invalide '
                                    '(ex. nom@exemple.com).',
                              );
                              return;
                            }
                            if (quartier.isEmpty) {
                              setState(
                                () => _error = 'Le quartier est obligatoire.',
                              );
                              return;
                            }
                            if (password.length <
                                AuthRepository.minPasswordLength) {
                              setState(
                                () => _error =
                                    'Mot de passe trop court '
                                    '(${AuthRepository.minPasswordLength} '
                                    'caractères min).',
                              );
                              return;
                            }

                            ref
                                .read(authControllerProvider.notifier)
                                .register(
                                  name: name,
                                  phone: phone,
                                  email: email,
                                  quartier: quartier,
                                  password: password,
                                );
                          },
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Retour connexion'),
                        ),
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
