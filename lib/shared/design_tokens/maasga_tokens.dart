import 'package:flutter/material.dart';

/// Constantes de charte MAASGA **indépendantes du mode clair/sombre** :
/// couleurs de marque, rayons, espacements.
///
/// Tout ce qui dépend du thème (fonds, textes, bordures, statuts) vit dans
/// [MaasgaPalette] et se lit via `context.maasga`. Écrire une couleur de fond ou
/// de texte en dur dans un écran le fige en mode clair — c'est précisément ce
/// qui rendait l'application illisible en sombre.
class MaasgaTokens {
  static const Color white = Color(0xFFFFFFFF);
  static const Color bgSoft = Color(0xFFF4FAFF);
  static const Color bgMuted = Color(0xFFE9F4FF);
  static const Color blue900 = Color(0xFF0B3F8A);
  static const Color blue700 = Color(0xFF0077B6);
  static const Color cyan500 = Color(0xFF00B4D8);
  static const Color cyan300 = Color(0xFF7CD9EA);
  static const Color success = Color(0xFF12B76A);
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusPill = 999;
  static const double spaceMd = 16;
  static const double spaceLg = 24;

  static const LinearGradient brandGradient = LinearGradient(
    colors: [blue900, cyan500],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// Palette résolue pour le thème courant.
///
/// Enregistrée comme [ThemeExtension] par `AppTheme.light()` et
/// `AppTheme.dark()`, et lue via `context.maasga`. Un écran qui n'utilise que
/// ces champs (plus `Theme.of(context).colorScheme`) est correct dans les deux
/// modes sans branchement `isDark` à la main.
@immutable
class MaasgaPalette extends ThemeExtension<MaasgaPalette> {
  const MaasgaPalette({
    required this.pageGradient,
    required this.card,
    required this.cardAlt,
    required this.cardBorder,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.buttonGradient,
    required this.shadow,
    required this.success,
    required this.successSurface,
    required this.warning,
    required this.warningSurface,
    required this.danger,
    required this.dangerSurface,
    required this.info,
    required this.infoSurface,
  });

  /// Fond de page, appliqué par `MaasgaShell`.
  final LinearGradient pageGradient;

  /// Fond d'une carte posée sur [pageGradient].
  final Color card;

  /// Fond légèrement contrasté par rapport à [card] : sous-sections, champs
  /// désactivés, lignes de tableau alternées.
  final Color cardAlt;

  final Color cardBorder;
  final Color divider;

  /// Texte principal — titres et corps.
  final Color textPrimary;

  /// Texte secondaire — sous-titres, légendes.
  final Color textSecondary;

  /// Texte tertiaire — mentions discrètes, horodatages.
  final Color textMuted;

  /// Couleur interactive de marque : icônes, liens, éléments actifs. Le bleu
  /// foncé de la charte n'a pas assez de contraste sur un fond sombre, ce champ
  /// bascule donc sur le cyan en mode sombre.
  final Color accent;

  /// Couleur du contenu posé sur [accent].
  final Color onAccent;

  /// Dégradé des boutons principaux — assombri en mode sombre pour ne pas
  /// éblouir.
  final LinearGradient buttonGradient;

  final Color shadow;

  final Color success;
  final Color successSurface;
  final Color warning;
  final Color warningSurface;
  final Color danger;
  final Color dangerSurface;
  final Color info;
  final Color infoSurface;

  /// Style du texte saisi dans les champs de formulaire.
  TextStyle get inputTextStyle =>
      TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w500);

  static const MaasgaPalette light = MaasgaPalette(
    pageGradient: LinearGradient(
      colors: [MaasgaTokens.bgSoft, MaasgaTokens.white, MaasgaTokens.bgMuted],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    card: MaasgaTokens.white,
    cardAlt: Color(0xFFF5F8FC),
    cardBorder: Color(0xFFE2E8F0),
    divider: Color(0xFFE7EDF5),
    textPrimary: Color(0xFF101828),
    textSecondary: Color(0xFF475467),
    textMuted: Color(0xFF757575),
    accent: MaasgaTokens.blue700,
    onAccent: MaasgaTokens.white,
    buttonGradient: MaasgaTokens.brandGradient,
    shadow: Color(0xFF101828),
    success: Color(0xFF12B76A),
    successSurface: Color(0xFFE7F8F0),
    warning: Color(0xFFB54708),
    warningSurface: Color(0xFFFFF6E5),
    danger: Color(0xFFE53935),
    dangerSurface: Color(0xFFFDECEC),
    info: Color(0xFF1B3A8D),
    infoSurface: Color(0xFFEAF1FF),
  );

  /// Mode sombre : fonds bleu nuit plutôt que gris neutres, pour que
  /// l'application reste reconnaissable comme MAASGA une fois le thème inversé.
  static const MaasgaPalette dark = MaasgaPalette(
    pageGradient: LinearGradient(
      colors: [Color(0xFF0A1322), Color(0xFF101C31), Color(0xFF0B1728)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    card: Color(0xFF151F33),
    cardAlt: Color(0xFF1B2740),
    cardBorder: Color(0xFF25324B),
    divider: Color(0xFF22304A),
    textPrimary: Color(0xFFE9EEF8),
    textSecondary: Color(0xFFA7B4CC),
    textMuted: Color(0xFF7C8AA5),
    accent: Color(0xFF6FD3E8),
    onAccent: Color(0xFF04121A),
    buttonGradient: LinearGradient(
      colors: [Color(0xFF1E4FA8), Color(0xFF0FA0C4)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    shadow: Color(0xFF000000),
    success: Color(0xFF3DDC97),
    successSurface: Color(0xFF10382A),
    warning: Color(0xFFF5B851),
    warningSurface: Color(0xFF3D2B0F),
    danger: Color(0xFFFF6B6B),
    dangerSurface: Color(0xFF41161A),
    info: Color(0xFF7FB4FF),
    infoSurface: Color(0xFF152744),
  );

  @override
  MaasgaPalette copyWith({
    LinearGradient? pageGradient,
    Color? card,
    Color? cardAlt,
    Color? cardBorder,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? onAccent,
    LinearGradient? buttonGradient,
    Color? shadow,
    Color? success,
    Color? successSurface,
    Color? warning,
    Color? warningSurface,
    Color? danger,
    Color? dangerSurface,
    Color? info,
    Color? infoSurface,
  }) {
    return MaasgaPalette(
      pageGradient: pageGradient ?? this.pageGradient,
      card: card ?? this.card,
      cardAlt: cardAlt ?? this.cardAlt,
      cardBorder: cardBorder ?? this.cardBorder,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      buttonGradient: buttonGradient ?? this.buttonGradient,
      shadow: shadow ?? this.shadow,
      success: success ?? this.success,
      successSurface: successSurface ?? this.successSurface,
      warning: warning ?? this.warning,
      warningSurface: warningSurface ?? this.warningSurface,
      danger: danger ?? this.danger,
      dangerSurface: dangerSurface ?? this.dangerSurface,
      info: info ?? this.info,
      infoSurface: infoSurface ?? this.infoSurface,
    );
  }

  @override
  MaasgaPalette lerp(covariant MaasgaPalette? other, double t) {
    if (other == null) return this;
    return MaasgaPalette(
      pageGradient: LinearGradient.lerp(pageGradient, other.pageGradient, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardAlt: Color.lerp(cardAlt, other.cardAlt, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      buttonGradient: LinearGradient.lerp(
        buttonGradient,
        other.buttonGradient,
        t,
      )!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSurface: Color.lerp(dangerSurface, other.dangerSurface, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSurface: Color.lerp(infoSurface, other.infoSurface, t)!,
    );
  }
}

extension MaasgaThemeX on BuildContext {
  /// Palette MAASGA du thème courant.
  ///
  /// Retombe sur la palette correspondant à la luminosité si l'extension n'est
  /// pas enregistrée : un test widget qui monte un composant dans un
  /// `MaterialApp` nu ne doit pas planter.
  MaasgaPalette get maasga {
    final theme = Theme.of(this);
    return theme.extension<MaasgaPalette>() ??
        (theme.brightness == Brightness.dark
            ? MaasgaPalette.dark
            : MaasgaPalette.light);
  }

  /// `true` si le thème rendu est sombre. À préférer à une comparaison sur
  /// `themeControllerProvider`, qui vaut `system` la plupart du temps et ne dit
  /// donc rien de la luminosité réellement appliquée.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
