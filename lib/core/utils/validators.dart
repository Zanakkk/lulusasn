import '../constants/app_config.dart';

/// Input validation utilities
class Validators {
  Validators._(); // Private constructor

  // ============================================================================
  // EMAIL VALIDATION
  // ============================================================================

  /// Validate email format
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }

    // RFC 5322 compliant regex (simplified)
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }

    return null; // Valid
  }

  /// Check if email is valid (returns bool)
  static bool isValidEmail(String email) {
    return Validators.email(email) == null;
  }

  // ============================================================================
  // PASSWORD VALIDATION
  // ============================================================================

  /// Validate password (minimum length)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }

    if (value.length < AppConfig.minPasswordLength) {
      return 'Password minimal ${AppConfig.minPasswordLength} karakter';
    }

    return null; // Valid
  }

  /// Validate strong password (with requirements)
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }

    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }

    // Check for uppercase
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password harus mengandung huruf besar';
    }

    // Check for lowercase
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password harus mengandung huruf kecil';
    }

    // Check for number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password harus mengandung angka';
    }

    return null; // Valid
  }

  /// Validate password confirmation match
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }

    if (value != password) {
      return 'Password tidak sama';
    }

    return null; // Valid
  }

  // ============================================================================
  // USERNAME VALIDATION
  // ============================================================================

  /// Validate username
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username wajib diisi';
    }

    if (value.length < AppConfig.minUsernameLength) {
      return 'Username minimal ${AppConfig.minUsernameLength} karakter';
    }

    if (value.length > AppConfig.maxUsernameLength) {
      return 'Username maksimal ${AppConfig.maxUsernameLength} karakter';
    }

    // Only alphanumeric and underscore
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username hanya boleh huruf, angka, dan underscore';
    }

    return null; // Valid
  }

  // ============================================================================
  // NAME VALIDATION
  // ============================================================================

  /// Validate full name
  static String? fullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama lengkap wajib diisi';
    }

    if (value.length < 3) {
      return 'Nama minimal 3 karakter';
    }

    if (value.length > 50) {
      return 'Nama maksimal 50 karakter';
    }

    // Only letters and spaces
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(value)) {
      return 'Nama hanya boleh huruf dan spasi';
    }

    return null; // Valid
  }

  // ============================================================================
  // PHONE NUMBER VALIDATION
  // ============================================================================

  /// Validate Indonesian phone number
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor telepon wajib diisi';
    }

    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');

    // Indonesian phone number patterns:
    // 08xx-xxxx-xxxx (mobile)
    // +628xx-xxxx-xxxx (mobile with country code)
    // 021-xxxx-xxxx (Jakarta landline)
    final phoneRegex = RegExp(r'^(\+62|62|0)[0-9]{9,12}$');

    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Format nomor telepon tidak valid';
    }

    return null; // Valid
  }

  // ============================================================================
  // NUMERIC VALIDATION
  // ============================================================================

  /// Validate required field
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  /// Validate number
  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return 'Angka wajib diisi';
    }

    if (int.tryParse(value) == null && double.tryParse(value) == null) {
      return 'Harus berupa angka';
    }

    return null;
  }

  /// Validate integer
  static String? integer(String? value) {
    if (value == null || value.isEmpty) {
      return 'Angka wajib diisi';
    }

    if (int.tryParse(value) == null) {
      return 'Harus berupa angka bulat';
    }

    return null;
  }

  /// Validate number range
  static String? numberRange(String? value, int min, int max) {
    if (value == null || value.isEmpty) {
      return 'Angka wajib diisi';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return 'Harus berupa angka';
    }

    if (number < min || number > max) {
      return 'Angka harus antara $min dan $max';
    }

    return null;
  }

  // ============================================================================
  // LENGTH VALIDATION
  // ============================================================================

  /// Validate minimum length
  static String? minLength(String? value, int length) {
    if (value == null || value.isEmpty) {
      return 'Field wajib diisi';
    }

    if (value.length < length) {
      return 'Minimal $length karakter';
    }

    return null;
  }

  /// Validate maximum length
  static String? maxLength(String? value, int length) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    if (value.length > length) {
      return 'Maksimal $length karakter';
    }

    return null;
  }

  /// Validate exact length
  static String? exactLength(String? value, int length) {
    if (value == null || value.isEmpty) {
      return 'Field wajib diisi';
    }

    if (value.length != length) {
      return 'Harus $length karakter';
    }

    return null;
  }

  // ============================================================================
  // URL VALIDATION
  // ============================================================================

  /// Validate URL
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL wajib diisi';
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Format URL tidak valid';
    }

    return null;
  }

  // ============================================================================
  // DATE VALIDATION
  // ============================================================================

  /// Validate date format (YYYY-MM-DD)
  static String? date(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tanggal wajib diisi';
    }

    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(value)) {
      return 'Format tanggal harus YYYY-MM-DD';
    }

    // Try parsing
    try {
      DateTime.parse(value);
    } catch (e) {
      return 'Tanggal tidak valid';
    }

    return null;
  }

  /// Validate age (minimum age required)
  static String? minimumAge(DateTime? birthDate, int minimumAge) {
    if (birthDate == null) {
      return 'Tanggal lahir wajib diisi';
    }

    final today = DateTime.now();
    final age = today.year - birthDate.year;

    if (age < minimumAge) {
      return 'Umur minimal $minimumAge tahun';
    }

    return null;
  }

  // ============================================================================
  // CUSTOM VALIDATORS
  // ============================================================================

  /// Validate question text (for admin)
  static String? questionText(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pertanyaan wajib diisi';
    }

    if (value.length < 10) {
      return 'Pertanyaan minimal 10 karakter';
    }

    if (value.length > 500) {
      return 'Pertanyaan maksimal 500 karakter';
    }

    return null;
  }

  /// Validate answer option (for admin)
  static String? answerOption(String? value) {
    if (value == null || value.isEmpty) {
      return 'Opsi jawaban wajib diisi';
    }

    if (value.length > 200) {
      return 'Opsi maksimal 200 karakter';
    }

    return null;
  }

  /// Validate explanation (for admin)
  static String? explanation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Penjelasan wajib diisi';
    }

    if (value.length < 20) {
      return 'Penjelasan minimal 20 karakter';
    }

    if (value.length > 1000) {
      return 'Penjelasan maksimal 1000 karakter';
    }

    return null;
  }

  // ============================================================================
  // COMPOSITE VALIDATORS
  // ============================================================================

  /// Combine multiple validators
  static String? Function(String?) combine(
      List<String? Function(String?)> validators,
      ) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }

  /// Validate if at least one field is filled
  static String? atLeastOne(List<String?> values, String message) {
    final hasValue = values.any((v) => v != null && v.isNotEmpty);
    return hasValue ? null : message;
  }
}