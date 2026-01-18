import 'package:flutter/material.dart';

/// Duolingo-Style Color Palette
/// Friendly, vibrant but not harsh, rounded feel
class AppColors {
  AppColors._();

  // ============================================================================
  // PRIMARY COLORS (Duolingo)
  // ============================================================================

  static const Color green = Color(0xFF58CC02);       // Duolingo Green (primary)
  static const Color darkGreen = Color(0xFF58A700);   // Duolingo Dark Green
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFAFAFA);  // Soft off-white
  static const Color black = Color(0xFF000000);

  // ============================================================================
  // ACCENT COLORS
  // ============================================================================

  static const Color blue = Color(0xFF1CB0F6);        // Duolingo Blue
  static const Color orange = Color(0xFFFF9600);      // Duolingo Orange
  static const Color yellow = Color(0xFFFFC800);      // Duolingo Yellow
  static const Color red = Color(0xFFFF4B4B);         // Soft Red
  static const Color gold = Color(0xFFFFD700);        // Premium Gold
  static const Color purple = Color(0xFFCE82FF);      // Soft Purple
  static const Color pink = Color(0xFFFF8FA3);        // Soft Pink
  static const Color cyan = Color(0xFF58D4D8);        // Soft Cyan

  // ============================================================================
  // GRAY SCALE
  // ============================================================================

  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF0F0F0);
  static const Color gray200 = Color(0xFFE5E5E5);
  static const Color gray300 = Color(0xFFD4D4D4);
  static const Color gray400 = Color(0xFFAFAFAF);
  static const Color gray500 = Color(0xFF888888);
  static const Color gray600 = Color(0xFF777777);
  static const Color gray700 = Color(0xFF555555);
  static const Color gray800 = Color(0xFF3C3C3C);
  static const Color gray900 = Color(0xFF1F1F1F);

  // ============================================================================
  // CATEGORY COLORS (TWK, TIU, TKP)
  // ============================================================================

  static const Color twkColor = Color(0xFF1CB0F6);    // Blue (TWK)
  static const Color tiuColor = Color(0xFFFF9600);    // Orange (TIU)
  static const Color tkpColor = Color(0xFF58CC02);    // Green (TKP)

  // Aliases untuk consistency dengan widget usage
  static const Color twk = twkColor;
  static const Color tiu = tiuColor;
  static const Color tkp = tkpColor;

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  static const Color success = Color(0xFF58CC02);     // Green
  static const Color error = Color(0xFFFF4B4B);       // Soft Red
  static const Color warning = Color(0xFFFF9600);     // Orange
  static const Color info = Color(0xFF1CB0F6);        // Blue

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  static const Color textPrimary = gray800;           // #3C3C3C
  static const Color textSecondary = gray600;         // #777777
  static const Color textTertiary = gray400;          // #AFAFAF
  static const Color textOnDark = white;

  // ============================================================================
  // BACKGROUND COLORS
  // ============================================================================

  static const Color cardBackground = white;
  static const Color surfaceBackground = gray50;
  static const Color overlayBackground = Color(0xCC000000); // 80% black

  // ============================================================================
  // BORDER COLORS (ADDED FOR WIDGETS)
  // ============================================================================

  static const Color borderPrimary = gray200;         // Light border
  static const Color borderSecondary = gray300;
  static const Color borderLight = gray100;
  static const Color borderDark = gray800;

  // Alias untuk widget usage
  static const Color border = borderPrimary;          // Default border color

  // ============================================================================
  // SHADOW COLORS (ADDED FOR NEOBRUTALISM)
  // ============================================================================

  static const Color shadow = Color(0xFF000000);      // Black shadow for neobrutalism
  static const Color shadowLight = Color(0x1A000000); // 10% black
  static const Color shadowMedium = Color(0x33000000); // 20% black
  static const Color shadowDark = Color(0x4D000000);  // 30% black

  // ============================================================================
  // FUNCTIONAL COLORS (ADDED FOR WIDGETS)
  // ============================================================================

  static const Color primary = green;                 // Primary action color
  static const Color primaryDark = darkGreen;
  static const Color secondary = blue;
  static const Color neutral = gray500;               // Neutral elements

  // ============================================================================
  // STATUS COLORS (Energy, Premium, etc)
  // ============================================================================

  static const Color energyFull = Color(0xFF58CC02);  // Green
  static const Color energyMedium = Color(0xFFFF9600); // Orange
  static const Color energyLow = Color(0xFFFF4B4B);   // Red
  static const Color premiumBadge = Color(0xFFFFD700); // Gold
  static const Color streakFire = Color(0xFFFF9600);  // Orange

  // ============================================================================
  // CHART COLORS
  // ============================================================================

  static const List<Color> chartColors = [
    Color(0xFF58CC02), // Green
    Color(0xFF1CB0F6), // Blue
    Color(0xFFFF9600), // Orange
    Color(0xFFFFD700), // Gold
    Color(0xFFCE82FF), // Purple
    Color(0xFF58D4D8), // Cyan
  ];

  // ============================================================================
  // GRADIENT COLORS
  // ============================================================================

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFC800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF58CC02), Color(0xFF58A700)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF1CB0F6), Color(0xFF0D8BBF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  static Color getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'TWK':
        return twkColor;
      case 'TIU':
        return tiuColor;
      case 'TKP':
        return tkpColor;
      default:
        return gray800;
    }
  }

  static Color getEnergyColor(double percentage) {
    if (percentage >= 0.6) return energyFull;
    if (percentage >= 0.3) return energyMedium;
    return energyLow;
  }

  static Color getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return success;
    if (accuracy >= 0.6) return warning;
    return error;
  }

  /// Get lighter shade of a color
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Get darker shade of a color
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}