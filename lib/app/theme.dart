//
// import '../../app/theme.dart';
//
// ╔══════════════════════════════════════════════════════════════╗
// ║              LULUZZZ — Official Design System                ║
// ║  Style  : Modern Minimal                                     ║
// ║  Font   : Plus Jakarta Sans                                  ║
// ║  Palette: Navy · Gold · White                                ║
// ╚══════════════════════════════════════════════════════════════╝

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FORMATTERS  (hanya yang benar-benar dipakai)
// ─────────────────────────────────────────────────────────────────────────────
class Formatters {
  Formatters._();

  // Rupiah — dipakai lewat .toRupiah / .toRupiahCompact
  static String rupiah(int v) =>
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(v);

  static String rupiahCompact(int v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}M';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}K';
    return rupiah(v);
  }

  // Tanggal — dipakai lewat DateTimeExtensions
  static String date(DateTime d) => DateFormat('d MMMM yyyy', 'id_ID').format(d);
  static String dateShort(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);
  static String time(DateTime d) => DateFormat('HH:mm').format(d);
  static String dateTime(DateTime d) => DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(d);

  static String relativeTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan lalu';
    return '${(diff.inDays / 365).floor()} tahun lalu';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXTENSIONS
// ─────────────────────────────────────────────────────────────────────────────

extension IntFormatX on int {
  String get toRupiah => Formatters.rupiah(this);
  String get toRupiahCompact => Formatters.rupiahCompact(this);
}

extension DateTimeFormatX on DateTime {
  String get toFormattedDate => Formatters.date(this);
  String get toShortDate => Formatters.dateShort(this);
  String get toFormattedTime => Formatters.time(this);
  String get toFormattedDateTime => Formatters.dateTime(this);
  String get toRelativeTime => Formatters.relativeTime(this);

  bool get isToday {
    final n = DateTime.now();
    return year == n.year && month == n.month && day == n.day;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUILDCONTEXT EXTENSIONS  (show snackbar — sudah dipakai)
// ─────────────────────────────────────────────────────────────────────────────
extension BuildContextX on BuildContext {
  // Screen helpers
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;

  // Theme shortcuts
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;

  // Navigation
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  Future<T?> push<T>(Widget page) =>
      Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => page));

  // Snackbar
  void showSnackbar(String msg, {Color? bg, Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg, duration: duration),
    );
  }

  void showSuccess(String msg) => showSnackbar(msg, bg: const Color(0xFF10B981));
  void showError(String msg) => showSnackbar(msg, bg: const Color(0xFFEF4444));

  void hideKeyboard() => FocusScope.of(this).unfocus();
}

// ─────────────────────────────────────────────────────────────────────────────
// APP CONFIG
// ─────────────────────────────────────────────────────────────────────────────
class AppConfig {
  AppConfig._();
  static const int minPasswordLength = 6;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
}

