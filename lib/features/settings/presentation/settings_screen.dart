import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/theme_controller.dart';
import '../../../core/config/env.dart';
import '../../../shared/widgets/maasga_shell.dart';
import '../../notifications/data/push_service.dart';

/// Réglages de l'application.
///
/// Volontairement limité à ce qui existe réellement : l'ancienne version
/// affichait cinq tuiles décoratives, dont une « Sécurité — PIN / biométrie
/// (bientôt) » qui promettait une fonctionnalité absente du code.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);

    return MaasgaShell(
      title: 'Réglages',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsCard(
            icon: Icons.brightness_6_outlined,
            title: 'Thème',
            subtitle: _themeLabel(themeMode),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Clair')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Sombre')),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) =>
                      _setTheme(ref, selection.first),
                ),
              ),
            ),
          ),
          _SettingsCard(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle:
                'Commandes, rendez-vous et actualités. La désactivation se '
                'fait dans les réglages Android.',
            trailing: TextButton(
              onPressed: () => _sendTestNotification(context, ref),
              child: const Text('Tester'),
            ),
          ),
          const _SettingsCard(
            icon: Icons.language_outlined,
            title: 'Langue',
            subtitle: 'Français — seule langue disponible dans cette version.',
          ),
          const _SettingsCard(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: 'MAASGA Mobile ${Env.appVersion}',
          ),
        ],
      ),
    );
  }

  void _setTheme(WidgetRef ref, ThemeMode mode) {
    ref.read(themeControllerProvider.notifier).setTheme(mode);
  }

  static String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Suit le réglage du téléphone';
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
    }
  }

  /// Envoie une notification locale immédiate pour vérifier que le canal
  /// Android et les autorisations sont bien en place.
  Future<void> _sendTestNotification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Messenger capturé avant l'await : après, le `context` peut être démonté.
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(pushServiceProvider).showTestNotification();
      messenger.showSnackBar(
        const SnackBar(content: Text('Notification de test envoyée.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Envoi impossible. Autorisez les notifications MAASGA dans '
            'les réglages Android.',
          ),
        ),
      );
    }
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(child: Icon(icon)),
              title: Text(title),
              subtitle: Text(subtitle),
              trailing: trailing,
            ),
            if (child != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}
