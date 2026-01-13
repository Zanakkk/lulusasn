// lib/core/services/storage_service.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Local storage service using SharedPreferences.
///
/// Responsibilities:
/// - Store/retrieve simple key-value data
/// - Cache user preferences
/// - Store onboarding status
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

  /// Check if onboarding is completed
  bool get isOnboardingCompleted {
    return getBool(_keyOnboardingCompleted) ?? false;
  }

  /// Mark onboarding as completed
  Future<void> setOnboardingCompleted(bool completed) async {
    await setBool(_keyOnboardingCompleted, completed);
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
  }

  // ---------- LAST LOGIN ----------

  /// Get last login email (for auto-fill)
  String? get lastLoginEmail {
    return getString(_keyLastLoginEmail);
  }

  /// Save last login email
  Future<void> setLastLoginEmail(String email) async {
    await setString(_keyLastLoginEmail, email);
  }

  /// Clear last login email
  Future<void> clearLastLoginEmail() async {
    await remove(_keyLastLoginEmail);
  }

  // ---------- NOTIFICATIONS ----------

  /// Check if notifications are enabled
  bool get notificationsEnabled {
    return getBool(_keyNotificationsEnabled) ?? true; // Default: enabled
  }

  /// Toggle notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    await setBool(_keyNotificationsEnabled, enabled);
  }

  // ---------- SOUND ----------

  /// Check if sound is enabled
  bool get soundEnabled {
    return getBool(_keySoundEnabled) ?? true; // Default: enabled
  }

  /// Toggle sound
  Future<void> setSoundEnabled(bool enabled) async {
    await setBool(_keySoundEnabled, enabled);
  }

  // ---------- FIRST LAUNCH ----------

  /// Check if this is the first app launch
  bool get isFirstLaunch {
    return getBool(_keyFirstLaunch) ?? true;
  }

  /// Mark first launch as completed
  Future<void> setFirstLaunchCompleted() async {
    await setBool(_keyFirstLaunch, false);
  }

  // ---------- APP VERSION ----------

  /// Get stored app version
  String? get appVersion {
    return getString(_keyAppVersion);
  }

  /// Save current app version
  Future<void> setAppVersion(String version) async {
    await setString(_keyAppVersion, version);
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
}