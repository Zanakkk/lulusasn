// lib/features/tryout/screens/tryout_marketplace_screen.dart
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';

final _currencyFmt = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);

// ═══════════════════════════════════════════════════════════════════════════════
// MARKETPLACE SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class TryoutMarketplaceScreen extends StatefulWidget {
  final String? currentGoal; // ← terima dari luar (MainNavigationScreen)

  const TryoutMarketplaceScreen({super.key, this.currentGoal});

  @override
  State<TryoutMarketplaceScreen> createState() =>
      _TryoutMarketplaceScreenState();
}

class _TryoutMarketplaceScreenState extends State<TryoutMarketplaceScreen> {
  String _filter = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  // Cache ownership per tryoutId agar tidak FutureBuilder berulang
  final Map<String, bool> _ownershipCache = {};

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _prefetchOwnership();
  }

  // Fetch semua ownership sekaligus — 1 query, bukan N query per card
  Future<void> _prefetchOwnership() async {
    if (_uid.isEmpty) return;
    final snap = await FirebaseFirestore.instance
        .collection('user_tryouts')
        .where('userId', isEqualTo: _uid)
        .get();
    final owned = {for (final d in snap.docs) d['tryoutId'] as String: true};
    if (mounted) setState(() => _ownershipCache.addAll(owned));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradient.navy,
              borderRadius: AppRadius.bMd,
              boxShadow: AppShadow.md,
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: AppColors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Marketplace', style: AppText.h2),
              Text('Temukan try out terbaik untukmu', style: AppText.bodySm),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search Bar ───────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.bMd,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadow.sm,
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (q) =>
              setState(() => _searchQuery = q.toLowerCase().trim()),
          style: AppText.body,
          decoration: InputDecoration(
            hintText: 'Cari try out...',
            hintStyle: AppText.body.copyWith(color: AppColors.textHint),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textHint,
                      size: 18,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  // ── Filter Chips ─────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    const chips = [
      ('all', 'Semua', Icons.apps_rounded),
      ('free', 'Gratis', Icons.card_giftcard_rounded),
      ('premium', 'Premium', Icons.workspace_premium_rounded),
    ];

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: chips.map((c) {
          final sel = _filter == c.$1;
          return GestureDetector(
            onTap: () => setState(() => _filter = c.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: sel ? AppGradient.navy : null,
                color: sel ? null : AppColors.surface,
                borderRadius: AppRadius.bFull,
                border: Border.all(
                  color: sel ? Colors.transparent : AppColors.border,
                ),
                boxShadow: sel ? AppShadow.sm : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    c.$3,
                    size: 13,
                    color: sel ? AppColors.gold : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    c.$2,
                    style: AppText.label.copyWith(
                      color: sel ? AppColors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildList() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('tryouts')
        .where('isActive', isEqualTo: true);

    final goal = widget.currentGoal;
    if (goal != null && goal.isNotEmpty && goal != 'other') {
      query = query.where('examTypeName', isEqualTo: goal.toUpperCase());
    }

    query = query.orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          );
        }
        if (snap.hasError) {
          return _StatusView(
            icon: Icons.error_outline_rounded,
            color: AppColors.error,
            title: 'Terjadi Kesalahan',
            subtitle: snap.error.toString(),
          );
        }

        var docs = snap.data?.docs ?? [];

        // Filter premium/free
        if (_filter != 'all') {
          final wantPremium = _filter == 'premium';
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['isPremium'] as bool? ?? false) == wantPremium;
          }).toList();
        }

        // Search
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return ['title', 'description', 'examTypeName'].any(
              (k) => (data[k] ?? '').toString().toLowerCase().contains(
                _searchQuery,
              ),
            );
          }).toList();
        }

        if (docs.isEmpty) {
          final goalLabel = switch (goal) {
            'cpns' => 'CPNS',
            'lpdp' => 'LPDP',
            'bumn' => 'BUMN',
            'pcpm' => 'PCPM',
            _ => null,
          };
          return _StatusView(
            icon: Icons.search_off_rounded,
            color: AppColors.primary,
            title: 'Belum Ada Try Out',
            subtitle: goalLabel != null
                ? 'Belum ada try out untuk $goalLabel.\nCoba lagi nanti!'
                : 'Try out akan segera ditambahkan!',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _prefetchOwnership();
            setState(() {});
          },
          color: AppColors.gold,
          backgroundColor: AppColors.surface,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              return _MarketplaceCard(
                tryoutId: doc.id,
                data: data,
                owned: _ownershipCache[doc.id] ?? false,
                onTap: () =>
                    _handleCardTap(context, tryoutId: doc.id, data: data),
              );
            },
          ),
        );
      },
    );
  }

  void _handleCardTap(
    BuildContext context, {
    required String tryoutId,
    required Map<String, dynamic> data,
  }) {
    final owned = _ownershipCache[tryoutId] ?? false;
    if (owned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kamu sudah memiliki Try Out ini!',
            style: AppText.body.copyWith(color: AppColors.white),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TryoutPurchaseScreen(
          tryoutId: tryoutId,
          tryoutTitle: data['title'] as String? ?? '',
          tryoutDescription: data['description'] as String? ?? '',
          isPremium: data['isPremium'] as bool? ?? false,
          energyCost: data['price'] as int? ?? 0,
        ),
      ),
    ).then((_) => _prefetchOwnership()); // refresh ownership setelah kembali
  }
}

