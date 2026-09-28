import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session_providers.dart';
import '../../../shared/design_tokens/maasga_tokens.dart';
import '../../../shared/services/user_prefs_service.dart';
import '../../../shared/widgets/maasga_primary_button.dart';
import '../data/auth_repository.dart';
import '../../../app/router/app_router.dart';

/// Drapeau de session : mis à `true` dès que l'utilisateur a validé son
/// numéro WhatsApp dans la session en cours. Court-circuite immédiatement
/// le gate sans attendre un nouveau fetch réseau.
/// Réinitialisé automatiquement si le compte change ou se déconnecte.
class WhatsappGateDismissedNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(currentUserIdProvider);
    return false;
  }

  void dismiss() {
    state = true;
  }
}

final whatsappGateDismissedProvider =
    NotifierProvider<WhatsappGateDismissedNotifier, bool>(
      WhatsappGateDismissedNotifier.new,
    );

/// `true` si le compte Google connecté n'a pas encore de numéro WhatsApp
/// exploitable (ni Firebase, ni SharedPreferences, ni D1).
final whatsappGateRequiredProvider = FutureProvider<bool>((ref) async {
  // Court-circuit session : l'utilisateur vient de soumettre son numéro.
  if (ref.watch(whatsappGateDismissedProvider)) return false;

  ref.watch(currentUserIdProvider);
  User? user;
  try {
    user = FirebaseAuth.instance.currentUser;
  } catch (_) {
    return false;
  }
  if (user == null) return false;
  if (!AuthRepository.isGoogleUser(user)) return false;
  if (AuthRepository.phoneFromFirebaseUser(user) != null) return false;

  // 1. Vérifier si un numéro valide est déjà stocké localement dans les préférences
  try {
    final prefs = await ref.watch(userPrefsServiceProvider.future);
    final localPhone = prefs.savedPhone;
    if (AuthRepository.isValidPhone(localPhone)) return false;
  } catch (_) {}

  // 2. Vérifier le profil D1 backend
  try {
    final dio = await ref.watch(dioProvider.future);
    final profile = await ref
        .watch(authRepositoryProvider)
        .fetchBackendProfile(dio);
    final phone = profile?['phone']?.toString() ?? '';
    if (AuthRepository.isValidPhone(phone)) return false;
  } catch (_) {}
  return true;
});

/// Calque bloquant posé au-dessus de l'app après une connexion Google sans
/// numéro WhatsApp.
///
/// Utilise [showDialog] au lieu d'un Stack dans le builder de MaterialApp :
/// le dialog s'affiche à l'intérieur du Navigator du router, ce qui garantit
/// qu'un Overlay est disponible pour les TextField.
class WhatsappGateHost extends ConsumerStatefulWidget {
  const WhatsappGateHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<WhatsappGateHost> createState() => _WhatsappGateHostState();
}

class _WhatsappGateHostState extends ConsumerState<WhatsappGateHost> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final dismissed = ref.watch(whatsappGateDismissedProvider);
    if (dismissed) {
      return widget.child;
    }

    final requiredAsync = ref.watch(whatsappGateRequiredProvider);
    // On ne tente d'ouvrir le dialog QUE si le FutureProvider a résolu avec succès
    // et vaut true (pas pendant un AsyncLoading où .value retient l'ancienne valeur).
    final required = requiredAsync.asData?.value ?? false;

    if (required && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(whatsappGateDismissedProvider)) {
          _dialogShown = false;
          return;
        }
        showDialog<void>(
          context: rootNavigatorKey.currentContext ?? context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.55),
          builder: (_) => const _WhatsappGateDialog(),
        ).then((_) {
          if (mounted) setState(() => _dialogShown = false);
        });
      });
    }

    return widget.child;
  }
}

class _WhatsappGateDialog extends ConsumerStatefulWidget {
  const _WhatsappGateDialog();

  @override
  ConsumerState<_WhatsappGateDialog> createState() =>
      _WhatsappGateDialogState();
}

class _WhatsappGateDialogState extends ConsumerState<_WhatsappGateDialog> {
  late final TextEditingController _phoneCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    String initial = '';
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final raw = AuthRepository.phoneFromFirebaseUser(user) ?? '';
        if (raw.isNotEmpty) {
          String local = raw;
          if (local.startsWith('+226')) {
            local = local.substring(4);
          } else if (local.startsWith('226')) {
            local = local.substring(3);
          }
          initial = local.trim();
        }
      }
    } catch (_) {}
    _phoneCtrl = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _phoneCtrl.text.trim();
    final phone = raw.startsWith('+') ? raw : '+226$raw';

    if (!AuthRepository.isValidPhone(phone)) {
      setState(() {
        _error =
            'Numéro WhatsApp invalide : 8 chiffres burkinabè '
            '(ex. 70 12 34 56) ou format international +226…';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // 1. Sauvegarde locale persistante immédiate dans les préférences de l'appareil
      try {
        final prefs = await ref.read(userPrefsServiceProvider.future);
        await prefs.save(phone: phone);
      } catch (e) {
        debugPrint('WhatsappGate: erreur sauvegarde locale: $e');
      }

      // 2. Synchronisation backend (non-bloquante : un échec réseau ou 500
      //    ne doit jamais bloquer un utilisateur authentifié).
      try {
        final dio = await ref.read(dioProvider.future);
        final user = FirebaseAuth.instance.currentUser;
        final name = user?.displayName ?? '';

        // Tenter PATCH /api/mobile/profile (mise à jour du profil connecté)
        try {
          await dio.patch(
            '/api/mobile/profile',
            data: {'phone': phone, if (name.isNotEmpty) 'name': name},
          );
        } catch (_) {}

        // Tenter aussi syncProfile (/api/mobile/register)
        final repo = ref.read(authRepositoryProvider);
        await repo.syncProfile(dio: dio, name: name, phone: phone);
      } catch (e) {
        debugPrint('WhatsappGate: sync backend échoué (non bloquant): $e');
      }

      // 3. Débloquer la session locale et invalider le gate
      ref.read(whatsappGateDismissedProvider.notifier).dismiss();
      ref.invalidate(whatsappGateRequiredProvider);

      // 4. Fermer le dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e'.replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;
    final dismissed = ref.watch(whatsappGateDismissedProvider);

    return PopScope(
      canPop: dismissed,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_outlined, size: 40, color: palette.accent),
                  const SizedBox(height: 12),
                  Text(
                    'Numéro WhatsApp obligatoire',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pour te recontacter (livraison, rendez-vous, '
                    'suivi de commande), MAASGA a besoin de ton '
                    'numéro WhatsApp. Cette étape ne peut pas être '
                    'ignorée.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _phoneCtrl,
                    enabled: !_saving,
                    keyboardType: TextInputType.phone,
                    style: palette.inputTextStyle,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saving ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: 'Téléphone WhatsApp *',
                      hintText: '70 00 00 00',
                      prefixText: '+226 ',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: palette.accent,
                      ),
                      filled: true,
                      fillColor: palette.cardAlt,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: palette.dangerSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: palette.danger.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: palette.danger, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: MaasgaPrimaryButton(
                      label: _saving ? 'Enregistrement...' : 'Enregistrer',
                      enabled: !_saving,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
