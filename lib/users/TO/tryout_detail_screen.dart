// lib/features/tryout/screens/tryout_detail_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import 'ExamScreen.dart';
import 'exam_review_screen.dart';

// ─── FIRESTORE STRATEGY ───────────────────────────────────────────────────────
// READ:
//   1. tryouts/{id}          → 1 read (full doc, embedded subtests)
//   2. user_tryouts/{uid_id} → 1 stream (real-time progress, no polling)
// WRITE:
//   - Init user_tryouts → 1 write (set, hanya jika belum ada)
//   - Progress update   → di ExamSessionScreen (update only)
// TOTAL: 1 read + 1 stream listener. Tidak ada write berulang.
// ─────────────────────────────────────────────────────────────────────────────

class TryoutDetailScreen extends StatefulWidget {
  final String tryoutId;
  const TryoutDetailScreen({super.key, required this.tryoutId});

  @override
  State<TryoutDetailScreen> createState() => _TryoutDetailScreenState();
}

class _TryoutDetailScreenState extends State<TryoutDetailScreen>
    with SingleTickerProviderStateMixin {

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool _isReloading = false;
  String? _error;
  Map<String, dynamic>? _tryout;
  Map<String, dynamic>? _progress;

  StreamSubscription<DocumentSnapshot>? _progressSub;
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;

  // ── Auth ───────────────────────────────────────────────────────────────────
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _headerFade =
        CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _loadTryout();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _headerAnim.dispose();
    super.dispose();
  }

  // ── Data Loading ───────────────────────────────────────────────────────────
  Future<void> _loadTryout({bool reload = false}) async {
    if (reload) {
      setState(() => _isReloading = true);
    } else {
      setState(() { _isLoading = true; _error = null; });
    }

    try {
      // 1. Fetch tryout (1 read)
      final snap = await FirebaseFirestore.instance
          .collection('tryouts')
          .doc(widget.tryoutId)
          .get();

      if (!snap.exists) throw Exception('Tryout tidak ditemukan');
      _tryout = snap.data()!;

      // 2. Ensure user_tryouts dokumen ada (1 conditional write)
      final progressRef = FirebaseFirestore.instance
          .collection('user_tryouts')
          .doc('${_uid}_tryout_${widget.tryoutId}');

      final progressSnap = await progressRef.get();
      if (!progressSnap.exists) {
        final subtests = _tryout!['subtests'] as List<dynamic>? ?? [];
        final initProgress = <String, dynamic>{};
        for (final s in subtests) {
          final sid = (s as Map<String, dynamic>)['id'] ?? s['name'];
          initProgress[sid] = {
            'status': 'not_started',
            'attempts': 0,
            'bestScore': null,
            'lastAttemptAt': null,
          };
        }
        await progressRef.set({
          'userId': _uid,
          'tryoutId': widget.tryoutId,
          'subtestProgress': initProgress,
          'totalAttempts': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Real-time listener untuk progress (stream, bukan polling)
      _progressSub?.cancel();
      _progressSub = progressRef.snapshots().listen((s) {
        if (s.exists && mounted) {
          setState(() => _progress = s.data());
        }
      });

      _headerAnim.forward();
      setState(() { _isLoading = false; _isReloading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isReloading = false;
      });
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _startSubtest(Map<String, dynamic> subtest) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamSessionScreen(
          tryoutId: widget.tryoutId,
          subtestId: subtest['id'] ?? subtest['name'],
          subtestData: subtest,
        ),
      ),
    ).then((_) => _loadTryout(reload: true));
  }

  Future<void> _reviewSubtest(Map<String, dynamic> subtest) async {
    HapticFeedback.mediumImpact();
    try {
      final sid = subtest['id'] ?? subtest['name'];
      final results = await FirebaseFirestore.instance
          .collection('exam_results')
          .where('userId', isEqualTo: _uid)
          .where('tryoutId', isEqualTo: widget.tryoutId)
          .where('subtestId', isEqualTo: sid)
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();

      if (results.docs.isEmpty) throw Exception('Belum ada hasil ujian');
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamReviewScreen(resultId: results.docs.first.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', ''),
            style: AppText.body.copyWith(color: AppColors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  // ============================================================================
  // BUILD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScaffold();
    if (_error != null) return _buildErrorScaffold();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          LayoutBuilder(builder: (ctx, box) {
            return box.maxWidth > 1024
                ? _buildDesktop()
                : _buildMobile();
          }),
          // Reload indicator strip
          if (_isReloading)
            Positioned(
              top: 0, left: 0, right: 0,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.border,
                color: AppColors.gold,
                minHeight: 3,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================
  Widget _buildDesktop() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left
                    SizedBox(
                      width: 340,
                      child: Column(children: [
                        _buildInfoCard(),
                        AppSpacing.vmd,
                        _buildStatsCard(),
                        AppSpacing.vmd,
                        _buildDescCard(),
                      ]),
                    ),
                    AppSpacing.hlg,
                    // Right — subtests
                    Expanded(child: _buildSubtestsCard()),
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
  // MOBILE LAYOUT
  // ============================================================================
  Widget _buildMobile() {
    return RefreshIndicator(
      onRefresh: () => _loadTryout(reload: true),
      color: AppColors.gold,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoCard(),
                AppSpacing.vmd,
                _buildStatsCard(),
                AppSpacing.vmd,
                _buildDescCard(),
                AppSpacing.vmd,
                _buildSubtestsCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SLIVER APP BAR
  // ============================================================================
  Widget _buildSliverAppBar() {
    final title = _tryout?['title'] ?? '';
    final examType = _tryout?['examTypeName'] ?? '';

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.15),
            borderRadius: AppRadius.bSm,
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: AppColors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: FadeTransition(
          opacity: _headerFade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (examType.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: AppGradient.gold,
                    borderRadius: AppRadius.bFull,
                  ),
                  child: Text(examType,
                      style: AppText.caption.copyWith(
                          color: AppColors.primary, fontSize: 9)),
                ),
              const SizedBox(height: 3),
              Text(title,
                  style: AppText.h3.copyWith(
                      color: AppColors.white, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(gradient: AppGradient.navy),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: FadeTransition(
              opacity: _headerFade,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Breadcrumb
                  Row(children: [
                    const Icon(Icons.home_rounded,
                        size: 12, color: AppColors.gold),
                    AppSpacing.hxs,
                    Text('Try Out',
                        style: AppText.caption.copyWith(
                            color: AppColors.gold, fontSize: 10)),
                    Icon(Icons.chevron_right_rounded,
                        size: 12,
                        color: AppColors.white.withOpacity(0.4)),
                    Text(examType,
                        style: AppText.caption.copyWith(
                            color: AppColors.white.withOpacity(0.5),
                            fontSize: 10)),
                  ]),
                  AppSpacing.vsm,
                  Text(title,
                      style: AppText.h1.copyWith(
                          color: AppColors.white, fontSize: 22),
                      maxLines: 2),
                  AppSpacing.vsm,
                  // Quick stats strip
                  Row(children: [
                    _AppBarChip(
                        '${_tryout?['totalQuestions'] ?? 0} Soal',
                        Icons.quiz_rounded),
                    AppSpacing.hsm,
                    _AppBarChip(
                        '${_tryout?['totalEstimatedMinutes'] ?? 0} Menit',
                        Icons.timer_rounded),
                    AppSpacing.hsm,
                    _AppBarChip(
                        '${_tryout?['subTestCount'] ?? 0} Subtes',
                        Icons.layers_rounded),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // INFO CARD
  // ============================================================================
  Widget _buildInfoCard() {
    final isActive = _tryout?['isActive'] == true;
    final isFlexible = _tryout?['isFlexibleDate'] == true;
    final price = _tryout?['price'] ?? 0;
    final examType = _tryout?['examTypeName'] ?? '-';
    final createdAt = (_tryout?['createdAt'] as Timestamp?)?.toDate();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader('Informasi Tryout', Icons.info_outline_rounded,
              AppColors.primary),
          AppSpacing.vmd,
          _InfoRow2('Tipe Ujian', examType, Icons.school_rounded,
              AppColors.info),
          _InfoRow2(
              'Status',
              isActive ? 'Aktif & Tersedia' : 'Tidak Aktif',
              isActive
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              isActive ? AppColors.success : AppColors.textSecondary),
          _InfoRow2(
              'Periode',
              isFlexible ? 'Tanggal Bebas' : 'Terjadwal',
              Icons.calendar_today_rounded,
              AppColors.warning),
          _InfoRow2(
              'Biaya',
              price == 0 ? 'Gratis' : 'Rp $price',
              Icons.attach_money_rounded,
              price == 0 ? AppColors.success : AppColors.gold),
          if (createdAt != null)
            _InfoRow2(
                'Dibuat',
                DateFormat('dd MMM yyyy').format(createdAt),
                Icons.schedule_rounded,
                AppColors.textSecondary),
        ],
      ),
    );
  }

  // ============================================================================
  // STATS CARD
  // ============================================================================
  Widget _buildStatsCard() {
    final totalQ = _tryout?['totalQuestions'] ?? 0;
    final totalMin = _tryout?['totalEstimatedMinutes'] ?? 0;
    final subCount = _tryout?['subTestCount'] ?? 0;

    // Hitung progress dari user_progress
    final subtestMap =
        _progress?['subtestProgress'] as Map<String, dynamic>? ?? {};
    final completed =
        subtestMap.values.where((v) => v['status'] == 'completed').length;
    final pct = subCount > 0 ? completed / subCount : 0.0;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader('Statistik', Icons.analytics_rounded, AppColors.info),
          AppSpacing.vmd,
          Row(children: [
            _StatBox('$totalQ', 'Soal', Icons.quiz_rounded, AppColors.primary),
            AppSpacing.hmd,
            _StatBox('${totalMin}m', 'Durasi', Icons.timer_rounded,
                AppColors.warning),
            AppSpacing.hmd,
            _StatBox('$subCount', 'Subtes', Icons.layers_rounded,
                AppColors.info),
          ]),
          if (_progress != null) ...[
            AppSpacing.vmd,
            Row(children: [
              Text('Progress: $completed/$subCount',
                  style: AppText.label
                      .copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              Text('${(pct * 100).toInt()}%',
                  style: AppText.label
                      .copyWith(color: AppColors.success)),
            ]),
            AppSpacing.vxs,
            ClipRRect(
              borderRadius: AppRadius.bFull,
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: AppColors.border,
                color: AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // DESCRIPTION CARD
  // ============================================================================
  Widget _buildDescCard() {
    final desc = _tryout?['description'] ?? '';
    if (desc.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader('Deskripsi', Icons.description_rounded,
              AppColors.textSecondary),
          AppSpacing.vmd,
          Text(desc,
              style: AppText.body.copyWith(
                  height: 1.65,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ============================================================================
  // SUBTESTS CARD
  // ============================================================================
  Widget _buildSubtestsCard() {
    final subtests = _tryout?['subtests'] as List<dynamic>? ?? [];
    if (subtests.isEmpty) return const SizedBox.shrink();

    final subtestMap =
        _progress?['subtestProgress'] as Map<String, dynamic>? ?? {};

    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _CardHeader(
                'Daftar Subtes (${subtests.length})',
                Icons.list_alt_rounded,
                AppColors.warning),
          ),
          const Divider(height: 1, color: AppColors.border),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(14),
            itemCount: subtests.length,
            separatorBuilder: (_, __) => AppSpacing.vsm,
            itemBuilder: (_, i) {
              final sub = subtests[i] as Map<String, dynamic>;
              final sid = sub['id'] ?? sub['name'];
              final prog =
                  subtestMap[sid] as Map<String, dynamic>? ?? {};

              // Sequential unlock
              bool unlocked = i == 0;
              if (i > 0) {
                final prevSub =
                subtests[i - 1] as Map<String, dynamic>;
                final prevId = prevSub['id'] ?? prevSub['name'];
                final prevProg =
                    subtestMap[prevId] as Map<String, dynamic>? ?? {};
                unlocked = prevProg['status'] == 'completed';
              }

              return _SubtestCard(
                subtest: sub,
                progress: prog,
                number: i + 1,
                unlocked: unlocked,
                onStart: () => _startSubtest(sub),
                onReview: () => _reviewSubtest(sub),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // LOADING & ERROR
  // ============================================================================
  Widget _buildLoadingScaffold() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  gradient: AppGradient.navy, shape: BoxShape.circle),
              child: const CircularProgressIndicator(
                  color: AppColors.gold, strokeWidth: 3),
            ),
            AppSpacing.vlg,
            Text('Memuat Tryout...',
                style: AppText.h3),
            AppSpacing.vsm,
            Text('Mohon tunggu', style: AppText.bodySm),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScaffold() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.softBg(AppColors.error),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 44),
              ),
              AppSpacing.vlg,
              Text('Gagal Memuat', style: AppText.h2),
              AppSpacing.vsm,
              Text(_error ?? 'Error tidak diketahui',
                  style: AppText.bodySm, textAlign: TextAlign.center),
              AppSpacing.vxl,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.bMd),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('Kembali'),
                    ),
                  ),
                  AppSpacing.hmd,
                  SizedBox(
                    width: 130,
                    child: ElevatedButton(
                      onPressed: _loadTryout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.bMd),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SUBTEST CARD WIDGET
// ============================================================================
class _SubtestCard extends StatelessWidget {
  final Map<String, dynamic> subtest;
  final Map<String, dynamic> progress;
  final int number;
  final bool unlocked;
  final VoidCallback onStart;
  final VoidCallback onReview;

  const _SubtestCard({
    required this.subtest,
    required this.progress,
    required this.number,
    required this.unlocked,
    required this.onStart,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final name = subtest['name'] ?? 'Subtes $number';
    final desc = subtest['description'] ?? '';
    final category = subtest['category'] ?? '';
    final difficulty = subtest['difficulty'] ?? 'medium';
    final minutes = subtest['estimatedMinutes'] ?? 0;
    final qCount = subtest['questionCount'] ?? 0;

    final status = progress['status']?.toString() ?? 'not_started';
    final bestScore = progress['bestScore'] is int
        ? progress['bestScore'] as int
        : int.tryParse(progress['bestScore']?.toString() ?? '');
    final attempts = progress['attempts'] is int
        ? progress['attempts'] as int
        : int.tryParse(progress['attempts']?.toString() ?? '') ?? 0;

    final isCompleted = status == 'completed';

    // Colors
    final Color stateColor = !unlocked
        ? AppColors.textHint
        : isCompleted
        ? AppColors.success
        : AppColors.primary;

    final Color diffColor = switch (difficulty) {
      'easy' => AppColors.success,
      'hard' => AppColors.error,
      _ => AppColors.warning,
    };

    final String diffLabel = switch (difficulty) {
      'easy' => 'Mudah',
      'hard' => 'Sulit',
      _ => 'Menengah',
    };

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: unlocked ? 1.0 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.bMd,
          border: Border.all(
            color: isCompleted
                ? AppColors.success.withOpacity(0.4)
                : AppColors.border,
            width: isCompleted ? 1.5 : 1,
          ),
          boxShadow: AppShadow.sm,
        ),
        child: Column(
          children: [
            // ── Header strip ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.softBg(stateColor),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.md)),
              ),
              child: Row(
                children: [
                  // Number / lock badge
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: stateColor,
                      borderRadius: AppRadius.bSm,
                    ),
                    child: Center(
                      child: unlocked
                          ? Text('$number',
                          style: AppText.label.copyWith(
                              color: AppColors.white, fontSize: 13))
                          : const Icon(Icons.lock_rounded,
                          color: AppColors.white, size: 16),
                    ),
                  ),
                  AppSpacing.hmd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: AppText.bodyLg.copyWith(
                                fontWeight: FontWeight.w700)),
                        if (desc.isNotEmpty)
                          Text(desc,
                              style: AppText.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.softBg(stateColor),
                      borderRadius: AppRadius.bFull,
                      border: Border.all(
                          color: stateColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          !unlocked
                              ? Icons.lock_rounded
                              : isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 10,
                          color: stateColor,
                        ),
                        AppSpacing.hxs,
                        Text(
                          !unlocked
                              ? 'Terkunci'
                              : isCompleted
                              ? 'Selesai'
                              : 'Belum',
                          style: AppText.label.copyWith(
                              color: stateColor, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta chips
                  Row(children: [
                    if (category.isNotEmpty) ...[
                      _Tag(category, AppColors.info),
                      AppSpacing.hxs,
                    ],
                    _Tag(diffLabel, diffColor),
                    AppSpacing.hxs,
                    _Tag('$qCount soal', AppColors.primary),
                    AppSpacing.hxs,
                    _Tag('${minutes}m', AppColors.warning),
                  ]),

                  // Score / locked info
                  if (isCompleted && bestScore != null) ...[
                    AppSpacing.vmd,
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.softBg(AppColors.success),
                        borderRadius: AppRadius.bMd,
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.25)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: AppRadius.bSm,
                          ),
                          child: const Icon(Icons.emoji_events_rounded,
                              color: AppColors.white, size: 16),
                        ),
                        AppSpacing.hmd,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Skor Terbaik',
                                style: AppText.caption),
                            Row(children: [
                              Text('$bestScore',
                                  style: AppText.h2.copyWith(
                                      color: AppColors.success)),
                              Text('/100',
                                  style: AppText.bodySm),
                            ]),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Percobaan',
                                style: AppText.caption),
                            Text('$attempts kali',
                                style: AppText.bodyLg.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ]),
                    ),
                  ],

                  if (!unlocked) ...[
                    AppSpacing.vmd,
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: AppRadius.bMd,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 14,
                            color: AppColors.textSecondary),
                        AppSpacing.hxs,
                        Text(
                          'Selesaikan subtes sebelumnya untuk membuka.',
                          style: AppText.bodySm,
                        ),
                      ]),
                    ),
                  ],

                  AppSpacing.vmd,

                  // Action buttons
                  Row(children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: unlocked ? onStart : null,
                          icon: Icon(
                            isCompleted
                                ? Icons.replay_rounded
                                : Icons.play_arrow_rounded,
                            size: 15,
                          ),
                          label: Text(isCompleted ? 'Ulangi' : 'Mulai'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: unlocked
                                ? AppColors.primary
                                : AppColors.surfaceAlt,
                            foregroundColor: unlocked
                                ? AppColors.white
                                : AppColors.textHint,
                            disabledBackgroundColor: AppColors.surfaceAlt,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.bMd),
                            textStyle: AppText.btnSm,
                            // Hapus minimumSize agar tidak konflik
                          ),
                        ),
                      ),
                    ),
                    if (isCompleted) ...[
                      AppSpacing.hxs,
                      // Ganti SizedBox + OutlinedButton → Expanded + SizedBox
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: onReview,
                            icon: const Icon(Icons.bar_chart_rounded, size: 15),
                            label: const Text('Review'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.bMd),
                              textStyle: AppText.btnSm
                                  .copyWith(color: AppColors.primary),
                              // Hapus minimumSize agar tidak konflik
                            ),
                          ),
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SMALL REUSABLE WIDGETS
// ============================================================================

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.sm,
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _CardHeader(this.title, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.softBg(color),
          borderRadius: AppRadius.bSm,
        ),
        child: Icon(icon, size: 15, color: color),
      ),
      AppSpacing.hsm,
      Text(title,
          style: AppText.label.copyWith(color: AppColors.textPrimary)),
    ]);
  }
}

class _InfoRow2 extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _InfoRow2(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        AppSpacing.hxs,
        SizedBox(
          width: 90,
          child: Text(label, style: AppText.bodySm),
        ),
        Expanded(
          child: Text(value,
              style: AppText.body.copyWith(
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatBox(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.softBg(color),
          borderRadius: AppRadius.bMd,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          AppSpacing.vxs,
          Text(value,
              style: AppText.h3.copyWith(color: color)),
          Text(label, style: AppText.caption.copyWith(fontSize: 10)),
        ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.softBg(color),
        borderRadius: AppRadius.bFull,
      ),
      child: Text(label,
          style: AppText.caption.copyWith(color: color, fontSize: 10)),
    );
  }
}

class _AppBarChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _AppBarChip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        borderRadius: AppRadius.bFull,
        border: Border.all(color: AppColors.white.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: AppColors.gold),
        AppSpacing.hxs,
        Text(label,
            style: AppText.label.copyWith(
                color: AppColors.white, fontSize: 10)),
      ]),
    );
  }
}