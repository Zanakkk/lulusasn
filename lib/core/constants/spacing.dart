import 'package:flutter/material.dart';

/// Consistent spacing system (8px base)
class AppSpacing {
  AppSpacing._(); // Private constructor

  // ============================================================================
  // BASE SPACING (Multiples of 8)
  // ============================================================================

  static const double xs = 4;    // Extra small
  static const double sm = 8;    // Small
  static const double md = 16;   // Medium
  static const double lg = 24;   // Large
  static const double xl = 32;   // Extra large
  static const double xxl = 48;  // 2× Extra large
  static const double xxxl = 64; // 3× Extra large

  // ============================================================================
  // BORDER RADIUS (ADDED FOR WIDGETS)
  // ============================================================================

  static const double radiusNone = 0;     // Neobrutalism default (no radius)
  static const double radiusSm = 4;       // ADDED (lowercase)
  static const double radiusSM = 4;       // ADDED
  static const double radiusMd = 8;       // ADDED (lowercase)
  static const double radiusMD = 8;
  static const double radiusLg = 12;      // ADDED (lowercase)
  static const double radiusLG = 12;
  static const double radiusXl = 16;      // ADDED (lowercase)
  static const double radiusXL = 16;
  static const double radiusFull = 999;   // ADDED (fully rounded)
  static const double radiusRound = 999;  // Alias

  // ============================================================================
  // PADDING (EdgeInsets)
  // ============================================================================

  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  static const EdgeInsets paddingXXL = EdgeInsets.all(xxl);

  // Horizontal padding
  static const EdgeInsets paddingHorizontalXS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets paddingHorizontalSM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets paddingVerticalXS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingVerticalSM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLG = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXL = EdgeInsets.symmetric(vertical: xl);

  // Common patterns
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: xl, vertical: md);
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets dialogPadding = EdgeInsets.all(lg);

  // ============================================================================
  // MARGIN (SizedBox for consistency)
  // ============================================================================

  static const SizedBox gapXS = SizedBox(width: xs, height: xs);
  static const SizedBox gapSM = SizedBox(width: sm, height: sm);
  static const SizedBox gapMD = SizedBox(width: md, height: md);
  static const SizedBox gapLG = SizedBox(width: lg, height: lg);
  static const SizedBox gapXL = SizedBox(width: xl, height: xl);
  static const SizedBox gapXXL = SizedBox(width: xxl, height: xxl);

  // Horizontal gaps
  static const SizedBox horizontalGapXS = SizedBox(width: xs);
  static const SizedBox horizontalGapSM = SizedBox(width: sm);
  static const SizedBox horizontalGapMD = SizedBox(width: md);
  static const SizedBox horizontalGapLG = SizedBox(width: lg);
  static const SizedBox horizontalGapXL = SizedBox(width: xl);

  // Vertical gaps
  static const SizedBox verticalGapXS = SizedBox(height: xs);
  static const SizedBox verticalGapSM = SizedBox(height: sm);
  static const SizedBox verticalGapMD = SizedBox(height: md);
  static const SizedBox verticalGapLG = SizedBox(height: lg);
  static const SizedBox verticalGapXL = SizedBox(height: xl);
  static const SizedBox verticalGapXXL = SizedBox(height: xxl);



  static const BorderRadius borderRadiusNone = BorderRadius.zero;
  static const BorderRadius borderRadiusSM = BorderRadius.all(Radius.circular(radiusSM));
  static const BorderRadius borderRadiusMD = BorderRadius.all(Radius.circular(radiusMD));
  static const BorderRadius borderRadiusLG = BorderRadius.all(Radius.circular(radiusLG));
  static const BorderRadius borderRadiusXL = BorderRadius.all(Radius.circular(radiusXL));
  static const BorderRadius borderRadiusRound = BorderRadius.all(Radius.circular(radiusRound));

  // ============================================================================
  // BORDER WIDTH (Neobrutalism uses thick borders)
  // ============================================================================

  static const double borderThin = 2;
  static const double borderMedium = 3;
  static const double borderThick = 4;
  static const double borderExtraThick = 5;

  // ============================================================================
  // ELEVATION / SHADOW OFFSET (Flat shadows for Neobrutalism)
  // ============================================================================

  static const Offset shadowSmall = Offset(4, 4);
  static const Offset shadowMedium = Offset(6, 6);
  static const Offset shadowLarge = Offset(8, 8);
  static const Offset shadowExtraLarge = Offset(12, 12);

  // ============================================================================
  // ICON SIZES
  // ============================================================================

  static const double iconXS = 16;
  static const double iconSM = 20;
  static const double iconMD = 24;
  static const double iconLG = 32;
  static const double iconXL = 48;
  static const double iconXXL = 64;

  // ============================================================================
  // BUTTON HEIGHTS
  // ============================================================================

  static const double buttonHeightSM = 40;
  static const double buttonHeightMD = 48;
  static const double buttonHeightLG = 56;
  static const double buttonHeightXL = 64;

  // ============================================================================
  // CARD SIZES
  // ============================================================================

  static const double cardMinHeight = 100;
  static const double cardMaxWidth = 600;

  // ============================================================================
  // APP BAR
  // ============================================================================

  static const double appBarHeight = 56;
  static const double appBarBorderWidth = borderMedium;

  // ============================================================================
  // BOTTOM NAVIGATION
  // ============================================================================

  static const double bottomNavHeight = 70;
  static const double bottomNavIconSize = iconLG;

  // ============================================================================
  // DIVIDER
  // ============================================================================

  static const double dividerThickness = borderMedium;
  static const double dividerIndent = md;
}