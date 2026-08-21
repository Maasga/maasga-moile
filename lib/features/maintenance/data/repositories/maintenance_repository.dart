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
        'plan_type': data['plan_type'] ?? 'semestriel',
        'payment_method': data['payment_method'] ?? 'a_confirmer',
        'request_type': 'contrat',
        'description':
            'Souscription contrat maintenance - ${data['plan_type'] ?? ''}',
        'equipment_type': 'Split mural',
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
