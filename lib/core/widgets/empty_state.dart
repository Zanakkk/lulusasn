// lib/core/widgets/empty_state.dart

import 'package:flutter/material.dart';
import 'brutalist_button.dart';

/// Brutalist-style empty state widget.
///
/// Use cases:
/// - No data available
/// - Empty search results
/// - No internet connection
/// - Feature not yet available
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Color iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.iconColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon in brutalist box
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(6, 6),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              // Action button
              if (actionText != null && onAction != null) ...[
                const SizedBox(height: 32),
                DuolingoButton.primary(
                  text: actionText!,
                  onPressed: onAction,
                  width: double.infinity,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// No data variant
  factory EmptyState.noData({
    String title = 'Tidak Ada Data',
    String message = 'Belum ada data yang tersedia saat ini.',
    String? actionText,
    VoidCallback? onAction,
  }) {
    return EmptyState(
      icon: Icons.inbox_outlined,
      title: title,
      message: message,
      actionText: actionText,
      onAction: onAction,
    );
  }

  /// Empty search results
  factory EmptyState.noResults({
    String searchQuery = '',
    VoidCallback? onClearSearch,
  }) {
    return EmptyState(icon: Icons.search_off,
      title: 'Tidak Ditemukan',
      message: searchQuery.isEmpty
          ? 'Coba gunakan kata kunci yang berbeda.'
          : 'Tidak ada hasil untuk "$searchQuery".',
      actionText: onClearSearch != null ? 'HAPUS PENCARIAN' : null,
      onAction: onClearSearch,
    );
  }
  /// No internet connection
  factory EmptyState.noInternet({
    required VoidCallback onRetry,
  }) {
    return EmptyState(
      icon: Icons.wifi_off,
      title: 'Tidak Ada Koneksi',
      message: 'Periksa koneksi internet Anda dan coba lagi.',
      actionText: 'COBA LAGI',
      onAction: onRetry,
      iconColor: Colors.red,
    );
  }
  /// Coming soon
  factory EmptyState.comingSoon({
    String? feature,
  }) {
    return EmptyState(
      icon: Icons.construction_outlined,
      title: 'Segera Hadir',
      message: feature != null
          ? '$feature akan segera tersedia.'
          : 'Fitur ini sedang dalam pengembangan.',
      iconColor: const Color(0xFFFFD700),
    );
  }
  /// No notifications
  factory EmptyState.noNotifications() {
    return const EmptyState(
      icon: Icons.notifications_none,
      title: 'Tidak Ada Notifikasi',
      message: 'Anda akan menerima notifikasi di sini.',
    );
  }
  /// Empty favorites
  factory EmptyState.noFavorites({
    VoidCallback? onBrowse,
  }) {
    return EmptyState(
      icon: Icons.favorite_border,
      title: 'Belum Ada Favorit',
      message: 'Tandai soal atau materi favorit Anda di sini.',
      actionText: onBrowse != null ? 'JELAJAHI' : null,
      onAction: onBrowse,
    );
  }
  /// Error state (with retry)
  factory EmptyState.error({
    String title = 'Terjadi Kesalahan',
    String message = 'Gagal memuat data. Silakan coba lagi.',
    required VoidCallback onRetry,
  }) {
    return EmptyState(
      icon: Icons.error_outline,
      title: title,
      message: message,
      actionText: 'COBA LAGI',
      onAction: onRetry,
      iconColor: Colors.red,
    );
  }
}