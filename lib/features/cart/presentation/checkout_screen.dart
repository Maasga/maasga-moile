import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/services/user_prefs_service.dart';
import '../../../shared/widgets/maasga_primary_button.dart';
import '../../../shared/widgets/maasga_shell.dart';
import '../../client_space/data/client_dashboard_repository.dart';
import '../../rdv/domain/neighborhoods.dart';
import 'cart_state.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _quartierCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  // Location state
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _preciseAddress;
  Set<Marker> _markers = {};
  final LatLng _initialPos = const LatLng(12.3647, -1.5335); // Ouagadougou

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillUserInfo());
  }

  void _prefillUserInfo() async {
    // 1. Essayer depuis le dashboard client (données D1)
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
            if (_quartierCtrl.text.isEmpty && profile.quartier.isNotEmpty) {
              _quartierCtrl.text = profile.quartier;
            }
          });
        }
        return;
      }
    } catch (_) {}

    // 2. Fallback : UserPrefsService (Firebase Auth + SharedPreferences)
    try {
      final prefs = ref.read(userPrefsProvider);
      if (prefs != null && mounted) {
        setState(() {
          if (_nameCtrl.text.isEmpty) _nameCtrl.text = prefs.savedName;
          if (_phoneCtrl.text.isEmpty) _phoneCtrl.text = prefs.savedPhone;
          if (_quartierCtrl.text.isEmpty) {
            _quartierCtrl.text = prefs.savedQuartier;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _quartierCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _showQuartierPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuartierSearchDialog(
        currentSelection: _quartierCtrl.text,
        onSelected: (val) {
          setState(() => _quartierCtrl.text = val);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _updateLocation(LatLng pos) async {
    setState(() {
      _selectedLocation = pos;
      _markers = {
        Marker(
          markerId: const MarkerId('order_pos'),
          position: pos,
          draggable: true,
          onDragEnd: _updateLocation,
        ),
      };
    });

    try {
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _preciseAddress = '${p.street}, ${p.subLocality}, ${p.locality}';
        });
      }
    } catch (_) {}
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service de localisation désactivé')),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition();
    final latLng = LatLng(position.latitude, position.longitude);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
    _updateLocation(latLng);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return MaasgaShell(
      title: 'Validation Commande',
      showDrawer: false,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Informations personnelles ──────────────────────────────
          _buildSectionHeader(
            icon: Icons.person_outline,
            title: 'Vos informations',
          ),
          const SizedBox(height: 12),

          _buildLabel('Nom complet *'),
          TextField(
            controller: _nameCtrl,
            decoration: _buildInputDecoration(
              'Votre nom',
              Icons.person_outline,
            ),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),

          _buildLabel('Téléphone *'),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: _buildInputDecoration(
              'XX XX XX XX',
              Icons.phone_outlined,
            ),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 24),

          // ── Adresse de livraison ───────────────────────────────────
          _buildSectionHeader(
            icon: Icons.location_on_outlined,
            title: 'Adresse de livraison',
          ),
          const SizedBox(height: 12),

          _buildLabel('Quartier (Ouagadougou) *'),
          InkWell(
            onTap: _showQuartierPicker,
            child: IgnorePointer(
              child: TextField(
                controller: _quartierCtrl,
                decoration:
                    _buildInputDecoration(
                      'Sélectionner votre quartier',
                      Icons.location_city_outlined,
                    ).copyWith(
                      suffixIcon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF1B3A8D),
                      ),
                    ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildLabel('Localisation précise (optionnel)'),
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD8EAFB)),
            ),
            clipBehavior: Clip.antiAlias,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPos,
                zoom: 12,
              ),
              onMapCreated: (c) => _mapController = c,
              onTap: _updateLocation,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(Icons.my_location, color: Color(0xFF1B3A8D), size: 18),
              TextButton(
                onPressed: _getCurrentLocation,
                child: Text(
                  'Me localiser automatiquement',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1B3A8D),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          if (_preciseAddress != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF1B3A8D),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _preciseAddress!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF1B3A8D),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // ── Notes supplémentaires ──────────────────────────────────
          _buildSectionHeader(
            icon: Icons.notes_outlined,
            title: 'Notes (optionnel)',
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Instructions spéciales, informations complémentaires...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD8EAFB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1B3A8D),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1A1A1A),
            ),
          ),

          const SizedBox(height: 24),

          // ── Comment vous serez contacté ────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD8EAFB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF1B3A8D),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Comment ça marche ?',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B3A8D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildStep(
                  number: '1',
                  text: 'Vous confirmez votre commande ci-dessous.',
                ),
                _buildStep(
                  number: '2',
                  text:
                      'L\'équipe MAASGA vous contacte par e-mail et WhatsApp pour finaliser les détails.',
                ),
                _buildStep(
                  number: '3',
                  text:
                      'Le paiement et la livraison sont arrangés directement avec vous.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Récapitulatif du total ─────────────────────────────────
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFF0F0F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total estimé',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF757575),
                    ),
                  ),
                  Text(
                    '$total FCFA',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B3A8D),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          MaasgaPrimaryButton(
            label: _loading ? 'Envoi en cours...' : 'Confirmer ma commande',
            enabled: cart.isNotEmpty && !_loading,
            onPressed: () => _submitOrder(context, ref, cart),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1B3A8D), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildStep({required String number, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF1B3A8D),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF475467),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: const Color(0xFF6B7280),
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF1B3A8D), size: 20),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8EAFB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1B3A8D), width: 1.5),
      ),
    );
  }

  Future<void> _submitOrder(
    BuildContext context,
    WidgetRef ref,
    List<CartLine> lines,
  ) async {
    if (_nameCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _quartierCtrl.text.isEmpty) {
      setState(() => _error = 'Veuillez remplir les champs obligatoires (*).');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = await ref.read(dioProvider.future);
      final quantity = lines.fold<int>(0, (sum, line) => sum + line.quantity);
      final total = ref.read(cartTotalProvider);

      // Détail ligne par ligne. Indispensable : `product_id` seul perdait tout
      // le contenu d'un panier multi-articles (il valait même `null` dès qu'il
      // y avait plus d'un produit, laissant le serveur sans savoir quoi livrer).
      //
      // `unit_price` est transmis pour que le serveur puisse RECALCULER le
      // total à partir de ses propres prix : `total_price` ci-dessous vient du
      // client et ne doit jamais être considéré comme la source de vérité
      // (un client modifié pourrait annoncer 1 FCFA). La vérification côté
      // worker `/api/mobile/commandes` reste à faire.
      final items = lines
          .map(
            (line) => {
              'product_id': line.product.id,
              'name': line.product.name,
              'quantity': line.quantity,
              'unit_price': line.product.price,
              'line_total': line.total,
            },
          )
          .toList();

      final response = await dio.post(
        '/api/mobile/commandes',
        data: {
          'client_name': _nameCtrl.text.trim(),
          'client_phone': _phoneCtrl.text.trim(),
          'quartier': _quartierCtrl.text.trim(),
          'items': items,
          // Conservés pour compatibilité avec la version actuelle du worker.
          'product_id': lines.isNotEmpty ? lines.first.product.id : null,
          'quantity': quantity,
          'total_price': total,
          'latitude': _selectedLocation?.latitude,
          'longitude': _selectedLocation?.longitude,
          'adresse_precise': _preciseAddress,
          'notes': _notesCtrl.text.trim().isEmpty
              ? null
              : _notesCtrl.text.trim(),
        },
      );

      final resData = response.data as Map<String, dynamic>? ?? const {};
      final orderId = resData['orderId'] ?? resData['id'];

      if (!context.mounted) return;

      // Sauvegarder pour auto-remplissage futur
      final prefs = ref.read(userPrefsProvider);
      await prefs?.save(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        quartier: _quartierCtrl.text.trim(),
      );

      // Invalider le dashboard pour rafraîchir la liste des commandes
      ref.invalidate(clientDashboardProvider);
      ref.read(cartProvider.notifier).clear();

      // Re-vérifié : le `await prefs?.save` ci-dessus a pu démonter l'écran
      // depuis la garde de la ligne 627. La commande est déjà enregistrée et
      // le panier vidé, il ne reste que la navigation à abandonner.
      if (!context.mounted) return;

      // Rediriger vers l'écran de confirmation avec les infos utiles
      context.go(
        '/order-confirmation',
        extra: {
          'orderId': orderId?.toString() ?? '',
          'clientName': _nameCtrl.text.trim(),
          'clientPhone': _phoneCtrl.text.trim(),
          'total': total,
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Erreur lors de l\'envoi de la commande : $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Sélecteur de quartier ──────────────────────────────────────────────────

class _QuartierSearchDialog extends StatefulWidget {
  final String currentSelection;
  final Function(String) onSelected;

  const _QuartierSearchDialog({
    required this.currentSelection,
    required this.onSelected,
  });

  @override
  State<_QuartierSearchDialog> createState() => _QuartierSearchDialogState();
}

class _QuartierSearchDialogState extends State<_QuartierSearchDialog> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = ouagaNeighborhoods
        .where((q) => q.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
          const SizedBox(height: 20),
          Text(
            'Choisir un quartier',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Rechercher un quartier...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final q = filtered[index];
                final isSelected = q == widget.currentSelection;
                return ListTile(
                  title: Text(
                    q,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isSelected
                          ? const Color(0xFF1B3A8D)
                          : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF1B3A8D))
                      : null,
                  onTap: () => widget.onSelected(q),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
