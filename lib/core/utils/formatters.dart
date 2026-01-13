// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:intl/intl.dart';

/// Formatting utilities for display
class Formatters {
  Formatters._(); // Private constructor

  // ============================================================================
  // NUMBER FORMATTING
  // ============================================================================

  /// Format number with thousand separators
  /// Example: 1000000 → "1.000.000"
  static String number(int value) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(value);
  }

  /// Format decimal number
  /// Example: 1234.56 → "1.234,56"
  static String decimal(double value, {int decimalPlaces = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimalPlaces}', 'id_ID');
    return formatter.format(value);
  }

  /// Format percentage
  /// Example: 0.856 → "85.6%"
  static String percentage(double value, {int decimalPlaces = 1}) {
    final percent = value * 100;
    return '${percent.toStringAsFixed(decimalPlaces)}%';
  }

  /// Format accuracy percentage
  /// Example: 0.75 → "75%"
  static String accuracy(double value) {
    return percentage(value, decimalPlaces: 0);
  }

  // ============================================================================
  // CURRENCY FORMATTING (Indonesian Rupiah)
  // ============================================================================

  /// Format Rupiah
  /// Example: 50000 → "Rp 50.000"
  static String rupiah(int value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  /// Format Rupiah with K/M suffix for large numbers
  /// Example: 1500000 → "Rp 1.5M"
  static String rupiahCompact(int value) {
    if (value >= 1000000) {
      final millions = value / 1000000;
      return 'Rp ${millions.toStringAsFixed(millions % 1 == 0 ? 0 : 1)}M';
    } else if (value >= 1000) {
      final thousands = value / 1000;
      return 'Rp ${thousands.toStringAsFixed(thousands % 1 == 0 ? 0 : 1)}K';
    }
    return rupiah(value);
  }

  /// Format diamond price
  /// Example: 5 → "Rp 50.000"
  static String diamondPrice(int diamondCount) {
    final price = diamondCount * 10000; // 1 diamond = Rp 10.000
    return rupiah(price);
  }

  // ============================================================================
  // DATE & TIME FORMATTING
  // ============================================================================

  /// Format date to Indonesian format
  /// Example: 2024-01-15 → "15 Januari 2024"
  static String date(DateTime date) {
    final formatter = DateFormat('d MMMM yyyy', 'id_ID');
    return formatter.format(date);
  }

  /// Format date short
  /// Example: 2024-01-15 → "15 Jan 2024"
  static String dateShort(DateTime date) {
    final formatter = DateFormat('d MMM yyyy', 'id_ID');
    return formatter.format(date);
  }

  /// Format date very short
  /// Example: 2024-01-15 → "15/01/2024"
  static String dateCompact(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  /// Format time
  /// Example: 14:30:00 → "14:30"
  static String time(DateTime dateTime) {
    final formatter = DateFormat('HH:mm');
    return formatter.format(dateTime);
  }

  /// Format date and time
  /// Example: 2024-01-15 14:30 → "15 Jan 2024, 14:30"
  static String dateTime(DateTime dateTime) {
    final formatter = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
    return formatter.format(dateTime);
  }

  /// Format relative time
  /// Example: "2 jam lalu", "3 hari lalu", "Baru saja"
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu lalu';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan lalu';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years tahun lalu';
    }
  }

  /// Format time ago (shorter version)
  /// Example: "2j", "3h", "5m"
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}d';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j';
    } else {
      return '${difference.inDays}h';
    }
  }

  // ============================================================================
  // DURATION FORMATTING
  // ============================================================================

  /// Format duration to MM:SS
  /// Example: 125 seconds → "02:05"
  static String duration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Format duration to HH:MM:SS
  /// Example: 3725 seconds → "01:02:05"
  static String durationLong(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Format duration in human readable format
  /// Example: 125 → "2 menit 5 detik"
  static String durationHuman(int seconds) {
    if (seconds < 60) {
      return '$seconds detik';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '$minutes menit';
      }
      return '$minutes menit $remainingSeconds detik';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      if (minutes == 0) {
        return '$hours jam';
      }
      return '$hours jam $minutes menit';
    }
  }

  /// Format countdown timer
  /// Example: 125 seconds → "02:05 tersisa"
  static String countdown(int seconds) {
    return '${duration(seconds)} tersisa';
  }

  // ============================================================================
  // TEXT FORMATTING
  // ============================================================================

  /// Capitalize first letter
  /// Example: "hello world" → "Hello world"
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Title case (capitalize each word)
  /// Example: "hello world" → "Hello World"
  static String titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Truncate text with ellipsis
  /// Example: "Long text here" → "Long te..."
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Remove extra spaces
  /// Example: "hello  world" → "hello world"
  static String cleanSpaces(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // ============================================================================
  // ENERGY FORMATTING
  // ============================================================================

  /// Format energy display
  /// Example: (3, 5) → "3/5"
  static String energy(int current, int max) {
    return '$current/$max';
  }

  /// Format energy with icon
  /// Example: (3, 5) → "⚡ 3/5"
  static String energyWithIcon(int current, int max) {
    return '⚡ $current/$max';
  }

  /// Format energy percentage
  /// Example: (3, 5) → "60%"
  static String energyPercentage(int current, int max) {
    final percent = (current / max) * 100;
    return '${percent.toStringAsFixed(0)}%';
  }

  // ============================================================================
  // SCORE FORMATTING
  // ============================================================================

  /// Format exam score
  /// Example: (7, 10) → "7/10"
  static String score(int correct, int total) {
    return '$correct/$total';
  }

  /// Format score with percentage
  /// Example: (7, 10) → "7/10 (70%)"
  static String scoreWithPercentage(int correct, int total) {
    final percent = (correct / total) * 100;
    return '$correct/$total (${percent.toStringAsFixed(0)}%)';
  }

  /// Format XP gain
  /// Example: 150 → "+150 XP"
  static String xpGain(int xp) {
    return '+$xp XP';
  }

  // ============================================================================
  // STREAK FORMATTING
  // ============================================================================

  /// Format streak count
  /// Example: 7 → "🔥 7 hari"
  static String streak(int days) {
    return '🔥 $days hari';
  }

  /// Format streak milestone
  /// Example: 7 → "Streak 7 hari!"
  static String streakMilestone(int days) {
    return 'Streak $days hari!';
  }

  // ============================================================================
  // RANK FORMATTING
  // ============================================================================

  /// Format rank with medal emoji
  /// Example: 1 → "🥇 #1"
  static String rank(int position) {
    String medal = '';
    if (position == 1) medal = '🥇';
    else if (position == 2) medal = '🥈';
    else if (position == 3) medal = '🥉';

    return medal.isEmpty ? '#$position' : '$medal #$position';
  }

  // ============================================================================
  // FILE SIZE FORMATTING
  // ============================================================================

  /// Format file size
  /// Example: 1536 bytes → "1.5 KB"
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ============================================================================
  // PHONE NUMBER FORMATTING
  // ============================================================================

  /// Format Indonesian phone number
  /// Example: "08123456789" → "0812-3456-789"
  static String phoneNumber(String phone) {
    // Remove non-numeric characters
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');

    if (cleaned.startsWith('08') && cleaned.length >= 10) {
      // Mobile: 0812-3456-7890
      return '${cleaned.substring(0, 4)}-${cleaned.substring(4, 8)}-${cleaned.substring(8)}';
    }

    return phone; // Return as-is if format unknown
  }
}