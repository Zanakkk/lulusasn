// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'formatters.dart';


// Import math for pow
import 'dart:math';
// ============================================================================
// STRING EXTENSIONS
// ============================================================================

extension StringExtensions on String {
  /// Check if string is empty or null
  bool get isNullOrEmpty => isEmpty;

  /// Capitalize first letter
  String get capitalize => Formatters.capitalize(this);

  /// Title case (capitalize each word)
  String get titleCase => Formatters.titleCase(this);

  /// Remove extra spaces
  String get cleanSpaces => Formatters.cleanSpaces(this);

  /// Truncate with ellipsis
  String truncate(int maxLength) => Formatters.truncate(this, maxLength);

  /// Check if string is valid email
  bool get isEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this);
  }

  /// Check if string is numeric
  bool get isNumeric => int.tryParse(this) != null || double.tryParse(this) != null;

  /// Parse to int safely
  int? get toIntOrNull => int.tryParse(this);

  /// Parse to double safely
  double? get toDoubleOrNull => double.tryParse(this);

  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');
}

// ============================================================================
// INT EXTENSIONS
// ============================================================================

extension IntExtensions on int {
  /// Format as Rupiah
  String get toRupiah => Formatters.rupiah(this);

  /// Format as compact Rupiah (with K/M suffix)
  String get toRupiahCompact => Formatters.rupiahCompact(this);

  /// Format with thousand separators
  String get toFormatted => Formatters.number(this);

  /// Format as duration (MM:SS)
  String get toDuration => Formatters.duration(this);

  /// Format as duration (HH:MM:SS)
  String get toDurationLong => Formatters.durationLong(this);

  /// Format as human readable duration
  String get toDurationHuman => Formatters.durationHuman(this);

  /// Format as XP gain
  String get toXpGain => Formatters.xpGain(this);

  /// Format as rank
  String get toRank => Formatters.rank(this);

  /// Format as file size
  String get toFileSize => Formatters.fileSize(this);

  /// Check if number is even
  bool get isEven => this % 2 == 0;

  /// Check if number is ?odd
  bool get isOdd => this % 2 != 0;

  /// Clamp between min and max

  int clampValue(int min, int max) => clamp(min, max) as int;

}

// ============================================================================
// DOUBLE EXTENSIONS
// ============================================================================

extension DoubleExtensions on double {
  /// Format as percentage
  String toPercentage({int decimalPlaces = 1}) {
    return Formatters.percentage(this, decimalPlaces: decimalPlaces);
  }

  /// Format as accuracy
  String get toAccuracy => Formatters.accuracy(this);

  /// Format as decimal
  String toDecimal({int decimalPlaces = 2}) {
    return Formatters.decimal(this, decimalPlaces: decimalPlaces);
  }

  /// Round to specific decimal places
  double roundTo(int decimalPlaces) {
    final factor = pow(10, decimalPlaces);
    return (this * factor).round() / factor;
  }

  /// Clamp between min and max
  double clampValue(double min, double max) => clamp(min, max) as double;
}

// ============================================================================
// DATETIME EXTENSIONS
// ============================================================================

extension DateTimeExtensions on DateTime {
  /// Format as Indonesian date
  String get toFormattedDate => Formatters.date(this);

  /// Format as short date
  String get toShortDate => Formatters.dateShort(this);

  /// Format as compact date
  String get toCompactDate => Formatters.dateCompact(this);

  /// Format as time
  String get toFormattedTime => Formatters.time(this);

  /// Format as date and time
  String get toFormattedDateTime => Formatters.dateTime(this);

  /// Format as relative time
  String get toRelativeTime => Formatters.relativeTime(this);

  /// Format as time ago (short)
  String get toTimeAgo => Formatters.timeAgo(this);

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Get start of day (00:00:00)
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day (23:59:59)
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  /// Add days
  DateTime addDays(int days) => add(Duration(days: days));

  /// Subtract days
  DateTime subtractDays(int days) => subtract(Duration(days: days));

  /// Check if date is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Check if date is in the future
  bool get isFuture => isAfter(DateTime.now());

  /// Get days until this date
  int get daysUntil {
    final now = DateTime.now();
    final difference = this.difference(now);
    return difference.inDays;
  }

  /// Get days since this date
  int get daysSince {
    final now = DateTime.now();
    final difference = now.difference(this);
    return difference.inDays;
  }

  /// Format as YYYY-MM-DD (for Firestore)
  String get toDateString {
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// DURATION EXTENSIONS
// ============================================================================

extension DurationExtensions on Duration {
  /// Format as MM:SS
  String get toFormatted => Formatters.duration(inSeconds);

  /// Format as HH:MM:SS
  String get toFormattedLong => Formatters.durationLong(inSeconds);

  /// Format as human readable
  String get toHuman => Formatters.durationHuman(inSeconds);

  /// Format as countdown
  String get toCountdown => Formatters.countdown(inSeconds);
}

// ============================================================================
// LIST EXTENSIONS
// ============================================================================

extension ListExtensions<T> on List<T> {
  /// Check if list is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Get first element or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last element or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Shuffle list (returns new list)
  List<T> get shuffled {
    final copy = List<T>.from(this);
    copy.shuffle();
    return copy;
  }

  /// Get random element
  T? get random {
    if (isEmpty) return null;
    return this[Random().nextInt(length)];
  }

  /// Chunk list into smaller lists
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}

// ============================================================================
// COLOR EXTENSIONS
// ============================================================================

extension ColorExtensions on Color {
  /// Convert to hex string
  String get toHex {
    return '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  /// Lighten color by percentage
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Darken color by percentage
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Change opacity
  Color withOpacityValue(double opacity) {
    return withOpacity(opacity.clamp(0.0, 1.0));
  }
}

// ============================================================================
// BUILDCONTEXT EXTENSIONS
// ============================================================================

extension BuildContextExtensions on BuildContext {
  /// Get screen size
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Check if mobile
  bool get isMobile => screenWidth < 600;

  /// Check if tablet
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  /// Check if desktop
  bool get isDesktop => screenWidth >= 1200;

  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => theme.textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Show snackbar (shorthand)
  void showSnackbar(String message, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: backgroundColor,
      ),
    );
  }

  /// Show success snackbar
  void showSuccess(String message) {
    showSnackbar(message, backgroundColor: Colors.green);
  }

  /// Show error snackbar
  void showError(String message) {
    showSnackbar(message, backgroundColor: Colors.red);
  }

  /// Pop navigator
  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  /// Push route
  Future<T?> push<T>(Widget page) {
    return Navigator.of(this).push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Push replacement
  Future<T?> pushReplacement<T, TO>(Widget page) {
    return Navigator.of(this).pushReplacement<T, TO>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Hide keyboard
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}

// ============================================================================
// MAP EXTENSIONS
// ============================================================================

extension MapExtensions<K, V> on Map<K, V> {
  /// Get value or default
  V getOrDefault(K key, V defaultValue) {
    return this[key] ?? defaultValue;
  }

  /// Check if key exists and value is not null
  bool hasValue(K key) {
    return containsKey(key) && this[key] != null;
  }
}