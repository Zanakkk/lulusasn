// ============================================================================
// lib/admin/pages/promotion_verification_screen.dart
// Redesigned using Luluzzz Design System
// Navy · Gold · White | Plus Jakarta Sans | 8-pt Grid
// ============================================================================

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';

// ============================================================================
// SCREEN 1: TRYOUT LIST
// ============================================================================
class PromotionVerificationScreen extends StatelessWidget {
  const PromotionVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          _buildStatsRow(),
          _buildSectionLabel('Tryout Aktif'),
          _buildTryoutGrid(context),
          const SliverToBoxAdapter(child: AppSpacing.vxl),
        ],
      ),
    );
  }

  // ── 1. HEADER ─────────────────────────────────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(gradient: AppGradient.navy),
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Breadcrumb + Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_rounded,
                        color: AppColors.gold,
                        size: 14,
                      ),
                      AppSpacing.hxs,
                      Text(
                        'Admin Panel',
                        style: AppText.caption.copyWith(color: AppColors.gold),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.white.withOpacity(0.4),
                          size: 14,
                        ),
                      ),
                      Text(
                        'Verifikasi Promosi',
                        style: AppText.caption.copyWith(
                          color: AppColors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vsm,
                  Text(
                    'Verifikasi Promosi',
                    style: AppText.display.copyWith(color: AppColors.white),
                  ),
                  AppSpacing.vxs,
                  Text(
                    'Kelola dan validasi akses tryout gratis pengguna.',
                    style: AppText.body.copyWith(
                      color: AppColors.white.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.hlg,
            // Right: Admin Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.07),
                borderRadius: AppRadius.bMd,
                border: Border.all(color: AppColors.white.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppGradient.gold,
                      borderRadius: AppRadius.bSm,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  AppSpacing.hsm,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administrator',
                        style: AppText.label.copyWith(color: AppColors.white),
                      ),
                      Text(
                        'Super Admin',
                        style: AppText.caption.copyWith(
                          color: AppColors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. STATS ROW ──────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('user_tryouts')
              .snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            final pending = docs
                .where(
                  (d) => (d.data() as Map)['proofStatus'] == 'pending_review',
                )
                .length;
            final approved = docs
                .where((d) => (d.data() as Map)['proofStatus'] == 'approved')
                .length;
            final rejected = docs
                .where((d) => (d.data() as Map)['proofStatus'] == 'rejected')
                .length;

            return Row(
              children: [
                _StatCard(
                  label: 'Total Pengajuan',
                  value: docs.length.toString(),
                  icon: Icons.assignment_ind_rounded,
                  accent: AppColors.info,
                ),
                AppSpacing.hmd,
                _StatCard(
                  label: 'Menunggu Review',
                  value: pending.toString(),
                  icon: Icons.pending_actions_rounded,
                  accent: AppColors.warning,
                ),
                AppSpacing.hmd,
                _StatCard(
                  label: 'Disetujui',
                  value: approved.toString(),
                  icon: Icons.check_circle_rounded,
                  accent: AppColors.success,
                ),
                AppSpacing.hmd,
                _StatCard(
                  label: 'Ditolak',
                  value: rejected.toString(),
                  icon: Icons.cancel_rounded,
                  accent: AppColors.error,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                gradient: AppGradient.gold,
                borderRadius: AppRadius.bFull,
              ),
            ),
            AppSpacing.hsm,
            Text(title, style: AppText.h3),
          ],
        ),
      ),
    );
  }

  // ── 3. TRYOUT GRID ────────────────────────────────────────────────────────
  Widget _buildTryoutGrid(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tryouts')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snap.data!.docs;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 420,
              mainAxisExtent: 190,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate((ctx, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              return _TryoutCard(
                tryoutId: d.id,
                title: data['title'] ?? 'Untitled',
                examTypeName: data['examTypeName'] ?? 'Kategori',
                isPremium: data['isPremium'] ?? false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubmissionListScreen(
                      tryoutId: d.id,
                      tryoutTitle: data['title'] ?? 'Untitled',
                    ),
                  ),
                ),
              );
            }, childCount: docs.length),
          ),
        );
      },
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.bLg,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadow.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.softBg(accent),
                borderRadius: AppRadius.bMd,
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            AppSpacing.hmd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.caption),
                  const SizedBox(height: 2),
                  Text(value, style: AppText.h1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tryout Card ───────────────────────────────────────────────────────────────
class _TryoutCard extends StatelessWidget {
  final String tryoutId;
  final String title;
  final String examTypeName;
  final bool isPremium;
  final VoidCallback onTap;

  const _TryoutCard({
    required this.tryoutId,
    required this.title,
    required this.examTypeName,
    required this.isPremium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_tryouts')
          .where('tryoutId', isEqualTo: tryoutId)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final pending = docs
            .where((d) => (d.data() as Map)['proofStatus'] == 'pending_review')
            .length;
        final hasPending = pending > 0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.bLg,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.bLg,
                border: Border.all(
                  color: hasPending
                      ? AppColors.warning.withOpacity(0.5)
                      : AppColors.border,
                  width: hasPending ? 1.5 : 1,
                ),
                boxShadow: hasPending ? AppShadow.md : AppShadow.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Category chip + Premium + Pending badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softBg(AppColors.primary),
                          borderRadius: AppRadius.bFull,
                        ),
                        child: Text(
                          examTypeName.toUpperCase(),
                          style: AppText.label.copyWith(
                            color: AppColors.primary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      if (isPremium) ...[
                        AppSpacing.hxs,
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppGradient.gold,
                            borderRadius: AppRadius.bFull,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                size: 10,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'PREMIUM',
                                style: AppText.label.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (hasPending)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softBg(AppColors.warning),
                            borderRadius: AppRadius.bFull,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$pending Pending',
                                style: AppText.label.copyWith(
                                  color: AppColors.warning,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  AppSpacing.vmd,
                  // Title
                  Text(
                    title,
                    style: AppText.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Footer: users count + arrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          AppSpacing.hxs,
                          Text(
                            '${docs.length} pengguna',
                            style: AppText.bodySm,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppRadius.bSm,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// SCREEN 2: SUBMISSION LIST — SPLIT PANEL
// ============================================================================
class SubmissionListScreen extends StatefulWidget {
  final String tryoutId;
  final String tryoutTitle;

  const SubmissionListScreen({
    super.key,
    required this.tryoutId,
    required this.tryoutTitle,
  });

  @override
  State<SubmissionListScreen> createState() => _SubmissionListScreenState();
}

class _SubmissionListScreenState extends State<SubmissionListScreen> {
  String _filter = 'pending_review';
  QueryDocumentSnapshot? _selectedDoc;

  static const _filters = [
    {'val': 'pending_review', 'label': 'Menunggu', 'color': AppColors.warning},
    {'val': 'approved', 'label': 'Disetujui', 'color': AppColors.success},
    {'val': 'rejected', 'label': 'Ditolak', 'color': AppColors.error},
    {'val': 'all', 'label': 'Semua', 'color': AppColors.primary},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          // ── PANEL KIRI ───────────────────────────────────────────────────
          SizedBox(
            width: 400,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  right: BorderSide(color: AppColors.border, width: 1),
                ),
                boxShadow: AppShadow.md,
              ),
              child: Column(
                children: [
                  _buildLeftHeader(context),
                  _buildFilterPills(),
                  Expanded(child: _buildList()),
                ],
              ),
            ),
          ),

          // ── PANEL KANAN ──────────────────────────────────────────────────
          Expanded(
            child: _selectedDoc == null
                ? _buildEmptyState()
                : _ReviewPanel(
                    key: ValueKey(_selectedDoc!.id),
                    doc: _selectedDoc!,
                  ),
          ),
        ],
      ),
    );
  }

  // ── Left Header ─────────────────────────────────────────────────────────
  Widget _buildLeftHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.navy),
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: AppRadius.bSm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.08),
                borderRadius: AppRadius.bSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.white,
                    size: 16,
                  ),
                  AppSpacing.hxs,
                  Text(
                    'Kembali',
                    style: AppText.label.copyWith(
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.vmd,
          Text(
            'Daftar Pengajuan',
            style: AppText.caption.copyWith(color: AppColors.gold),
          ),
          AppSpacing.vxs,
          Text(
            widget.tryoutTitle,
            style: AppText.h2.copyWith(color: AppColors.white),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Filter Pills ────────────────────────────────────────────────────────
  Widget _buildFilterPills() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: _filters.map((f) {
          final isActive = _filter == f['val'];
          final color = f['color'] as Color;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _filter = f['val'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? color : Colors.transparent,
                  borderRadius: AppRadius.bSm,
                ),
                child: Text(
                  f['label'] as String,
                  textAlign: TextAlign.center,
                  style: AppText.label.copyWith(
                    color: isActive ? AppColors.white : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── List ─────────────────────────────────────────────────────────────────
  Widget _buildList() {
    var q = FirebaseFirestore.instance
        .collection('user_tryouts')
        .where('tryoutId', isEqualTo: widget.tryoutId);
    if (_filter != 'all') q = q.where('proofStatus', isEqualTo: _filter);

    return StreamBuilder<QuerySnapshot>(
      stream: q.orderBy('submittedAt', descending: true).snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 48, color: AppColors.textHint),
                AppSpacing.vsm,
                Text('Tidak ada data', style: AppText.bodySm),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => AppSpacing.vsm,
          itemBuilder: (_, i) {
            final doc = docs[i];
            return _UserCard(
              doc: doc,
              isSelected: _selectedDoc?.id == doc.id,
              onTap: () => setState(() => _selectedDoc = doc),
            );
          },
        );
      },
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      color: AppColors.bg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: AppShadow.md,
              ),
              child: Icon(
                Icons.touch_app_rounded,
                size: 48,
                color: AppColors.textHint,
              ),
            ),
            AppSpacing.vlg,
            Text(
              'Pilih Pengajuan',
              style: AppText.h3.copyWith(color: AppColors.textSecondary),
            ),
            AppSpacing.vsm,
            Text(
              'Pilih item di sisi kiri untuk mereview bukti.',
              style: AppText.bodySm,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET: USER CARD (Panel Kiri)
// ============================================================================
class _UserCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserCard({
    required this.doc,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['proofStatus'] ?? 'pending_review';

    final Color statusColor = switch (status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };

    final String statusLabel = switch (status) {
      'approved' => 'Disetujui',
      'rejected' => 'Ditolak',
      _ => 'Menunggu',
    };

    final submittedAt = (data['submittedAt'] as Timestamp?)?.toDate();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.bMd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.softBg(AppColors.primary)
                : AppColors.surface,
            borderRadius: AppRadius.bMd,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
                  borderRadius: AppRadius.bMd,
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              AppSpacing.hmd,
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['userId'] ?? '-',
                      style: AppText.bodyLg.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vxs,
                    if (submittedAt != null)
                      Text(
                        DateFormat('dd MMM yyyy · HH:mm').format(submittedAt),
                        style: AppText.caption,
                      ),
                  ],
                ),
              ),
              AppSpacing.hsm,
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.softBg(statusColor),
                  borderRadius: AppRadius.bFull,
                ),
                child: Text(
                  statusLabel,
                  style: AppText.label.copyWith(
                    color: statusColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET: REVIEW PANEL (Panel Kanan)
// ============================================================================
class _ReviewPanel extends StatefulWidget {
  final QueryDocumentSnapshot doc;

  const _ReviewPanel({required this.doc, super.key});

  @override
  State<_ReviewPanel> createState() => _ReviewPanelState();
}

class _ReviewPanelState extends State<_ReviewPanel> {
  bool _isProcessing = false;

  Map<String, dynamic> get data => widget.doc.data() as Map<String, dynamic>;
  Map<String, dynamic> get proofs => data['promotionProofs'] ?? {};

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance
          .collection('user_tryouts')
          .doc(widget.doc.id)
          .update({
            'proofStatus': newStatus,
            'isActive': newStatus == 'approved',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'approved'
                  ? '✓ Pengajuan berhasil disetujui'
                  : '✗ Pengajuan ditolak',
            ),
            backgroundColor: newStatus == 'approved'
                ? AppColors.success
                : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.bSm),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['proofStatus'] ?? 'pending_review';
    final isApproved = status == 'approved';
    final isPending = status == 'pending_review';
    final submittedAt = (data['submittedAt'] as Timestamp?)?.toDate();

    final Color statusColor = switch (status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };

    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          // ── Top Toolbar ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                // User info
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: AppRadius.bMd,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.hmd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['userId'] ?? '-', style: AppText.h3),
                      if (submittedAt != null) ...[
                        AppSpacing.vxs,
                        Text(
                          'Diajukan: ${DateFormat('dd MMM yyyy, HH:mm').format(submittedAt)}',
                          style: AppText.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softBg(statusColor),
                    borderRadius: AppRadius.bFull,
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      AppSpacing.hxs,
                      Text(switch (status) {
                        'approved' => 'Disetujui',
                        'rejected' => 'Ditolak',
                        _ => 'Menunggu Review',
                      }, style: AppText.label.copyWith(color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Proof Images ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bukti Promosi', style: AppText.h2),
                  AppSpacing.vsm,
                  Text(
                    'Periksa setiap bukti sebelum memberikan keputusan.',
                    style: AppText.bodySm,
                  ),
                  AppSpacing.vlg,
                  _ProofRow(
                    label: 'Bukti Follow',
                    icon: Icons.person_add_rounded,
                    url: proofs['followProof'],
                    color: const Color(0xFFE4405F),
                  ),
                  AppSpacing.vlg,
                  _ProofRow(
                    label: 'Bukti Story',
                    icon: Icons.slideshow_rounded,
                    url: proofs['storyProof'],
                    color: const Color(0xFFAC45E6),
                  ),
                  AppSpacing.vlg,
                  _ProofRow(
                    label: 'Bukti Tag',
                    icon: Icons.label_rounded,
                    url: proofs['tagProof'],
                    color: AppColors.info,
                  ),
                ],
              ),
            ),
          ),

          // ── Action Bar ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
              boxShadow: AppShadow.md,
            ),
            child: Column(
              children: [
                if (_isProcessing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: LinearProgressIndicator(color: AppColors.primary),
                  ),
                if (isPending)
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Tolak',
                          icon: Icons.close_rounded,
                          color: AppColors.error,
                          isOutlined: true,
                          onPressed: () => _updateStatus('rejected'),
                        ),
                      ),
                      AppSpacing.hmd,
                      Expanded(
                        child: _ActionButton(
                          label: 'Setujui',
                          icon: Icons.check_rounded,
                          color: AppColors.success,
                          isOutlined: false,
                          onPressed: () => _updateStatus('approved'),
                        ),
                      ),
                    ],
                  )
                else
                  _ActionButton(
                    label: isApproved ? 'Cabut Akses' : 'Aktifkan Kembali',
                    icon: isApproved
                        ? Icons.block_rounded
                        : Icons.refresh_rounded,
                    color: isApproved ? AppColors.error : AppColors.success,
                    isOutlined: isApproved,
                    onPressed: () =>
                        _updateStatus(isApproved ? 'rejected' : 'approved'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Proof Row ─────────────────────────────────────────────────────────────────
class _ProofRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? url;
  final Color color;

  const _ProofRow({
    required this.label,
    required this.icon,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.softBg(color),
                borderRadius: AppRadius.bSm,
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            AppSpacing.hsm,
            Text(
              label,
              style: AppText.label.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
        AppSpacing.vsm,
        // Image Container
        Container(
          height: 420,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: AppRadius.bLg,
            border: Border.all(color: AppColors.border),
          ),
          child: url == null || url!.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_rounded,
                      size: 40,
                      color: AppColors.textHint,
                    ),
                    AppSpacing.vsm,
                    Text('Gambar tidak tersedia', style: AppText.bodySm),
                  ],
                )
              : ClipRRect(
                  borderRadius: AppRadius.bLg,
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: Image.network(
                      url!,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                : null,
                            color: AppColors.primary,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_rounded,
                            size: 40,
                            color: AppColors.textHint,
                          ),
                          AppSpacing.vsm,
                          Text('Gagal memuat gambar', style: AppText.bodySm),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isOutlined;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isOutlined,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: isOutlined ? color : AppColors.white),
        AppSpacing.hsm,
        Text(
          label,
          style: AppText.btnMd.copyWith(
            color: isOutlined ? color : AppColors.white,
          ),
        ),
      ],
    );

    if (isOutlined) {
      return SizedBox(
        height: 50,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
          ),
          child: content,
        ),
      );
    }

    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
        ),
        child: content,
      ),
    );
  }
}
