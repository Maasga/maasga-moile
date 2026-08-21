import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/maasga_contact.dart';

/// Écran affiché après la soumission réussie d'une commande.
///
/// L'équipe MAASGA contactera le client par e-mail et WhatsApp
/// pour finaliser le paiement et la livraison.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.clientName,
    required this.clientPhone,
    required this.total,
  });

  final String orderId;
  final String clientName;
  final String clientPhone;
  final int total;

  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: MaasgaContact.email,
      queryParameters: {
        'subject': 'Suivi commande${orderId.isNotEmpty ? " #$orderId" : ""}',
        'body':
            'Bonjour,\n\nJe souhaite avoir des informations sur ma commande'
            '${orderId.isNotEmpty ? " n°$orderId" : ""}.\n\nCordialement,\n$clientName',
      },
    );
    if (await canLaunchUrl(uri)) {
      // Un mailto: doit sortir de l'app : sans ce mode, Android peut tenter de
      // l'ouvrir dans une vue interne et ne rien afficher du tout.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
      MaasgaContact.whatsAppUrl(MaasgaContact.whatsAppMsgCommande),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Icône de succès ──────────────────────────────────
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(48),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32),
                  size: 56,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Commande envoyée !',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Merci $clientName, votre commande a bien été reçue.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF475467),
                ),
                textAlign: TextAlign.center,
              ),

              if (orderId.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Référence : #$orderId',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B3A8D),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── Récapitulatif ────────────────────────────────────
              _InfoCard(
                children: [
                  _InfoRow(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Total estimé',
                    value: '$total FCFA',
                    valueColor: const Color(0xFF1B3A8D),
                    valueBold: true,
                  ),
                  const Divider(height: 20, color: Color(0xFFF0F0F0)),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Téléphone enregistré',
                    value: clientPhone,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Prochaines étapes ────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Prochaines étapes',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _StepCard(
                number: '1',
                icon: Icons.mark_email_read_outlined,
                title: 'Confirmation par e-mail',
                description:
                    'Vous recevrez un e-mail de confirmation de la part de l\'équipe MAASGA avec les détails de votre commande.',
                color: const Color(0xFF1B3A8D),
              ),

              const SizedBox(height: 12),

              _StepCard(
                number: '2',
                icon: Icons.chat_outlined,
                title: 'Contact WhatsApp',
                description:
                    'Un conseiller MAASGA vous contactera sur WhatsApp pour organiser la livraison et le règlement.',
                color: const Color(0xFF25D366),
              ),

              const SizedBox(height: 12),

              _StepCard(
                number: '3',
                icon: Icons.local_shipping_outlined,
                title: 'Livraison à votre adresse',
                description:
                    'Une fois le paiement confirmé, votre commande est préparée et livrée chez vous.',
                color: const Color(0xFFF57C00),
              ),

              const SizedBox(height: 28),

              // ── Boutons de contact ───────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Contacter MAASGA directement',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _ContactButton(
                icon: Icons.email_outlined,
                label: 'Envoyer un e-mail',
                subtitle: MaasgaContact.email,
                backgroundColor: const Color(0xFFE8EDFF),
                iconColor: const Color(0xFF1B3A8D),
                onTap: _openEmail,
              ),

              const SizedBox(height: 10),

              _ContactButton(
                icon: Icons.chat_bubble_outline,
                label: 'Contacter sur WhatsApp',
                subtitle: MaasgaContact.phoneInternational,
                backgroundColor: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF25D366),
                onTap: _openWhatsApp,
              ),

              const SizedBox(height: 32),

              // ── Bouton retour accueil ────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3A8D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Retour à l\'accueil',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => context.go('/client-space'),
                child: Text(
                  'Voir mes commandes',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B3A8D),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Composants internes ────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF757575),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final String number;
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF757575),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFF9E9E9E),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
