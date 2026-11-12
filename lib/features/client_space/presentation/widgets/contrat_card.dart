import 'package:flutter/material.dart';
import '../../../../shared/design_tokens/maasga_tokens.dart';
import '../../domain/contrat_maintenance.dart';
import 'contrat_detail_sheet.dart';

class ContratCard extends StatelessWidget {
  const ContratCard({required this.contrat, this.onViewInvoice, super.key});

  final ContratMaintenance contrat;
  final VoidCallback? onViewInvoice;

  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => ContratDetailSheet.show(context, contrat),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contrat.type,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: palette.textPrimary,
                            ),
                          ),
                          Text(
                            contrat.period,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textSecondary,
                            ),
                          ),
                          Text(
                            contrat.quartier,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textSecondary,
                            ),
                          ),
                          if (contrat.nbClimatiseurs != null)
                            Text(
                              '${contrat.nbClimatiseurs} climatiseur(s)',
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.textMuted,
                              ),
                            ),
                          if (contrat.frequenceVisites != null)
                            Text(
                              contrat.frequenceVisites!,
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.textMuted,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            contrat.price,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: palette.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(contrat: contrat, palette: palette),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: palette.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progression visites
                Row(
                  children: [
                    Text(
                      'Visites : ${contrat.visitesEffectuees}/${contrat.visitesTotales}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: contrat.visitesTotales > 0
                        ? contrat.visitesEffectuees / contrat.visitesTotales
                        : 0,
                    backgroundColor: palette.cardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onViewInvoice,
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: Text(
                    'Facture PDF',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.accent,
                    side: BorderSide(color: palette.accent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (contrat.visites.isNotEmpty) ...[
                  Divider(height: 24, color: palette.divider),
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        'VISITES EFFECTUÉES (${contrat.visitesEffectuees})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.accent,
                        ),
                      ),
                      children: contrat.visites
                          .map((v) => _VisiteItem(visite: v, palette: palette))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.contrat, required this.palette});
  final ContratMaintenance contrat;
  final MaasgaPalette palette;

  @override
  Widget build(BuildContext context) {
    final st = contrat.status.toLowerCase();
    final isPending = st.contains('attente') || st == 'pending';
    final isCancelled =
        st.contains('annul') || st.contains('refus') || st == 'cancelled';
    final bgColor = isPending
        ? palette.warningSurface
        : isCancelled
            ? palette.dangerSurface
            : palette.successSurface;
    final textColor = isPending
        ? palette.warning
        : isCancelled
            ? palette.danger
            : palette.success;
    final label = isPending
        ? 'En attente'
        : isCancelled
            ? 'Annulé'
            : contrat.status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _VisiteItem extends StatelessWidget {
  const _VisiteItem({required this.visite, required this.palette});
  final VisiteContrat visite;
  final MaasgaPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            visite.isCompleted ? Icons.check_circle : Icons.pending_outlined,
            size: 16,
            color: visite.isCompleted ? palette.success : palette.warning,
          ),
          const SizedBox(width: 8),
          Text(
            visite.date,
            style: TextStyle(fontSize: 12, color: palette.textPrimary),
          ),
          const Spacer(),
          Text(
            'Tech: ${visite.technicianName}',
            style: TextStyle(fontSize: 11, color: palette.textMuted),
          ),
          const SizedBox(width: 8),
          if (visite.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: palette.successSurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Effectuée',
                style: TextStyle(
                  fontSize: 9,
                  color: palette.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
