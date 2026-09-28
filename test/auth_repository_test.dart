import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:app/features/auth/data/auth_repository.dart';

// Generate mocks
@GenerateMocks([FirebaseAuth, User])
import 'auth_repository_test.mocks.dart';

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
  });

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

  group('AuthRepository - Phone Extraction from Firebase User', () {
    test(
      'should extract phone number from Firebase user when phoneNumber is set',
      () {
        when(mockUser.phoneNumber).thenReturn('+22670123456');
        when(mockUser.email).thenReturn(null);

        final extracted = AuthRepository.phoneFromFirebaseUser(mockUser);
        expect(extracted, '+22670123456');
      },
    );

    test(
      'should extract phone number from Firebase user when email is synthetic',
      () {
        when(mockUser.phoneNumber).thenReturn(null);
        when(mockUser.email).thenReturn('+22670123456@maasga.app');

        final extracted = AuthRepository.phoneFromFirebaseUser(mockUser);
        expect(extracted, '+22670123456');
      },
    );

    test(
      'should return null when Firebase user has no valid phone or synthetic email',
      () {
        when(
          mockUser.phoneNumber,
        ).thenReturn('+1234567890'); // Invalid Burkinabe format
        when(mockUser.email).thenReturn('test@example.com'); // Not synthetic

        final extracted = AuthRepository.phoneFromFirebaseUser(mockUser);
        expect(extracted, isNull);
      },
    );

    test('should return null when Firebase user has empty phone and email', () {
      when(mockUser.phoneNumber).thenReturn('');
      when(mockUser.email).thenReturn('');

      final extracted = AuthRepository.phoneFromFirebaseUser(mockUser);
      expect(extracted, isNull);
    });
  });

  group('AuthRepository - Google User Detection', () {
    test('should return false for null user', () {
      expect(AuthRepository.isGoogleUser(null), isFalse);
    });

    test('should return false for user without providerData', () {
      when(mockUser.providerData).thenReturn([]);
      expect(AuthRepository.isGoogleUser(mockUser), isFalse);
    });
  });

  group('AuthRepository - Instance Creation', () {
    test('should create AuthRepository with FirebaseAuth instance', () {
      final repo = AuthRepository(mockFirebaseAuth);
      expect(repo, isNotNull);
    });
  });
}
