import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/design_tokens/maasga_tokens.dart';
import '../../domain/contrat_maintenance.dart';

/// Bottom sheet affichant le détail complet d'un contrat de maintenance.
class ContratDetailSheet extends StatelessWidget {
  const ContratDetailSheet({super.key, required this.contrat});

  final ContratMaintenance contrat;

  static Future<void> show(BuildContext context, ContratMaintenance contrat) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContratDetailSheet(contrat: contrat),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.maasga;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
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
                    'Détail du contrat',
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
                  // Bannière statut
                  _StatusBanner(contrat: contrat, palette: palette),
                  const SizedBox(height: 20),

                  // Formule
                  _SectionTitle('Formule', palette),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.workspace_premium_outlined,
                    label: contrat.type,
                    palette: palette,
                    large: true,
                  ),
                  if (contrat.planType.isNotEmpty)
                    _DetailRow(
                      icon: Icons.list_alt_outlined,
                      label: contrat.planType,
                      palette: palette,
                    ),
                  const SizedBox(height: 20),

                  // Prix
                  _SectionTitle('Prix', palette),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: contrat.price,
                    palette: palette,
                    large: true,
                    color: palette.accent,
                  ),
                  const SizedBox(height: 20),

                  // Équipements
                  if (contrat.nbClimatiseurs != null ||
                      contrat.equipmentType != null ||
                      contrat.typeEtablissement != null ||
                      contrat.frequenceVisites != null) ...[
                    _SectionTitle('Équipement', palette),
                    const SizedBox(height: 8),
                    if (contrat.nbClimatiseurs != null)
                      _DetailRow(
                        icon: Icons.ac_unit_outlined,
                        label: '${contrat.nbClimatiseurs} climatiseur(s)',
                        palette: palette,
                      ),
                    if (contrat.equipmentType != null)
                      _DetailRow(
                        icon: Icons.devices_outlined,
                        label: contrat.equipmentType!,
                        palette: palette,
                      ),
                    if (contrat.typeEtablissement != null)
                      _DetailRow(
                        icon: Icons.business_outlined,
                        label: contrat.typeEtablissement!,
                        palette: palette,
                      ),
                    if (contrat.frequenceVisites != null)
                      _DetailRow(
                        icon: Icons.repeat_outlined,
                        label: contrat.frequenceVisites!,
                        palette: palette,
                      ),
                    const SizedBox(height: 20),
                  ],

                  // Localisation & dates
                  _SectionTitle('Informations', palette),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: contrat.quartier,
                    palette: palette,
                  ),
                  if (contrat.period.isNotEmpty)
                    _DetailRow(
                      icon: Icons.date_range_outlined,
                      label: contrat.period,
                      palette: palette,
                    ),
                  if (contrat.nextVisitDate != null)
                    _DetailRow(
                      icon: Icons.event_outlined,
                      label: 'Prochaine visite : ${_formatDate(contrat.nextVisitDate!)}',
                      palette: palette,
                    ),
                  if (contrat.preferredDate != null)
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date préférée : ${_formatDate(contrat.preferredDate!)}',
                      palette: palette,
                    ),
                  const SizedBox(height: 20),

                  // Progression des visites
                  _SectionTitle('Visites', palette),
                  const SizedBox(height: 8),
                  _VisitesProgress(contrat: contrat, palette: palette),

                  // Liste des visites
                  if (contrat.visites.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...contrat.visites.map(
                      (v) => _VisiteRow(visite: v, palette: palette),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Description
                  if (contrat.description != null &&
                      contrat.description!.isNotEmpty) ...[
                    _SectionTitle('Description', palette),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: palette.cardAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        contrat.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Référence
                  _SectionTitle('Référence', palette),
                  const SizedBox(height: 8),
                  _CopyableRow(label: '#${contrat.id}', palette: palette),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

// ─── Widgets helpers ──────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.contrat, required this.palette});
  final ContratMaintenance contrat;
  final MaasgaPalette palette;

  Color get _bg {
    if (contrat.isPending) return palette.warningSurface;
    if (contrat.isActive) return palette.successSurface;
    return palette.dangerSurface;
  }

  Color get _fg {
    if (contrat.isPending) return palette.warning;
    if (contrat.isActive) return palette.success;
    return palette.danger;
  }

  String get _label {
    if (contrat.isPending) return 'En attente de validation';
    if (contrat.isActive) return 'Contrat actif';
    final s = contrat.status.toLowerCase();
    if (s.contains('annul')) return 'Annulé';
    if (s.contains('refus')) return 'Refusé';
    return contrat.status;
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
            _label,
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

class _VisitesProgress extends StatelessWidget {
  const _VisitesProgress({required this.contrat, required this.palette});
  final ContratMaintenance contrat;
  final MaasgaPalette palette;

  @override
  Widget build(BuildContext context) {
    final ratio = contrat.visitesTotales > 0
        ? contrat.visitesEffectuees / contrat.visitesTotales
        : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${contrat.visitesEffectuees}/${contrat.visitesTotales} visites effectuées',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: palette.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _VisiteRow extends StatelessWidget {
  const _VisiteRow({required this.visite, required this.palette});
  final VisiteContrat visite;
  final MaasgaPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            visite.isCompleted ? Icons.check_circle : Icons.pending_outlined,
            size: 16,
            color: visite.isCompleted ? palette.success : palette.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      visite.date,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: palette.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      visite.technicianName,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: visite.isCompleted
                            ? palette.successSurface
                            : palette.warningSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        visite.isCompleted ? 'Effectuée' : 'En attente',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: visite.isCompleted
                              ? palette.success
                              : palette.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                if (visite.actions != null && visite.actions!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    visite.actions!,
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ],
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
