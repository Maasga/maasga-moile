import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/maasga_tokens.dart';
import '../../domain/commande.dart';
import 'commande_detail_sheet.dart';

class CommandeCard extends StatelessWidget {
  const CommandeCard({
    required this.commande,
    this.onViewInvoice,
    this.onCancel,
    this.onDownloadDevis,
    this.onViewDevis,
    this.onAcceptDevis,
    this.onRejectDevis,
    super.key,
  });

  final Commande commande;
  final VoidCallback? onViewInvoice;
  final VoidCallback? onCancel;
  final VoidCallback? onDownloadDevis;
  final VoidCallback? onViewDevis;
  final VoidCallback? onAcceptDevis;
  final VoidCallback? onRejectDevis;

  Color _statusBg(BuildContext context, CommandeStatus s) {
    final p = context.maasga;
    if (s == CommandeStatus.installed || s == CommandeStatus.livre) return p.successSurface;
    if (s == CommandeStatus.paid || s == CommandeStatus.devisValide) return p.infoSurface;
    if (s == CommandeStatus.validationTerrain || s == CommandeStatus.devisEnAttente) return p.warningSurface;
    if (s == CommandeStatus.cancelled || s == CommandeStatus.devisRefuse || s == CommandeStatus.refunded) return p.dangerSurface;
    return p.cardAlt;
  }

  Color _statusFg(BuildContext context, CommandeStatus s) {
    final p = context.maasga;
    if (s == CommandeStatus.installed || s == CommandeStatus.livre) return p.success;
    if (s == CommandeStatus.paid || s == CommandeStatus.devisValide) return p.info;
    if (s == CommandeStatus.validationTerrain || s == CommandeStatus.devisEnAttente) return p.warning;
    if (s == CommandeStatus.cancelled || s == CommandeStatus.devisRefuse || s == CommandeStatus.refunded) return p.danger;
    return p.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;
    final isCancelled =
        commande.status == CommandeStatus.cancelled ||
        commande.status == CommandeStatus.refunded;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => CommandeDetailSheet.show(context, commande),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info principale ────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image produit
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: palette.cardAlt,
                      child: Image.asset(
                        commande.productImage ??
                            'assets/products/product_placeholder.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.ac_unit,
                          size: 24,
                          color: palette.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Nom + ID + Prix
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commande.productName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: palette.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '#${commande.id} · ${_shortDate(commande.date)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: palette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          commande.price,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: palette.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge statut
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusBg(context, commande.status),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          commande.status.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _statusFg(context, commande.status),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: palette.textMuted,
                      ),
                    ],
                  ),
                ],
              ),

              // ── Bannière annulée ──────────────────────────────────
              if (isCancelled) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.dangerSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: palette.danger, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Commande annulée',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Boutons d'action ──────────────────────────────────
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if ([
                    CommandeStatus.paid,
                    CommandeStatus.livre,
                    CommandeStatus.validationTerrain,
                    CommandeStatus.devisEnAttente,
                    CommandeStatus.devisValide,
                    CommandeStatus.devisRefuse,
                    CommandeStatus.installed,
                    CommandeStatus.cancelled,
                    CommandeStatus.refunded,
                  ].contains(commande.status))
                    _ActionBtn(
                      icon: Icons.receipt_long_outlined,
                      label: 'Reçu',
                      color: palette.accent,
                      onTap: onViewInvoice,
                    ),
                  if (commande.status == CommandeStatus.devisEnAttente ||
                      commande.status == CommandeStatus.devisValide)
                    _ActionBtn(
                      icon: Icons.file_download_outlined,
                      label: 'Devis',
                      color: palette.info,
                      onTap: onDownloadDevis,
                    ),
                  if (commande.status == CommandeStatus.devisEnAttente ||
                      commande.status == CommandeStatus.devisValide ||
                      commande.status == CommandeStatus.devisRefuse)
                    _ActionBtn(
                      icon: Icons.description_outlined,
                      label: 'Voir devis',
                      color: palette.accent,
                      onTap: onViewDevis,
                    ),
                  if (commande.status == CommandeStatus.devisEnAttente)
                    _ActionBtn(
                      icon: Icons.check_circle_outline,
                      label: 'Valider',
                      color: palette.success,
                      onTap: onAcceptDevis,
                      filled: true,
                    ),
                  if (commande.status == CommandeStatus.devisEnAttente)
                    _ActionBtn(
                      icon: Icons.highlight_off,
                      label: 'Refuser',
                      color: palette.danger,
                      onTap: onRejectDevis,
                    ),
                  if ([
                    CommandeStatus.paid,
                    CommandeStatus.livre,
                    CommandeStatus.validationTerrain,
                    CommandeStatus.devisEnAttente,
                    CommandeStatus.devisRefuse,
                  ].contains(commande.status))
                    _ActionBtn(
                      icon: Icons.undo,
                      label: 'Annuler',
                      color: palette.danger,
                      onTap: onCancel,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Raccourcit la date ISO pour l'affichage (ex. "13/10/2026 23:14")
  String _shortDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

// ── Bouton d'action compact ────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 13),
        label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 13),
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.08),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
