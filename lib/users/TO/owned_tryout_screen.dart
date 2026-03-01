// lib/features/tryout/screens/my_tryouts_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/theme.dart';
import 'tryout_detail_screen.dart';

// ─── FIRESTORE STRATEGY ───────────────────────────────────────────────────────
// SEBELUM (buruk):
//   Stream user_tryouts → N FutureBuilder each fetch tryouts/{id}
//   = 1 stream + N reads (N = jumlah tryout user)
//
// SESUDAH (efisien):
//   1. Stream user_tryouts (real-time)
//   2. Batch fetch tryout metadata — hanya 1x saat IDs berubah
//      menggunakan whereIn (max 10 per query, di-chunk otomatis)
//   3. Cache hasil di Map<tryoutId, data> — tidak re-fetch jika ID sama
//   = 1 stream + ceil(N/10) reads, cached
// ─────────────────────────────────────────────────────────────────────────────

class MyTryoutsScreen extends StatefulWidget {
  const MyTryoutsScreen({super.key});

  @override
  State<MyTryoutsScreen> createState() => _MyTryoutsScreenState();
}

class _MyTryoutsScreenState extends State<MyTryoutsScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  String _filter = 'all';
  bool _isLoadingMeta = false;

  // user_tryouts docs (stream)
  List<Map<String, dynamic>> _userTryouts = [];
  StreamSubscription<QuerySnapshot>? _sub;

  // Cache tryout metadata (batch fetched)
  final Map<String, Map<String, dynamic>> _tryoutCache = {};
  final Set<String> _fetchedIds = {};

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _subscribeUserTryouts();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Stream user_tryouts ────────────────────────────────────────────────────
  void _subscribeUserTryouts() {
    _sub = FirebaseFirestore.instance
        .collection('user_tryouts')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .listen((snap) async {
          if (!mounted) return;

          final docs = snap.docs
              .map((d) => {'__id': d.id, ...d.data()})
              .toList();

          // Collect IDs yang belum di-cache
          final newIds = docs
              .map((d) => d['tryoutId'] as String? ?? '')
              .where((id) => id.isNotEmpty && !_fetchedIds.contains(id))
              .toSet();

          if (newIds.isNotEmpty) {
            await _batchFetchTryouts(newIds);
          }

          if (mounted) {
            setState(() => _userTryouts = docs);
            if (_fadeCtrl.status == AnimationStatus.dismissed) {
              _fadeCtrl.forward();
            }
          }
        });
  }

  /// Batch fetch tryout metadata — whereIn chunks of 10
  Future<void> _batchFetchTryouts(Set<String> ids) async {
    if (!mounted) return;
    setState(() => _isLoadingMeta = true);

    try {
      final idList = ids.toList();
      // Firestore whereIn limit = 10
      for (int i = 0; i < idList.length; i += 10) {
        final chunk = idList.sublist(
          i,
          i + 10 > idList.length ? idList.length : i + 10,
        );
        final snap = await FirebaseFirestore.instance
            .collection('tryouts')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snap.docs) {
          _tryoutCache[doc.id] = doc.data();
        }
        _fetchedIds.addAll(chunk);
      }
    } catch (e) {
      debugPrint('[MyTryouts] batch fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMeta = false);
    }
  }

  // ── Filtered list ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    return _userTryouts.where((doc) {
      final isActive = doc['isActive'] == true;
      return switch (_filter) {
        'active' => isActive,
        'pending' => !isActive,
        _ => true,
      };
    }).toList();
  }

  // ============================================================================
  // BUILD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            if (_isLoadingMeta && _userTryouts.isEmpty)
              const LinearProgressIndicator(
                color: AppColors.gold,
                backgroundColor: AppColors.border,
                minHeight: 2,
              ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.navy),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              borderRadius: AppRadius.bMd,
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: AppColors.gold,
              size: 22,
            ),
          ),
          AppSpacing.hmd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Try Out Saya',
                  style: AppText.h2.copyWith(color: AppColors.white),
                ),
                Text(
                  'Lanjutkan perjalanan belajarmu',
                  style: AppText.bodySm.copyWith(
                    color: AppColors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          // Summary chips
          StreamBuilder<int>(
            stream: Stream.value(_userTryouts.length),
            builder: (_, __) => _HeaderChip(
              '${_userTryouts.length} Tryout',
              Icons.quiz_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // FILTER BAR
  // ============================================================================
  Widget _buildFilterBar() {
    const filters = [
      ('all', 'Semua', Icons.grid_view_rounded),
      ('active', 'Aktif', Icons.play_circle_rounded),
      ('pending', 'Pending', Icons.schedule_rounded),
    ];

    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: filters.map((f) {
          final selected = _filter == f.$1;
          return GestureDetector(
            onTap: () => setState(() => _filter = f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceAlt,
                borderRadius: AppRadius.bFull,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    f.$3,
                    size: 13,
                    color: selected ? AppColors.white : AppColors.textSecondary,
                  ),
                  AppSpacing.hxs,
                  Text(
                    f.$2,
                    style: AppText.label.copyWith(
                      fontSize: 12,
                      color: selected
                          ? AppColors.white
                          : AppColors.textSecondary,
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

  // ============================================================================
  // BODY
  // ============================================================================
  Widget _buildBody() {
    // Still waiting for first stream event
    if (_userTryouts.isEmpty && _isLoadingMeta) {
      return _buildSkeleton();
    }

    final filtered = _filtered;

    if (filtered.isEmpty) return _buildEmpty();

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => AppSpacing.vmd,
        itemBuilder: (_, i) {
          final doc = filtered[i];
          final tryoutId = doc['tryoutId'] as String? ?? '';
          final meta = _tryoutCache[tryoutId];

          // Metadata belum ready (edge case, biasanya sudah ada)
          if (meta == null) return _CardSkeleton();

          return _TryoutCard(
            userDoc: doc,
            tryoutMeta: meta,
            tryoutId: tryoutId,
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    final icon = switch (_filter) {
      'pending' => Icons.check_circle_rounded,
      'active' => Icons.hourglass_empty_rounded,
      _ => Icons.bookmark_border_rounded,
    };
    final title = switch (_filter) {
      'pending' => 'Tidak Ada Pending',
      'active' => 'Belum Ada Tryout Aktif',
      _ => 'Belum Ada Try Out',
    };
    final sub = switch (_filter) {
      'pending' => 'Semua tryout sudah diverifikasi',
      'active' => 'Tryout yang diverifikasi muncul di sini',
      _ => 'Beli try out di Marketplace untuk memulai',
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppGradient.navy,
              shape: BoxShape.circle,
              boxShadow: AppShadow.lg,
            ),
            child: Icon(icon, size: 36, color: AppColors.gold),
          ),
          AppSpacing.vlg,
          Text(title, style: AppText.h3),
          AppSpacing.vsm,
          Text(sub, style: AppText.bodySm, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: 4,
      separatorBuilder: (_, __) => AppSpacing.vmd,
      itemBuilder: (_, __) => _CardSkeleton(),
    );
  }
}

// ============================================================================
// TRYOUT CARD
// ============================================================================
class _TryoutCard extends StatelessWidget {
  final Map<String, dynamic> userDoc;
  final Map<String, dynamic> tryoutMeta;
  final String tryoutId;

  const _TryoutCard({
    required this.userDoc,
    required this.tryoutMeta,
    required this.tryoutId,
  });

  @override
  Widget build(BuildContext context) {
    // ── Data ──────────────────────────────────────────────────────────────────
    final title = tryoutMeta['title'] as String? ?? 'Tanpa Judul';
    final examType = tryoutMeta['examTypeName'] as String? ?? '';
    final totalQ = tryoutMeta['totalQuestions'] as int? ?? 0;
    final totalMin = tryoutMeta['totalEstimatedMinutes'] as int? ?? 0;
    final subtests = tryoutMeta['subtests'] as List<dynamic>? ?? [];
    final subCount = subtests.length;

    final isActive = userDoc['isActive'] == true;
    final proofStatus = userDoc['proofStatus'] as String? ?? 'pending_review';
    final subtestProgress =
        userDoc['subtestProgress'] as Map<String, dynamic>? ?? {};

    final completed = subtestProgress.values
        .where((v) => (v as Map<String, dynamic>?)?['status'] == 'completed')
        .length;
    final progressRatio = subCount > 0 ? completed / subCount : 0.0;
    final isDone = progressRatio >= 1.0 && subCount > 0;
    final notStarted = completed == 0;
    final inProgress = !notStarted && !isDone;

    // ── Status semantics ──────────────────────────────────────────────────────
    final _StatusInfo status = !isActive
        ? _StatusInfo(
            label: 'Pending Review',
            icon: Icons.schedule_rounded,
            color: AppColors.warning,
          )
        : isDone
        ? _StatusInfo(
            label: 'Selesai',
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
          )
        : notStarted
        ? _StatusInfo(
            label: 'Belum Dimulai',
            icon: Icons.play_circle_outline_rounded,
            color: AppColors.info,
          )
        : _StatusInfo(
            label: 'Sedang Berlangsung',
            icon: Icons.pending_rounded,
            color: AppColors.primary,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TryoutDetailScreen(tryoutId: tryoutId),
                ),
              )
            : null,
        borderRadius: AppRadius.bLg,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.bLg,
            border: Border.all(
              color: isActive
                  ? status.color.withOpacity(0.25)
                  : AppColors.border,
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: AppShadow.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Colored accent top bar ─────────────────────────────────
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: status.color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Row 1: type badge + status pill ─────────────────
                    Row(
                      children: [
                        if (examType.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppGradient.navy,
                              borderRadius: AppRadius.bFull,
                            ),
                            child: Text(
                              examType,
                              style: AppText.label.copyWith(
                                color: AppColors.gold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          AppSpacing.hxs,
                        ],
                        const Spacer(),
                        // Status pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softBg(status.color),
                            borderRadius: AppRadius.bFull,
                            border: Border.all(
                              color: status.color.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(status.icon, size: 11, color: status.color),
                              AppSpacing.hxs,
                              Text(
                                status.label,
                                style: AppText.label.copyWith(
                                  color: status.color,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    AppSpacing.vsm,

                    // ── Title ────────────────────────────────────────────
                    Text(
                      title,
                      style: AppText.bodyLg.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    AppSpacing.vmd,

                    // ── Stats row ────────────────────────────────────────
                    Row(
                      children: [
                        _MiniStat(
                          '$totalQ soal',
                          Icons.quiz_rounded,
                          AppColors.primary,
                        ),
                        AppSpacing.hmd,
                        _MiniStat(
                          '${totalMin}m',
                          Icons.timer_rounded,
                          AppColors.warning,
                        ),
                        AppSpacing.hmd,
                        _MiniStat(
                          '$subCount subtes',
                          Icons.layers_rounded,
                          AppColors.info,
                        ),
                        const Spacer(),
                        // CTA
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? AppColors.softBg(AppColors.success)
                                  : AppColors.primary,
                              borderRadius: AppRadius.bMd,
                              border: isDone
                                  ? Border.all(
                                      color: AppColors.success.withOpacity(0.4),
                                    )
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isDone
                                      ? Icons.bar_chart_rounded
                                      : notStarted
                                      ? Icons.play_arrow_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 13,
                                  color: isDone
                                      ? AppColors.success
                                      : AppColors.white,
                                ),
                                AppSpacing.hxs,
                                Text(
                                  isDone
                                      ? 'Review'
                                      : notStarted
                                      ? 'Mulai'
                                      : 'Lanjut',
                                  style: AppText.label.copyWith(
                                    fontSize: 11,
                                    color: isDone
                                        ? AppColors.success
                                        : AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // ── Progress bar ─────────────────────────────────────
                    if (isActive && inProgress) ...[
                      AppSpacing.vmd,
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Progress: $completed/$subCount subtes',
                                      style: AppText.caption,
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${(progressRatio * 100).toInt()}%',
                                      style: AppText.label.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                AppSpacing.vxs,
                                ClipRRect(
                                  borderRadius: AppRadius.bFull,
                                  child: LinearProgressIndicator(
                                    value: progressRatio,
                                    minHeight: 5,
                                    backgroundColor: AppColors.border,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ── Done badge ───────────────────────────────────────
                    if (isActive && isDone) ...[
                      AppSpacing.vmd,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softBg(AppColors.success),
                          borderRadius: AppRadius.bMd,
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: AppColors.success,
                              size: 15,
                            ),
                            AppSpacing.hxs,
                            Text(
                              'Semua subtes telah diselesaikan!',
                              style: AppText.bodySm.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Pending banner ───────────────────────────────────
                    if (!isActive) ...[
                      AppSpacing.vmd,
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.softBg(AppColors.warning),
                          borderRadius: AppRadius.bMd,
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: AppColors.warning,
                            ),
                            AppSpacing.hxs,
                            Expanded(
                              child: Text(
                                proofStatus == 'pending_review'
                                    ? 'Bukti pembayaran sedang diverifikasi admin'
                                    : 'Menunggu verifikasi admin',
                                style: AppText.caption.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

// ============================================================================
// SKELETON LOADER
// ============================================================================
class _CardSkeleton extends StatefulWidget {
  @override
  State<_CardSkeleton> createState() => _CardSkeletonState();
}

class _CardSkeletonState extends State<_CardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final opacity = 0.4 + (_anim.value * 0.3);
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.bLg,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // accent bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border.withOpacity(opacity),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Bone(60, 18, opacity),
                        const Spacer(),
                        _Bone(80, 22, opacity),
                      ],
                    ),
                    AppSpacing.vsm,
                    _Bone(double.infinity, 16, opacity),
                    AppSpacing.vxs,
                    _Bone(200, 16, opacity),
                    AppSpacing.vmd,
                    Row(
                      children: [
                        _Bone(60, 14, opacity),
                        AppSpacing.hmd,
                        _Bone(50, 14, opacity),
                        AppSpacing.hmd,
                        _Bone(60, 14, opacity),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bone extends StatelessWidget {
  final double w, h, opacity;
  const _Bone(this.w, this.h, this.opacity);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.border.withOpacity(opacity),
        borderRadius: AppRadius.bSm,
      ),
    );
  }
}

// ============================================================================
// SMALL WIDGETS
// ============================================================================
class _MiniStat extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _MiniStat(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        AppSpacing.hxs,
        Text(
          label,
          style: AppText.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _HeaderChip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        borderRadius: AppRadius.bFull,
        border: Border.all(color: AppColors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.gold),
          AppSpacing.hxs,
          Text(
            label,
            style: AppText.label.copyWith(color: AppColors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// Helper class
class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _StatusInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}
