// ============================================================================
// lib/admin/pages/promotion_verification_screen.dart
// ============================================================================
// ignore_for_file: deprecated_member_use

import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';

final _currencyFmt = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);
final _dateFmt = DateFormat('dd MMM yyyy, HH:mm');

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Apakah doc ini paid (bukan free/promo)?
bool _isPaid(Map<String, dynamic> d) => d['paymentMethod'] != null;

/// Apakah doc ini free/promo?
bool _isFree(Map<String, dynamic> d) => d['paymentMethod'] == null;

// ============================================================================
// SCREEN 1 — TRYOUT LIST
// ============================================================================
class PromotionVerificationScreen extends StatelessWidget {
  const PromotionVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          _buildStats(),
          _buildSectionLabel('Tryout Aktif'),
          _buildTryoutGrid(context),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() => SliverToBoxAdapter(
    child: Container(
      decoration: const BoxDecoration(gradient: AppGradient.navy),
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: AppColors.gold,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Admin',
                      style: AppText.caption.copyWith(color: AppColors.gold),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.white.withOpacity(0.35),
                        size: 13,
                      ),
                    ),
                    Text(
                      'Manajemen Akses',
                      style: AppText.caption.copyWith(
                        color: AppColors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Manajemen Akses',
                  style: AppText.display.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelola akses gratis (promo) & berbayar pengguna per tryout.',
                  style: AppText.body.copyWith(
                    color: AppColors.white.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
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
                const SizedBox(width: 10),
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

  // ── Stats ──────────────────────────────────────────────────────────────────
  Widget _buildStats() => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_tryouts')
            .snapshots(),
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          final all = docs
              .map((d) => d.data() as Map<String, dynamic>)
              .toList();
          final paid = all.where(_isPaid).length;
          final free = all.where(_isFree).length;
          final pend = all
              .where((d) => d['proofStatus'] == 'pending_review')
              .length;
          final appr = all.where((d) => d['proofStatus'] == 'approved').length;

          return Row(
            children: [
              _StatCard(
                'Total Akses',
                docs.length.toString(),
                Icons.people_alt_rounded,
                AppColors.primary,
              ),
              const SizedBox(width: 12),
              _StatCard(
                'Berbayar',
                paid.toString(),
                Icons.credit_card_rounded,
                AppColors.success,
              ),
              const SizedBox(width: 12),
              _StatCard(
                'Gratis/Promo',
                free.toString(),
                Icons.card_giftcard_rounded,
                AppColors.info,
              ),
              const SizedBox(width: 12),
              _StatCard(
                'Promo Menunggu',
                pend.toString(),
                Icons.pending_actions_rounded,
                AppColors.warning,
              ),
              const SizedBox(width: 12),
              _StatCard(
                'Promo Disetujui',
                appr.toString(),
                Icons.check_circle_rounded,
                AppColors.gold,
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _buildSectionLabel(String t) => SliverToBoxAdapter(
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
          const SizedBox(width: 10),
          Text(t, style: AppText.h3),
        ],
      ),
    ),
  );

  // ── Grid ───────────────────────────────────────────────────────────────────
  Widget _buildTryoutGrid(BuildContext context) => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('tryouts')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots(),
    builder: (_, snap) {
      if (!snap.hasData)
        return const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        );
      final docs = snap.data!.docs;
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisExtent: 200,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          delegate: SliverChildBuilderDelegate((ctx, i) {
            final d = docs[i];
            final data = d.data() as Map<String, dynamic>;
            return _TryoutCard(
              tryoutId: d.id,
              title: data['title'] ?? 'Untitled',
              examTypeName: data['examTypeName'] ?? '',
              price: data['price'] as int? ?? 0,
              onTap: () => Navigator.push(
                ctx,
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

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color accent;
  const _StatCard(this.label, this.value, this.icon, this.accent);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.softBg(accent),
              borderRadius: AppRadius.bMd,
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.caption),
                const SizedBox(height: 2),
                Text(value, style: AppText.h2),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Tryout Card ────────────────────────────────────────────────────────────────
class _TryoutCard extends StatelessWidget {
  final String tryoutId, title, examTypeName;
  final int price;
  final VoidCallback onTap;
  const _TryoutCard({
    required this.tryoutId,
    required this.title,
    required this.examTypeName,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_tryouts')
          .where('tryoutId', isEqualTo: tryoutId)
          .snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        final all = docs.map((d) => d.data() as Map<String, dynamic>).toList();
        final pend = all
            .where((d) => d['proofStatus'] == 'pending_review')
            .length;
        final paid = all.where(_isPaid).length;
        final free = all.where(_isFree).length;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.bLg,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.bLg,
                border: Border.all(
                  color: pend > 0
                      ? AppColors.warning.withOpacity(0.6)
                      : AppColors.border,
                  width: pend > 0 ? 1.5 : 1,
                ),
                boxShadow: pend > 0 ? AppShadow.md : AppShadow.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row
                  Row(
                    children: [
                      _Chip(examTypeName.toUpperCase(), AppColors.primary),
                      const SizedBox(width: 6),
                      if (price > 0)
                        _Chip(_currencyFmt.format(price), AppColors.success)
                      else
                        _Chip('GRATIS', AppColors.info),
                      const Spacer(),
                      if (pend > 0) _Chip('$pend Pending', AppColors.warning),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: AppText.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Footer counts
                  Row(
                    children: [
                      _CountBadge(
                        Icons.credit_card_rounded,
                        '$paid Bayar',
                        AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _CountBadge(
                        Icons.card_giftcard_rounded,
                        '$free Promo',
                        AppColors.info,
                      ),
                      const Spacer(),
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

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.softBg(color),
      borderRadius: AppRadius.bFull,
    ),
    child: Text(
      label,
      style: AppText.label.copyWith(color: color, fontSize: 10),
    ),
  );
}

class _CountBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _CountBadge(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(
        label,
        style: AppText.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

// ============================================================================
// SCREEN 2 — SUBMISSION LIST (Split Panel)
// ============================================================================
class SubmissionListScreen extends StatefulWidget {
  final String tryoutId, tryoutTitle;
  const SubmissionListScreen({
    super.key,
    required this.tryoutId,
    required this.tryoutTitle,
  });
  @override
  State<SubmissionListScreen> createState() => _SubmissionListScreenState();
}

class _SubmissionListScreenState extends State<SubmissionListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  // 0 = Free/Promo, 1 = Paid
  String _proofFilter = 'all'; // untuk tab Free
  QueryDocumentSnapshot? _selected;

  static const _proofFilters = [
    {'val': 'all', 'label': 'Semua'},
    {'val': 'pending_review', 'label': 'Menunggu'},
    {'val': 'approved', 'label': 'Disetujui'},
    {'val': 'rejected', 'label': 'Ditolak'},
  ];

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          // ── PANEL KIRI ─────────────────────────────────────────────────────
          SizedBox(
            width: 420,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.border)),
                boxShadow: AppShadow.md,
              ),
              child: Column(
                children: [
                  _buildLeftHeader(context),
                  _buildTabs(),
                  Expanded(
                    child: TabBarView(
                      controller: _tab,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [_buildFreeTab(), _buildPaidTab()],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── PANEL KANAN ────────────────────────────────────────────────────
          Expanded(
            child: _selected == null ? _buildEmptyState() : _buildDetailPanel(),
          ),
        ],
      ),
    );
  }

  // ── Left Header ────────────────────────────────────────────────────────────
  Widget _buildLeftHeader(BuildContext ctx) => Container(
    decoration: const BoxDecoration(gradient: AppGradient.navy),
    padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => Navigator.pop(ctx),
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
                  size: 15,
                ),
                const SizedBox(width: 6),
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
        const SizedBox(height: 14),
        Text(
          'Daftar Akses',
          style: AppText.caption.copyWith(color: AppColors.gold),
        ),
        const SizedBox(height: 4),
        Text(
          widget.tryoutTitle,
          style: AppText.h2.copyWith(color: AppColors.white),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  // ── Tabs ────────────────────────────────────────────────────────────────────
  Widget _buildTabs() => Container(
    decoration: const BoxDecoration(
      color: AppColors.surfaceAlt,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: TabBar(
      controller: _tab,
      onTap: (_) => setState(() => _selected = null),
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.primary,
      indicatorWeight: 2,
      labelStyle: AppText.label,
      tabs: const [
        Tab(
          icon: Icon(Icons.card_giftcard_rounded, size: 16),
          text: 'Gratis / Promo',
        ),
        Tab(icon: Icon(Icons.credit_card_rounded, size: 16), text: 'Berbayar'),
      ],
    ),
  );

  // ── Free Tab ────────────────────────────────────────────────────────────────
  Widget _buildFreeTab() => Column(
    children: [
      Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: _proofFilters.map((f) {
            final active = _proofFilter == f['val'];
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() {
                  _proofFilter = f['val']!;
                  _selected = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.surfaceAlt,
                    borderRadius: AppRadius.bFull,
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    f['label']!,
                    style: AppText.label.copyWith(
                      color: active ? AppColors.white : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      Expanded(child: _buildFreeList()),
    ],
  );

  Widget _buildFreeList() {
    // Query tanpa compound index dulu — filter proofStatus di client side
    final stream = FirebaseFirestore.instance
        .collection('user_tryouts')
        .where('tryoutId', isEqualTo: widget.tryoutId)
        .orderBy('submittedAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (_, snap) {
        if (snap.hasError) return _IndexErrorWidget(snap.error.toString());
        if (!snap.hasData)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );

        // Filter di client: free = tidak ada paymentMethod
        var docs = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['paymentMethod'] == null;
        }).toList();

        // Filter proofStatus di client
        if (_proofFilter != 'all') {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['proofStatus'] == _proofFilter;
          }).toList();
        }

        return _buildListView(docs, isFree: true);
      },
    );
  }

  // ── Paid Tab ────────────────────────────────────────────────────────────────
  Widget _buildPaidTab() {
    final stream = FirebaseFirestore.instance
        .collection('user_tryouts')
        .where('tryoutId', isEqualTo: widget.tryoutId)
        .orderBy('submittedAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (_, snap) {
        if (snap.hasError) return _IndexErrorWidget(snap.error.toString());
        if (!snap.hasData)
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );

        // Filter di client: paid = ada paymentMethod
        final docs = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['paymentMethod'] != null;
        }).toList();

        return _buildListView(docs, isFree: false);
      },
    );
  }

  // ── Generic List View ───────────────────────────────────────────────────────
  Widget _buildList(AsyncSnapshot<QuerySnapshot> snap, {required bool isFree}) {
    if (snap.hasError) return _IndexErrorWidget(snap.error.toString());
    if (!snap.hasData)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    return _buildListView(snap.data!.docs, isFree: isFree);
  }

  Widget _buildListView(
    List<QueryDocumentSnapshot> docs, {
    required bool isFree,
  }) {
    if (docs.isEmpty)
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 44, color: AppColors.textHint),
            const SizedBox(height: 10),
            Text('Tidak ada data', style: AppText.bodySm),
          ],
        ),
      );

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final doc = docs[i];
        return isFree
            ? _FreeUserCard(
                doc: doc,
                isSelected: _selected?.id == doc.id,
                onTap: () => setState(() => _selected = doc),
              )
            : _PaidUserCard(
                doc: doc,
                isSelected: _selected?.id == doc.id,
                onTap: () => setState(() => _selected = doc),
              );
      },
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() => Container(
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
            child: const Icon(
              Icons.touch_app_rounded,
              size: 44,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Pilih Pengguna',
            style: AppText.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih item di kiri untuk melihat detail.',
            style: AppText.bodySm,
          ),
        ],
      ),
    ),
  );

