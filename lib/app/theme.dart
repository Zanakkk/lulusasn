

// ============================================================================
// NEOBRUTALISM THEME (System fonts + LineIcons)
// ============================================================================
import 'package:flutter/material.dart';

final neobrutTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  // System fonts = instant load
  fontFamily:
  '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',

  colorScheme: const ColorScheme.light(
    primary: Color(0xFF000000), // Black
    secondary: Color(0xFFFFD700), // Gold
    tertiary: Color(0xFF00FF00), // Green
    surface: Color(0xFFFFFFFF), // White
    error: Color(0xFFFF0000), // Red
    onPrimary: Color(0xFFFFFFFF),
    onSurface: Color(0xFF000000),
  ),

  scaffoldBackgroundColor: const Color(0xFFF5F5F5),

  // ✅ FIXED: CardTheme → CardThemeData
  cardTheme: const CardThemeData(
    elevation: 0,
    color: Color(0xFFFFFFFF),
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Color(0xFF000000), width: 3),
      borderRadius: BorderRadius.zero,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: const Color(0xFF000000),
      foregroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shadowColor: Colors.transparent,
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFFFFFFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: const BorderSide(color: Color(0xFF000000), width: 3),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: const BorderSide(color: Color(0xFF000000), width: 3),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: const BorderSide(color: Color(0xFF000000), width: 4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: const BorderSide(color: Color(0xFFFF0000), width: 3),
    ),
  ),
);