// ─────────────────────────────────────────────────────────────────────────────
// VALIDATORS  (hanya email & password — yang benar-benar dipakai)
// ─────────────────────────────────────────────────────────────────────────────
class Validators {
  Validators._();

  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email wajib diisi';
    final ok = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return ok.hasMatch(v) ? null : 'Format email tidak valid';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password wajib diisi';
    if (v.length < AppConfig.minPasswordLength) {
      return 'Password minimal ${AppConfig.minPasswordLength} karakter';
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────
  static const primary = Color(0xFF0F172A); // Navy  — CTA, active state
  static const gold = Color(0xFFD4AF37); // Gold  — accent, highlight
  static const white = Color(0xFFFFFFFF); // White — surface, text on dark

  // ── Background ─────────────────────────────────────────────────
  static const bg = Color(0xFFF8F9FC); // Off-white canvas
  static const surface = Color(0xFFFFFFFF); // Card / dialog surface
  static const surfaceAlt = Color(0xFFF1F3F8); // Input, chip background

  // ── Text ───────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF0F172A); // Headings
  static const textSecondary = Color(0xFF64748B); // Sub-text, labels
  static const textHint = Color(0xFFB0B8C8); // Placeholder

  // ── Border ─────────────────────────────────────────────────────
  static const border = Color(0xFFE2E8F0); // Default border
  static const borderFocus = Color(0xFF0F172A); // Focused input border

  // ── Semantic ───────────────────────────────────────────────────
  static const success = Color(0xFF10B981); // Benar / berhasil
  static const warning = Color(0xFFF59E0B); // Perhatian
  static const error = Color(0xFFEF4444); // Salah / gagal
  static const info = Color(0xFF3B82F6); // Informasi

  // ── Utility ────────────────────────────────────────────────────
  /// Warna teks otomatis (putih di bg gelap, navy di bg terang)
  static Color onColor(Color bg) {
    return bg.computeLuminance() > 0.4 ? primary : white;
  }

  /// Background lembut dari warna semantic (untuk chip/badge)
  static Color softBg(Color c) => c.withOpacity(0.10);
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY  (semua pakai Plus Jakarta Sans)
// ─────────────────────────────────────────────────────────────────────────────
class AppText {
  AppText._();

  static TextStyle _j(double size, FontWeight w, {Color? color, double? ls}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: w,
        color: color ?? AppColors.textPrimary,
        letterSpacing: ls,
        height: 1.4,
      );

  // ── Display ────────────────────────────────────────────────────
  static TextStyle display = _j(32, FontWeight.w800, ls: -0.5);
  static TextStyle h1 = _j(24, FontWeight.w700, ls: -0.3);
  static TextStyle h2 = _j(20, FontWeight.w700);
  static TextStyle h3 = _j(17, FontWeight.w700);

  // ── Body ───────────────────────────────────────────────────────
  static TextStyle bodyLg = _j(15, FontWeight.w500);
  static TextStyle body = _j(14, FontWeight.w400);
  static TextStyle bodySm = _j(
    13,
    FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ── Label / Caption ────────────────────────────────────────────
  static TextStyle label = _j(12, FontWeight.w600);
  static TextStyle caption = _j(
    11,
    FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // ── Button ─────────────────────────────────────────────────────
  static TextStyle btnLg = _j(15, FontWeight.w700, color: AppColors.white);
  static TextStyle btnMd = _j(14, FontWeight.w700, color: AppColors.white);
  static TextStyle btnSm = _j(13, FontWeight.w600, color: AppColors.white);
}

// ─────────────────────────────────────────────────────────────────────────────
// SPACING  (8-pt grid)
// ─────────────────────────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Gap helpers
  static const vxs = SizedBox(height: xs);
  static const vsm = SizedBox(height: sm);
  static const vmd = SizedBox(height: md);
  static const vlg = SizedBox(height: lg);
  static const vxl = SizedBox(height: xl);

  static const hxs = SizedBox(width: xs);
  static const hsm = SizedBox(width: sm);
  static const hmd = SizedBox(width: md);
  static const hlg = SizedBox(width: lg);
}

// ─────────────────────────────────────────────────────────────────────────────
// RADIUS
// ─────────────────────────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;

  static BorderRadius circular(double r) => BorderRadius.circular(r);
  static const bSm = BorderRadius.all(Radius.circular(sm));
  static const bMd = BorderRadius.all(Radius.circular(md));
  static const bLg = BorderRadius.all(Radius.circular(lg));
  static const bXl = BorderRadius.all(Radius.circular(xl));
  static const bFull = BorderRadius.all(Radius.circular(full));
}

// ─────────────────────────────────────────────────────────────────────────────
// SHADOWS
// ─────────────────────────────────────────────────────────────────────────────
class AppShadow {
  AppShadow._();

  static const sm = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 4, offset: Offset(0, 2)),
  ];
  static const md = [
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 10, offset: Offset(0, 4)),
  ];
  static const lg = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 20, offset: Offset(0, 8)),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// GRADIENTS
// ─────────────────────────────────────────────────────────────────────────────
class AppGradient {
  AppGradient._();

  /// Navy solid → digunakan di header, hero
  static const navy = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gold shimmer → premium badge, accent strip
  static const gold = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFF0D060)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle surface → card hover / highlighted row
  static const surface = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// RESPONSIVE
// ─────────────────────────────────────────────────────────────────────────────
enum ScreenSize { mobile, tablet, desktop }

class AppResponsive {
  AppResponsive._();

  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  static ScreenSize of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < mobileMax) return ScreenSize.mobile;
    if (w < tabletMax) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  static bool isMobile(BuildContext context) =>
      of(context) == ScreenSize.mobile;
  static bool isTablet(BuildContext context) =>
      of(context) == ScreenSize.tablet;
  static bool isDesktop(BuildContext context) =>
      of(context) == ScreenSize.desktop;

  /// Pilih nilai berdasarkan screen size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    required T tablet,
    required T desktop,
  }) => switch (of(context)) {
    ScreenSize.mobile => mobile,
    ScreenSize.tablet => tablet,
    ScreenSize.desktop => desktop,
  };

  /// Padding konten utama per screen size
  static EdgeInsets pagePadding(BuildContext context) => value(
    context,
    mobile: const EdgeInsets.all(16),
    tablet: const EdgeInsets.all(24),
    desktop: const EdgeInsets.all(32),
  );

  /// Max width konten agar tidak terlalu lebar di layar besar
  static double maxContentWidth(BuildContext context) =>
      value(context, mobile: double.infinity, tablet: 860, desktop: 1200);
}

// ─────────────────────────────────────────────────────────────────────────────
// FLUTTER ThemeData
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.gold,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.primary,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppText.h2,
      iconTheme: const IconThemeData(color: AppColors.primary),
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
        textStyle: AppText.btnLg,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
        textStyle: AppText.btnLg.copyWith(color: AppColors.primary),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AppRadius.bMd,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.bMd,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.bMd,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.bMd,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: AppText.body.copyWith(color: AppColors.textHint),
      labelStyle: AppText.label,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.bLg,
        side: const BorderSide(color: AppColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );
}
