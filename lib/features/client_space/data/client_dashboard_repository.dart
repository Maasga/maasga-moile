import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/session/session_providers.dart';
import '../../../shared/services/user_prefs_service.dart';
import '../domain/commande.dart';
import '../domain/contrat_maintenance.dart';
import '../domain/rendez_vous.dart';
import '../domain/user_profile.dart';

class ClientDashboardData {
  ClientDashboardData({
    required this.profile,
    required this.orders,
    required this.rdvs,
    required this.maintenanceContracts,
    required this.freeMaintenances,
    required this.payments,
  });

  final UserProfile profile;
  final List<Commande> orders;
  final List<RendezVous> rdvs;
  final List<ContratMaintenance> maintenanceContracts;
  final List<dynamic> freeMaintenances;
  final List<dynamic> payments;
}

class ClientDashboardRepository {
  ClientDashboardRepository(this._dio, [this._userPrefsService]);
  final Dio _dio;
  final UserPrefsService? _userPrefsService;

  Future<ClientDashboardData> fetchDashboard() async {
    final response = await _dio.get('/api/mobile/client-dashboard');
    final data = response.data as Map<String, dynamic>? ?? const {};

    final clientMap =
        (data['client'] ?? data['profile'] ?? data['user']) as Map?;
    var profile = UserProfile.fromJson(
      clientMap?.cast<String, dynamic>() ?? {},
    );

    // Fallback avec les préférences sauvegardées localement et Firebase
    final savedName = _userPrefsService?.savedName;
    final savedPhone = _userPrefsService?.savedPhone;
    final savedEmail = _userPrefsService?.savedEmail;
    final savedQuartier = _userPrefsService?.savedQuartier;
    final savedPhotoUrl = _userPrefsService?.savedPhotoUrl;

    profile = profile.copyWith(
      fullName: (profile.fullName.isEmpty || profile.fullName == 'Client MAASGA') &&
              (savedName != null && savedName.isNotEmpty)
          ? savedName
          : null,
      phone: profile.phone.isEmpty && (savedPhone != null && savedPhone.isNotEmpty)
          ? savedPhone
          : null,
      email: profile.email.isEmpty && (savedEmail != null && savedEmail.isNotEmpty)
          ? savedEmail
          : null,
      quartier: (profile.quartier.isEmpty || profile.quartier == 'Ouagadougou') &&
              (savedQuartier != null && savedQuartier.isNotEmpty)
          ? savedQuartier
          : null,
      photoUrl: (profile.photoUrl == null || profile.photoUrl!.isEmpty) &&
              (savedPhotoUrl != null && savedPhotoUrl.isNotEmpty)
          ? savedPhotoUrl
          : null,
    );

    // Commandes backend
    final rawOrders =
        (data['orders'] ?? data['commandes'] ?? data['orders_list'])
            as List<dynamic>? ??
        [];
    final List<Commande> orders = [];
    final Set<String> knownOrderIds = {};

    for (final item in rawOrders) {
      if (item is Map) {
        try {
          final c = Commande.fromJson(item.cast<String, dynamic>());
          orders.add(c);
          if (c.id.isNotEmpty) knownOrderIds.add(c.id);
        } catch (e) {
          if (kDebugMode) debugPrint('Erreur parsing Commande: $e');
        }
      }
    }

    // RDVs backend
    final rawRdvs =
        (data['rdvs'] ??
                data['rendez_vous'] ??
                data['rendezvous'] ??
                data['appointments'])
            as List<dynamic>? ??
        [];
    final List<RendezVous> rdvs = [];
    final Set<String> knownRdvIds = {};

    for (final item in rawRdvs) {
      if (item is Map) {
        try {
          final r = RendezVous.fromJson(item.cast<String, dynamic>());
          rdvs.add(r);
          if (r.id.isNotEmpty) knownRdvIds.add(r.id);
        } catch (e) {
          if (kDebugMode) debugPrint('Erreur parsing RendezVous: $e');
        }
      }
    }

    // Contrats backend
    final rawContracts =
        (data['maintenanceContracts'] ??
                data['maintenance_contracts'] ??
                data['contrats'] ??
                data['contracts'] ??
                data['maintenances'])
            as List<dynamic>? ??
        [];
    final List<ContratMaintenance> contracts = [];
    final Set<String> knownContractIds = {};

    for (final item in rawContracts) {
      if (item is Map) {
        try {
          final cm = ContratMaintenance.fromJson(item.cast<String, dynamic>());
          contracts.add(cm);
          if (cm.id.isNotEmpty) knownContractIds.add(cm.id);
        } catch (e) {
          if (kDebugMode) debugPrint('Erreur parsing ContratMaintenance: $e');
        }
      }
    }

    // Fusion avec les activités enregistrées localement
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _userPrefsService != null) {
        final localOrders = _userPrefsService.getLocalOrders(user.uid);
        for (final lo in localOrders) {
          final id = lo['id']?.toString() ?? '';
          if (id.isEmpty || !knownOrderIds.contains(id)) {
            orders.add(Commande.fromJson(lo));
            if (id.isNotEmpty) knownOrderIds.add(id);
          }
        }

        final localRdvs = _userPrefsService.getLocalRdvs(user.uid);
        for (final lr in localRdvs) {
          final id = lr['id']?.toString() ?? '';
          if (id.isEmpty || !knownRdvIds.contains(id)) {
            rdvs.add(RendezVous.fromJson(lr));
            if (id.isNotEmpty) knownRdvIds.add(id);
          }
        }

        final localContracts = _userPrefsService.getLocalContracts(user.uid);
        for (final lc in localContracts) {
          final id = lc['id']?.toString() ?? '';
          if (id.isEmpty || !knownContractIds.contains(id)) {
            contracts.add(ContratMaintenance.fromJson(lc));
            if (id.isNotEmpty) knownContractIds.add(id);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur fusion activités locales: $e');
    }

    return ClientDashboardData(
      profile: profile,
      orders: orders,
      rdvs: rdvs,
      maintenanceContracts: contracts,
      freeMaintenances:
          (data['freeMaintenances'] ??
                  data['free_maintenances'] ??
                  data['maintenances_gratuites'])
              as List<dynamic>? ??
          [],
      payments:
          (data['payments'] ?? data['paiements']) as List<dynamic>? ?? const [],
    );
  }

  Future<void> updateProfile({
    String? name,
    String? quartier,
    String? phone,
    String? email,
    String? photoUrl,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (quartier != null) body['quartier'] = quartier;
    if (phone != null) body['phone'] = phone;
    if (email != null) body['email'] = email;
    if (photoUrl != null) {
      body['photo_url'] = photoUrl;
      body['photoUrl'] = photoUrl;
    }

    try {
      await _dio.patch('/api/mobile/profile', data: body);
    } catch (e) {
      debugPrint('updateProfile backend PATCH warning: $e');
    }

    // Sauvegarde locale systématique
    await _userPrefsService?.save(
      name: name,
      phone: phone,
      email: email,
      quartier: quartier,
      photoUrl: photoUrl,
    );

    // Mise à jour de Firebase Auth si applicable
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      if (name != null && name.isNotEmpty) {
        try {
          await fbUser.updateDisplayName(name);
        } catch (_) {}
      }
      if (photoUrl != null &&
          photoUrl.isNotEmpty &&
          (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'))) {
        try {
          await fbUser.updatePhotoURL(photoUrl);
        } catch (_) {}
      }
    }
  }

  Future<void> handleDevisAction(
    String orderId,
    String action, {
    String? reason,
  }) async {
    await _dio.post(
      '/api/mobile/order/$orderId/devis-action',
      data: {'action': action, 'reason': reason},
    );
  }

  Future<void> cancelOrder(String orderId) async {
    await _dio.post('/api/mobile/commandes/$orderId/annuler');
  }
}

final clientDashboardRepositoryProvider =
    FutureProvider<ClientDashboardRepository>((ref) async {
      final dio = await ref.watch(dioProvider.future);
      final userPrefs = await ref.watch(userPrefsServiceProvider.future);
      return ClientDashboardRepository(dio, userPrefs);
    });

/// Tableau de bord du client connecté (profil, commandes, RDV, contrats).
///
/// `watch(currentUserIdProvider)` lie ce cache au compte courant. Sans lui, le
/// provider n'étant pas `autoDispose`, la réponse du premier utilisateur reste
/// en mémoire et s'affiche telle quelle après une reconnexion sur un autre
/// compte.
final clientDashboardProvider = FutureProvider<ClientDashboardData>((
  ref,
) async {
  ref.watch(currentUserIdProvider);
  final repo = await ref.watch(clientDashboardRepositoryProvider.future);
  return repo.fetchDashboard();
});
