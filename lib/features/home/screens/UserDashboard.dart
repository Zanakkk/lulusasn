// lib/features/home/screens/home_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../app/theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

class _UserProfile {
  final String name, goal;

  const _UserProfile({required this.name, required this.goal});

  factory _UserProfile.fromDoc(Map<String, dynamic> d) => _UserProfile(
    // Firestore field: displayName
    name: d['displayName'] as String? ?? 'Pengguna',
    // Firestore field: goal (stored lowercase e.g. "cpns")
    goal: (d['goal'] as String? ?? '').toLowerCase(),
  );

  String get goalLabel => switch (goal) {
    'cpns' => 'CPNS',
    'lpdp' => 'LPDP',
    'bumn' => 'BUMN',
    'pcpm' => 'PCPM',
    _ => goal.toUpperCase(),
  };

  String get examName => switch (goal) {
    'cpns' => 'SKD CPNS',
    'lpdp' => 'Seleksi LPDP',
    'bumn' => 'Rekrutmen BUMN',
    'pcpm' => 'Seleksi PCPM BI',
    _ => 'Ujian',
  };
}

class _TryoutSession {
  final String tryoutId, proofStatus;
  final bool isActive;
  final DateTime lastAttemptAt;
  // subtestProgress: { "TWK": { bestScore: 60, status: "completed", attempts: 2 }, ... }
  final Map<String, Map<String, dynamic>> subtestProgress;

  const _TryoutSession({
    required this.tryoutId,
    required this.proofStatus,
    required this.isActive,
    required this.lastAttemptAt,
    required this.subtestProgress,
  });

