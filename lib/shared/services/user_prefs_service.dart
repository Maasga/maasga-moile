import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service d'auto-remplissage des formulaires.
///
/// Priorité des données :
///   1. Firebase Auth (displayName, email, phoneNumber)
///   2. SharedPreferences (dernières valeurs saisies)
///
/// À appeler dans initState() de chaque écran avec formulaire.
class UserPrefsService {
  static const _keyName = 'maasga_pref_name';
  static const _keyPhone = 'maasga_pref_phone';
  static const _keyEmail = 'maasga_pref_email';
  static const _keyQuartier = 'maasga_pref_quartier';
  static const _keyPhotoUrl = 'maasga_pref_photo_url';

  final SharedPreferences _prefs;

  UserPrefsService(this._prefs);

  // ─── Lecture ──────────────────────────────────────────────────────────────

  String get savedName {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final fbName = firebaseUser?.displayName ?? '';
    return fbName.isNotEmpty ? fbName : (_prefs.getString(_keyName) ?? '');
  }

  String get savedPhone {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    // Firebase stocke parfois le numéro dans phoneNumber
    final fbPhone = firebaseUser?.phoneNumber ?? '';
    final stored = _prefs.getString(_keyPhone) ?? '';
    // Préférer la valeur stockée si elle est plus complète
    if (stored.isNotEmpty) return stored;
    if (fbPhone.isNotEmpty) return fbPhone;
    // Si l'email est synthétique (@maasga.app) on en extrait le numéro
    final email = firebaseUser?.email ?? '';
    if (email.endsWith('@maasga.app')) {
      return email.replaceAll('@maasga.app', '');
    }
    return '';
  }

  String get savedEmail {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final fbEmail = firebaseUser?.email ?? '';
    // Ne pas retourner les emails synthétiques (@maasga.app)
    if (fbEmail.isNotEmpty && !fbEmail.endsWith('@maasga.app')) {
      return fbEmail;
    }
    return _prefs.getString(_keyEmail) ?? '';
  }

  String get savedQuartier => _prefs.getString(_keyQuartier) ?? '';

  String get savedPhotoUrl {
    final stored = _prefs.getString(_keyPhotoUrl) ?? '';
    if (stored.isNotEmpty) return stored;
    return FirebaseAuth.instance.currentUser?.photoURL ?? '';
  }

  // ─── Écriture ─────────────────────────────────────────────────────────────

  Future<void> save({
    String? name,
    String? phone,
    String? email,
    String? quartier,
    String? photoUrl,
  }) async {
    if (name != null && name.isNotEmpty) await _prefs.setString(_keyName, name);
    if (phone != null && phone.isNotEmpty) {
      await _prefs.setString(_keyPhone, phone);
    }
    if (email != null && email.isNotEmpty && !email.endsWith('@maasga.app')) {
      await _prefs.setString(_keyEmail, email);
    }
    if (quartier != null && quartier.isNotEmpty) {
      await _prefs.setString(_keyQuartier, quartier);
    }
    if (photoUrl != null) {
      if (photoUrl.isEmpty) {
        await _prefs.remove(_keyPhotoUrl);
      } else {
        await _prefs.setString(_keyPhotoUrl, photoUrl);
      }
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_keyName);
    await _prefs.remove(_keyPhone);
    await _prefs.remove(_keyEmail);
    await _prefs.remove(_keyQuartier);
    await _prefs.remove(_keyPhotoUrl);
  }

  // ─── Activités locales (Commandes, RDV, Contrats) ─────────────────────────

  List<Map<String, dynamic>> getLocalOrders(String uid) {
    final raw = _prefs.getString('maasga_orders_$uid');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveLocalOrder(String uid, Map<String, dynamic> order) async {
    final list = getLocalOrders(uid);
    list.removeWhere((item) => item['id']?.toString() == order['id']?.toString());
    list.insert(0, order);
    await _prefs.setString('maasga_orders_$uid', jsonEncode(list));
  }

  List<Map<String, dynamic>> getLocalRdvs(String uid) {
    final raw = _prefs.getString('maasga_rdvs_$uid');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveLocalRdv(String uid, Map<String, dynamic> rdv) async {
    final list = getLocalRdvs(uid);
    list.removeWhere((item) => item['id']?.toString() == rdv['id']?.toString());
    list.insert(0, rdv);
    await _prefs.setString('maasga_rdvs_$uid', jsonEncode(list));
  }

  List<Map<String, dynamic>> getLocalContracts(String uid) {
    final raw = _prefs.getString('maasga_contracts_$uid');
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveLocalContract(
    String uid,
    Map<String, dynamic> contract,
  ) async {
    final list = getLocalContracts(uid);
    list.removeWhere(
      (item) => item['id']?.toString() == contract['id']?.toString(),
    );
    list.insert(0, contract);
    await _prefs.setString('maasga_contracts_$uid', jsonEncode(list));
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final userPrefsServiceProvider = FutureProvider<UserPrefsService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return UserPrefsService(prefs);
});

/// Provider synchrone pour les écrans qui utilisent initState
final userPrefsProvider = Provider<UserPrefsService?>((ref) {
  final async = ref.watch(userPrefsServiceProvider);
  return async.when(
    data: (service) => service,
    loading: () => null,
    error: (_, _) => null,
  );
});
