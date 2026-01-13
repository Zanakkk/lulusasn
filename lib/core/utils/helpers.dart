import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_config.dart';
// Import Timer for debounce
import 'dart:async';
/// General helper functions
class Helpers {
  Helpers._(); // Private constructor

  // ============================================================================
  // ENERGY CALCULATIONS
  // ============================================================================

  /// Calculate current energy based on regen
  static int calculateCurrentEnergy({
    required int currentEnergy,
    required int maxEnergy,
    required DateTime lastRegen,
    required int regenRateMinutes,
  }) {
    // Already at max
    if (currentEnergy >= maxEnergy) return maxEnergy;

    // Calculate time passed
    final now = DateTime.now();
    final minutesPassed = now.difference(lastRegen).inMinutes;

    // Calculate energy to add
    final energyToAdd = minutesPassed ~/ regenRateMinutes;

    // Return clamped value
    return min(currentEnergy + energyToAdd, maxEnergy);
  }

  /// Calculate time until next energy
  static Duration timeUntilNextEnergy({
    required DateTime lastRegen,
    required int regenRateMinutes,
  }) {
    final now = DateTime.now();
    final minutesPassed = now.difference(lastRegen).inMinutes;
    final minutesUntilNext = regenRateMinutes - (minutesPassed % regenRateMinutes);
    return Duration(minutes: minutesUntilNext);
  }

  /// Calculate time until full energy
  static Duration timeUntilFullEnergy({
    required int currentEnergy,
    required int maxEnergy,
    required DateTime lastRegen,
    required int regenRateMinutes,
  }) {
    if (currentEnergy >= maxEnergy) return Duration.zero;

    final energyNeeded = maxEnergy - currentEnergy;
    final minutesNeeded = energyNeeded * regenRateMinutes;

    final now = DateTime.now();
    final minutesPassed = now.difference(lastRegen).inMinutes;
    final minutesRemaining = minutesNeeded - (minutesPassed % regenRateMinutes);

    return Duration(minutes: minutesRemaining);
  }

  // ============================================================================
  // XP & LEVELING CALCULATIONS
  // ============================================================================

  /// Calculate level from XP
  static int calculateLevel(int xp) {
    int level = 1;
    int xpRequired = AppConfig.xpForLevel(level);
    int totalXp = 0;

    while (totalXp + xpRequired <= xp) {
      totalXp += xpRequired;
      level++;
      xpRequired = AppConfig.xpForLevel(level);
    }

    return level;
  }

  /// Calculate XP progress for current level
  /// Returns: {current: int, required: int, percentage: double}
  static Map<String, dynamic> calculateLevelProgress(int totalXp) {
    final level = calculateLevel(totalXp);
    final xpForCurrentLevel = AppConfig.xpForLevel(level);

    // Calculate XP used for previous levels
    int xpUsed = 0;
    for (int i = 1; i < level; i++) {
      xpUsed += AppConfig.xpForLevel(i);
    }

    final currentLevelXp = totalXp - xpUsed;
    final percentage = currentLevelXp / xpForCurrentLevel;

    return {
      'level': level,
      'current': currentLevelXp,
      'required': xpForCurrentLevel,
      'percentage': percentage,
    };
  }

  /// Calculate XP earned from exam
  static int calculateExamXp({
    required int correctCount,
    required int totalQuestions,
    required bool isPerfectScore,
    required bool isFirstExamToday,
  }) {
    int xp = 0;

    // Base XP from correct answers
    xp += correctCount * AppConfig.xpPerCorrectAnswer;

    // Participation XP for wrong answers
    final wrongCount = totalQuestions - correctCount;
    xp += wrongCount * AppConfig.xpPerWrongAnswer;

    // Bonus XP for perfect score
    if (isPerfectScore) {
      xp += AppConfig.bonusXpPerfectScore;
    }

    // Bonus XP for first exam of the day
    if (isFirstExamToday) {
      xp += AppConfig.bonusXpFirstExamDaily;
    }

    return xp;
  }

  // ============================================================================
  // STREAK CALCULATIONS
  // ============================================================================

