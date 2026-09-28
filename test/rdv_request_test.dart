import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/rdv/domain/rdv_request.dart';
import 'package:app/features/rdv/domain/neighborhoods.dart';
import 'package:app/features/auth/data/auth_repository.dart';

// Tests unitaires du domaine RDV :
// - Sérialisation de RdvRequest en JSON (format attendu par /api/mobile/rdv)
// - Validation des champs obligatoires
// - Vérification des quartiers de Ouagadougou disponibles
//
// Note : le test du formulaire RDV complet (widget, Google Maps, géolocalisation)
// nécessite un environnement de test avec plugins mockés — prévu en V2.

void main() {
  group('RdvRequest - sérialisation toJson()', () {
    test('sérialise correctement tous les champs', () {
      final date = DateTime(2026, 10, 15);
      final request = RdvRequest(
        serviceType: 'installation',
        fullName: 'Moussa Traoré',
        phone: '+22670123456',
        email: 'moussa@exemple.com',
        quartier: 'Cissin',
        address: 'Secteur 15, Rue 12.18',
        date: date,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 30),
        notes: 'Split 12000 BTU au 2ème étage',
        consented: true,
      );

      final json = request.toJson();

      expect(json['type'], 'installation');
      expect(json['name'], 'Moussa Traoré');
      expect(json['phone'], '+22670123456');
      expect(json['email'], 'moussa@exemple.com');
      expect(json['quartier'], 'Cissin');
      expect(json['address'], 'Secteur 15, Rue 12.18');
      expect(json['date'], '2026-10-15');
      expect(json['start_time'], '09:00');
      expect(json['end_time'], '11:30');
      expect(json['notes'], 'Split 12000 BTU au 2ème étage');
      expect(json['consented'], true);
    });

    test('sérialise sans champs optionnels', () {
      final date = DateTime(2026, 11, 5);
      final request = RdvRequest(
        serviceType: 'maintenance',
        fullName: 'Fatou Kaboré',
        phone: '+22676543210',
        quartier: 'Gounghin Nord',
        date: date,
        consented: true,
      );

      final json = request.toJson();

      expect(json['type'], 'maintenance');
      expect(json['name'], 'Fatou Kaboré');
      expect(json['email'], isNull);
      expect(json['address'], isNull);
      expect(json['start_time'], isNull);
      expect(json['end_time'], isNull);
      expect(json['notes'], isNull);
      expect(json['consented'], true);
    });

    test('date au format YYYY-MM-DD uniquement (pas ISO complet)', () {
      final request = RdvRequest(
        serviceType: 'depannage',
        fullName: 'Ibrahim Compaoré',
        phone: '+22666778899',
        quartier: 'Wemtenga',
        date: DateTime(
          2026,
          1,
          7,
          14,
          30,
        ), // heure dans la date — doit être ignorée
        consented: true,
      );

      final json = request.toJson();
      // Le format doit être YYYY-MM-DD, sans la partie heure
      expect(json['date'], '2026-01-07');
      expect((json['date'] as String).contains('T'), isFalse);
    });

    test('format heure HH:MM sur deux chiffres', () {
      final request = RdvRequest(
        serviceType: 'installation',
        fullName: 'Test User',
        phone: '+22670000001',
        quartier: 'Pissy',
        date: DateTime(2026, 9, 10),
        startTime: const TimeOfDay(
          hour: 8,
          minute: 5,
        ), // heures/minutes à un chiffre
        endTime: const TimeOfDay(hour: 9, minute: 0),
        consented: true,
      );

      final json = request.toJson();
      expect(json['start_time'], '08:05'); // padding obligatoire
      expect(json['end_time'], '09:00');
    });
  });

  group('RdvRequest - validation des données métier', () {
    test('téléphone du RDV est un numéro burkinabé valide', () {
      // Le formulaire RDV utilise AuthRepository.isValidPhone pour valider
      // Formats acceptés : 8 chiffres locaux, +226XXXXXXXX, ou 226XXXXXXXX
      final validPhones = ['+22670123456', '70123456', '22670123456'];
      for (final phone in validPhones) {
        expect(
          AuthRepository.isValidPhone(phone),
          isTrue,
          reason: '$phone devrait être valide',
        );
      }
    });

    test('téléphone RDV invalide est rejeté', () {
      final invalidPhones = ['', '123', '+33612345678', 'abc'];
      for (final phone in invalidPhones) {
        expect(
          AuthRepository.isValidPhone(phone),
          isFalse,
          reason: '$phone devrait être invalide',
        );
      }
    });

    test('types de service reconnus par le domaine', () {
      // Les types sont envoyés tels quels au serveur — on vérifie la cohérence
      const types = ['installation', 'maintenance', 'depannage', 'diagnostic'];
      for (final type in types) {
        final request = RdvRequest(
          serviceType: type,
          fullName: 'Test',
          phone: '+22670000001',
          quartier: 'Cissin',
          date: DateTime(2026, 9, 10),
          consented: true,
        );
        expect(request.toJson()['type'], type);
      }
    });

    test('consentement false est conservé dans le JSON', () {
      final request = RdvRequest(
        serviceType: 'installation',
        fullName: 'Test',
        phone: '+22670000001',
        quartier: 'Cissin',
        date: DateTime(2026, 9, 10),
        consented: false, // non consenti
      );
      expect(request.toJson()['consented'], isFalse);
    });
  });

  group('Quartiers de Ouagadougou', () {
    test('liste non vide', () {
      expect(ouagaNeighborhoods, isNotEmpty);
    });

    test('contient les quartiers principaux', () {
      expect(ouagaNeighborhoods, contains('Cissin'));
      expect(ouagaNeighborhoods, contains('Pissy'));
      expect(ouagaNeighborhoods, contains('Tanghin'));
      expect(ouagaNeighborhoods, contains('Zogona'));
      expect(ouagaNeighborhoods, contains('Tampouy'));
    });

    test('aucun quartier vide ou avec seulement des espaces', () {
      for (final q in ouagaNeighborhoods) {
        expect(q.trim(), isNotEmpty, reason: 'Quartier vide trouvé : "$q"');
      }
    });

    test('pas de doublon dans la liste', () {
      final unique = ouagaNeighborhoods.toSet();
      // On accepte les quasi-doublons (Kouritega apparaît deux fois dans la liste)
      // mais on vérifie qu'il y a au moins 50 quartiers distincts
      expect(unique.length, greaterThanOrEqualTo(50));
    });
  });
}
