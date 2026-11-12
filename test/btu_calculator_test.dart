import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/simulator/services/btu_calculator.dart';

void main() {
  group('BtuCalculator', () {
    test('should calculate basic BTU correctly', () {
      final btu = BtuCalculator.calculate(
        surface: 20.0,
        height: 2.5,
        solarExposure: 'faible',
        windows: 0,
        roomType: 'chambre',
      );

      // Base: 20 * 350 = 7000
      // Height factor (2.5m): 1.0
      // Solar exposure (faible): 1.0
      // Windows (0): 0.97
      // Room type (chambre): 1.0
      // Tropical majoration: 1.12
      // Expected: 7000 * 1.0 * 1.0 * 0.97 * 1.0 * 1.12 = 7604.8
      expect(btu, closeTo(7604.8, 0.001));
    });

    test('should apply height factor correctly', () {
      final btuLow = BtuCalculator.calculate(
        surface: 20.0,
        height: 2.5,
        solarExposure: 'faible',
        windows: 0,
        roomType: 'chambre',
      );

      final btuHigh = BtuCalculator.calculate(
        surface: 20.0,
        height: 3.5,
        solarExposure: 'faible',
        windows: 0,
        roomType: 'chambre',
      );

      // Height 2.5m: factor 1.0
      // Height 3.5m: factor 1.25
      // Difference should be 25% increase
      expect(btuHigh, closeTo(btuLow * 1.25, 0.001));
    });

    test('should apply solar exposure factor correctly', () {
      final btuFaible = BtuCalculator.calculate(
        surface: 20.0,
        height: 2.5,
        solarExposure: 'faible',
        windows: 0,
        roomType: 'chambre',
      );

      final btuForte = BtuCalculator.calculate(
        surface: 20.0,
        height: 2.5,
        solarExposure: 'forte',
        windows: 0,
        roomType: 'chambre',
      );

      // Solar exposure faible: factor 1.0
      // Solar exposure forte: factor 1.2
      // Difference should be 20% increase
      expect(btuForte, closeTo(btuFaible * 1.2, 0.001));
    });

    test('should apply windows factor correctly', () {
      final btuZero = BtuCalculator.calculate(
        surface: 20.0,
        height: 2.5,
        solarExposure: 'faible',
        windows: 0,
        roomType: 'chambre',
      );

      final btuThree = BtuCalculator.calculate(
        surface: 20.0,
        height: 2.5,
        solarExposure: 'faible',
        windows: 3,
        roomType: 'chambre',
      );

      // Windows 0: factor 0.97
      // Windows 3+: factor 1.18
      expect(btuThree, closeTo(btuZero / 0.97 * 1.18, 0.001));
    });

    test('should apply room type factor correctly', () {
      final btuChambre = BtuCalculator.calculate(
        surface: 20.0,
        height: 2.5,
        solarExposure: 'faible',
        windows: 0,
        roomType: 'chambre',
      );

      final btuCuisine = BtuCalculator.calculate(
        surface: 20.0,
        height: 2.5,
        solarExposure: 'faible',
        windows: 0,
        roomType: 'cuisine',
      );

      // Chambre: factor 1.0
      // Cuisine: factor 1.25
      // Difference should be 25% increase
      expect(btuCuisine, closeTo(btuChambre * 1.25, 0.001));
    });

    test('should apply all factors cumulatively', () {
      final btu = BtuCalculator.calculate(
        surface: 30.0,
        height: 3.0,
        solarExposure: 'forte',
        windows: 2,
        roomType: 'salon',
      );

      // Base: 30 * 350 = 10500
      // Height factor (3.0m): 1.15
      // Solar exposure (forte): 1.20
      // Windows (2): 1.12
      // Room type (salon): 1.10
      // Tropical majoration: 1.12
      // Expected: 10500 * 1.15 * 1.2 * 1.12 * 1.10 * 1.12
      final expected = 10500 * 1.15 * 1.2 * 1.12 * 1.10 * 1.12;
      expect(btu, closeTo(expected, 0.001));
    });
  });

  group('BtuCalculator.getCvRecommendation', () {
    test('should return correct CV for low BTU', () {
      expect(BtuCalculator.getCvRecommendation(8000), '1 CV');
      expect(BtuCalculator.getCvRecommendation(9000), '1 CV');
    });

    test('should return correct CV for medium BTU', () {
      expect(BtuCalculator.getCvRecommendation(10000), '1,5 CV');
      expect(BtuCalculator.getCvRecommendation(12000), '1,5 CV');
    });

    test('should return correct CV for high BTU', () {
      expect(BtuCalculator.getCvRecommendation(15000), '2 CV');
      expect(BtuCalculator.getCvRecommendation(18000), '2 CV');
    });

    test('should return correct CV for very high BTU', () {
      expect(BtuCalculator.getCvRecommendation(20000), '3 CV');
      expect(BtuCalculator.getCvRecommendation(24000), '3 CV');
    });

    test('should return correct CV for extremely high BTU', () {
      expect(BtuCalculator.getCvRecommendation(25000), '5 CV');
      expect(BtuCalculator.getCvRecommendation(30000), '5 CV');
    });
  });

  group('BtuCalculator.getCommercialBtu', () {
    test('should return correct commercial BTU for low BTU', () {
      expect(BtuCalculator.getCommercialBtu(8000), 9000);
      expect(BtuCalculator.getCommercialBtu(9000), 9000);
    });

    test('should return correct commercial BTU for medium BTU', () {
      expect(BtuCalculator.getCommercialBtu(10000), 12000);
      expect(BtuCalculator.getCommercialBtu(12000), 12000);
    });

    test('should return correct commercial BTU for high BTU', () {
      expect(BtuCalculator.getCommercialBtu(15000), 18000);
      expect(BtuCalculator.getCommercialBtu(18000), 18000);
    });

    test('should return correct commercial BTU for very high BTU', () {
      expect(BtuCalculator.getCommercialBtu(20000), 24000);
      expect(BtuCalculator.getCommercialBtu(24000), 24000);
    });

    test('should return correct commercial BTU for extremely high BTU', () {
      expect(BtuCalculator.getCommercialBtu(25000), 36000);
      expect(BtuCalculator.getCommercialBtu(30000), 36000);
    });
  });

  group('BtuCalculator.getPowerKey', () {
    test('should return correct power key for low BTU', () {
      expect(BtuCalculator.getPowerKey(8000), '1cv');
      expect(BtuCalculator.getPowerKey(9000), '1cv');
    });

    test('should return correct power key for medium BTU', () {
      expect(BtuCalculator.getPowerKey(10000), '1.5cv');
      expect(BtuCalculator.getPowerKey(12000), '1.5cv');
    });

    test('should return correct power key for high BTU', () {
      expect(BtuCalculator.getPowerKey(15000), '2cv');
      expect(BtuCalculator.getPowerKey(18000), '2cv');
    });

    test('should return correct power key for very high BTU', () {
      expect(BtuCalculator.getPowerKey(20000), '3cv');
      expect(BtuCalculator.getPowerKey(24000), '3cv');
    });

    test('should return correct power key for extremely high BTU', () {
      expect(BtuCalculator.getPowerKey(25000), '5cv');
      expect(BtuCalculator.getPowerKey(30000), '5cv');
    });
  });
}
