import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';

class MaintenanceRepository {
  MaintenanceRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> submitRequest(Map<String, dynamic> data) async {
    try {
      final payload = {
        'name': data['name'] ?? '',
        'phone': data['phone'] ?? '',
        'email': data['email'] ?? '',
        'quartier': data['quartier'] ?? '',
        'plan_type': (data['plan_type'] ?? data['formule'] ?? 'residentiel')
            .toString()
            .toLowerCase(),
        'nb_climatiseurs': data['nb_climatiseurs'] ?? 1,
        'frequence_visites': data['frequence_visites'] ?? 'Confort',
        'type_etablissement': data['type_etablissement'] ?? '',
        'exigences': data['exigences'] ?? '',
        'preferred_date': data['preferred_date'] ?? '',
        'payment_method': data['payment_method'] ?? 'a_confirmer',
        'request_type': data['request_type'] ?? 'contrat',
        'description': data['description'] ??
            'Souscription contrat maintenance ${data['plan_type'] ?? data['formule'] ?? ''}',
        'equipment_type': data['equipment_type'] ?? 'Split mural',
      };
      final response = await _dio.post(
        '/api/mobile/maintenance',
        data: payload,
      );
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) return responseData;
      return {'success': true};
    } on DioException catch (e) {
      final errData = e.response?.data;
      if (errData is Map<String, dynamic> && errData['error'] != null) {
        throw errData['error'].toString();
      }
      throw 'Une erreur est survenue lors de l\'envoi de votre demande.';
    } catch (e) {
      throw 'Erreur réseau. Veuillez réessayer.';
    }
  }
}

final maintenanceRepositoryProvider = FutureProvider<MaintenanceRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  return MaintenanceRepository(dio);
});