// ── Status View ───────────────────────────────────────────────────────────────
class _StatusView extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _StatusView({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    print(subtitle);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppText.h3),
          const SizedBox(height: 6),
          Text(subtitle, style: AppText.bodySm, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARKETPLACE CARD  — Navy · Gold · White design system
// ═══════════════════════════════════════════════════════════════════════════════
class _MarketplaceCard extends StatelessWidget {
  final String tryoutId;
  final Map<String, dynamic> data;
  final bool owned;
  final VoidCallback onTap;

  const _MarketplaceCard({
    required this.tryoutId,
    required this.data,
    required this.owned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Untitled';
    final description = data['description'] as String? ?? '';
    final examTypeName = data['examTypeName'] as String? ?? '';
    final isPremium = data['isPremium'] as bool? ?? false;
    final price = data['price'] as int? ?? 0;
    final totalQuestions = data['totalQuestions'] as int? ?? 0;
    final totalMinutes = data['totalEstimatedMinutes'] as int? ?? 0;
    final subtests = data['subtests'] as List? ?? [];

    // ── Palette sesuai design system ─────────────────────────────────────
    // Premium  → Gold gradient + Navy text
    // Free     → Navy solid  + White text
    final isPremiumStrip = isPremium
        ? AppGradient.gold
        : const LinearGradient(
            colors: [AppColors.primary, Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final accentColor = isPremium ? AppColors.gold : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.bLg,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadow.sm,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.bLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top accent strip: 4px gold / navy ─────────────────────────
              Container(
                height: 4,
                decoration: BoxDecoration(gradient: isPremiumStrip),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Row 1: exam type chip + premium/free pill ──────────
                    Row(
                      children: [
                        if (examTypeName.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              // ── Chip: navy tint ──────────────────────────
                              color: AppColors.primary.withOpacity(0.07),
                              borderRadius: AppRadius.bSm,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.15),
                              ),
                            ),
                            child: Text(
                              examTypeName,
                              style: AppText.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const Spacer(),
                        // ── Pill: gold gradient (premium) / navy (free) ────
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: isPremiumStrip,
                            borderRadius: AppRadius.bFull,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPremium
                                    ? Icons.star_rounded
                                    : Icons.bolt_rounded,
                                size: 11,
                                color: isPremium
                                    ? AppColors.primary
                                    : AppColors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPremium ? 'Premium' : 'Gratis',
                                style: AppText.label.copyWith(
                                  color: isPremium
                                      ? AppColors.primary
                                      : AppColors.white,
                                  fontSize: 10,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── Title ──────────────────────────────────────────────
                    Text(
                      title,
                      style: AppText.bodyLg.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppText.bodySm,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 12),

                    // ── Stats row: info/warning/success tetap, navy wrap ───
                    Row(
                      children: [
                        _MiniStat(
                          Icons.quiz_rounded,
                          '$totalQuestions soal',
                          AppColors.info,
                        ),
                        const SizedBox(width: 10),
                        _MiniStat(
                          Icons.timer_rounded,
                          '${totalMinutes}m',
                          AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        _MiniStat(
                          Icons.layers_rounded,
                          '${subtests.length} subtes',
                          AppColors.success,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 12),

                    // ── Price + CTA ────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Harga: gold (premium) / navy (free) ───────────
                        Text(
                          isPremium ? _currencyFmt.format(price) : 'GRATIS',
                          style: AppText.h3.copyWith(color: accentColor),
                        ),
                        const Spacer(),
                        // ── CTA button ────────────────────────────────────
                        owned
                            ? _OwnedBadge()
                            : _CtaButton(
                                isPremium: isPremium,
                                gradient: isPremiumStrip,
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI STAT
// ─────────────────────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  const _MiniStat(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: AppRadius.bSm,
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppText.caption),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA BUTTON  — gradient: gold (premium) / navy (free)
// ─────────────────────────────────────────────────────────────────────────────
class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.isPremium, required this.gradient});
  final bool isPremium;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.bMd,
        boxShadow: [
          BoxShadow(
            color: (isPremium ? AppColors.gold : AppColors.primary).withOpacity(
              0.25,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: isPremium ? AppColors.primary : AppColors.white,
          ),
          const SizedBox(width: 5),
          Text(
            'Dapatkan',
            style: AppText.label.copyWith(
              color: isPremium ? AppColors.primary : AppColors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OWNED BADGE  — sudah dimiliki, tidak bisa diklik lagi
// ─────────────────────────────────────────────────────────────────────────────
class _OwnedBadge extends StatelessWidget {
  const _OwnedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.10),
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.success.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: AppColors.success,
          ),
          const SizedBox(width: 5),
          Text(
            'Dimiliki',
            style: AppText.label.copyWith(
              color: AppColors.success,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// UPLOAD STATE & PROOF SLOT
// ═══════════════════════════════════════════════════════════════════════════════
enum UploadStage { idle, compressing, uploading, saving, done, error }

class UploadState {
  final UploadStage stage;
  final double progress;
  final String message;
  const UploadState({
    this.stage = UploadStage.idle,
    this.progress = 0.0,
    this.message = '',
  });

  bool get isActive =>
      stage != UploadStage.idle &&
      stage != UploadStage.done &&
      stage != UploadStage.error;
  bool get isError => stage == UploadStage.error;
  bool get isDone => stage == UploadStage.done;
}

class ProofSlot {
  final String type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  Uint8List? bytes;
  String? fileName;

  ProofSlot({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  bool get hasFile => bytes != null;
  void clear() {
    bytes = null;
    fileName = null;
  }
}
// ═══════════════════════════════════════════════════════════════════════════════
// TRYOUT PURCHASE SCREEN  —  Flutter Web Engineer Edition
// Layout  : Split-panel di web (≥720px), single column di mobile
// Palette : Navy #0F172A · Gold #D4AF37 · White — sesuai AppColors
// ═══════════════════════════════════════════════════════════════════════════════

class TryoutPurchaseScreen extends StatefulWidget {
  const TryoutPurchaseScreen({
    super.key,
    required this.tryoutId,
    required this.tryoutTitle,
    required this.tryoutDescription,
    required this.isPremium,
    required this.energyCost,
  });

  final String tryoutId;
  final String tryoutTitle;
  final String tryoutDescription;
  final bool isPremium;
  final int energyCost;

  @override
  State<TryoutPurchaseScreen> createState() => _TryoutPurchaseScreenState();
}

class _TryoutPurchaseScreenState extends State<TryoutPurchaseScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _animCtrl,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.03),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

  final _uploadState = ValueNotifier(const UploadState());
  String _selectedOption = 'free';

  late final List<ProofSlot> _slots = [
    ProofSlot(
      type: 'follow',
      title: 'Follow Instagram',
      description: 'Follow @luluzzz lalu screenshot',
      icon: Icons.person_add_rounded,
      color: AppColors.error,
    ),
    ProofSlot(
      type: 'story',
      title: 'Share di Story',
      description: 'Share & screenshot story-mu',
      icon: Icons.auto_stories_rounded,
      color: AppColors.info,
    ),
    ProofSlot(
      type: 'tag',
      title: 'Tag 3 Teman',
      description: 'Tag di komentar & screenshot',
      icon: Icons.alternate_email_rounded,
      color: AppColors.warning,
    ),
  ];

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _allUploaded => _slots.every((s) => s.hasFile);

  @override
  void dispose() {
    _animCtrl.dispose();
    _uploadState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isWide = screenW >= 720;

    return Scaffold(
      // ── Background: Navy gradient tipis agar tidak flat ──────────────────
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(isWide),
                Expanded(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: isWide
                          ? _buildWideLayout() // ← split panel
                          : _buildNarrowLayout(), // ← single column
                    ),
                  ),
                ),
              ],
            ),
            _buildFloatingNotif(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAppBar(bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.primary, // ← Navy, bukan putih
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          // ── Back button — gold accent di navy bg ──────────────────────────
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: AppRadius.bSm,
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dapatkan Try Out',
                style: AppText.h3.copyWith(color: AppColors.white),
              ),
              Text(
                'Pilih metode akses',
                style: AppText.bodySm.copyWith(
                  color: AppColors.white.withOpacity(0.55),
                ),
              ),
            ],
          ),
          const Spacer(),
          // ── Gold accent strip di kanan appbar ─────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppGradient.gold,
              borderRadius: AppRadius.bFull,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isPremium ? 'PREMIUM' : 'GRATIS',
                  style: AppText.label.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDE LAYOUT  —  Left panel (info) | Right panel (action)
  // Mengisi penuh lebar layar, tidak ada dead space
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── LEFT PANEL: 38% lebar layar — navy bg ─────────────────────────
        Flexible(flex: 38, child: _buildLeftPanel()),
        // ── Divider tipis ─────────────────────────────────────────────────
        const VerticalDivider(width: 1, color: AppColors.border),
        // ── RIGHT PANEL: 62% lebar layar — konten utama ───────────────────
        Flexible(flex: 62, child: _buildRightPanel(isWide: true)),
      ],
    );
  }

  // ── Left panel ─────────────────────────────────────────────────────────────
  Widget _buildLeftPanel() {
    final isPremium = widget.isPremium;
    final uploadedCount = _slots.where((s) => s.hasFile).length;

    return Container(
      // ── Navy solid, konsisten dengan appbar ─────────────────────────────
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Type badge ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: isPremium
                  ? AppGradient.gold
                  : const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
              borderRadius: AppRadius.bFull,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPremium ? Icons.star_rounded : Icons.bolt_rounded,
                  size: 13,
                  color: isPremium ? AppColors.primary : AppColors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  isPremium ? 'PREMIUM' : 'GRATIS',
                  style: AppText.label.copyWith(
                    color: isPremium ? AppColors.primary : AppColors.white,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Judul ────────────────────────────────────────────────────────
          Text(
            widget.tryoutTitle,
            style: AppText.h1.copyWith(color: AppColors.white, height: 1.3),
          ),
          if (widget.tryoutDescription.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.tryoutDescription,
              style: AppText.body.copyWith(
                color: AppColors.white.withOpacity(0.62),
                height: 1.6,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Spacer(),

          // ── Progress indicator upload ─────────────────────────────────────
          if (_selectedOption == 'free') ...[
            _buildUploadProgress(uploadedCount),
            const SizedBox(height: 24),
          ],

          // ── Info card bawah ───────────────────────────────────────────────
          _buildLeftInfoCard(),
        ],
      ),
    );
  }

  Widget _buildUploadProgress(int uploaded) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bukti Upload',
              style: AppText.label.copyWith(
                color: AppColors.white.withOpacity(0.7),
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '$uploaded / ${_slots.length}',
              style: AppText.label.copyWith(
                color: AppColors.gold,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: AppRadius.bFull,
          child: LinearProgressIndicator(
            value: uploaded / _slots.length,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.12),
            valueColor: const AlwaysStoppedAnimation(AppColors.gold),
          ),
        ),
        const SizedBox(height: 12),
        // ── Dot indicator per slot ────────────────────────────────────────
        Row(
          children: _slots.map((s) {
            final done = s.hasFile;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: done ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: done ? AppColors.gold : Colors.white.withOpacity(0.2),
                  borderRadius: AppRadius.bFull,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLeftInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: AppRadius.bMd,
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          _LeftInfoRow(
            icon: Icons.shield_outlined,
            label: 'Data kamu aman & terenkripsi',
          ),
          const SizedBox(height: 10),
          _LeftInfoRow(
            icon: Icons.timer_outlined,
            label: 'Review bukti dalam 1×24 jam',
          ),
          const SizedBox(height: 10),
          _LeftInfoRow(
            icon: Icons.verified_outlined,
            label: 'Akses penuh setelah disetujui',
          ),
        ],
      ),
    );
  }

  // ── Right panel ────────────────────────────────────────────────────────────
  Widget _buildRightPanel({required bool isWide}) {
    return Container(
      color: AppColors.bg,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 36 : 16,
          vertical: 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isWide) ...[
              // ── Mobile: info card ────────────────────────────────────────
              _buildMobileTryoutCard(),
              const SizedBox(height: 20),
            ],

            // ── Section header ────────────────────────────────────────────
            Text('Metode Akses', style: AppText.h3),
            const SizedBox(height: 4),
            Text('Pilih cara mendapatkan try out ini.', style: AppText.bodySm),
            const SizedBox(height: 16),

            _OptionSelector(
              selected: _selectedOption,
              onChanged: (v) => setState(() => _selectedOption = v),
            ),
            const SizedBox(height: 20),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.025),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _selectedOption == 'free'
                  ? _buildFreeSection(isWide: isWide)
                  : _buildPaidSection(),
            ),

            const SizedBox(height: 20),
            _buildSubmitButton(),
            const SizedBox(height: 16),

            // ── Fine print ────────────────────────────────────────────────
            Text(
              'Dengan mengirim, kamu menyetujui bahwa bukti yang diunggah adalah asli dan sesuai dengan instruksi.',
              style: AppText.caption.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NARROW (MOBILE) LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNarrowLayout() {
    return _buildRightPanel(isWide: false);
  }

  // ── Mobile tryout card (hanya muncul di narrow) ───────────────────────────
  Widget _buildMobileTryoutCard() {
    final isPremium = widget.isPremium;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.bLg,
        boxShadow: AppShadow.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: isPremium
                  ? AppGradient.gold
                  : const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
              borderRadius: AppRadius.bFull,
            ),
            child: Text(
              isPremium ? 'PREMIUM' : 'GRATIS',
              style: AppText.label.copyWith(
                color: isPremium ? AppColors.primary : AppColors.white,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.tryoutTitle,
            style: AppText.h2.copyWith(color: AppColors.white),
          ),
          if (widget.tryoutDescription.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.tryoutDescription,
              style: AppText.bodySm.copyWith(
                color: Colors.white.withOpacity(0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FREE SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFreeSection({required bool isWide}) {
    return Column(
      key: const ValueKey('free'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Info banner: gold accent ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.08),
            borderRadius: AppRadius.bMd,
            border: Border.all(color: AppColors.gold.withOpacity(0.30)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.gold,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Upload 3 bukti promosi untuk akses penuh secara gratis.',
                  style: AppText.bodySm.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Proof slots ────────────────────────────────────────────────────
        ..._slots.asMap().entries.map(
          (e) => _AnimatedProofCard(
            key: ValueKey(e.key),
            index: e.key,
            slot: e.value,
            onPick: () => _pickImage(e.value),
            onRemove: () => setState(() => e.value.clear()),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAID SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPaidSection() {
    const methods = [
      (Icons.qr_code_rounded, 'QRIS Payment', AppColors.info),
      (Icons.credit_card_rounded, 'Credit Card', AppColors.primary),
      (Icons.account_balance_rounded, 'Bank Transfer', AppColors.warning),
    ];

    return Container(
      key: const ValueKey('paid'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.construction_rounded,
              size: 42,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text('Coming Soon', style: AppText.h3),
          const SizedBox(height: 6),
          Text(
            'Metode pembayaran sedang dikembangkan.',
            style: AppText.bodySm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ...methods.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: m.$3.withOpacity(0.10),
                      borderRadius: AppRadius.bSm,
                    ),
                    child: Icon(m.$1, size: 18, color: m.$3),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    m.$2,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: AppRadius.bFull,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Segera',
                      style: AppText.caption.copyWith(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBMIT BUTTON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSubmitButton() {
    final canSubmit = _selectedOption == 'free' && _allUploaded;
    final isPaid = _selectedOption == 'paid';

    return ValueListenableBuilder<UploadState>(
      valueListenable: _uploadState,
      builder: (_, state, __) {
        final isLoading = state.isActive;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: AppRadius.bMd,
            boxShadow: canSubmit && !isLoading
                ? [
                    BoxShadow(
                      // ── Gold glow saat siap submit ───────────────────────
                      color: AppColors.gold.withOpacity(0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: (canSubmit && !isLoading) ? _handleSubmit : null,
            style: ElevatedButton.styleFrom(
              // ── Aktif: Navy; Disabled: surfaceAlt ─────────────────────────
              backgroundColor: canSubmit && !isLoading
                  ? AppColors.primary
                  : AppColors.surfaceAlt,
              foregroundColor: canSubmit && !isLoading
                  ? AppColors.white
                  : AppColors.textHint,
              disabledBackgroundColor: AppColors.surfaceAlt,
              disabledForegroundColor: AppColors.textHint,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.bMd,
                side: BorderSide(
                  color: canSubmit && !isLoading
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              textStyle: AppText.btnMd,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isLoading
                  ? const Row(
                      key: ValueKey('loading'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Mengirim...'),
                      ],
                    )
                  : Row(
                      key: ValueKey(_selectedOption + canSubmit.toString()),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPaid
                              ? Icons.lock_rounded
                              : canSubmit
                              ? Icons.check_circle_rounded
                              : Icons.upload_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPaid
                              ? 'Belum Tersedia'
                              : canSubmit
                              ? 'Kirim & Dapatkan Try Out'
                              : 'Upload Semua Bukti Terlebih Dahulu',
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOATING NOTIF
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFloatingNotif() {
    return ValueListenableBuilder<UploadState>(
      valueListenable: _uploadState,
      builder: (_, state, __) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          bottom: state.stage == UploadStage.idle ? -140 : 24,
          right: 24,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 260),
            opacity: state.stage == UploadStage.idle ? 0 : 1,
            child: _FloatingNotifCard(
              state: state,
              onDismiss: state.isError || state.isDone
                  ? () => _uploadState.value = const UploadState()
                  : null,
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGIC (tidak berubah)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _pickImage(ProofSlot slot) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      final file = result?.files.firstOrNull;
      if (file?.bytes == null) return;

      _uploadState.value = const UploadState(
        stage: UploadStage.compressing,
        message: 'Memproses gambar...',
        progress: 0.2,
      );

      final compressed = await _compressImage(file!.bytes!);
      if (!mounted) return;
      setState(() {
        slot.bytes = compressed;
        slot.fileName = file.name;
      });

      _uploadState.value = const UploadState(
        stage: UploadStage.done,
        message: 'Gambar siap!',
        progress: 1,
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _uploadState.value = const UploadState();
    } catch (e) {
      _uploadState.value = UploadState(
        stage: UploadStage.error,
        message: 'Gagal: $e',
      );
    }
  }

  Future<void> _handleSubmit() async {
    try {
      final urls = <String>[];
      for (var i = 0; i < _slots.length; i++) {
        _uploadState.value = UploadState(
          stage: UploadStage.uploading,
          message: 'Mengunggah bukti ${i + 1} dari ${_slots.length}...',
          progress: (i / _slots.length) * 0.88,
        );
        final url = await _uploadFile(
          bytes: _slots[i].bytes!,
          fileName: _slots[i].fileName ?? '${_slots[i].type}.jpg',
          proofType: _slots[i].type,
          onProgress: (p) => _uploadState.value = UploadState(
            stage: UploadStage.uploading,
            message: 'Mengunggah bukti ${i + 1} dari ${_slots.length}...',
            progress: ((i + p) / _slots.length) * 0.88,
          ),
        );
        if (url == null) throw Exception('Gagal upload: ${_slots[i].title}');
        urls.add(url);
      }

      _uploadState.value = const UploadState(
        stage: UploadStage.saving,
        message: 'Menyimpan data...',
        progress: 0.95,
      );

      await FirebaseFirestore.instance
          .collection('user_tryouts')
          .doc('${_uid}_tryout_${widget.tryoutId}')
          .set({
            'userId': _uid,
            'tryoutId': widget.tryoutId,
            'proofStatus': 'pending_review',
            'submittedAt': FieldValue.serverTimestamp(),
            'promotionProofs': {
              'followProof': urls[0],
              'storyProof': urls[1],
              'tagProof': urls[2],
            },
            'isActive': false,
          });

      _uploadState.value = const UploadState(
        stage: UploadStage.done,
        message: 'Berhasil! Sedang menunggu review admin.',
        progress: 1.0,
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _uploadState.value = UploadState(
        stage: UploadStage.error,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<String?> _uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String proofType,
    required void Function(double) onProgress,
  }) async {
    try {
      final path =
          'tryout_proofs/$_uid/${widget.tryoutId}/${proofType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(path);
      final task = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      task.snapshotEvents.listen((s) {
        if (s.totalBytes > 0) onProgress(s.bytesTransferred / s.totalBytes);
      });
      await task;
      return ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final img = html.ImageElement()..src = url;
      await img.onLoad.first;
      html.Url.revokeObjectUrl(url);
      const maxDim = 1200;
      var w = img.naturalWidth, h = img.naturalHeight;
      if (w == 0 || h == 0) return bytes;
      if (w > maxDim || h > maxDim) {
        if (w >= h) {
          h = (h * maxDim / w).round();
          w = maxDim;
        } else {
          w = (w * maxDim / h).round();
          h = maxDim;
        }
      }
      final canvas = html.CanvasElement(width: w, height: h)
        ..context2D.drawImageScaled(img, 0, 0, w, h);
      return base64Decode(canvas.toDataUrl('image/jpeg', 0.82).split(',').last);
    } catch (_) {
      return bytes;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXTRACTED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

// ── Left info row ─────────────────────────────────────────────────────────────
class _LeftInfoRow extends StatelessWidget {
  const _LeftInfoRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppText.bodySm.copyWith(
              color: AppColors.white.withOpacity(0.65),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Option Selector ───────────────────────────────────────────────────────────
class _OptionSelector extends StatelessWidget {
  const _OptionSelector({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: 'Gratis',
              icon: Icons.celebration_rounded,
              isSelected: selected == 'free',
              // ── Navy saat aktif ───────────────────────────────────────────
              selectedColor: AppColors.primary,
              onTap: () => onChanged('free'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _Tab(
              label: 'Bayar',
              icon: Icons.credit_card_rounded,
              isSelected: selected == 'paid',
              selectedColor: AppColors.primary,
              onTap: () => onChanged('paid'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: AppRadius.bSm,
          boxShadow: isSelected ? AppShadow.sm : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppText.label.copyWith(
                color: isSelected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated Proof Card ───────────────────────────────────────────────────────
class _AnimatedProofCard extends StatefulWidget {
  const _AnimatedProofCard({
    super.key,
    required this.index,
    required this.slot,
    required this.onPick,
    required this.onRemove,
  });
  final int index;
  final ProofSlot slot;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  State<_AnimatedProofCard> createState() => _AnimatedProofCardState();
}

class _AnimatedProofCardState extends State<_AnimatedProofCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ProofCard(
            slot: widget.slot,
            onPick: widget.onPick,
            onRemove: widget.onRemove,
          ),
        ),
      ),
    );
  }
}

class _ProofCard extends StatelessWidget {
  const _ProofCard({
    required this.slot,
    required this.onPick,
    required this.onRemove,
  });
  final ProofSlot slot;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bMd,
        border: Border.all(
          // ── Border ikut warna slot saat selesai upload ───────────────────
          color: slot.hasFile ? slot.color : AppColors.border,
          width: slot.hasFile ? 1.5 : 1,
        ),
        boxShadow: slot.hasFile
            ? [
                BoxShadow(
                  color: slot.color.withOpacity(0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : AppShadow.sm,
      ),
      child: Row(
        children: [
          // ── Icon ──────────────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            width: 52,
            height: 52,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: slot.hasFile ? slot.color : slot.color.withOpacity(0.10),
              borderRadius: AppRadius.bSm,
            ),
            child: Icon(
              slot.hasFile ? Icons.check_rounded : slot.icon,
              color: slot.hasFile ? AppColors.white : slot.color,
              size: 22,
            ),
          ),
          // ── Text ──────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.title,
                  style: AppText.label.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(slot.description, style: AppText.caption),
                if (slot.hasFile && slot.fileName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    slot.fileName!,
                    style: AppText.caption.copyWith(
                      color: slot.color,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // ── Action ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: slot.hasFile
                ? GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: AppRadius.bSm,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: onPick,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        // ── Upload button: Navy ──────────────────────────────
                        color: AppColors.primary.withOpacity(0.07),
                        borderRadius: AppRadius.bSm,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        'Upload',
                        style: AppText.label.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Floating Notif Card ───────────────────────────────────────────────────────
class _FloatingNotifCard extends StatelessWidget {
  const _FloatingNotifCard({required this.state, this.onDismiss});
  final UploadState state;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = state.isError
        ? AppColors.error
        : state.isDone
        ? AppColors.success
        : AppColors.info;

    return Material(
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.15),
      borderRadius: AppRadius.bMd,
      child: Container(
        width: 290,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.bMd,
          border: Border.all(color: color.withOpacity(0.30), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (state.isError)
                  Icon(Icons.error_outline_rounded, color: color, size: 18)
                else if (state.isDone)
                  Icon(Icons.check_circle_rounded, color: color, size: 18)
                else
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.message,
                    style: AppText.bodySm.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  GestureDetector(
                    onTap: onDismiss,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: AppColors.textHint,
                    ),
                  ),
              ],
            ),
            if (state.isActive && state.progress > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: AppRadius.bFull,
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 5,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(state.progress * 100).toInt()}%',
                  style: AppText.caption.copyWith(color: color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
