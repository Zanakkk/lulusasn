// ============================================================================
// DUOLINGO-STYLE THEME (Gamification UI)
// ============================================================================
import 'package:flutter/material.dart';

final duolingoTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  // Duolingo uses rounded, friendly fonts
  fontFamily:
      '-apple-system, BlinkMacSystemFont, "SF Pro", "Segoe UI", Roboto, sans-serif',

  colorScheme: const ColorScheme.light(
    primary: Color(0xFF58CC02), // Duolingo Green
    secondary: Color(0xFF1CB0F6), // Duolingo Blue
    tertiary: Color(0xFFFF9600), // Duolingo Orange
    surface: Color(0xFFFFFFFF), // White
    error: Color(0xFFFF4B4B), // Soft Red
    onPrimary: Color(0xFFFFFFFF),
    onSurface: Color(0xFF3C3C3C),
    outline: Color(0xFFE5E5E5), // Light Gray borders
  ),

  scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Off-white
  // Rounded cards with subtle shadows
  cardTheme: CardThemeData(
    elevation: 2,
    color: const Color(0xFFFFFFFF),
    shadowColor: Colors.black.withOpacity(0.08),
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: Color(0xFFE5E5E5), width: 2),
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),

  // Rounded buttons with bold text
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: const Color(0xFF58CC02),
      foregroundColor: const Color(0xFFFFFFFF),
      disabledBackgroundColor: const Color(0xFFE5E5E5),
      disabledForegroundColor: const Color(0xFFAFAFAF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF58A700), width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
      shadowColor: Colors.transparent,
    ),
  ),

  // Outlined button (secondary style)
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF1CB0F6),
      side: const BorderSide(color: Color(0xFFE5E5E5), width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    ),
  ),

  // Rounded input fields
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFFFFFFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE5E5E5), width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE5E5E5), width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF1CB0F6), width: 3),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFFF4B4B), width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFFF4B4B), width: 3),
    ),
  ),

  // AppBar style
  appBarTheme: const AppBarTheme(
    elevation: 0,
    centerTitle: false,
    backgroundColor: Color(0xFFFFFFFF),
    foregroundColor: Color(0xFF3C3C3C),
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      color: Color(0xFF3C3C3C),
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
  ),

  // Bottom navigation bar
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFFFFFFFF),
    selectedItemColor: Color(0xFF58CC02),
    unselectedItemColor: Color(0xFFAFAFAF),
    showSelectedLabels: true,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  ),

  // Chip style (for tags, badges)
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFFF0F0F0),
    selectedColor: const Color(0xFF58CC02),
    disabledColor: const Color(0xFFE5E5E5),
    labelStyle: const TextStyle(
      color: Color(0xFF3C3C3C),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    secondaryLabelStyle: const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE5E5E5), width: 2),
    ),
  ),

  // Progress indicator
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xFF58CC02),
    linearTrackColor: Color(0xFFE5E5E5),
    circularTrackColor: Color(0xFFE5E5E5),
  ),

  // Dialog
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFFFFFFFF),
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    titleTextStyle: const TextStyle(
      color: Color(0xFF3C3C3C),
      fontSize: 22,
      fontWeight: FontWeight.w700,
    ),
    contentTextStyle: const TextStyle(
      color: Color(0xFF777777),
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
  ),

  // Bottom sheet
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFFFFFFFF),
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),

  // Snackbar
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF3C3C3C),
    contentTextStyle: const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
  ),

  // Floating action button
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF58CC02),
    foregroundColor: Color(0xFFFFFFFF),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      side: BorderSide(color: Color(0xFF58A700), width: 2),
    ),
  ),

  // Switch
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFFFFFFFF);
      }
      return const Color(0xFFE5E5E5);
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF58CC02);
      }
      return const Color(0xFFE5E5E5);
    }),
  ),

  // Slider
  sliderTheme: const SliderThemeData(
    activeTrackColor: Color(0xFF58CC02),
    inactiveTrackColor: Color(0xFFE5E5E5),
    thumbColor: Color(0xFFFFFFFF),
    overlayColor: Color(0x2958CC02),
    valueIndicatorColor: Color(0xFF58CC02),
  ),
);

// ============================================================================
// COLOR CONSTANTS (for custom widgets)
// ============================================================================
class DuolingoColors {
  static const green = Color(0xFF58CC02);
  static const darkGreen = Color(0xFF58A700);
  static const blue = Color(0xFF1CB0F6);
  static const orange = Color(0xFFFF9600);
  static const yellow = Color(0xFFFFC800);
  static const red = Color(0xFFFF4B4B);
  static const gold = Color(0xFFFFD700);

  static const gray50 = Color(0xFFFAFAFA);
  static const gray100 = Color(0xFFF0F0F0);
  static const gray200 = Color(0xFFE5E5E5);
  static const gray400 = Color(0xFFAFAFAF);
  static const gray600 = Color(0xFF777777);
  static const gray800 = Color(0xFF3C3C3C);

  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
}

// ============================================================================
// TEXT STYLES (Duolingo-style)
// ============================================================================
class DuolingoTextStyles {
  static const displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: DuolingoColors.gray800,
    height: 1.2,
  );

  static const displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: DuolingoColors.gray800,
    height: 1.2,
  );

  static const titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: DuolingoColors.gray800,
    height: 1.3,
  );

  static const titleMedium = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: DuolingoColors.gray800,
    height: 1.3,
  );

  static const bodyLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: DuolingoColors.gray800,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: DuolingoColors.gray600,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: DuolingoColors.gray600,
    height: 1.4,
  );

  static const labelLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: DuolingoColors.gray800,
  );

  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: DuolingoColors.gray600,
  );
}
