// Tests de widgets présentationnels purs (sans provider ni réseau).
//
// google_fonts est configuré pour NE PAS tenter de télécharger les polices en
// test (sinon flaky/erreurs réseau en CI) — il retombe sur la police par défaut.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app/features/catalog/presentation/category_chip.dart';
import 'package:app/features/rdv/presentation/widgets/step_indicator.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('CategoryChip', () {
    testWidgets('affiche son label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CategoryChip(label: 'Climatiseurs', selected: false, onTap: () {}),
        ),
      );

      expect(find.text('Climatiseurs'), findsOneWidget);
    });

    testWidgets('déclenche onTap au clic', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          CategoryChip(
            label: 'Ventilation',
            selected: true,
            onTap: () => tapped++,
          ),
        ),
      );

      await tester.tap(find.text('Ventilation'));
      expect(tapped, 1);
    });
  });

  group('StepIndicator', () {
    testWidgets('affiche les 3 étapes', (tester) async {
      await tester.pumpWidget(_wrap(const StepIndicator(currentStep: 1)));

      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Détails'), findsOneWidget);
      expect(find.text('Confirmation'), findsOneWidget);
    });
  });
}
