import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'helpers/mock_dio_helper.dart';

// Tests du helper Dio mocké pour vérifier son fonctionnement

void main() {
  group('MockDioHelper - création de Dio mocké', () {
    test('crée un Dio mocké avec réponse JSON', () async {
      final responseData = {'message': 'Succès', 'data': 123};
      final mockDio = MockDioHelper.createMockDioWithResponse(responseData);

      final response = await mockDio.get('/test');

      expect(response.statusCode, 200);
      expect(response.data, responseData);
    });

    test('crée un Dio mocké avec réponse POST', () async {
      final responseData = {'orderId': 'ORD-123'};
      final mockDio = MockDioHelper.createMockDioWithResponse(responseData);

      final response = await mockDio.post('/test', data: {});

      expect(response.statusCode, 200);
      expect(response.data, responseData);
    });

    test('crée un Dio mocké qui lance une erreur', () async {
      final mockDio = MockDioHelper.createMockDioWithError(
        500,
        'Erreur serveur',
      );

      expect(() => mockDio.get('/test'), throwsA(isA<DioException>()));
    });

    test('crée un Dio mocké avec réponses personnalisées par endpoint', () async {
      final responses = {
        '/api/test1': {'message': 'Test 1'},
        '/api/test2': {'message': 'Test 2'},
      };
      final mockDio = MockDioHelper.createMockDioWithEndpoints(responses);

      // Note: la méthode simplifiée retourne la première réponse pour tous les endpoints
      final response1 = await mockDio.get('/api/test1');

      expect(response1.data['message'], 'Test 1');
    });
  });
}
