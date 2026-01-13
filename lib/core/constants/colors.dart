import 'package:flutter/material.dart';

/// Neobrutalism Color Palette
/// High contrast, bold colors, no gradients
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============================================================================
  // PRIMARY COLORS (Neobrutalism)
  // ============================================================================

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F5F5);

  // ============================================================================
  // ACCENT COLORS
  // ============================================================================

  static const Color gold = Color(0xFFFFD700);        // Premium, rewards
  static const Color green = Color(0xFF00FF00);       // Success, correct answer
  static const Color red = Color(0xFFFF0000);         // Error, wrong answer
  static const Color blue = Color(0xFF0000FF);        // Info, links
  static const Color purple = Color(0xFF9D00FF);      // Special, premium features
  static const Color orange = Color(0xFFFF6B00);      // Warning, energy low
  static const Color pink = Color(0xFFFF69B4);        // Streaks, achievements
  static const Color cyan = Color(0xFF00FFFF);        // Learning, progress

  // ============================================================================
  // CATEGORY COLORS (TWK, TIU, TKP)
  // ============================================================================

  static const Color twkColor = Color(0xFF4169E1);    // Royal Blue (TWK)
  static const Color tiuColor = Color(0xFFFF4500);    // Orange Red (TIU)
  static const Color tkpColor = Color(0xFF32CD32);    // Lime Green (TKP)

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  static const Color success = green;
  static const Color error = red;
  static const Color warning = orange;
  static const Color info = blue;

  // ============================================================================
  // TEXT COLORS
  // ============================================================================

  static const Color textPrimary = black;
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color textOnDark = white;

  // ============================================================================
  // BACKGROUND COLORS
  // ============================================================================

  static const Color cardBackground = white;
  static const Color surfaceBackground = Color(0xFFFAFAFA);
  static const Color overlayBackground = Color(0x80000000); // 50% black

  // ============================================================================
  // BORDER COLORS
  // ============================================================================

  static const Color borderPrimary = black;
  static const Color borderSecondary = Color(0xFF333333);
  static const Color borderLight = Color(0xFFCCCCCC);

  // ============================================================================
  // STATUS COLORS (Energy, Premium, etc)
  // ============================================================================

  static const Color energyFull = green;
  static const Color energyMedium = orange;
  static const Color energyLow = red;
  static const Color premiumBadge = gold;
  static const Color streakFire = Color(0xFFFF4500);

  // ============================================================================
  // CHART COLORS
  // ============================================================================

  static const List<Color> chartColors = [
    Color(0xFF4169E1), // Blue
    Color(0xFFFF4500), // Orange
    Color(0xFF32CD32), // Green
    Color(0xFFFFD700), // Gold
    Color(0xFF9D00FF), // Purple
    Color(0xFF00FFFF), // Cyan
  ];

  // ============================================================================
  // GRADIENT COLORS (Use sparingly - Neobrutalism avoids gradients)
  // ============================================================================

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get category color by name
  static Color getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'TWK':
        return twkColor;
      case 'TIU':
        return tiuColor;
      case 'TKP':
        return tkpColor;
      default:
        return black;
    }
  }

  /// Get energy color based on percentage
  static Color getEnergyColor(double percentage) {
    if (percentage >= 0.6) return energyFull;
    if (percentage >= 0.3) return energyMedium;
    return energyLow;
  }

  /// Get accuracy color based on percentage
  static Color getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return green;
    if (accuracy >= 0.6) return orange;
    return red;
  }
}