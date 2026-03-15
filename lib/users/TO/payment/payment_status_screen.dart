// lib/users/TO/payment/payment_status_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lulusasn/app/routes.dart';
import 'package:lulusasn/app/theme.dart';

final _currencyFmt = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);

class PaymentStatusScreen extends StatefulWidget {
  final String billLinkId;
  final String tryoutId;
  final String tryoutTitle;
  final int amount;

  const PaymentStatusScreen({
    super.key,
    required this.billLinkId,
    this.tryoutId = '',
    this.tryoutTitle = '',
    this.amount = 0,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen>
    with SingleTickerProviderStateMixin {
  // ── State utama ─────────────────────────────────────────────────────────────
  String _status = 'loading'; // loading → pending / success / failed
  String _tryoutTitle = '';
  String _tryoutId = '';
  int _amount = 0;
  String _failReason = '';
  bool _checking = false; // untuk tombol cek manual

  // ── Pulse animation ─────────────────────────────────────────────────────────
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _load(); // baca Firestore langsung saat halaman dibuka
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ── Baca Firestore (dipanggil saat init & tombol cek manual) ────────────────
  Future<void> _load({bool showFeedback = false}) async {
    if (_checking) return;
    setState(() => _checking = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('transactions')
          .doc(widget.billLinkId)
          .get();

      if (!mounted) return;

      if (!doc.exists) {
        setState(() {
          _status = 'notfound';
          _checking = false;
        });
        return;
      }

      final d = doc.data()!;
      final status = (d['status'] as String? ?? 'pending').trim().toLowerCase();

      setState(() {
        _status = status;
        _tryoutTitle = d['tryoutTitle'] as String? ?? widget.tryoutTitle;
        _tryoutId = d['tryoutId'] as String? ?? widget.tryoutId;
        _amount = (d['amount'] as num?)?.toInt() ?? widget.amount;
        _failReason = d['failureReason'] as String? ?? '';
        _checking = false;
      });

      debugPrint(
        '📦 PaymentStatus loaded — status: $status, id: ${widget.billLinkId}',
      );

      if (showFeedback && mounted) {
        final msg = switch (status) {
          'success' => '✅ Pembayaran sudah dikonfirmasi!',
          'failed' => '❌ Pembayaran gagal.',
          _ => '⏳ Pembayaran belum terkonfirmasi.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg,
              style: AppText.body.copyWith(color: AppColors.white),
            ),
            backgroundColor: status == 'success'
                ? AppColors.success
                : status == 'failed'
                ? AppColors.error
                : AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ _load error: $e');
      if (mounted) setState(() => _checking = false);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_status == 'success' || _status == 'failed') {
          Navigator.pop(context);
          return;
        }
        final ok = await _showExitDialog(context);
        if (ok == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: switch (_status) {
            'loading' => const Center(
              key: ValueKey('loading'),
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
            'success' => _buildSuccess(),
            'failed' => _buildFailed(),
            'notfound' => _buildNotFound(),
            _ => _buildPending(), // pending & default
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // PENDING
  // ══════════════════════════════════════════════════════════════
  Widget _buildPending() {
    return SafeArea(
      key: const ValueKey('pending'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Spacer(flex: 2),
            _PulseIcon(ctrl: _pulse),
            const SizedBox(height: 32),
            Text(
              'Menunggu Konfirmasi',
              style: AppText.h2.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan "Cek Pembayaran" setelah selesai membayar\nuntuk memverifikasi statusmu.',
              style: AppText.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _InfoCard(
              children: [
                _InfoRow(
                  Icons.receipt_long_rounded,
                  'Bill ID',
                  widget.billLinkId,
                  AppColors.primary,
                ),
                _InfoRow(
                  Icons.book_rounded,
                  'Try Out',
                  _tryoutTitle.isEmpty ? '-' : _tryoutTitle,
                  AppColors.info,
                ),
                _InfoRow(
                  Icons.payments_rounded,
                  'Total',
                  _amount == 0 ? '-' : _currencyFmt.format(_amount),
                  AppColors.gold,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // ✅ Tombol CEK PEMBAYARAN
            _PrimaryButton(
              icon: _checking
                  ? Icons.hourglass_top_rounded
                  : Icons.search_rounded,
              label: _checking ? 'Mengecek...' : 'Cek Pembayaran',
              color: AppColors.primary,
              onTap: _checking ? () {} : () => _load(showFeedback: true),
            ),
            const SizedBox(height: 12),
            _SecondaryButton(
              icon: Icons.storefront_rounded,
              label: 'Kembali ke Marketplace',
              onTap: () async {
                final ok = await _showExitDialog(context);
                if (ok == true && context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SUCCESS
  // ══════════════════════════════════════════════════════════════
  Widget _buildSuccess() {
    return SafeArea(
      key: const ValueKey('success'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Pembayaran Berhasil!',
              style: AppText.h1.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try out sudah aktif dan siap digunakan.',
              style: AppText.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _InfoCard(
              accentColor: AppColors.success,
              children: [
                _InfoRow(
                  Icons.receipt_long_rounded,
                  'Bill ID',
                  widget.billLinkId,
                  AppColors.primary,
                ),
                _InfoRow(
                  Icons.book_rounded,
                  'Try Out',
                  _tryoutTitle.isEmpty ? '-' : _tryoutTitle,
                  AppColors.info,
                ),
                _InfoRow(
                  Icons.payments_rounded,
                  'Dibayar',
                  _currencyFmt.format(_amount),
                  AppColors.gold,
                ),
                _InfoRow(
                  Icons.check_circle_rounded,
                  'Status',
                  'Aktif & Tersedia',
                  AppColors.success,
                ),
              ],
            ),
            const Spacer(),
            _PrimaryButton(
              icon: Icons.play_arrow_rounded,
              label: 'Mulai Try Out Sekarang',
              color: AppColors.success,
              onTap: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.tryoutDetail,
                arguments: {'tryoutId': _tryoutId},
              ),
            ),
            const SizedBox(height: 12),
            _SecondaryButton(
              icon: Icons.storefront_rounded,
              label: 'Kembali ke Marketplace',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // FAILED
  // ══════════════════════════════════════════════════════════════
  Widget _buildFailed() {
    final reasonLabel = switch (_failReason) {
      'EXPIRED' => 'Waktu pembayaran habis',
      'CANCELLED' => 'Pembayaran dibatalkan',
      _ => 'Pembayaran gagal diproses',
    };
    return SafeArea(
      key: const ValueKey('failed'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Pembayaran Gagal',
              style: AppText.h1.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              reasonLabel,
              style: AppText.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _InfoCard(
              accentColor: AppColors.error,
              children: [
                _InfoRow(
                  Icons.receipt_long_rounded,
                  'Bill ID',
                  widget.billLinkId,
                  AppColors.primary,
                ),
                _InfoRow(
                  Icons.book_rounded,
                  'Try Out',
                  _tryoutTitle.isEmpty ? '-' : _tryoutTitle,
                  AppColors.info,
                ),
                _InfoRow(
                  Icons.payments_rounded,
                  'Jumlah',
                  _currencyFmt.format(_amount),
                  AppColors.gold,
                ),
                _InfoRow(
                  Icons.error_outline_rounded,
                  'Alasan',
                  reasonLabel,
                  AppColors.error,
                ),
              ],
            ),
            const Spacer(),
            _PrimaryButton(
              icon: Icons.refresh_rounded,
              label: 'Coba Bayar Lagi',
              color: AppColors.primary,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            _SecondaryButton(
              icon: Icons.storefront_rounded,
              label: 'Kembali ke Marketplace',
              onTap: () => Navigator.popUntil(
                context,
                (r) => r.isFirst || r.settings.name == AppRoutes.main,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // NOT FOUND
  // ══════════════════════════════════════════════════════════════
  Widget _buildNotFound() {
    return SafeArea(
      key: const ValueKey('notfound'),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Transaksi tidak ditemukan',
                style: AppText.h2.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bill ID: ${widget.billLinkId}',
                style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              _SecondaryButton(
                icon: Icons.storefront_rounded,
                label: 'Kembali ke Marketplace',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Exit dialog ──────────────────────────────────────────────────────────────
  Future<bool?> _showExitDialog(BuildContext ctx) => showDialog<bool>(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.bLg),
      title: Text('Keluar dari halaman ini?', style: AppText.h3),
      content: Text(
        'Jika sudah bayar, tekan "Cek Pembayaran" dulu sebelum keluar.',
        style: AppText.body.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Tetap di Sini',
            style: AppText.label.copyWith(color: AppColors.primary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Keluar',
            style: AppText.label.copyWith(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _PulseIcon extends StatelessWidget {
  final AnimationController ctrl;
  const _PulseIcon({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final scale = 1.0 + (ctrl.value * 0.08);
        final opacity = 0.15 + (ctrl.value * 0.12);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale * 1.3,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warning.withOpacity(opacity * 0.6),
                ),
              ),
            ),
            Transform.scale(
              scale: scale,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warning.withOpacity(opacity),
                ),
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.warning,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: AppColors.white,
                size: 36,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  final Color? accentColor;
  const _InfoCard({required this.children, this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bLg,
        border: Border.all(
          color: (accentColor ?? AppColors.border).withOpacity(
            accentColor != null ? 0.3 : 1,
          ),
        ),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        children:
            children
                .expand(
                  (w) => [w, const Divider(height: 1, color: AppColors.border)],
                )
                .toList()
              ..removeLast(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoRow(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: AppRadius.bSm,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppText.bodySm)),
          Flexible(
            child: Text(
              value,
              style: AppText.label.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
          textStyle: AppText.btnMd,
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
          textStyle: AppText.btnMd,
        ),
      ),
    );
  }
}
