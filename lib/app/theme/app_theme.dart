import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/design_tokens/maasga_tokens.dart';

class AppTheme {
  // MAASGA Brand Primary Color
  static const Color primaryColor = Color(0xFF1B3A8D);

  // Couleurs de texte garanties lisibles sur fond blanc/clair
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMedium = Color(0xFF475467);

  /// Sous-thèmes communs aux deux modes : seule la façon de dériver les
  /// couleurs change d'un mode à l'autre, pas la géométrie.
  static const FlexSubThemesData _subThemes = FlexSubThemesData(
    blendOnLevel: 0,
    blendOnColors: false,
    useMaterial3Typography: true,
    useM2StyleDividerInM3: true,
    alignedDropdown: true,
    useInputDecoratorThemeInDialogs: true,
    defaultRadius: 12.0,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputDecoratorUnfocusedBorderIsColored: false,
  );

  static ThemeData light() {
    final base = FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: primaryColor,
        primaryContainer: Color(0xFFD0E4FF),
        secondary: Color(0xFF0077B6),
        secondaryContainer: Color(0xFFCEE9FF),
        tertiary: Color(0xFF006875),
        tertiaryContainer: Color(0xFF95F0FF),
        appBarColor: Color(0xFFCEE9FF),
        error: Color(0xFFB00020),
      ),
      // blendLevel à 0 pour éviter que FlexColorScheme teinte les surfaces
      // en bleu-clair et rende les textes sans couleur explicite illisibles.
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 0,
      subThemesData: _subThemes,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
    );

    const palette = MaasgaPalette.light;

    // On force un textTheme explicitement sombre pour que tous les widgets
    // qui héritent leur couleur du thème (Text sans style, titres, etc.)
    // soient toujours lisibles sur fond blanc/clair.
    return base.copyWith(
      extensions: const [palette],
      textTheme: base.textTheme.apply(
        bodyColor: _textDark,
        displayColor: _textDark,
        decorationColor: _textDark,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      colorScheme: base.colorScheme.copyWith(
        onSurface: _textDark,
        onSurfaceVariant: _textMedium,
      ),
      // Force la couleur du texte saisi dans TOUS les TextFields
      // pour éviter le texte invisible sur fond blanc en mode clair.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: _textMedium),
        hintStyle: TextStyle(color: _textMedium.withValues(alpha: 0.6)),
      ),
    );
  }

  /// Thème sombre.
  ///
  /// Reçoit le même traitement explicite que [light] : `FlexThemeData.dark`
  /// seul laissait les textes et les champs de saisie hériter de couleurs
  /// dérivées, et les écrans qui posent leur propre fond se retrouvaient avec du
  /// texte quasi invisible. Chaque surface visible est donc fixée à partir de
  /// [MaasgaPalette.dark], la même source que celle utilisée par les écrans.
  static ThemeData dark() {
    final base = FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: Color(0xFFB1C5FF),
        primaryContainer: primaryColor,
        secondary: Color(0xFFB0CCFF),
        secondaryContainer: Color(0xFF004881),
        tertiary: Color(0xFF4FD8EB),
        tertiaryContainer: Color(0xFF004E59),
        appBarColor: Color(0xFF004881),
        error: Color(0xFFCF6679),
      ),
      // blendLevel bas et surfaces explicites : les mélanges généreux de Flex
      // produisaient des cartes presque indistinguables du fond de page.
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 6,
      subThemesData: _subThemes,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
    );

    const palette = MaasgaPalette.dark;

    return base.copyWith(
      extensions: const [palette],
      // Le fond de l'écran est peint par le dégradé de `MaasgaShell` ; ce
      // scaffold sert de repli aux écrans qui n'en utilisent pas.
      scaffoldBackgroundColor: palette.pageGradient.colors.first,
      canvasColor: palette.card,
      cardColor: palette.card,
      dividerColor: palette.divider,
      textTheme: base.textTheme.apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
        decorationColor: palette.textPrimary,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      colorScheme: base.colorScheme.copyWith(
        surface: palette.card,
        onSurface: palette.textPrimary,
        onSurfaceVariant: palette.textSecondary,
        outline: palette.cardBorder,
        outlineVariant: palette.divider,
        error: palette.danger,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: palette.card,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: palette.cardAlt,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: palette.cardAlt,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: base.popupMenuTheme.copyWith(color: palette.cardAlt),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: palette.cardAlt,
        contentTextStyle: TextStyle(color: palette.textPrimary),
      ),
      // Champs de saisie : fond légèrement plus clair que la carte qui les
      // porte, sinon la zone cliquable est invisible sur fond sombre.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.cardAlt,
        labelStyle: TextStyle(color: palette.textSecondary),
        hintStyle: TextStyle(color: palette.textMuted),
        prefixIconColor: palette.textSecondary,
        suffixIconColor: palette.textSecondary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.accent, width: 1.6),
        ),
      ),
      iconTheme: IconThemeData(color: palette.textSecondary),
    );
  }
}
