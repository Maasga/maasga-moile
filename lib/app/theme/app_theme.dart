import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // MAASGA Brand Primary Color
  static const Color primaryColor = Color(0xFF1B3A8D);

  // Couleurs de texte garanties lisibles sur fond blanc/clair
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMedium = Color(0xFF475467);

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
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 0,
        blendOnColors: false,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        defaultRadius: 12.0,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorUnfocusedBorderIsColored: false,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
    );

    // On force un textTheme explicitement sombre pour que tous les widgets
    // qui héritent leur couleur du thème (Text sans style, titres, etc.)
    // soient toujours lisibles sur fond blanc/clair.
    return base.copyWith(
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
        labelStyle: TextStyle(color: _textMedium),
        hintStyle: TextStyle(color: _textMedium.withValues(alpha: 0.6)),
        // Le style du texte saisi doit être explicitement sombre
        // (certains backends de rendu Flutter héritent onSurface du thème)
      ),
    );
  }

  static ThemeData dark() {
    return FlexThemeData.dark(
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
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        defaultRadius: 12.0,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorUnfocusedBorderIsColored: false,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
    );
  }
}