  // ── Detail Panel (kanan) ───────────────────────────────────────────────────
  Widget _buildDetailPanel() {
    final data = _selected!.data() as Map<String, dynamic>;
    return _isPaid(data)
        ? _PaidDetailPanel(key: ValueKey(_selected!.id), doc: _selected!)
        : _FreeReviewPanel(key: ValueKey(_selected!.id), doc: _selected!);
  }
}

// ============================================================================
// CARD: Free User
// ============================================================================
class _FreeUserCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool isSelected;
  final VoidCallback onTap;
  const _FreeUserCard({
    required this.doc,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['proofStatus'] as String? ?? 'pending_review';
    final Color sc = switch (status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };
    final String sl = switch (status) {
      'approved' => 'Disetujui',
      'rejected' => 'Ditolak',
      _ => 'Menunggu',
    };
    final sub = (data['submittedAt'] as Timestamp?)?.toDate();

    return _CardShell(
      isSelected: isSelected,
      onTap: onTap,
      accentColor: sc,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.softBg(sc),
          borderRadius: AppRadius.bMd,
        ),
        child: Icon(
          Icons.card_giftcard_rounded,
          color: isSelected ? AppColors.white : sc,
          size: 18,
        ),
      ),
      title: data['userId'] ?? '-',
      subtitle: sub != null ? _dateFmt.format(sub) : '-',
      trailing: _StatusPill(sc, sl),
    );
  }
}

