import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/design_tokens/maasga_tokens.dart';
import '../../domain/commande.dart';

/// Bottom sheet affichant le détail complet d'une commande.
class CommandeDetailSheet extends StatelessWidget {
  const CommandeDetailSheet({super.key, required this.commande});

  final Commande commande;

  static Future<void> show(BuildContext context, Commande commande) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommandeDetailSheet(commande: commande),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: palette.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Détail de la commande',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: palette.textMuted),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: palette.divider),

          // Contenu scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statut + ID
                  _StatusBanner(commande: commande, palette: palette),
                  const SizedBox(height: 20),

                  // Produit(s)
                  _SectionTitle('Produit(s)', palette),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.ac_unit_outlined,
                    label: commande.productName,
                    palette: palette,
                    large: true,
                  ),
                  if (commande.produitQuantite != null &&
                      commande.produitQuantite! > 1)
                    _DetailRow(
                      icon: Icons.numbers,
                      label: 'Quantité : ${commande.produitQuantite}',
                      palette: palette,
                    ),
                  const SizedBox(height: 20),

                  // Prix
                  _SectionTitle('Prix', palette),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: commande.price,
                    palette: palette,
                    large: true,
                    color: palette.accent,
                  ),
                  if (commande.installationPrix != null &&
                      commande.installationPrix! > 0)
                    _DetailRow(
                      icon: Icons.build_outlined,
                      label: 'Installation : ${_fmt(commande.installationPrix!)} FCFA',
                      palette: palette,
                    ),
                  const SizedBox(height: 20),

                  // Informations de livraison
                  _SectionTitle('Livraison', palette),
                  const SizedBox(height: 8),
                  if (commande.devisClientQuartier != null &&
                      commande.devisClientQuartier!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: commande.devisClientQuartier!,
                      palette: palette,
                    ),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: _formatDate(commande.date),
                    palette: palette,
                  ),
                  const SizedBox(height: 20),

                  // Référence
                  _SectionTitle('Référence', palette),
                  const SizedBox(height: 8),
                  _CopyableRow(
                    label: '#${commande.id}',
                    palette: palette,
                  ),

                  // Notes (uniquement si utile et pas technique)
                  if (_shouldShowNotes(commande)) ...[
                    const SizedBox(height: 20),
                    _SectionTitle('Notes', palette),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.cardAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _cleanNotes(commande.notes ?? ''),
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowNotes(Commande c) {
    if (c.notes == null || c.notes!.isEmpty) return false;
    final cleaned = _cleanNotes(c.notes!);
    return cleaned.isNotEmpty;
  }

  String _cleanNotes(String notes) {
    // Supprimer le préfixe [Méthode] et la partie "Produits: xxx" déjà affichée
    var result = notes
        .replaceAll(RegExp(r'^\[.*?\]\s*'), '')  // retirer [Téléphone] etc.
        .replaceAll(RegExp(r'Produits:\s*[^|]+(\|\s*[^|]+)*'), '')
        .replaceAll(RegExp(r'\|\s*$'), '')
        .replaceAll(RegExp(r'^\s*\|\s*'), '')
        .trim();
    return result;
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  String _fmt(int val) {
    return val.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }
}

// ─── Widgets helpers ──────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.commande, required this.palette});
  final Commande commande;
  final MaasgaPalette palette;

  Color get _bg {
    switch (commande.status) {
      case CommandeStatus.installed:
        return palette.successSurface;
      case CommandeStatus.paid:
      case CommandeStatus.devisValide:
        return palette.infoSurface;
      case CommandeStatus.livre:
        return palette.successSurface;
      case CommandeStatus.validationTerrain:
      case CommandeStatus.devisEnAttente:
        return palette.warningSurface;
      case CommandeStatus.cancelled:
      case CommandeStatus.devisRefuse:
        return palette.dangerSurface;
      default:
        return palette.cardAlt;
    }
  }

  Color get _fg {
    switch (commande.status) {
      case CommandeStatus.installed:
      case CommandeStatus.livre:
        return palette.success;
      case CommandeStatus.paid:
      case CommandeStatus.devisValide:
        return palette.info;
      case CommandeStatus.validationTerrain:
      case CommandeStatus.devisEnAttente:
        return palette.warning;
      case CommandeStatus.cancelled:
      case CommandeStatus.devisRefuse:
        return palette.danger;
      default:
        return palette.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: _fg),
          const SizedBox(width: 10),
          Text(
            commande.status.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.palette);
  final String title;
  final MaasgaPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: palette.textMuted,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.palette,
    this.large = false,
    this.color,
  });
  final IconData icon;
  final String label;
  final MaasgaPalette palette;
  final bool large;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: palette.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: large ? 15 : 13,
                fontWeight: large ? FontWeight.w600 : FontWeight.w400,
                color: color ?? palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyableRow extends StatelessWidget {
  const _CopyableRow({required this.label, required this.palette});
  final String label;
  final MaasgaPalette palette;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: label));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Référence copiée : $label'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: palette.cardAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.tag, size: 16, color: palette.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
                fontFamily: 'monospace',
              ),
            ),
            const Spacer(),
            Icon(Icons.copy_outlined, size: 14, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}
