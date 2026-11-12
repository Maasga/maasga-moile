import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/design_tokens/maasga_tokens.dart';
import '../../../shared/widgets/main_bottom_nav.dart';
import '../../../shared/widgets/maasga_app_bar.dart';
import '../../../shared/services/user_prefs_service.dart';
import '../../auth/data/auth_repository.dart';
import '../../client_space/data/client_dashboard_repository.dart';
import '../../notifications/data/activity_repository.dart';
import '../data/rdv_repository.dart';
import '../domain/rdv_request.dart';
import 'widgets/rdv_confirmation_step.dart';
import 'widgets/rdv_form_step.dart';
import 'widgets/service_type_card.dart';
import 'widgets/step_indicator.dart';

class RdvScreen extends ConsumerStatefulWidget {
  const RdvScreen({super.key});

  @override
  ConsumerState<RdvScreen> createState() => _RdvScreenState();
}

class _RdvScreenState extends ConsumerState<RdvScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1 Data
  String? _selectedServiceType;

  // Step 2 Data
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedQuartier;
  String? _selectedAddress;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isConsented = false;

  // Global State
  bool _isLoading = false;
  RdvRequest? _completedRequest;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    // 1. Depuis le dashboard client si disponible
    try {
      final dashboard = ref.read(clientDashboardProvider);
      if (dashboard.hasValue) {
        final profile = dashboard.value!.profile;
        if (mounted) {
          setState(() {
            if (_nameCtrl.text.isEmpty && profile.fullName.isNotEmpty) {
              _nameCtrl.text = profile.fullName;
            }
            if (_phoneCtrl.text.isEmpty && profile.phone.isNotEmpty) {
              _phoneCtrl.text = profile.phone;
            }
            if (_emailCtrl.text.isEmpty && profile.email.isNotEmpty) {
              _emailCtrl.text = profile.email;
            }
            _selectedQuartier ??= profile.quartier.isNotEmpty
                ? profile.quartier
                : null;
          });
          return;
        }
      }
    } catch (_) {}

    // 2. Depuis Firebase Auth + SharedPreferences
    try {
      final prefs = ref.read(userPrefsProvider);
      final repo = ref.read(authRepositoryProvider);
      final firebaseProfile = await repo.getProfile();
      if (mounted) {
        setState(() {
          if (_nameCtrl.text.isEmpty) {
            _nameCtrl.text =
                prefs?.savedName ?? firebaseProfile?['name']?.toString() ?? '';
          }
          if (_phoneCtrl.text.isEmpty) {
            _phoneCtrl.text =
                prefs?.savedPhone ??
                firebaseProfile?['phone']?.toString() ??
                '';
          }
          if (_emailCtrl.text.isEmpty) {
            _emailCtrl.text =
                prefs?.savedEmail ??
                firebaseProfile?['email']?.toString() ??
                '';
          }
          _selectedQuartier ??= prefs?.savedQuartier.isNotEmpty == true
              ? prefs!.savedQuartier
              : null;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitDemande() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date')),
      );
      return;
    }
    if (!_isConsented) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez accepter les conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    final dashboardData = ref.read(clientDashboardProvider).asData?.value;
    final clientId = dashboardData?.profile.id;
    final rawPhone = _phoneCtrl.text.trim();
    final normalizedPhone = rawPhone.startsWith('+226')
        ? rawPhone
        : rawPhone.startsWith('226')
            ? '+$rawPhone'
            : '+226$rawPhone';

    final request = RdvRequest(
      serviceType: _selectedServiceType!,
      fullName: _nameCtrl.text.trim(),
      phone: normalizedPhone,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      quartier: _selectedQuartier!,
      address: _selectedAddress,
      date: _selectedDate!,
      startTime: _startTime,
      endTime: _endTime,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      consented: _isConsented,
      clientId: clientId,
      userId: user?.uid,
    );

    try {
      final repo = await ref.read(rdvRepositoryProvider.future);
      await repo.submitRdv(request);

      // Sauvegarder pour auto-remplissage futur
      final prefs = ref.read(userPrefsProvider);
      if (prefs != null) {
        await prefs.save(
          name: request.fullName,
          phone: request.phone,
          email: request.email,
          quartier: request.quartier,
        );

        // Sauvegarde locale de l'activité pour affichage immédiat dans l'espace client
        if (user != null) {
          final timeStr = request.startTime != null
              ? '${request.startTime!.hour.toString().padLeft(2, '0')}:${request.startTime!.minute.toString().padLeft(2, '0')}'
              : '';
          final dateStr = request.date.toIso8601String().split('T')[0];
          final rdvMap = {
            'id': 'rdv_${DateTime.now().millisecondsSinceEpoch}',
            'type': request.serviceType,
            'service_type': request.serviceType,
            'date': timeStr.isNotEmpty ? '$dateStr, $timeStr' : dateStr,
            'status': 'En attente',
            'statut': 'En attente',
            'quartier': request.quartier,
            'address': request.address,
            'notes': request.notes,
            'client_name': request.fullName,
            'name': request.fullName,
            'client_phone': request.phone,
            'phone': request.phone,
            'created_at': DateTime.now().toIso8601String(),
          };
          await prefs.saveLocalRdv(user.uid, rdvMap);
        }
      }

      // Invalider les fournisseurs pour rafraîchir les données dans l'espace client
      ref.invalidate(clientDashboardProvider);
      ref.invalidate(userActivityProvider);

      setState(() {
        _completedRequest = request;
        _isLoading = false;
      });
      _nextPage();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.maasga.pageGradient.colors.first,
      resizeToAvoidBottomInset: false,
      appBar: MaasgaAppBar(
        notificationsCount: ref.watch(unreadNotificationCountProvider),
      ),
      body: Column(
        children: [
          StepIndicator(currentStep: _currentStep),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentStep = idx),
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),
          if (_currentStep < 2) _buildFooter(),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(),
    );
  }

  Widget _buildStep1() {
    final types = [
      (
        icon: Icons.design_services_outlined,
        title: 'Devis / Dimensionnement',
        desc: 'Un technicien visite votre espace et vous fait un devis précis',
      ),
      (
        icon: Icons.construction_outlined,
        title: 'Installation',
        desc: 'Pose professionnelle de votre climatiseur par nos experts',
      ),
      (
        icon: Icons.build_circle_outlined,
        title: 'Maintenance / Entretien',
        desc: 'Nettoyage et vérification de votre climatiseur existant',
      ),
      (
        icon: Icons.warning_amber_outlined,
        title: 'Dépannage / Réparation urgente',
        desc: 'Intervention rapide pour panne ou dysfonctionnement',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Choisissez votre service',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.maasga.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...types.map(
          (type) => ServiceTypeCard(
            icon: type.icon,
            title: type.title,
            description: type.desc,
            isSelected: _selectedServiceType == type.title,
            onTap: () => setState(() => _selectedServiceType = type.title),
          ),
        ),

        // ── Accès aux contrats de maintenance ──────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Divider(color: context.maasga.divider),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'Contrats & Abonnements',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.maasga.textMuted,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/maintenance'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.maasga.infoSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.maasga.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.maasga.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.verified_user_outlined,
                      color: context.maasga.accent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contrat de maintenance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.maasga.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Souscrivez à un abonnement entretien annuel ou semestriel',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.maasga.textMuted,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: context.maasga.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return RdvFormStep(
      selectedServiceType: _selectedServiceType ?? 'Service non sélectionné',
      onBack: _previousPage,
      formKey: _formKey,
      nameCtrl: _nameCtrl,
      phoneCtrl: _phoneCtrl,
      emailCtrl: _emailCtrl,
      notesCtrl: _notesCtrl,
      selectedQuartier: _selectedQuartier,
      onQuartierChanged: (val) => setState(() => _selectedQuartier = val),
      selectedDate: _selectedDate,
      onDateChanged: (val) => setState(() => _selectedDate = val),
      startTime: _startTime,
      endTime: _endTime,
      onTimeChanged: (val, isStart) => setState(() {
        if (isStart) {
          _startTime = val;
        } else {
          _endTime = val;
        }
      }),
      isConsented: _isConsented,
      address: _selectedAddress,
      onAddressChanged: (val) => setState(() => _selectedAddress = val),
      onConsentChanged: (val) => setState(() => _isConsented = val ?? false),
    );
  }

  Widget _buildStep3() {
    if (_completedRequest == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RdvConfirmationStep(
      request: _completedRequest!,
      onGoToMyRdv: () => context.go('/client-space'),
    );
  }

  Widget _buildFooter() {
    final palette = context.maasga;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.card,
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _currentStep == 0
            ? ElevatedButton(
                onPressed: _selectedServiceType != null ? _nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.maasga.accent,
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continuer',
                  style: GoogleFonts.poppins(
                    color: _selectedServiceType != null
                        ? Colors.white
                        : const Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    flex: 35,
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: context.maasga.accent),
                      ),
                      child: Text(
                        'Retour',
                        style: GoogleFonts.poppins(
                          color: context.maasga.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 65,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitDemande,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.maasga.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Confirmer ma demande',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