// ============================================================================
// CARD: Paid User
// ============================================================================
class _PaidUserCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool isSelected;
  final VoidCallback onTap;
  const _PaidUserCard({
    required this.doc,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final paid = (data['paidAt'] as Timestamp?)?.toDate();
    final amount = data['paidAmount'] as int? ?? 0;

    return _CardShell(
      isSelected: isSelected,
      onTap: onTap,
      accentColor: AppColors.success,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.softBg(AppColors.success),
          borderRadius: AppRadius.bMd,
        ),
        child: Icon(
          Icons.credit_card_rounded,
          color: isSelected ? AppColors.white : AppColors.success,
          size: 18,
        ),
      ),
      title: data['userId'] ?? '-',
      subtitle: paid != null ? _dateFmt.format(paid) : '-',
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _StatusPill(AppColors.success, 'Lunas'),
          const SizedBox(height: 3),
          Text(
            _currencyFmt.format(amount),
            style: AppText.caption.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generic card shell ─────────────────────────────────────────────────────────
class _CardShell extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;
  final Widget leading, trailing;
  final String title, subtitle;
  const _CardShell({
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
    required this.leading,
    required this.trailing,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: AppRadius.bMd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
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
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.label.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusPill(this.color, this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.softBg(color),
      borderRadius: AppRadius.bFull,
    ),
    child: Text(
      label,
      style: AppText.label.copyWith(color: color, fontSize: 10),
    ),
  );
}

// ============================================================================
// DETAIL PANEL: PAID
// ============================================================================
class _PaidDetailPanel extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _PaidDetailPanel({required this.doc, super.key});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final paidAt = (data['paidAt'] as Timestamp?)?.toDate();
    final subAt = (data['submittedAt'] as Timestamp?)?.toDate();
    final updAt = (data['updatedAt'] as Timestamp?)?.toDate();
    final amount = data['paidAmount'] as int? ?? 0;
    final method = data['paymentMethod'] as String? ?? '-';
    final isActive = data['isActive'] as bool? ?? false;
    final attempts = data['totalAttempts'] as int? ?? 0;

    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          // Toolbar
          _DetailToolbar(
            icon: Icons.credit_card_rounded,
            iconColor: AppColors.success,
            title: data['userId'] ?? '-',
            subtitle: 'Akses Berbayar',
            badge: _StatusPill(AppColors.success, 'LUNAS'),
          ),
          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ringkasan Transaksi', style: AppText.h2),
                  const SizedBox(height: 4),
                  Text(
                    'Detail pembayaran dan status akses pengguna.',
                    style: AppText.bodySm,
                  ),
                  const SizedBox(height: 24),

                  // Info grid
                  _InfoGrid(
                    items: [
                      _InfoItem(
                        Icons.receipt_long_rounded,
                        'Metode Pembayaran',
                        method.toUpperCase(),
                        AppColors.primary,
                      ),
                      _InfoItem(
                        Icons.monetization_on_rounded,
                        'Jumlah Dibayar',
                        _currencyFmt.format(amount),
                        AppColors.success,
                      ),
                      _InfoItem(
                        Icons.calendar_today_rounded,
                        'Tanggal Bayar',
                        paidAt != null ? _dateFmt.format(paidAt) : '-',
                        AppColors.info,
                      ),
                      _InfoItem(
                        Icons.send_rounded,
                        'Diajukan',
                        subAt != null ? _dateFmt.format(subAt) : '-',
                        AppColors.gold,
                      ),
                      _InfoItem(
                        Icons.update_rounded,
                        'Terakhir Update',
                        updAt != null ? _dateFmt.format(updAt) : '-',
                        AppColors.textSecondary,
                      ),
                      _InfoItem(
                        Icons.quiz_rounded,
                        'Total Percobaan',
                        attempts.toString(),
                        AppColors.warning,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Status akses
                  _AccessStatusCard(isActive: isActive),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DETAIL PANEL: FREE / PROMO (Review)
// ============================================================================
class _FreeReviewPanel extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const _FreeReviewPanel({required this.doc, super.key});
  @override
  State<_FreeReviewPanel> createState() => _FreeReviewPanelState();
}

class _FreeReviewPanelState extends State<_FreeReviewPanel> {
  bool _processing = false;

  Map<String, dynamic> get data => widget.doc.data() as Map<String, dynamic>;
  Map<String, dynamic> get proofs =>
      (data['promotionProofs'] as Map?)?.cast<String, dynamic>() ?? {};

  Future<void> _setStatus(String s) async {
    setState(() => _processing = true);
    try {
      await FirebaseFirestore.instance
          .collection('user_tryouts')
          .doc(widget.doc.id)
          .update({
            'proofStatus': s,
            'isActive': s == 'approved',
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s == 'approved' ? '✓ Pengajuan disetujui' : '✗ Pengajuan ditolak',
            ),
            backgroundColor: s == 'approved'
                ? AppColors.success
                : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.bSm),
            margin: const EdgeInsets.all(16),
          ),
        );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['proofStatus'] as String? ?? 'pending_review';
    final isPending = status == 'pending_review';
    final isApproved = status == 'approved';
    final subAt = (data['submittedAt'] as Timestamp?)?.toDate();
    final updAt = (data['updatedAt'] as Timestamp?)?.toDate();

    final Color sc = switch (status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };
    final String sl = switch (status) {
      'approved' => 'DISETUJUI',
      'rejected' => 'DITOLAK',
      _ => 'MENUNGGU',
    };

    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          _DetailToolbar(
            icon: Icons.card_giftcard_rounded,
            iconColor: sc,
            title: data['userId'] ?? '-',
            subtitle: 'Akses Gratis / Promo',
            badge: _StatusPill(sc, sl),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta info
                  _InfoGrid(
                    items: [
                      _InfoItem(
                        Icons.send_rounded,
                        'Diajukan',
                        subAt != null ? _dateFmt.format(subAt) : '-',
                        AppColors.info,
                      ),
                      if (updAt != null)
                        _InfoItem(
                          Icons.update_rounded,
                          'Diperbarui',
                          _dateFmt.format(updAt),
                          AppColors.gold,
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Proof images
                  Text('Bukti Promosi', style: AppText.h2),
                  const SizedBox(height: 4),
                  Text(
                    'Periksa setiap bukti sebelum memberikan keputusan.',
                    style: AppText.bodySm,
                  ),
                  const SizedBox(height: 20),

                  _ProofRow(
                    'Bukti Follow',
                    Icons.person_add_rounded,
                    proofs['followProof'] as String?,
                    const Color(0xFFE4405F),
                  ),
                  const SizedBox(height: 24),
                  _ProofRow(
                    'Bukti Story',
                    Icons.slideshow_rounded,
                    proofs['storyProof'] as String?,
                    const Color(0xFFAC45E6),
                  ),
                  const SizedBox(height: 24),
                  _ProofRow(
                    'Bukti Tag',
                    Icons.label_rounded,
                    proofs['tagProof'] as String?,
                    AppColors.info,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Action bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
              boxShadow: AppShadow.md,
            ),
            child: Column(
              children: [
                if (_processing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: LinearProgressIndicator(color: AppColors.primary),
                  ),
                if (isPending)
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          'Tolak',
                          Icons.close_rounded,
                          AppColors.error,
                          outlined: true,
                          onTap: () => _setStatus('rejected'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          'Setujui',
                          Icons.check_rounded,
                          AppColors.success,
                          outlined: false,
                          onTap: () => _setStatus('approved'),
                        ),
                      ),
                    ],
                  )
                else
                  _ActionBtn(
                    isApproved ? 'Cabut Akses' : 'Aktifkan Kembali',
                    isApproved ? Icons.block_rounded : Icons.refresh_rounded,
                    isApproved ? AppColors.error : AppColors.success,
                    outlined: isApproved,
                    onTap: () =>
                        _setStatus(isApproved ? 'rejected' : 'approved'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SHARED DETAIL WIDGETS
// ============================================================================

class _DetailToolbar extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final Widget badge;
  const _DetailToolbar({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.softBg(iconColor),
            borderRadius: AppRadius.bMd,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.h3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: AppText.caption),
            ],
          ),
        ),
        badge,
      ],
    ),
  );
}

class _InfoItem {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoItem(this.icon, this.label, this.value, this.color);
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoGrid({required this.items});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: items
        .map(
          (item) => SizedBox(
            width: 260,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.bMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.softBg(item.color),
                      borderRadius: AppRadius.bSm,
                    ),
                    child: Icon(item.icon, color: item.color, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label, style: AppText.caption),
                        const SizedBox(height: 2),
                        Text(
                          item.value,
                          style: AppText.label.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList(),
  );
}

class _AccessStatusCard extends StatelessWidget {
  final bool isActive;
  const _AccessStatusCard({required this.isActive});
  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.softBg(color),
        borderRadius: AppRadius.bLg,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.lock_open_rounded : Icons.lock_rounded,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isActive ? 'Akses Aktif' : 'Akses Tidak Aktif',
                style: AppText.h3.copyWith(color: color),
              ),
              Text(
                isActive
                    ? 'Pengguna dapat mengerjakan tryout ini.'
                    : 'Pengguna tidak dapat mengakses tryout ini.',
                style: AppText.bodySm,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProofRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? url;
  final Color color;
  const _ProofRow(this.label, this.icon, this.url, this.color);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
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
          const SizedBox(width: 8),
          Text(label, style: AppText.label),
        ],
      ),
      const SizedBox(height: 10),
      Container(
        height: 400,
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
                    size: 36,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 8),
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
                    loadingBuilder: (_, child, p) => p == null
                        ? child
                        : Center(
                            child: CircularProgressIndicator(
                              value: p.expectedTotalBytes != null
                                  ? p.cumulativeBytesLoaded /
                                        p.expectedTotalBytes!
                                  : null,
                              color: AppColors.primary,
                            ),
                          ),
                    errorBuilder: (_, __, ___) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          size: 36,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 8),
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

// ============================================================================
// ERROR WIDGET — tampilkan link index Firestore agar bisa diklik
// ============================================================================
class _IndexErrorWidget extends StatelessWidget {
  final String error;
  const _IndexErrorWidget(this.error);

  // Ekstrak URL index dari pesan error Firestore
  String? _extractUrl(String err) {
    final match = RegExp(
      r'https://console\.firebase\.google\.com\S+',
    ).firstMatch(err);
    return match?.group(0);
  }

  @override
  Widget build(BuildContext context) {
    final url = _extractUrl(error);
    final isIndex = url != null || error.contains('index');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.softBg(AppColors.error),
            borderRadius: AppRadius.bLg,
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: AppRadius.bMd,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isIndex
                          ? 'Index Firestore Diperlukan'
                          : 'Terjadi Kesalahan',
                      style: AppText.h3.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isIndex
                    ? 'Query ini membutuhkan composite index di Firestore. '
                          'Tekan tombol di bawah untuk membuat index secara otomatis.'
                    : error,
                style: AppText.bodySm,
              ),
              if (url != null) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.bMd,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(
                    url,
                    style: AppText.caption.copyWith(
                      color: AppColors.info,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (url != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => html.window.open(url, '_blank'),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Buat Index Sekarang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.bMd,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Salin Pesan Error'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.bMd,
                      ),
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

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;
  const _ActionBtn(
    this.label,
    this.icon,
    this.color, {
    required this.outlined,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 17, color: outlined ? color : AppColors.white),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppText.btnMd.copyWith(
            color: outlined ? color : AppColors.white,
          ),
        ),
      ],
    );
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
              ),
              child: child,
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
              ),
              child: child,
            ),
    );
  }
}
