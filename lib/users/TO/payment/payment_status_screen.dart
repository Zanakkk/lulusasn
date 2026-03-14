// lib/users/TO/payment/payment_status_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';
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
    required this.tryoutId,
    required this.tryoutTitle,
    required this.amount,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen>
    with TickerProviderStateMixin {
  // ── Animations ──────────────────────────────────────────────────────────────
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final AnimationController _appearCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _appearCtrl,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _appearCtrl, curve: Curves.easeOutCubic));

  // ── Data (bisa di-populate dari Firestore saat deep link) ───────────────────
  late String _tryoutTitle = widget.tryoutTitle;
  late int _amount = widget.amount;
  late String _tryoutId = widget.tryoutId;

  // ── Timer ───────────────────────────────────────────────────────────────────
  Timer? _timeoutTimer;
  Timer? _elapsedTimer;
  bool _showManualCheck = false;
  bool _timersCancelled = false;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Kalau masuk dari deep link Flip, widget fields kosong →
    // ambil data dari Firestore sekali (non-blocking).
    if (_tryoutTitle.isEmpty || _amount == 0) _fetchMissingData();
    _startTimeout();
    _startElapsed();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _appearCtrl.dispose();
    _cancelTimers();
    super.dispose();
  }

  // ── Fetch data saat masuk dari deep link ─────────────────────────────────────
  Future<void> _fetchMissingData() async {
    final doc = await FirebaseFirestore.instance
        .collection('transactions')
        .doc(widget.billLinkId)
        .get();
    if (!doc.exists || !mounted) return;
    final d = doc.data()!;
    setState(() {
      _tryoutTitle = d['tryoutTitle'] as String? ?? _tryoutTitle;
      _amount = (d['amount'] as num?)?.toInt() ?? _amount;
      _tryoutId = d['tryoutId'] as String? ?? _tryoutId;
    });
  }

  // ── Timer helpers ────────────────────────────────────────────────────────────
  void _startTimeout() {
    _timeoutTimer = Timer(const Duration(minutes: 3), () {
      if (mounted) setState(() => _showManualCheck = true);
    });
  }

  void _startElapsed() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  // ✅ Cancel hanya sekali, tidak pernah dari dalam build()
  void _cancelTimers() {
    if (_timersCancelled) return;
    _timersCancelled = true;
    _timeoutTimer?.cancel();
    _elapsedTimer?.cancel();
  }

  String get _elapsedLabel {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
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
        final ok = await _showExitDialog(context);
        if (ok == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .doc(widget.billLinkId)
              .snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              );
            }

            final data = snap.data?.data() as Map<String, dynamic>? ?? {};
            final status = data['status'] as String? ?? 'pending';

            // Cancel timer di sini — dijaga flag agar hanya sekali
            if (status == 'success' || status == 'failed') _cancelTimers();

            return FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: switch (status) {
                  'success' => _buildSuccess(context),
                  'failed' => _buildFailed(context, data),
                  _ => _buildPending(context),
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PENDING
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildPending(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Spacer(flex: 2),
            _PulseIcon(ctrl: _pulseCtrl),
            const SizedBox(height: 32),
            Text(
              'Menunggu Konfirmasi',
              style: AppText.h2.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Halaman ini update otomatis setelah\npembayaran dikonfirmasi Flip.',
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
                  _tryoutTitle,
                  AppColors.info,
                ),
                _InfoRow(
                  Icons.payments_rounded,
                  'Total',
                  _currencyFmt.format(_amount),
                  AppColors.gold,
                ),
                _InfoRow(
                  Icons.timer_rounded,
                  'Menunggu',
                  _elapsedLabel,
                  AppColors.warning,
                ),
              ],
            ),
            if (_showManualCheck) ...[
              const SizedBox(height: 16),
              _SecondaryButton(
                icon: Icons.refresh_rounded,
                label: 'Sudah Bayar? Cek Status',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Mengecek status...',
                      style: AppText.body.copyWith(color: AppColors.white),
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
                    margin: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
            const Spacer(),
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

  // ════════════════════════════════════════════════════════════════════════════
  // SUCCESS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildSuccess(BuildContext context) {
    return SafeArea(
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
                  _tryoutTitle,
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

  // ════════════════════════════════════════════════════════════════════════════
  // FAILED
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildFailed(BuildContext context, Map<String, dynamic> data) {
    final reason = data['failureReason'] as String? ?? 'FAILED';
    final reasonLabel = switch (reason) {
      'EXPIRED' => 'Waktu pembayaran habis',
      'CANCELLED' => 'Pembayaran dibatalkan',
      _ => 'Pembayaran gagal diproses',
    };

    return SafeArea(
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
                  _tryoutTitle,
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

  // ── Exit dialog ──────────────────────────────────────────────────────────────
  Future<bool?> _showExitDialog(BuildContext ctx) => showDialog<bool>(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.bLg),
      title: Text('Keluar dari halaman ini?', style: AppText.h3),
      content: Text(
        'Pembayaran masih diproses. Jika sudah bayar, akses tryout aktif otomatis di "Try Out Saya".',
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
  final String label;
  final String value;
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
