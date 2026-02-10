// lib/core/services/storage_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Local storage service using SharedPreferences.
///
/// Responsibilities:
/// - Store/retrieve simple key-value data
/// - Cache user preferences
/// - Store onboarding status
/// - Store goal setting status
/// - Theme preferences
/// - Last login info
class StorageService {
  // Singleton pattern
  StorageService._();
  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  ///
  /// Call this once in main() before runApp()
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    if (kDebugMode) {
      print('✅ StorageService initialized');
    }
  }

  /// Ensure prefs is initialized
  void _ensureInitialized() {
    if (_prefs == null) {
      throw Exception(
        'StorageService not initialized. Call initialize() first.',
      );
    }
  }

  // ============================================================================
  // STORAGE KEYS
  // ============================================================================

  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyGoalCompleted = 'goal_completed';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLastLoginEmail = 'last_login_email';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyAppVersion = 'app_version';

  // ============================================================================
  // GENERIC METHODS
  // ============================================================================

  /// Save string value
  Future<bool> setString(String key, String value) async {
    _ensureInitialized();
    return await _prefs!.setString(key, value);
  }

  /// Get string value
  String? getString(String key) {
    _ensureInitialized();
    return _prefs!.getString(key);
  }

  /// Save int value
  Future<bool> setInt(String key, int value) async {
    _ensureInitialized();
    return await _prefs!.setInt(key, value);
  }

  /// Get int value
  int? getInt(String key) {
    _ensureInitialized();
    return _prefs!.getInt(key);
  }

  /// Save bool value
  Future<bool> setBool(String key, bool value) async {
    _ensureInitialized();
    return await _prefs!.setBool(key, value);
  }

  /// Get bool value
  bool? getBool(String key) {
    _ensureInitialized();
    return _prefs!.getBool(key);
  }

  /// Save double value
  Future<bool> setDouble(String key, double value) async {
    _ensureInitialized();
    return await _prefs!.setDouble(key, value);
  }

  /// Get double value
  double? getDouble(String key) {
    _ensureInitialized();
    return _prefs!.getDouble(key);
  }

  /// Save string list
  Future<bool> setStringList(String key, List<String> value) async {
    _ensureInitialized();
    return await _prefs!.setStringList(key, value);
  }

  /// Get string list
  List<String>? getStringList(String key) {
    _ensureInitialized();
    return _prefs!.getStringList(key);
  }

  /// Remove specific key
  Future<bool> remove(String key) async {
    _ensureInitialized();
    return await _prefs!.remove(key);
  }

  /// Check if key exists
  bool containsKey(String key) {
    _ensureInitialized();
    return _prefs!.containsKey(key);
  }

  /// Clear all data
  Future<bool> clear() async {
    _ensureInitialized();
    return await _prefs!.clear();
  }

  // ============================================================================
  // APP-SPECIFIC METHODS
  // ============================================================================

  // ---------- ONBOARDING ----------

  /// Check if onboarding is completed (Getter)
  bool get isOnboardingCompleted {
    return getBool(_keyOnboardingCompleted) ?? false;
  }

  /// Check if onboarding has been seen (Method style)
  /// Alias untuk isOnboardingCompleted
  bool hasSeenOnboarding() {
    return getBool(_keyOnboardingCompleted) ?? false;
  }

  /// Mark onboarding as completed
  Future<void> setOnboardingCompleted(bool completed) async {
    await setBool(_keyOnboardingCompleted, completed);
    if (kDebugMode) {
      print('✅ Onboarding completed: $completed');
    }
  }

  /// Mark onboarding as seen (Shorthand)
  Future<void> setOnboardingSeen() async {
    await setBool(_keyOnboardingCompleted, true);
    if (kDebugMode) {
      print('✅ Onboarding marked as seen');
    }
  }

  /// Reset onboarding status (for testing)
  Future<void> resetOnboarding() async {
    await remove(_keyOnboardingCompleted);
    if (kDebugMode) {
      print('🔄 Onboarding reset');
    }
  }

  // ---------- GOAL SETTING ----------

  /// Check if goal has been set (Getter)
  bool get isGoalCompleted {
    return getBool(_keyGoalCompleted) ?? false;
  }

  /// Check if goal has been set (Method style)
  bool hasSetGoal() {
    return getBool(_keyGoalCompleted) ?? false;
  }

  /// Mark goal as completed
  Future<void> setGoalCompleted() async {
    await setBool(_keyGoalCompleted, true);
    if (kDebugMode) {
      print('✅ Goal setting completed');
    }
  }

  /// Reset goal status (for testing)
  Future<void> resetGoal() async {
    await remove(_keyGoalCompleted);
    if (kDebugMode) {
      print('🔄 Goal reset');
    }
  }

  // ---------- THEME ----------

  /// Get saved theme mode
  /// Returns: 'light', 'dark', or null (system default)
  String? get themeMode {
    return getString(_keyThemeMode);
  }

  /// Save theme mode
  Future<void> setThemeMode(String mode) async {
    await setString(_keyThemeMode, mode);
    if (kDebugMode) {
      print('🎨 Theme mode set to: $mode');
    }
  }

  // ---------- LAST LOGIN ----------

  /// Get last login email (for auto-fill)
  String? get lastLoginEmail {
    return getString(_keyLastLoginEmail);
  }

  /// Save last login email
  Future<void> setLastLoginEmail(String email) async {
    await setString(_keyLastLoginEmail, email);
    if (kDebugMode) {
      print('📧 Last login email saved: $email');
    }
  }

  /// Clear last login email
  Future<void> clearLastLoginEmail() async {
    await remove(_keyLastLoginEmail);
    if (kDebugMode) {
      print('🗑️ Last login email cleared');
    }
  }

  // ---------- NOTIFICATIONS ----------

  /// Check if notifications are enabled
  bool get notificationsEnabled {
    return getBool(_keyNotificationsEnabled) ?? true; // Default: enabled
  }

  /// Toggle notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    await setBool(_keyNotificationsEnabled, enabled);
    if (kDebugMode) {
      print('🔔 Notifications ${enabled ? "enabled" : "disabled"}');
    }
  }

  // ---------- SOUND ----------

  /// Check if sound is enabled
  bool get soundEnabled {
    return getBool(_keySoundEnabled) ?? true; // Default: enabled
  }

  /// Toggle sound
  Future<void> setSoundEnabled(bool enabled) async {
    await setBool(_keySoundEnabled, enabled);
    if (kDebugMode) {
      print('🔊 Sound ${enabled ? "enabled" : "disabled"}');
    }
  }

  // ---------- FIRST LAUNCH ----------

  /// Check if this is the first app launch
  bool get isFirstLaunch {
    return getBool(_keyFirstLaunch) ?? true;
  }

  /// Mark first launch as completed
  Future<void> setFirstLaunchCompleted() async {
    await setBool(_keyFirstLaunch, false);
    if (kDebugMode) {
      print('✅ First launch completed');
    }
  }

  // ---------- APP VERSION ----------

  /// Get stored app version
  String? get appVersion {
    return getString(_keyAppVersion);
  }

  /// Save current app version
  Future<void> setAppVersion(String version) async {
    await setString(_keyAppVersion, version);
    if (kDebugMode) {
      print('📱 App version saved: $version');
    }
  }

  // ============================================================================
  // RESET METHODS (FOR TESTING & LOGOUT)
  // ============================================================================

  /// Reset entire onboarding flow (onboarding + goal)
  Future<void> resetOnboardingFlow() async {
    await remove(_keyOnboardingCompleted);
    await remove(_keyGoalCompleted);
    if (kDebugMode) {
      print('🔄 Onboarding flow reset (onboarding + goal)');
    }
  }

  /// Clear all user-related data (use on logout)
  Future<void> clearUserData() async {
    await remove(_keyOnboardingCompleted);
    await remove(_keyGoalCompleted);
    await remove(_keyLastLoginEmail);

    if (kDebugMode) {
      print('🗑️ User data cleared');
    }
  }

  /// Clear all app data (nuclear option)
  Future<void> clearAllData() async {
    await clear();
    if (kDebugMode) {
      print('💣 All storage data cleared');
    }
  }

  // ============================================================================
  // DEBUG METHODS
  // ============================================================================

  /// Print all stored keys (debug only)
  void printAllKeys() {
    if (kDebugMode) {
      _ensureInitialized();
      final keys = _prefs!.getKeys();
      print('📦 StorageService Keys: $keys');
    }
  }

  /// Get all stored data (debug only)
  Map<String, dynamic> getAllData() {
    _ensureInitialized();
    final keys = _prefs!.getKeys();
    final Map<String, dynamic> data = {};

    for (final key in keys) {
      data[key] = _prefs!.get(key);
    }

    return data;
  }

  /// Print all data with values (debug only)
  void printAllData() {
    if (kDebugMode) {
      final data = getAllData();
      print('📦 StorageService Data:');
      data.forEach((key, value) {
        print('  $key: $value');
      });
    }
  }

  /// Get status summary (debug only)
  String getStatusSummary() {
    return '''
📊 Storage Status:
  - Onboarding Completed: ${isOnboardingCompleted}
  - Goal Completed: ${isGoalCompleted}
  - First Launch: ${isFirstLaunch}
  - Notifications: ${notificationsEnabled}
  - Sound: ${soundEnabled}
  - Theme: ${themeMode ?? 'system'}
  - Last Login: ${lastLoginEmail ?? 'none'}
  - App Version: ${appVersion ?? 'unknown'}
''';
  }

  /// Print status summary (debug only)
  void printStatus() {
    if (kDebugMode) {
      print(getStatusSummary());
    }
  }
  // ---------- LOGIN STATUS ----------

  static const String _keyHasEverLoggedIn = 'has_ever_logged_in';

  /// Check if user has ever logged in before (Getter)
  bool get hasEverLoggedIn {
    return getBool(_keyHasEverLoggedIn) ?? false;
  }

  /// Mark user as logged in before
  Future<void> setHasEverLoggedIn(bool value) async {
    await setBool(_keyHasEverLoggedIn, value);
    if (kDebugMode) {
      print('✅ Has ever logged in: $value');
    }
  }

  /// Reset login status (for testing)
  Future<void> resetLoginStatus() async {
    await remove(_keyHasEverLoggedIn);
    if (kDebugMode) {
      print('🔄 Login status reset');
    }
  }
}