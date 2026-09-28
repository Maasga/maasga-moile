import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/auth/data/auth_repository.dart';

void main() {
  group('AuthRepository - Phone Validation', () {
    test('should validate valid Burkinabe phone numbers', () {
      expect(AuthRepository.isValidPhone('70123456'), isTrue);
      expect(AuthRepository.isValidPhone('70 12 34 56'), isTrue);
      expect(AuthRepository.isValidPhone('70-12-34-56'), isTrue);
      expect(AuthRepository.isValidPhone('+22670123456'), isTrue);
      expect(AuthRepository.isValidPhone('+226 70 12 34 56'), isTrue);
      expect(AuthRepository.isValidPhone('22670123456'), isTrue);
      expect(AuthRepository.isValidPhone('226 70 12 34 56'), isTrue);
    });

    test('should reject invalid phone numbers', () {
      expect(AuthRepository.isValidPhone('1234567'), isFalse); // Too short
      expect(AuthRepository.isValidPhone('123456789'), isFalse); // Too long
      expect(AuthRepository.isValidPhone('7012345'), isFalse); // Too short
      expect(AuthRepository.isValidPhone('abcdefgh'), isFalse); // Not digits
      expect(
        AuthRepository.isValidPhone('+2267012345'),
        isFalse,
      ); // Missing digit
      expect(
        AuthRepository.isValidPhone('+226701234567'),
        isFalse,
      ); // Extra digit
      expect(AuthRepository.isValidPhone(''), isFalse); // Empty
      expect(AuthRepository.isValidPhone('+226'), isFalse); // Only prefix
    });
  });

  group('AuthRepository - Synthetic Email', () {
    test('should detect synthetic emails correctly', () {
      expect(
        AuthRepository.isSyntheticEmail('+22670123456@maasga.app'),
        isTrue,
      );
      expect(
        AuthRepository.isSyntheticEmail('+22670123456@maasga.app'),
        isTrue,
      );
      expect(AuthRepository.isSyntheticEmail('test@maasga.app'), isTrue);
      expect(
        AuthRepository.isSyntheticEmail('TEST@MAASGA.APP'),
        isTrue,
      ); // Case insensitive

      expect(AuthRepository.isSyntheticEmail('test@other.com'), isFalse);
      expect(
        AuthRepository.isSyntheticEmail('test@maasgaapp'),
        isFalse,
      ); // Missing dot
      expect(
        AuthRepository.isSyntheticEmail('test@maasga.'),
        isFalse,
      ); // Empty domain
      expect(AuthRepository.isSyntheticEmail(''), isFalse); // Empty
    });
  });
}
