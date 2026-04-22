// lib/users/TO/payment/proof_submitted_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lulusasn/app/theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PROOF SUBMITTED SCREEN
// Ditampilkan setelah user berhasil upload 3 bukti promosi (jalur gratis).
// ═══════════════════════════════════════════════════════════════════════════════
class ProofSubmittedScreen extends StatefulWidget {
  final String tryoutTitle;

  const ProofSubmittedScreen({super.key, required this.tryoutTitle});

  @override
  State<ProofSubmittedScreen> createState() => _ProofSubmittedScreenState();
}

class _ProofSubmittedScreenState extends State<ProofSubmittedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final Animation<double> _scaleBadge = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
  );

  late final Animation<double> _fadeContent = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.40, 1.0, curve: Curves.easeOut),
  );

  late final Animation<Offset> _slideContent =
      Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.40, 1.0, curve: Curves.easeOutCubic),
        ),
      );

  late final Timer _dotTimer;
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dotCount = (_dotCount % 3) + 1);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _dotTimer.cancel();
    super.dispose();
  }

  String get _dots => '.' * _dotCount;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Tidak bisa back — harus pakai tombol "Kembali ke Beranda"
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // ── Badge animasi ──────────────────────────────────────────
                ScaleTransition(
                  scale: _scaleBadge,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: AppGradient.gold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      color: AppColors.primary,
                      size: 52,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Konten utama ───────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeContent,
                  child: SlideTransition(
                    position: _slideContent,
                    child: Column(
                      children: [
                        Text(
                          'Bukti Terkirim!',
                          style: AppText.h1.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Admin sedang mereview buktimu$_dots',
                          style: AppText.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 28),

                        // ── Info card ──────────────────────────────────────
                        _InfoCard(tryoutTitle: widget.tryoutTitle),

                        const SizedBox(height: 20),

                        // ── Timeline steps ─────────────────────────────────
                        _TimelineCard(),

                        const SizedBox(height: 20),

                        // ── Kontak admin jika >24 jam ──────────────────────
                        _ContactAdminBanner(),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // ── CTA ────────────────────────────────────────────────────
                FadeTransition(
                  opacity: _fadeContent,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.popUntil(context, (r) => r.isFirst),
                          icon: const Icon(Icons.home_rounded, size: 18),
                          label: const Text('Kembali ke Beranda'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.bMd,
                            ),
                            textStyle: AppText.btnMd,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Info card tryout yang diajukan ────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String tryoutTitle;
  const _InfoCard({required this.tryoutTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bLg,
        border: Border.all(color: AppColors.gold.withOpacity(0.30)),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        children: [
          _Row(
            Icons.book_rounded,
            'Try Out',
            tryoutTitle.isNotEmpty ? tryoutTitle : '-',
            AppColors.info,
          ),
          const Divider(height: 16, color: AppColors.border),
          _Row(
            Icons.how_to_reg_rounded,
            'Metode',
            'Promosi Gratis',
            AppColors.success,
          ),
          const Divider(height: 16, color: AppColors.border),
          _Row(
            Icons.pending_actions_rounded,
            'Status',
            'Menunggu Review Admin',
            AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Row(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

// ── Timeline langkah selanjutnya ──────────────────────────────────────────────
class _TimelineCard extends StatelessWidget {
  const _TimelineCard();

  static const _steps = [
    (
      Icons.cloud_upload_rounded,
      AppColors.success,
      'Bukti berhasil dikirim',
      'Ketiga bukti promosimu sudah tersimpan.',
      true,
    ),
    (
      Icons.manage_search_rounded,
      AppColors.warning,
      'Admin sedang mereview',
      'Proses review memakan waktu hingga 1×24 jam.',
      false,
    ),
    (
      Icons.lock_open_rounded,
      AppColors.info,
      'Akses dibuka',
      'Try out langsung aktif setelah disetujui.',
      false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apa yang terjadi selanjutnya?',
            style: AppText.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ..._steps.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            final isLast = i == _steps.length - 1;
            return _TimelineStep(
              icon: s.$1,
              color: s.$2,
              title: s.$3,
              subtitle: s.$4,
              isDone: s.$5,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isLast;

  const _TimelineStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Garis vertikal + dot ─────────────────────────────────────────
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone ? color : color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: isDone ? AppColors.white : color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: AppRadius.bFull,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ── Teks ─────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.label.copyWith(
                      color: isDone
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Banner kontak admin jika >24 jam ──────────────────────────────────────────
class _ContactAdminBanner extends StatelessWidget {
  const _ContactAdminBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppText.caption.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                children: const [
                  TextSpan(
                    text:
                        'Belum disetujui dalam 1×24 jam? Hubungi admin kami di Instagram ',
                  ),
                  TextSpan(
                    text: '@luluzzz',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' dengan menyertakan screenshot bukti yang sudah kamu upload.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
