import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/config/maasga_contact.dart';
import '../../../../shared/widgets/main_bottom_nav.dart';
import '../widgets/formula_card.dart';
import '../widgets/maintenance_widgets.dart';
import '../../../../shared/widgets/maasga_app_bar.dart';
import '../../../../shared/design_tokens/maasga_tokens.dart';
import '../../../../shared/services/user_prefs_service.dart';
import '../../../client_space/data/client_dashboard_repository.dart';
import '../../data/repositories/maintenance_repository.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/notifications/data/activity_repository.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  final _scrollController = ScrollController();
  bool _isLoading = false;

  // Simulateur interactif
  int _simulatedAcCount = 2;
  String _simulatedFrequency = 'Confort'; // 'Essentiel', 'Confort', 'Pro'

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Calculs tarifaires dégressifs (v2) ───────────────────────────────────

  int _getUnitRate(int acCount) {
    if (acCount <= 4) return 8500;
    if (acCount <= 8) return 7500;
    if (acCount <= 15) return 6000;
    return 5000;
  }

  int _getVisitsPerYear(String freq) {
    switch (freq) {
      case 'Essentiel':
        return 1;
      case 'Pro':
        return 3;
      case 'Confort':
      default:
        return 2;
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  String _getMatchingFormula(int acCount) {
    if (acCount <= 4) return 'RÉSIDENTIEL';
    if (acCount <= 15) return 'PROFESSIONNEL / PME';
    return 'INDUSTRIEL';
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/success_check.json',
              width: 120,
              height: 120,
              repeat: false,
            ),
            const SizedBox(height: 8),
            Text(
              'Demande envoyée !',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nous vous confirmons votre contrat sous 2h. Notre équipe technique vous contactera sur WhatsApp pour planifier la 1ère visite.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B3A8D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Parfait',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1B3A8D);

    // Données calculées en direct
    final activeUnitRate = _getUnitRate(_simulatedAcCount);
    final activeVisits = _getVisitsPerYear(_simulatedFrequency);
    final pricePerVisit = activeUnitRate * _simulatedAcCount;
    final totalAnnual = pricePerVisit * activeVisits;
    final matchedFormula = _getMatchingFormula(_simulatedAcCount);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          MaasgaAppBar(
            notificationsCount: ref.watch(unreadNotificationCountProvider),
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              minHeight: 2,
            ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. BANNIÈRE INTRO
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Maintenance préventive · MAASGA',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Contrats de Maintenance',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tarification équitable par équipement : tarif dégressif calculé selon votre nombre de climatiseurs et la fréquence de visite.',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bolt,
                                color: Color(0xFFFFD700),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Un climatiseur bien entretenu consomme jusqu\'à 30% d\'énergie en moins et dure 2× plus longtemps.',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. AVANTAGES
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Pourquoi un contrat de maintenance ?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.65,
                    children: const [
                      BenefitCard(
                        icon: Icons.electric_bolt_outlined,
                        title: '-30% énergie',
                        subtitle: 'Économies sur votre facture',
                      ),
                      BenefitCard(
                        icon: Icons.timelapse_outlined,
                        title: '2× durée de vie',
                        subtitle: 'Votre clim dure plus longtemps',
                      ),
                      BenefitCard(
                        icon: Icons.air_outlined,
                        title: 'Air pur',
                        subtitle: 'Filtres propres, air sain garanti',
                      ),
                      BenefitCard(
                        icon: Icons.shield_outlined,
                        title: 'Zéro panne',
                        subtitle: 'Diagnostic précoce des problèmes',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. SIMULATEUR DYNAMIQUE INTERACTIF (v2)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD8EAFB)),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calculate_outlined,
                                color: primaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Simulateur de contrat',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  Text(
                                    'Estimez votre tarif en direct',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF757575),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Nombre de climatiseurs
                        Text(
                          'Nombre de climatiseurs :',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: _simulatedAcCount > 1
                                    ? () => setState(() => _simulatedAcCount--)
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                                color: primaryColor,
                              ),
                              Row(
                                children: [
                                  Text(
                                    '$_simulatedAcCount',
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _simulatedAcCount > 1
                                        ? 'climatiseurs'
                                        : 'climatiseur',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () =>
                                    setState(() => _simulatedAcCount++),
                                icon: const Icon(Icons.add_circle_outline),
                                color: primaryColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Sélecteurs rapides (chips)
                        Wrap(
                          spacing: 8,
                          children: [1, 2, 4, 8, 12, 20].map((count) {
                            final isSel = _simulatedAcCount == count;
                            return ChoiceChip(
                              label: Text('$count clim'),
                              selected: isSel,
                              onSelected: (_) =>
                                  setState(() => _simulatedAcCount = count),
                              selectedColor: primaryColor,
                              labelStyle: GoogleFonts.poppins(
                                fontSize: 12,
                                color: isSel ? Colors.white : const Color(0xFF4B5563),
                                fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Fréquence de visites
                        Text(
                          'Fréquence des visites par an :',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildFrequencyChip('Essentiel', '1 visite/an'),
                            const SizedBox(width: 8),
                            _buildFrequencyChip('Confort', '2 visites/an'),
                            const SizedBox(width: 8),
                            _buildFrequencyChip('Pro', '3 visites/an'),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Résultat du calcul dynamique
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tarif unitaire applicable :',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF166534),
                                    ),
                                  ),
                                  Text(
                                    '${_formatCurrency(activeUnitRate)} F / clim / visite',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Par visite globale :',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF166534),
                                    ),
                                  ),
                                  Text(
                                    '${_formatCurrency(pricePerVisit)} F CFA',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Color(0xFF86EFAC), height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    'Total annuel estimé :',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF14532D),
                                    ),
                                  ),
                                  Text(
                                    '${_formatCurrency(totalAnnual)} F CFA',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF14532D),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bouton action simulation
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _showSubscriptionForm(
                              matchedFormula,
                              acCount: _simulatedAcCount,
                              frequency: _simulatedFrequency,
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: Text(
                              'Souscrire avec cette configuration',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 4. CHOISISSEZ VOTRE FORMULE (4 CARTES)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Nos formules de maintenance',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Les prix s\'ajustent automatiquement selon la configuration sélectionnée ci-dessus.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // CARTE 1 — RÉSIDENTIEL
                        FormulaCard(
                          title: 'RÉSIDENTIEL',
                          targetRange: '1 à 4 climatiseurs',
                          unitRateText: '8 500 F / unité / visite',
                          frequencyTag: 'Essentiel (1x) ou Confort (2x)',
                          price: _simulatedAcCount <= 4
                              ? _formatCurrency(8500 * _simulatedAcCount * activeVisits)
                              : '34 000',
                          period: '/ an',
                          subtitle: _simulatedAcCount <= 4
                              ? 'soit ${_formatCurrency(8500 * _simulatedAcCount)} F par visite globale'
                              : 'Ex: 2 clim, Confort (2 visites) = 34 000 F/an',
                          target: 'Idéal pour : logements et petits bureaux',
                          inclusions: const [
                            'Nettoyage des filtres',
                            'Vérification complète du système',
                            'Contrôle performances de refroidissement',
                            'Vérification du gaz réfrigérant',
                            'Diagnostic technique préventif',
                          ],
                          isHighlighted: _simulatedAcCount <= 4,
                          ctaText: 'Choisir cette formule',
                          onSelect: () => _showSubscriptionForm(
                            'RÉSIDENTIEL',
                            acCount: _simulatedAcCount <= 4 ? _simulatedAcCount : 2,
                            frequency: _simulatedFrequency,
                          ),
                        ),

                        // CARTE 2 — PROFESSIONNEL / PME ⭐ RECOMMANDÉ
                        FormulaCard(
                          title: 'PROFESSIONNEL / PME',
                          badgeText: '⭐ RECOMMANDÉ',
                          targetRange: '5 à 15 climatiseurs',
                          unitRateText: '7 500 F (5-8) ou 6 000 F (9-15)',
                          frequencyTag: 'Confort (2x) ou Pro (3x)',
                          price: (_simulatedAcCount >= 5 && _simulatedAcCount <= 15)
                              ? _formatCurrency(activeUnitRate * _simulatedAcCount * activeVisits)
                              : '120 000',
                          period: '/ an',
                          subtitle: (_simulatedAcCount >= 5 && _simulatedAcCount <= 15)
                              ? 'soit ${_formatCurrency(activeUnitRate * _simulatedAcCount)} F par visite globale'
                              : 'Ex: 8 clim, Confort (2 visites) = 120 000 F/an',
                          target: 'Idéal pour : bureaux, commerces, PME',
                          isRecommended: true,
                          isHighlighted: _simulatedAcCount >= 5 && _simulatedAcCount <= 15,
                          bonusTitle: 'Bonus client inclus :',
                          bonusDesc: '1 diagnostic panne offert dans l\'année',
                          inclusions: const [
                            'Nettoyage complet unité intérieure + extérieure',
                            'Vérification du gaz réfrigérant',
                            'Diagnostic complet du système',
                            'Priorité sur les interventions de dépannage',
                            'Conseils d\'optimisation énergétique',
                          ],
                          ctaText: 'Choisir cette formule',
                          onSelect: () => _showSubscriptionForm(
                            'PROFESSIONNEL / PME',
                            acCount: (_simulatedAcCount >= 5 && _simulatedAcCount <= 15)
                                ? _simulatedAcCount
                                : 8,
                            frequency: _simulatedFrequency,
                          ),
                        ),

                        // CARTE 3 — INDUSTRIEL 🏆 MEILLEUR CHOIX
                        FormulaCard(
                          title: 'INDUSTRIEL',
                          badgeText: '🏆 MEILLEUR CHOIX',
                          targetRange: '16 climatiseurs et plus',
                          unitRateText: 'Dès 5 000 F / unité / visite',
                          frequencyTag: 'Pro (3x) ou contrat sur mesure',
                          price: 'Sur devis',
                          period: '',
                          subtitle: 'Tarif dégressif dès 5 000 F (base de négociation selon volume)',
                          target: 'Idéal pour : usines, hôtels, sites à gros parc',
                          isPremium: true,
                          isHighlighted: _simulatedAcCount >= 16,
                          bonusTitle: 'Avantages exclusifs :',
                          bonusDesc:
                              '• 1 recharge de gaz offerte (si besoin)\n• 10% de réduction sur les réparations\n• Support & intervention prioritaires',
                          inclusions: const [
                            'Nettoyage complet professionnel',
                            'Vérification approfondie gaz et pressions',
                            'Diagnostic complet du système',
                            'Intervention prioritaire garantie',
                            'Suivi technique et rapport personnalisé',
                          ],
                          ctaText: 'Demander un devis',
                          onSelect: () => _showSubscriptionForm(
                            'INDUSTRIEL',
                            acCount: _simulatedAcCount >= 16 ? _simulatedAcCount : 16,
                            frequency: _simulatedFrequency,
                          ),
                        ),

                        // CARTE 4 — SUR MESURE
                        FormulaCard(
                          title: 'SUR MESURE',
                          badgeText: 'CONTRAT PERSONNALISÉ',
                          targetRange: 'Multi-sites & Parcs mixtes',
                          unitRateText: 'Devis sur mesure',
                          price: 'Sur devis',
                          period: '',
                          subtitle: 'Selon vos besoins et votre cahier des charges',
                          customDescription:
                              'Votre parc ou vos exigences ne rentrent pas dans une formule standard ? Décrivez-nous votre besoin (plusieurs sites, chambres froides, astreinte ou délai d\'intervention garanti SLA), notre équipe construit un contrat adapté.',
                          target: 'Idéal pour : multi-sites, parcs mixtes, entreprises avec SLA',
                          isCustom: true,
                          inclusions: const [],
                          ctaText: 'Demander un contrat personnalisé',
                          onSelect: () => _showSubscriptionForm(
                            'SUR MESURE',
                            acCount: _simulatedAcCount,
                            frequency: _simulatedFrequency,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const _WhatsAppCTA(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(currentPath: '/maintenance'),
    );
  }

  Widget _buildFrequencyChip(String key, String label) {
    final isSel = _simulatedFrequency == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _simulatedFrequency = key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF1B3A8D) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? const Color(0xFF1B3A8D) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            children: [
              Text(
                key,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSel ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isSel
                      ? Colors.white.withValues(alpha: 0.85)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubscriptionForm(
    String initialFormule, {
    int? acCount,
    String? frequency,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SubscriptionFormModal(
        initialFormule: initialFormule,
        initialAcCount: acCount ?? _simulatedAcCount,
        initialFrequency: frequency ?? _simulatedFrequency,
        onSubmit: _submitRequestFromModal,
      ),
    );
  }

  Future<void> _submitRequestFromModal(Map<String, dynamic> data) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final dashboardData = ref.read(clientDashboardProvider).asData?.value;
      final clientId = dashboardData?.profile.id;
      final rawPhone = data['phone'] as String? ?? '';
      final normalizedPhone = rawPhone.startsWith('+226')
          ? rawPhone
          : rawPhone.startsWith('226')
              ? '+$rawPhone'
              : '+226$rawPhone';
      final email = (data['email'] as String?)?.isNotEmpty == true
          ? data['email'] as String
          : user?.email;

      final enrichedData = {
        ...data,
        'phone': normalizedPhone,
        'client_phone': normalizedPhone,
        'client_name': data['name'],
        if (email != null && email.isNotEmpty) 'email': email,
        if (email != null && email.isNotEmpty) 'client_email': email,
        if (clientId != null && clientId.isNotEmpty) 'client_id': clientId,
        'user_id': user?.uid ?? '',
        'firebase_uid': user?.uid ?? '',
      };

      final repo = await ref.read(maintenanceRepositoryProvider.future);
      await repo.submitRequest(enrichedData);

      // Enregistrer le contrat localement pour affichage instantané dans l'espace client
      if (user != null) {
        final prefs = ref.read(userPrefsProvider);
        if (prefs != null) {
          final formule = data['formule'] ?? data['plan_type'] ?? 'Standard';
          final acCount = data['nb_climatiseurs'] ?? 1;
          final priceStr = data['prix_annuel_estime'] != null
              ? '${_formatCurrency(data['prix_annuel_estime'] as int)} F CFA'
              : 'Sur devis';

          final contractMap = {
            'id': 'contract_${DateTime.now().millisecondsSinceEpoch}',
            'type': 'Contrat de maintenance ($formule)',
            'plan_type': data['plan_type'] ?? 'standard',
            'formule': formule,
            'nb_climatiseurs': acCount,
            'frequence': data['frequence_visites'] ?? 'Confort',
            'period': 'En cours de validation',
            'price': priceStr,
            'status': 'Actif',
            'statut': 'Actif',
            'quartier': data['quartier'] ?? 'Ouagadougou',
            'visites_totales': data['visites_an'] ?? 2,
            'visites_effectuees': 0,
            'visites': <Map<String, dynamic>>[],
            'created_at': DateTime.now().toIso8601String(),
          };
          await prefs.saveLocalContract(user.uid, contractMap);
        }
      }

      // Invalider les fournisseurs pour rafraîchir l'espace client
      ref.invalidate(clientDashboardProvider);
      ref.invalidate(userActivityProvider);

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ─── MODAL DE SOUSCRIPTION / DEVIS (v2) ──────────────────────────────────────

class _SubscriptionFormModal extends ConsumerStatefulWidget {
  final String initialFormule;
  final int initialAcCount;
  final String initialFrequency;
  final Function(Map<String, dynamic>) onSubmit;

  const _SubscriptionFormModal({
    required this.initialFormule,
    required this.initialAcCount,
    required this.initialFrequency,
    required this.onSubmit,
  });

  @override
  ConsumerState<_SubscriptionFormModal> createState() =>
      _SubscriptionFormModalState();
}

class _SubscriptionFormModalState
    extends ConsumerState<_SubscriptionFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _quartierCtrl = TextEditingController();
  final _siteCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late String _selectedFormule;
  late int _acCount;
  late String _frequency;

  @override
  void initState() {
    super.initState();
    _selectedFormule = widget.initialFormule;
    _acCount = widget.initialAcCount;
    _frequency = widget.initialFrequency;
    _fillUserData();
  }

  int _getUnitRate(int acCount) {
    if (acCount <= 4) return 8500;
    if (acCount <= 8) return 7500;
    if (acCount <= 15) return 6000;
    return 5000;
  }

  int _getVisitsPerYear(String freq) {
    switch (freq) {
      case 'Essentiel':
        return 1;
      case 'Pro':
        return 3;
      case 'Confort':
      default:
        return 2;
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  void _fillUserData() {
    final user = ref.read(userProfileProvider).value;
    if (user != null) {
      _nameCtrl.text = user['name'] ?? '';
      _phoneCtrl.text = user['phone'] ?? '';
      _emailCtrl.text = user['email'] ?? '';
      _quartierCtrl.text = user['quartier'] ?? '';
    } else {
      final prefs = ref.read(userPrefsProvider);
      if (prefs != null) {
        _nameCtrl.text = prefs.savedName;
        _phoneCtrl.text = prefs.savedPhone;
        _emailCtrl.text = prefs.savedEmail;
        _quartierCtrl.text = prefs.savedQuartier;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _quartierCtrl.dispose();
    _siteCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1B3A8D);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isCustom = _selectedFormule == 'SUR MESURE';
    final isIndustrial = _selectedFormule == 'INDUSTRIEL';

    final unitRate = _getUnitRate(_acCount);
    final visits = _getVisitsPerYear(_frequency);
    final totalAnnual = unitRate * _acCount * visits;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCustom || isIndustrial ? 'Demande de devis' : 'Souscription contrat',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Formule : $_selectedFormule',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F5),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Choix de la formule
                    _buildFieldLabel('Formule sélectionnée :'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        'RÉSIDENTIEL',
                        'PROFESSIONNEL / PME',
                        'INDUSTRIEL',
                        'SUR MESURE',
                      ].map((f) {
                        final isSel = _selectedFormule == f;
                        return ChoiceChip(
                          label: Text(f),
                          selected: isSel,
                          onSelected: (_) => setState(() => _selectedFormule = f),
                          selectedColor: primaryColor,
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isSel ? Colors.white : const Color(0xFF374151),
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Climatiseurs & Fréquence si pas Sur Mesure
                    if (!isCustom) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Climatiseurs :'),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: _acCount > 1
                                            ? () => setState(() => _acCount--)
                                            : null,
                                        icon: const Icon(Icons.remove, size: 20),
                                        color: primaryColor,
                                      ),
                                      Text(
                                        '$_acCount',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => setState(() => _acCount++),
                                        icon: const Icon(Icons.add, size: 20),
                                        color: primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Fréquence :'),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _frequency,
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Essentiel',
                                          child: Text('1x / an (Essentiel)'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Confort',
                                          child: Text('2x / an (Confort)'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Pro',
                                          child: Text('3x / an (Pro)'),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) setState(() => _frequency = v);
                                      },
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF1F2937),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Récapitulatif calculé
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isIndustrial
                                  ? 'Tarif unitaire : Dès 5 000 F / clim\nBase de devis :'
                                  : 'Tarif unitaire : ${_formatCurrency(unitRate)} F\nTotal estimé / an :',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: primaryColor,
                              ),
                            ),
                            Text(
                              isIndustrial
                                  ? 'Sur devis'
                                  : '${_formatCurrency(totalAnnual)} F CFA',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (isIndustrial || isCustom) ...[
                      _buildFieldLabel('Type d\'établissement / Site(s)'),
                      TextFormField(
                        controller: _siteCtrl,
                        style: context.maasga.inputTextStyle,
                        decoration: InputDecoration(
                          hintText: 'Ex: Hôtel 40 chambres, Usine zone industrielle...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                          prefixIcon: const Icon(Icons.apartment, color: primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFD8EAFB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryColor, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildFieldLabel('Besoins ou exigences spécifiques'),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 2,
                        style: context.maasga.inputTextStyle,
                        decoration: InputDecoration(
                          hintText: 'Ex: Chambres froides, astreinte weekend, intervention sous 4h...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFD8EAFB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryColor, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    _buildFieldLabel('Nom complet *'),
                    TextFormField(
                      controller: _nameCtrl,
                      style: context.maasga.inputTextStyle,
                      decoration: InputDecoration(
                        hintText: 'Votre nom complet',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: primaryColor,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD8EAFB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Téléphone (WhatsApp) *'),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: context.maasga.inputTextStyle,
                      decoration: InputDecoration(
                        hintText: 'XX XX XX XX',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: primaryColor,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD8EAFB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel('Quartier / Ville *'),
                    TextFormField(
                      controller: _quartierCtrl,
                      style: context.maasga.inputTextStyle,
                      decoration: InputDecoration(
                        hintText: 'Ex: Ouaga 2000, Koulouba...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: primaryColor,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD8EAFB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 18),

                    // Explication paiement
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF15803D),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Comment se passe le règlement ?',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isCustom || isIndustrial
                                ? 'Un devis chiffré vous est envoyé sous 2h. Le contrat est validé ensemble avant toute intervention.'
                                : 'Le règlement s\'effectue directement à la première visite technique — aucun paiement en ligne requis.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF166534),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bouton de validation
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!_formKey.currentState!.validate()) return;
                          Navigator.pop(context);
                          final planKey = _selectedFormule
                              .toLowerCase()
                              .replaceAll(' / ', '_')
                              .replaceAll(' ', '_');

                          widget.onSubmit({
                            'name': _nameCtrl.text.trim(),
                            'phone': _phoneCtrl.text.trim(),
                            'email': _emailCtrl.text.trim(),
                            'quartier': _quartierCtrl.text.trim(),
                            'plan_type': planKey,
                            'formule': _selectedFormule,
                            'nb_climatiseurs': isCustom ? null : _acCount,
                            'frequence_visites': isCustom ? 'Sur mesure' : _frequency,
                            'visites_an': isCustom ? null : visits,
                            'tarif_unitaire': isCustom ? null : unitRate,
                            'prix_annuel_estime': isCustom ? null : totalAnnual,
                            'type_etablissement': _siteCtrl.text.trim(),
                            'exigences': _notesCtrl.text.trim(),
                            'payment_method': 'a_la_visite',
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isCustom
                              ? 'Envoyer ma demande personnalisée'
                              : (isIndustrial
                                  ? 'Demander mon devis'
                                  : 'Confirmer ma souscription'),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    if (isCustom) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            launchUrl(
                              Uri.parse(MaasgaContact.whatsAppDirectLink),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                          label: Text(
                            'Échanger directement sur WhatsApp',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B3A8D),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF25D366)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1.0, end: 0, duration: 300.ms);
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1F2937),
        ),
      ),
    );
  }
}

class _WhatsAppCTA extends StatelessWidget {
  const _WhatsAppCTA();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_outlined, color: Color(0xFF43A047)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Besoin d\'aide ou d\'un conseil ? Contactez-nous sur WhatsApp',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
          ElevatedButton(
            onPressed: () => launchUrl(
              Uri.parse(MaasgaContact.whatsAppDirectLink),
              mode: LaunchMode.externalApplication,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43A047),
            ),
            child: Text(
              'WhatsApp',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