  factory _TryoutSession.fromDoc(Map<String, dynamic> d) {
    // Parse subtestProgress map
    final raw = d['subtestProgress'] as Map<String, dynamic>? ?? {};
    final progress = raw.map(
      (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
    );

    return _TryoutSession(
      tryoutId: d['tryoutId'] as String? ?? '',
      proofStatus: d['proofStatus'] as String? ?? '',
      isActive: d['isActive'] as bool? ?? false,
      lastAttemptAt:
          (d['lastAttemptAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subtestProgress: progress,
    );
  }
  bool get isPending => proofStatus == 'pending_review';

  DateTime get completedAt => lastAttemptAt;

  int get score => totalBestScore;

  // Subtest yang sudah completed
  bool get hasCompletedSubtest =>
      subtestProgress.values.any((v) => v['status'] == 'completed');

  // Total best score dari semua subtest
  int get totalBestScore => subtestProgress.values
      .map((v) => v['bestScore'] as int? ?? 0)
      .fold(0, (a, b) => a + b);

  // Map subtest -> bestScore untuk chart & analisis
  Map<String, int> get subtestBestScores =>
      subtestProgress.map((k, v) => MapEntry(k, v['bestScore'] as int? ?? 0));
}

class _RecommendedTO {
  final String id, title, examTypeName;
  final bool isPremium;
  final int totalQuestions, totalMinutes;

  const _RecommendedTO({
    required this.id,
    required this.title,
    required this.examTypeName,
    required this.isPremium,
    required this.totalQuestions,
    required this.totalMinutes,
  });

  factory _RecommendedTO.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return _RecommendedTO(
      id: doc.id,
      title: d['title'] as String? ?? '',
      examTypeName: d['examTypeName'] as String? ?? '',
      isPremium: d['isPremium'] as bool? ?? false,
      totalQuestions: d['totalQuestions'] as int? ?? 0,
      totalMinutes: d['totalEstimatedMinutes'] as int? ?? 0,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HOME SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  _UserProfile? _profile;
  List<_TryoutSession> _sessions = [];
  List<_RecommendedTO> _recommended = [];
  bool _loading = true;
  String? _error;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ── 3 parallel Firestore reads ─────────────────────────────────────────────
  Future<void> _loadAll() async {
    if (_uid.isEmpty) return;
    try {
      // Parallel: user doc + user_tryouts (max 10, ordered by lastAttemptAt)
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(_uid).get(),
        FirebaseFirestore.instance
            .collection('user_tryouts')
            .where('userId', isEqualTo: _uid)
            .orderBy('lastAttemptAt', descending: true)
            .limit(10)
            .get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      final toSnap = results[1] as QuerySnapshot;

      final profile = _UserProfile.fromDoc(
        userDoc.data() as Map<String, dynamic>? ?? {},
      );
      final sessions = toSnap.docs
          .map((d) => _TryoutSession.fromDoc(d.data() as Map<String, dynamic>))
          .toList();

      // Recommended TOs: active + sesuai goal, belum dimiliki user
      final ownedIds = sessions.map((s) => s.tryoutId).toSet();
      final recSnap = await FirebaseFirestore.instance
          .collection('tryouts')
          .where('isActive', isEqualTo: true)
          .where('examTypeName', isEqualTo: profile.goalLabel)
          .limit(6) // fetch lebih, filter owned client-side
          .get();

      final recommended = recSnap.docs
          .where((d) => !ownedIds.contains(d.id))
          .take(3)
          .map(_RecommendedTO.fromDoc)
          .toList();

      if (mounted) {
        setState(() {
          _profile = profile;
          _sessions = sessions;
          _recommended = recommended;
          _loading = false;
        });
      }
    } catch (e) {
      // Jika error berisi link index Firestore, akan terprint di console
      debugPrint('═══════════════════════════════════════');
      debugPrint('❌ _loadAll ERROR: $e');
      debugPrint('═══════════════════════════════════════');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // ── Computed ───────────────────────────────────────────────────────────────

  // Rata-rata totalBestScore dari semua user_tryouts yang isActive
  double get _avgScore {
    final active = _sessions.where((s) => s.isActive).toList();
    if (active.isEmpty) return 0;
    return active.map((s) => s.totalBestScore).reduce((a, b) => a + b) /
        active.length;
  }

  // Gabungkan semua subtestProgress dari semua sesi, ambil yg bestScore terendah
  String? get _weakestSubtest {
    if (_sessions.isEmpty) return null;
    final best = <String, List<int>>{};
    for (final s in _sessions) {
      s.subtestBestScores.forEach((k, v) {
        best.putIfAbsent(k, () => []).add(v);
      });
    }
    if (best.isEmpty) return null;
    // Rata-rata best score per subtest, ambil yang terendah
    final avgs = best.map(
      (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length),
    );
    return avgs.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  // Semua subtest scores untuk ditampilkan di analisis
  Map<String, int> get _allSubtestAvgs {
    final best = <String, List<int>>{};
    for (final s in _sessions) {
      s.subtestBestScores.forEach((k, v) {
        best.putIfAbsent(k, () => []).add(v);
      });
    }
    return best.map(
      (k, v) => MapEntry(k, (v.reduce((a, b) => a + b) / v.length).round()),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) return const _LoadingView();
    if (_error != null) return _ErrorView(message: _error!);

    final isMobile = AppResponsive.isMobile(context);
    final isTablet = AppResponsive.isTablet(context);
    final pad = isMobile
        ? 16.0
        : isTablet
        ? 20.0
        : 28.0;
    final profile = _profile!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: AppColors.gold,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Hero ───────────────────────────────────────────────────
              _buildHero(profile, isMobile),
              SizedBox(height: isMobile ? 16 : 24),

              // ── 2. Alert bar (pending verif) ──────────────────────────────
              if (_sessions.any((s) => s.isPending)) ...[
                _AlertBar(
                  icon: Icons.pending_actions_rounded,
                  color: AppColors.warning,
                  message:
                      'Bukti promosimu sedang direview admin. Akses tryout aktif setelah disetujui.',
                ),
                SizedBox(height: isMobile ? 12 : 16),
              ],

              // ── 3. Stats + Mini chart ─────────────────────────────────────
              isMobile
                  ? Column(
                      children: [
                        _buildStatsCard(profile),
                        const SizedBox(height: 12),
                        _buildMiniChart(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildStatsCard(profile)),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: _buildMiniChart()),
                      ],
                    ),

              SizedBox(height: isMobile ? 16 : 24),

              // ── 4. In-progress tryout (lanjutkan) ─────────────────────────
              // Tryout aktif tapi ada subtest yang belum completed
              if (_sessions.any(
                (s) =>
                    s.isActive &&
                    s.subtestProgress.values.any(
                      (v) => v['status'] != 'completed',
                    ),
              )) ...[
                _buildContinueCard(
                  _sessions.firstWhere(
                    (s) =>
                        s.isActive &&
                        s.subtestProgress.values.any(
                          (v) => v['status'] != 'completed',
                        ),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),
              ],

              // ── 5. Daily challenge + Weakest subtest ──────────────────────
              isMobile
                  ? Column(
                      children: [
                        _buildDailyChallenge(profile),
                        const SizedBox(height: 12),
                        if (_weakestSubtest != null)
                          _buildWeakSubtest(_weakestSubtest!),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDailyChallenge(profile)),
                        const SizedBox(width: 16),
                        if (_weakestSubtest != null)
                          Expanded(child: _buildWeakSubtest(_weakestSubtest!)),
                      ],
                    ),

              SizedBox(height: isMobile ? 16 : 24),

              // ── 6. Rekomendasi Tryout ─────────────────────────────────────
              _buildRecommendations(isMobile),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION BUILDERS
  // ══════════════════════════════════════════════════════════════════════════

  // ── 1. Hero ───────────────────────────────────────────────────────────────
  Widget _buildHero(_UserProfile p, bool isMobile) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Selamat pagi'
        : hour < 17
        ? 'Selamat siang'
        : 'Selamat malam';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: AppGradient.navy,
        borderRadius: AppRadius.bLg,
        boxShadow: AppShadow.md,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroContent(p, greeting, isMobile),
                const SizedBox(height: 20),
                _heroStats(p),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _heroContent(p, greeting, isMobile)),
                const SizedBox(width: 24),
                _heroStats(p),
              ],
            ),
    );
  }

  Widget _heroContent(_UserProfile p, String greeting, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: AppGradient.gold,
            borderRadius: AppRadius.bFull,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.flag_rounded,
                size: 12,
                color: AppColors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                'Target: ${p.goalLabel}',
                style: AppText.label.copyWith(
                  color: AppColors.primary,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$greeting,',
          style: AppText.body.copyWith(color: AppColors.white.withOpacity(0.7)),
        ),
        const SizedBox(height: 4),
        Text(
          p.name,
          style: (isMobile ? AppText.h2 : AppText.h1).copyWith(
            color: AppColors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Semangat persiapan ${p.goalLabel}-mu! Konsistensi adalah kunci.',
          style: AppText.bodySm.copyWith(
            color: AppColors.white.withOpacity(0.6),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _heroStats(_UserProfile p) {
    final activeCount = _sessions.where((s) => s.isActive).length;
    final pendingCount = _sessions.where((s) => s.isPending).length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeroStatBox(
          value: '$activeCount',
          label: 'Tryout\nAktif',
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.success,
        ),
        const SizedBox(width: 10),
        _HeroStatBox(
          value: _avgScore > 0 ? _avgScore.toStringAsFixed(0) : '-',
          label: 'Nilai\nRata-rata',
          icon: Icons.bar_chart_rounded,
          iconColor: AppColors.gold,
        ),
        if (pendingCount > 0) ...[
          const SizedBox(width: 10),
          _HeroStatBox(
            value: '$pendingCount',
            label: 'Menunggu\nReview',
            icon: Icons.pending_rounded,
            iconColor: AppColors.warning,
          ),
        ],
      ],
    );
  }

  // ── 3. Stats Card ─────────────────────────────────────────────────────────
  Widget _buildStatsCard(_UserProfile p) {
    const passingGrade = 255; // CPNS SKD default, idealnya dari Firestore
    final avg = _avgScore;
    final pct = (avg / 500 * 100).clamp(0, 100);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SectionLabel(
            icon: Icons.analytics_rounded,
            label: 'Progress Nilai',
          ),
          const SizedBox(height: 16),

          // Circular progress
          Center(
            child: SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(110, 110),
                    painter: _CircleProgressPainter(
                      progress: pct / 100,
                      color: avg >= passingGrade
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        avg > 0 ? avg.toStringAsFixed(0) : '-',
                        style: AppText.h2.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text('/ 500', style: AppText.caption),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Passing grade info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: avg >= passingGrade
                  ? AppColors.success.withOpacity(0.08)
                  : AppColors.warning.withOpacity(0.08),
              borderRadius: AppRadius.bMd,
              border: Border.all(
                color: avg >= passingGrade
                    ? AppColors.success.withOpacity(0.25)
                    : AppColors.warning.withOpacity(0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  avg >= passingGrade
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  size: 14,
                  color: avg >= passingGrade
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    avg >= passingGrade
                        ? 'Nilaimu sudah melewati passing grade!'
                        : 'Passing grade ${p.goalLabel}: $passingGrade poin',
                    style: AppText.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tryout count row
          Row(
            children: [
              const Icon(
                Icons.quiz_rounded,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 6),
              Text(
                '${_sessions.length} tryout diselesaikan',
                style: AppText.caption,
              ),
              const Spacer(),
              if (_sessions.isNotEmpty)
                Text(
                  'Terakhir: ${DateFormat('d MMM').format(_sessions.first.completedAt)}',
                  style: AppText.caption.copyWith(fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Mini Chart ─────────────────────────────────────────────────────────────
  Widget _buildMiniChart() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SectionLabel(
            icon: Icons.show_chart_rounded,
            label: 'Grafik Nilai Tryout',
          ),
          const SizedBox(height: 16),
          if (_sessions.isEmpty)
            _EmptyState(
              icon: Icons.bar_chart_rounded,
              message: 'Belum ada data tryout.\nSelesaikan tryout pertamamu!',
            )
          else
            SizedBox(
              height: 160,
              child: CustomPaint(
                painter: _MiniChartPainter(
                  sessions: _sessions.reversed.toList(),
                ),
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }

  // ── Continue Card ──────────────────────────────────────────────────────────
  Widget _buildContinueCard(_TryoutSession s) {
    // Hitung berapa subtest sudah selesai
    final done = s.subtestProgress.values
        .where((v) => v['status'] == 'completed')
        .length;
    final total = s.subtestProgress.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.05),
        borderRadius: AppRadius.bLg,
        border: Border.all(color: AppColors.info.withOpacity(0.25)),
        boxShadow: AppShadow.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.10),
              borderRadius: AppRadius.bMd,
            ),
            child: const Icon(
              Icons.play_circle_rounded,
              size: 28,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lanjutkan Tryout',
                  style: AppText.label.copyWith(
                    color: AppColors.info,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tryout ID: ${s.tryoutId}',
                  style: AppText.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text('$done dari $total subtes selesai', style: AppText.bodySm),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.info,
              borderRadius: AppRadius.bMd,
            ),
            child: Text(
              'Lanjut',
              style: AppText.label.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Daily Challenge ────────────────────────────────────────────────────────
  Widget _buildDailyChallenge(_UserProfile p) {
    // Soal harian — di implementasi nyata, fetch dari collection `daily_questions`
    // berdasarkan tanggal hari ini (1 read, cached seharian)
    final today = DateFormat('d MMMM yyyy', ).format(DateTime.now());

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionLabel(
            icon: Icons.bolt_rounded,
            label: 'Latihan Harian',
            trailing: Text(
              today,
              style: AppText.caption.copyWith(fontSize: 10),
            ),
          ),
          const SizedBox(height: 14),

          // Challenge preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppGradient.navy,
              borderRadius: AppRadius.bMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppGradient.gold,
                        borderRadius: AppRadius.bFull,
                      ),
                      child: Text(
                        '${p.goalLabel} · Hari Ini',
                        style: AppText.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '10 soal latihan segar menunggumu hari ini',
                  style: AppText.body.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selesaikan untuk menjaga streak belajarmu',
                  style: AppText.bodySm.copyWith(
                    color: AppColors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _InfoPill(Icons.quiz_rounded, '10 soal'),
                    const SizedBox(width: 8),
                    _InfoPill(Icons.timer_rounded, '~10 menit'),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {}, // navigate ke daily challenge
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppGradient.gold,
                          borderRadius: AppRadius.bMd,
                        ),
                        child: Text(
                          'Mulai',
                          style: AppText.label.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Weakest Subtest ────────────────────────────────────────────────────────
  Widget _buildWeakSubtest(String subtest) {
    final avgs = _allSubtestAvgs;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SectionLabel(
            icon: Icons.analytics_outlined,
            label: 'Analisis Kelemahan',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.06),
              borderRadius: AppRadius.bMd,
              border: Border.all(color: AppColors.error.withOpacity(0.20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fokus perkuat $subtest',
                        style: AppText.label.copyWith(color: AppColors.error),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nilaimu di $subtest masih di bawah rata-rata. '
                        'Latihan lebih banyak di subtes ini.',
                        style: AppText.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...avgs.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SubtestBar(
                label: e.key,
                value: e.value,
                maxValue: 100, // bestScore per subtest skala 0-100
                isWeak: e.key == subtest,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.book_rounded, size: 15),
              label: Text('Latihan $subtest Sekarang'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size(0, 40),
                textStyle: AppText.label.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recommendations ────────────────────────────────────────────────────────
  Widget _buildRecommendations(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionLabel(
              icon: Icons.recommend_rounded,
              label: 'Rekomendasi Tryout',
            ),
            const Spacer(),
            TextButton(
              onPressed: () {}, // navigate ke marketplace
              child: Text(
                'Lihat Semua',
                style: AppText.label.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_recommended.isEmpty)
          _EmptyState(
            icon: Icons.search_off_rounded,
            message: 'Belum ada tryout tersedia\nuntuk goalmu saat ini.',
          )
        else
          isMobile
              ? Column(
                  children: _recommended
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RecommendCard(r),
                        ),
                      )
                      .toList(),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _recommended
                      .map(
                        (r) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: r == _recommended.last ? 0 : 14,
                            ),
                            child: _RecommendCard(r),
                          ),
                        ),
                      )
                      .toList(),
                ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.bLg,
      border: Border.all(color: AppColors.border),
      boxShadow: AppShadow.sm,
    ),
    child: child,
  );
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  const _SectionLabel({required this.icon, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: AppRadius.bSm,
        ),
        child: Icon(icon, size: 14, color: AppColors.primary),
      ),
      const SizedBox(width: 8),
      Text(label, style: AppText.h3.copyWith(fontSize: 15)),
      if (trailing != null) ...[const Spacer(), trailing!],
    ],
  );
}

class _HeroStatBox extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color iconColor;
  const _HeroStatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 80,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.white.withOpacity(0.07),
      borderRadius: AppRadius.bMd,
      border: Border.all(color: AppColors.white.withOpacity(0.10)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppText.h3.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppText.caption.copyWith(
            color: AppColors.white.withOpacity(0.6),
            fontSize: 9,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _AlertBar extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  const _AlertBar({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: AppRadius.bMd,
      border: Border.all(color: color.withOpacity(0.30)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: AppText.bodySm.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    ),
  );
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.white.withOpacity(0.10),
      borderRadius: AppRadius.bFull,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.white.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppText.caption.copyWith(
            color: AppColors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

class _SubtestBar extends StatelessWidget {
  final String label;
  final int value, maxValue;
  final bool isWeak;
  const _SubtestBar({
    required this.label,
    required this.value,
    required this.maxValue,
    this.isWeak = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / maxValue).clamp(0.0, 1.0);
    final color = isWeak ? AppColors.error : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (isWeak)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.warning_rounded,
                  size: 12,
                  color: AppColors.error,
                ),
              ),
            Text(
              label,
              style: AppText.label.copyWith(
                color: isWeak ? AppColors.error : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '$value / $maxValue',
              style: AppText.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Stack(
          children: [
            Container(
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: AppRadius.bFull,
              ),
            ),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: AppRadius.bFull,
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.3), blurRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecommendCard extends StatelessWidget {
  final _RecommendedTO r;
  const _RecommendCard(this.r);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top strip
          Container(
            height: 3,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: r.isPremium ? AppGradient.gold : AppGradient.navy,
              borderRadius: AppRadius.bFull,
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: AppRadius.bSm,
                ),
                child: Text(
                  r.examTypeName.toUpperCase(),
                  style: AppText.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  gradient: r.isPremium ? AppGradient.gold : null,
                  color: r.isPremium
                      ? null
                      : AppColors.success.withOpacity(0.10),
                  borderRadius: AppRadius.bFull,
                ),
                child: Text(
                  r.isPremium ? 'Premium' : 'Gratis',
                  style: AppText.caption.copyWith(
                    color: r.isPremium ? AppColors.primary : AppColors.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            r.title,
            style: AppText.label.copyWith(color: AppColors.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.quiz_rounded,
                size: 12,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Text('${r.totalQuestions} soal', style: AppText.caption),
              const SizedBox(width: 10),
              const Icon(
                Icons.timer_rounded,
                size: 12,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Text('${r.totalMinutes}m', style: AppText.caption),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                gradient: AppGradient.navy,
                borderRadius: AppRadius.bMd,
              ),
              child: Center(
                child: Text(
                  'Dapatkan',
                  style: AppText.label.copyWith(color: AppColors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: AppColors.textHint),
          const SizedBox(height: 10),
          Text(message, style: AppText.bodySm, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ══════════════════════════════════════════════════════════════════════════════

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _CircleProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    final bg = Paint()
      ..color = AppColors.surfaceAlt
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bg);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -1.5708,
      progress * 2 * 3.14159,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _MiniChartPainter extends CustomPainter {
  final List<_TryoutSession> sessions;
  _MiniChartPainter({required this.sessions});

  @override
  void paint(Canvas canvas, Size size) {
    if (sessions.isEmpty) return;
    final scores = sessions.map((s) => s.score.toDouble()).toList();
    final maxV = scores.reduce((a, b) => a > b ? a : b);
    final minV = scores.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).clamp(1, double.infinity);

    final pts = <Offset>[];
    for (var i = 0; i < scores.length; i++) {
      final x = i / (scores.length - 1) * size.width;
      final y =
          size.height * 0.85 -
          ((scores[i] - minV) / range) * (size.height * 0.7);
      pts.add(Offset(x, y));
    }

    // Grid
    final gp = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 3),
        Offset(size.width, size.height * i / 3),
        gp,
      );
    }

    // Passing grade line
    final pg = Paint()
      ..color = AppColors.error.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final pgY =
        size.height * 0.85 - ((255 - minV) / range) * (size.height * 0.7);
    if (pgY >= 0 && pgY <= size.height) {
      canvas.drawLine(Offset(0, pgY), Offset(size.width, pgY), pg);
    }

    // Area
    if (pts.length > 1) {
      final path = Path()..moveTo(pts.first.dx, size.height);
      for (var i = 0; i < pts.length - 1; i++) {
        final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
        final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
        path.cubicTo(
          cp1.dx,
          cp1.dy,
          cp2.dx,
          cp2.dy,
          pts[i + 1].dx,
          pts[i + 1].dy,
        );
      }
      path
        ..lineTo(pts.last.dx, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            colors: [AppColors.primary.withOpacity(0.15), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );

      final lp = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 0; i < pts.length - 1; i++) {
        final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
        final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
        lp.cubicTo(
          cp1.dx,
          cp1.dy,
          cp2.dx,
          cp2.dy,
          pts[i + 1].dx,
          pts[i + 1].dy,
        );
      }
      canvas.drawPath(
        lp,
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Dots + score labels
    final dp = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    final db = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < pts.length; i++) {
      canvas.drawCircle(pts[i], 4, dp);
      canvas.drawCircle(pts[i], 4, db);

      final tp = TextPainter(
        text: TextSpan(
          text: '${scores[i].toInt()}',
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pts[i].dx - tp.width / 2, pts[i].dy - 16));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Loading & Error ────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(
      color: AppColors.primary,
      strokeWidth: 2.5,
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 40,
          color: AppColors.error,
        ),
        const SizedBox(height: 12),
        Text('Terjadi kesalahan', style: AppText.h3),
        const SizedBox(height: 4),
        Text(message, style: AppText.bodySm, textAlign: TextAlign.center),
      ],
    ),
  );
}
