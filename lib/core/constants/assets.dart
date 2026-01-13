/// Asset paths constants
/// Note: We minimize assets for performance - prefer system fonts & icons
class AppAssets {
  AppAssets._(); // Private constructor

  // ============================================================================
  // IMAGES (Use sparingly - prefer system icons for performance)
  // ============================================================================

  // Placeholder if needed in future
  static const String imagesPath = 'assets/images';

  // Example: Logo (if needed)
  // static const String logo = '$imagesPath/logo.png';
  // static const String logoWhite = '$imagesPath/logo_white.png';

  // ============================================================================
  // ICONS (Currently using LineIcons package instead)
  // ============================================================================

  // We're using LineIcons package for all icons (better performance)
  // No custom icon assets needed

  // ============================================================================
  // ANIMATIONS (Lottie files - use sparingly)
  // ============================================================================

  static const String animationsPath = 'assets/animations';

  // Example animations (add if needed)
  // static const String loadingAnimation = '$animationsPath/loading.json';
  // static const String successAnimation = '$animationsPath/success.json';
  // static const String levelUpAnimation = '$animationsPath/level_up.json';

  // ============================================================================
  // SOUNDS (Optional - for feedback)
  // ============================================================================

  static const String soundsPath = 'assets/sounds';

  // Example sounds (add if needed)
  // static const String correctSound = '$soundsPath/correct.mp3';
  // static const String wrongSound = '$soundsPath/wrong.mp3';
  // static const String levelUpSound = '$soundsPath/level_up.mp3';

  // ============================================================================
  // FONTS (Currently using system fonts for performance)
  // ============================================================================

  // We're using system fonts for best performance
  // No custom font assets needed

  // ============================================================================
  // DATA FILES (CSV templates, etc)
  // ============================================================================

  static const String dataPath = 'assets/data';

// Example: CSV template for bulk question import
// static const String questionTemplate = '$dataPath/question_template.csv';

// ============================================================================
// NOTES
// ============================================================================

// IMPORTANT: We minimize asset usage for optimal web performance
// - Icons: Use LineIcons package (tree-shakeable)
// - Fonts: Use system fonts (0ms load time)
// - Images: Use only when absolutely necessary
// - Animations: Avoid Lottie unless critical for UX

// If you add assets, remember to:
// 1. Add to pubspec.yaml under flutter: assets:
// 2. Optimize file sizes (compress images, minimize JSON)
// 3. Consider lazy loading for non-critical assets
}