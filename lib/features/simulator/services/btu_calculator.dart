/// Résultat complet du calcul BTU avec option multi-unités.
class BtuResult {
  const BtuResult({
    required this.btuExact,
    required this.btuCommercial,
    required this.cvLabel,
    required this.powerKey,
    required this.multiUnit,
  });

  /// BTU exact calculé (avant arrondi commercial)
  final double btuExact;

  /// BTU arrondi au palier commercial le plus proche
  final int btuCommercial;

  /// Label CV principal (ex. "3 CV")
  final String cvLabel;

  /// Clé pour filtrer le catalogue (ex. "3cv")
  final String powerKey;

  /// Alternative multi-unités si pertinente, null sinon.
  /// Ex. MultiUnitOption(label: "2 × 1.5 CV", powerKey: "1.5cv", count: 2)
  final MultiUnitOption? multiUnit;
}

class MultiUnitOption {
  const MultiUnitOption({
    required this.label,
    required this.powerKey,
    required this.count,
    required this.btuPerUnit,
    required this.cvPerUnit,
  });

  /// Ex. "2 × 1.5 CV (12 000 BTU chacun)"
  final String label;

  /// Clé catalogue pour chaque unité
  final String powerKey;

  /// Nombre d'unités
  final int count;

  /// BTU par unité
  final int btuPerUnit;

  /// Label CV par unité (ex. "1.5 CV")
  final String cvPerUnit;
}

class BtuCalculator {
  // ─── Calcul principal ──────────────────────────────────────────────────────

  static BtuResult calculateFull({
    required double surface,
    required double height,
    required String solarExposure,
    required int windows,
    required String roomType,
  }) {
    final btuExact = calculate(
      surface: surface,
      height: height,
      solarExposure: solarExposure,
      windows: windows,
      roomType: roomType,
    );
    final btuCommercial = getCommercialBtu(btuExact);
    final cvLabel = getCvRecommendation(btuExact);
    final powerKey = getPowerKey(btuExact);
    final multiUnit = _computeMultiUnit(btuExact, btuCommercial);

    return BtuResult(
      btuExact: btuExact,
      btuCommercial: btuCommercial,
      cvLabel: cvLabel,
      powerKey: powerKey,
      multiUnit: multiUnit,
    );
  }

  /// Détermine si une configuration multi-unités est pertinente et laquelle.
  ///
  /// Règles métier :
  /// - 24 000 BTU (3 CV) → alternative "2 × 1.5 CV" (12 000 BTU chacun)
  /// - 36 000 BTU (5 CV) → alternative "2 × 2 CV" (18 000 BTU chacun)
  /// - > 36 000 BTU      → alternative "2 × 2 CV + éventuellement plus"
  ///   (surface > 60 m²) → systématiquement recommandé
  /// - 18 000 BTU (2 CV) sur très grande pièce (calc > 15 000) → "2 × 1 CV" non pertinent
  static MultiUnitOption? _computeMultiUnit(double btuExact, int btuCommercial) {
    if (btuCommercial == 24000) {
      // 3 CV → 2 × 1.5 CV
      return const MultiUnitOption(
        label: '2 × 1,5 CV (12 000 BTU chacun)',
        powerKey: '1.5cv',
        count: 2,
        btuPerUnit: 12000,
        cvPerUnit: '1.5 CV',
      );
    }
    if (btuCommercial == 36000) {
      // 5 CV → 2 × 2 CV (couvre 2 × 25-40 m²)
      return const MultiUnitOption(
        label: '2 × 2 CV (18 000 BTU chacun)',
        powerKey: '2cv',
        count: 2,
        btuPerUnit: 18000,
        cvPerUnit: '2 CV',
      );
    }
    if (btuExact > 36000) {
      // Grande surface : 3 × 2 CV ou plus
      final units = (btuExact / 18000).ceil().clamp(2, 5);
      return MultiUnitOption(
        label: '$units × 2 CV (18 000 BTU chacun)',
        powerKey: '2cv',
        count: units,
        btuPerUnit: 18000,
        cvPerUnit: '2 CV',
      );
    }
    return null;
  }

  // ─── Calcul BTU brut ───────────────────────────────────────────────────────

  static double calculate({
    required double surface,
    required double height,
    required String solarExposure,
    required int windows,
    required String roomType,
  }) {
    // Base : 600 BTU/m² (norme NF EN 14825 adaptée climat tropical)
    // Pour les grandes surfaces (>40 m²) on applique un léger bonus d'efficacité
    // car un seul appareil gros format est moins performant par m².
    double base = surface <= 40 ? 600 : 580;
    double btu = surface * base;

    // Facteur hauteur plafond
    double hauteurFactor = 1.0;
    if (height >= 3.5) {
      hauteurFactor = 1.25;
    } else if (height >= 3.0) {
      hauteurFactor = 1.15;
    } else if (height >= 2.7) {
      hauteurFactor = 1.08;
    }
    btu *= hauteurFactor;

    // Facteur exposition solaire
    double expositionFactor;
    switch (solarExposure.toLowerCase()) {
      case 'faible':
        expositionFactor = 1.0;
        break;
      case 'forte':
        expositionFactor = 1.20;
        break;
      default: // Modérée
        expositionFactor = 1.10;
    }
    btu *= expositionFactor;

    // Facteur fenêtres / ouvertures
    // Chaque fenêtre ajoute des apports solaires et thermiques significatifs.
    double fenetresFactor;
    if (windows == 0) {
      fenetresFactor = 0.97; // Pièce très isolée → légère réduction
    } else if (windows == 1) {
      fenetresFactor = 1.05;
    } else if (windows == 2) {
      fenetresFactor = 1.12;
    } else {
      // 3+ fenêtres : +18%
      fenetresFactor = 1.18;
    }
    btu *= fenetresFactor;

    // Facteur type de pièce
    double typePieceFactor;
    switch (roomType.toLowerCase()) {
      case 'salon':
        // Occupation variable, souvent exposé
        typePieceFactor = 1.05;
        break;
      case 'cuisine':
        // Dégagement de chaleur important (cuisson, réfrigérateur, etc.)
        typePieceFactor = 1.25;
        break;
      case 'commerce':
      case 'commerce/boutique':
        // Occupation dense, éclairage fort, ouvertures fréquentes
        typePieceFactor = 1.20;
        break;
      case 'bureau':
        // Ordinateurs, imprimantes, occupation diurne dense
        typePieceFactor = 1.08;
        break;
      default:
        // Chambre : occupation faible, charges thermiques réduites
        typePieceFactor = 1.0;
    }
    btu *= typePieceFactor;

    // Majoration climat tropical Ouagadougou +12%
    // Températures extérieures fréquemment > 40°C → delta-T élevé
    btu *= 1.12;

    return btu;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static String getCvRecommendation(double btu) {
    if (btu <= 9000) return '1 CV';
    if (btu <= 12000) return '1,5 CV';
    if (btu <= 18000) return '2 CV';
    if (btu <= 24000) return '3 CV';
    return '5 CV';
  }

  static int getCommercialBtu(double btu) {
    if (btu <= 9000) return 9000;
    if (btu <= 12000) return 12000;
    if (btu <= 18000) return 18000;
    if (btu <= 24000) return 24000;
    return 36000;
  }

  static String getPowerKey(double btu) {
    if (btu <= 9000) return '1cv';
    if (btu <= 12000) return '1.5cv';
    if (btu <= 18000) return '2cv';
    if (btu <= 24000) return '3cv';
    return '5cv';
  }
}