  /// Calculate new streak based on last active date
  static int calculateStreak({
    required String lastActiveDate, // YYYY-MM-DD
    required int currentStreak,
  }) {
    final today = DateTime.now();
    final todayString = today.toIso8601String().split('T')[0];

    // Already active today
    if (lastActiveDate == todayString) {
      return currentStreak;
    }

    // Check if yesterday
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayString = yesterday.toIso8601String().split('T')[0];

    if (lastActiveDate == yesterdayString) {
      return currentStreak + 1; // Continue streak
    }

    // Streak broken
    return 1;
  }

  /// Check if streak reward milestone reached
  static Map<String, dynamic>? getStreakReward(int streak) {
    if (AppConfig.streakRewards.containsKey(streak)) {
      return AppConfig.streakRewards[streak];
    }
    return null;
  }

  // ============================================================================
  // ACCURACY CALCULATIONS
  // ============================================================================

  /// Calculate accuracy percentage
  static double calculateAccuracy(int correct, int total) {
    if (total == 0) return 0.0;
    return correct / total;
  }

  /// Get accuracy category
  /// Returns: "excellent", "good", "fair", "poor"
  static String getAccuracyCategory(double accuracy) {
    if (accuracy >= 0.9) return 'excellent';
    if (accuracy >= 0.7) return 'good';
    if (accuracy >= 0.5) return 'fair';
    return 'poor';
  }

  // ============================================================================
  // QUESTION SELECTION (ADAPTIVE)
  // ============================================================================

  /// Shuffle list (Fisher-Yates algorithm)
  static List<T> shuffleList<T>(List<T> list) {
    final shuffled = List<T>.from(list);
    final random = Random();

    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }

    return shuffled;
  }

  /// Get random elements from list
  static List<T> getRandomElements<T>(List<T> list, int count) {
    if (list.length <= count) return list;
    final shuffled = shuffleList(list);
    return shuffled.sublist(0, count);
  }

  // ============================================================================
  // PAYMENT CALCULATIONS
  // ============================================================================

  /// Calculate net revenue after Flip fee
  static int calculateNetRevenue(int grossAmount) {
    return AppConfig.calculateNetRevenue(grossAmount);
  }

  /// Calculate Flip transaction fee
  static int calculateFlipFee(int amount) {
    return (amount * AppConfig.flipFeePercentage / 100).round();
  }

  // ============================================================================
  // DATE & TIME HELPERS
  // ============================================================================

  /// Check if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Get days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    from = startOfDay(from);
    to = startOfDay(to);
    return to.difference(from).inDays;
  }

  /// Get current date string (YYYY-MM-DD)
  static String getCurrentDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ============================================================================
  // VALIDATION HELPERS
  // ============================================================================

  /// Check if user is premium
  static bool isPremiumActive({
    required bool isPremium,
    required DateTime? premiumUntil,
  }) {
    if (!isPremium) return false;
    if (premiumUntil == null) return false;
    return premiumUntil.isAfter(DateTime.now());
  }

  /// Check if email is verified
  static bool isEmailVerified(bool? emailVerified) {
    return emailVerified ?? false;
  }

  // ============================================================================
  // RANDOM GENERATORS
  // ============================================================================

  /// Generate random string (for IDs)
  static String generateRandomId([int length = 20]) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generate random number in range
  static int randomInt(int min, int max) {
    final random = Random();
    return min + random.nextInt(max - min + 1);
  }

  // ============================================================================
  // COLOR HELPERS
  // ============================================================================

  /// Get color for accuracy
  static Color getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  /// Get color for energy level
  static Color getEnergyColor(int current, int max) {
    final percentage = current / max;
    if (percentage >= 0.6) return Colors.green;
    if (percentage >= 0.3) return Colors.orange;
    return Colors.red;
  }

  // ============================================================================
  // DIALOG HELPERS
  // ============================================================================

  /// Show confirmation dialog
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Tidak',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ============================================================================
  // ERROR HANDLING
  // ============================================================================

  /// Get user-friendly error message from Firebase error
  static String getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Email tidak terdaftar';
      case 'wrong-password':
        return 'Password salah';
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'weak-password':
        return 'Password terlalu lemah';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-disabled':
        return 'Akun telah dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah';
      default:
        return 'Terjadi kesalahan. Coba lagi nanti';
    }
  }

  // ============================================================================
  // DEBOUNCE & THROTTLE
  // ============================================================================

  /// Simple debounce implementation
  static void Function() debounce(
      void Function() function,
      Duration delay,
      ) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, function);
    };
  }
}
