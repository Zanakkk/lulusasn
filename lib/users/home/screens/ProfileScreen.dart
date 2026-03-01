// lib/features/home/screens/profile_screen.dart
// ignore_for_file: file_names, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lulusasn/core/services/firebase_service.dart';

import '../../../app/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = FirebaseFirestore.instance;
  final _uid = FirebaseService.instance.currentUser?.uid ?? '';

  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _examTypes = [];
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await Future.wait([
      _db.collection('users').doc(_uid).get(),
      _db
          .collection('exam_types')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get(),
      _db.collection('exam_results').where('userId', isEqualTo: _uid).get(),
    ]);
    if (!mounted) return;
    setState(() {
      _user = (res[0] as DocumentSnapshot).data() as Map<String, dynamic>?;
      _examTypes = (res[1] as QuerySnapshot).docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();
      _results = (res[2] as QuerySnapshot).docs
          .map((d) => d.data() as Map<String, dynamic>)
          .toList();
      _loading = false;
    });
  }

  Map<String, Map<String, _CatStat>> _buildStats() {
    final out = <String, Map<String, _CatStat>>{};
    for (final t in _examTypes) {
      final name = t['name'] as String;
      out[name] = {
        for (final c in List<String>.from(t['categories'] ?? [])) c: _CatStat(),
      };
    }
    for (final r in _results) {
      final scores = r['categoryScores'] as Map<String, dynamic>? ?? {};
      scores.forEach((cat, val) {
        final v = val as Map<String, dynamic>;
        for (final t in _examTypes) {
          final name = t['name'] as String;
          if (List<String>.from(t['categories'] ?? []).contains(cat)) {
            out[name] ??= {};
            out[name]![cat] ??= _CatStat();
            out[name]![cat]!.total += v['total'] as int? ?? 0;
            out[name]![cat]!.correct += v['correct'] as int? ?? 0;
          }
        }
      });
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }
    if (_user == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: Text('Data tidak ditemukan')),
      );
    }

    final stats = _buildStats();
    final w = MediaQuery.sizeOf(context).width;
    final isTablet = w >= 600 && w < 1024;
    final isDesktop = w >= 1024;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.gold,
        child: isDesktop
            ? _DesktopLayout(user: _user!, results: _results, stats: stats)
            : isTablet
            ? _TabletLayout(user: _user!, results: _results, stats: stats)
            : _MobileLayout(user: _user!, results: _results, stats: stats),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MOBILE LAYOUT  (unchanged — sudah bagus)
// ═════════════════════════════════════════════════════════════════════════════
class _MobileLayout extends StatelessWidget {
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> results;
  final Map<String, Map<String, _CatStat>> stats;
  const _MobileLayout({
    required this.user,
    required this.results,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      _MobileHero(user: user, totalExams: results.length),
      SliverToBoxAdapter(child: _StatsStrip(results: results, dark: true)),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        sliver: SliverToBoxAdapter(
          child: Text('Progres Belajar', style: AppText.h3),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        sliver: SliverList(
          delegate: SliverChildListDelegate(
            stats.entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExamTypeCard(typeName: e.key, cats: e.value),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    ],
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// TABLET LAYOUT  (sidebar kiri + konten kanan)
// ═════════════════════════════════════════════════════════════════════════════
class _TabletLayout extends StatelessWidget {
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> results;
  final Map<String, Map<String, _CatStat>> stats;
  const _TabletLayout({
    required this.user,
    required this.results,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT — profile card (fixed width)
        SizedBox(
          width: 240,
          child: _ProfileCard(user: user, results: results),
        ),
        const SizedBox(width: 20),
        // RIGHT — stats + progress
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatsStrip(results: results, dark: false),
              const SizedBox(height: 20),
              Text('Progres Belajar', style: AppText.h3),
              const SizedBox(height: 12),
              ...stats.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExamTypeCard(typeName: e.key, cats: e.value),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// DESKTOP LAYOUT  (3-col: profile | progress | empty/future)
// ═════════════════════════════════════════════════════════════════════════════
class _DesktopLayout extends StatelessWidget {
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> results;
  final Map<String, Map<String, _CatStat>> stats;
  const _DesktopLayout({
    required this.user,
    required this.results,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // COL 1 — Profile sticky card
          SizedBox(
            width: 280,
            child: _ProfileCard(user: user, results: results),
          ),
          const SizedBox(width: 24),

          // COL 2 — Stats + exam cards
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatsStrip(results: results, dark: false),
                const SizedBox(height: 24),
                Text('Progres Belajar', style: AppText.h3),
                const SizedBox(height: 12),
                ...stats.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExamTypeCard(typeName: e.key, cats: e.value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // COL 3 — Activity / quick info
          SizedBox(width: 240, child: _ActivityPanel(results: results)),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE CARD  (tablet + desktop sidebar)
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> results;
  const _ProfileCard({required this.user, required this.results});

  @override
  Widget build(BuildContext context) {
    final name = user['displayName'] as String? ?? 'User';
    final email = user['email'] as String? ?? '';
    final photo = user['photoURL'] as String? ?? '';
    final goal = (user['goal'] as String? ?? '').toUpperCase();
    final since = (user['createdAt'] as Timestamp?)?.toDate();

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradient.navy,
        borderRadius: AppRadius.bXl,
        boxShadow: AppShadow.lg,
      ),
      child: Column(
        children: [
          // Top section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Gold glow avatar
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.25),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 43,
                      backgroundColor: const Color(0xFF334155),
                      backgroundImage: photo.isNotEmpty
                          ? NetworkImage(photo)
                          : null,
                      child: photo.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              size: 42,
                              color: AppColors.gold,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: AppText.h2.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: AppText.caption.copyWith(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (goal.isNotEmpty) _GoldChip(goal),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.white.withOpacity(0.08)),

          // Meta info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _MetaRow(
                  Icons.calendar_today_outlined,
                  'Bergabung',
                  since != null ? _fmtDate(since) : '-',
                ),
                const SizedBox(height: 12),
                _MetaRow(
                  Icons.assignment_turned_in_outlined,
                  'Total Ujian',
                  '${results.length}×',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${m[d.month - 1]} ${d.year}';
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _MetaRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: Colors.white.withOpacity(0.4)),
      const SizedBox(width: 10),
      Text(
        label,
        style: AppText.caption.copyWith(color: Colors.white.withOpacity(0.5)),
      ),
      const Spacer(),
      Text(value, style: AppText.label.copyWith(color: Colors.white)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVITY PANEL  (desktop col 3)
// ─────────────────────────────────────────────────────────────────────────────
class _ActivityPanel extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  const _ActivityPanel({required this.results});

  @override
  Widget build(BuildContext context) {
    // last 5 results
    final recent = results.length > 5 ? results.sublist(0, 5) : results;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aktivitas Terakhir', style: AppText.h3),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          _emptyState()
        else
          ...recent.map((r) => _ActivityItem(result: r)),
      ],
    );
  }

  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.bLg,
      border: Border.all(color: AppColors.border),
    ),
    child: Center(child: Text('Belum ada aktivitas', style: AppText.bodySm)),
  );
}

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ActivityItem({required this.result});

  @override
  Widget build(BuildContext context) {
    final score = result['score'] as int? ?? 0;
    final subtest = result['subtestId'] as String? ?? '-';
    final date = (result['completedAt'] as Timestamp?)?.toDate();
    final correct = result['correctAnswers'] as int? ?? 0;
    final total = result['totalQuestions'] as int? ?? 0;

    final color = score >= 70
        ? AppColors.success
        : score >= 50
        ? AppColors.warning
        : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.sm,
      ),
      child: Row(
        children: [
          // Score badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.softBg(color),
              borderRadius: AppRadius.bMd,
            ),
            child: Center(
              child: Text(
                '$score',
                style: AppText.label.copyWith(color: color, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtest, style: AppText.label),
                const SizedBox(height: 2),
                Text(
                  '$correct/$total benar  ·  ${_fmtDate(date)}',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day}/${d.month}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE HERO  (SliverAppBar)
// ─────────────────────────────────────────────────────────────────────────────
class _MobileHero extends StatelessWidget {
  final Map<String, dynamic> user;
  final int totalExams;
  const _MobileHero({required this.user, required this.totalExams});

  @override
  Widget build(BuildContext context) {
    final name = user['displayName'] as String? ?? 'User';
    final email = user['email'] as String? ?? '';
    final photo = user['photoURL'] as String? ?? '';
    final goal = (user['goal'] as String? ?? '').toUpperCase();

    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 290,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(gradient: AppGradient.navy),
            ),
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.gold, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withOpacity(0.3),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: const Color(0xFF334155),
                          backgroundImage: photo.isNotEmpty
                              ? NetworkImage(photo)
                              : null,
                          child: photo.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 44,
                                  color: AppColors.gold,
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(name, style: AppText.h1.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: AppText.caption.copyWith(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (goal.isNotEmpty) _GoldChip(goal),
                        if (goal.isNotEmpty) const SizedBox(width: 8),
                        _GoldChip('$totalExams Ujian'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS STRIP  (dark=true untuk mobile, light untuk tablet/desktop)
// ─────────────────────────────────────────────────────────────────────────────
class _StatsStrip extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final bool dark;
  const _StatsStrip({required this.results, required this.dark});

  @override
  Widget build(BuildContext context) {
    int totalQ = 0, totalC = 0, totalTime = 0;
    for (final r in results) {
      totalQ += r['totalQuestions'] as int? ?? 0;
      totalC += r['correctAnswers'] as int? ?? 0;
      totalTime += r['totalTimeSeconds'] as int? ?? 0;
    }
    final acc = totalQ > 0 ? (totalC / totalQ * 100).toStringAsFixed(0) : '0';
    final mins = (totalTime / 60).toStringAsFixed(0);

    final items = [
      (
        value: '${results.length}',
        label: 'Ujian',
        icon: Icons.assignment_rounded,
        color: AppColors.info,
      ),
      (
        value: '$totalQ',
        label: 'Soal',
        icon: Icons.quiz_outlined,
        color: AppColors.success,
      ),
      (
        value: '$acc%',
        label: 'Akurasi',
        icon: Icons.track_changes_rounded,
        color: AppColors.gold,
      ),
      (
        value: '${mins}m',
        label: 'Waktu',
        icon: Icons.timer_outlined,
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return Container(
      color: dark ? AppColors.primary : Colors.transparent,
      padding: EdgeInsets.fromLTRB(
        dark ? 16 : 0,
        0,
        dark ? 16 : 0,
        dark ? 24 : 0,
      ),
      child: dark
          // Mobile: horizontal strip (dark bg)
          ? Row(
              children: items
                  .map(
                    (item) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          right: item == items.last ? 0 : 8,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: AppRadius.bMd,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(item.icon, color: item.color, size: 18),
                            const SizedBox(height: 6),
                            Text(
                              item.value,
                              style: AppText.h3.copyWith(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              style: AppText.caption.copyWith(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            )
          // Tablet/Desktop: 2x2 grid (light bg)
          : GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: items
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.bMd,
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppShadow.sm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.softBg(item.color),
                              borderRadius: AppRadius.bSm,
                            ),
                            child: Icon(item.icon, color: item.color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item.value, style: AppText.h3),
                              Text(item.label, style: AppText.caption),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXAM TYPE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ExamTypeCard extends StatelessWidget {
  final String typeName;
  final Map<String, _CatStat> cats;
  const _ExamTypeCard({required this.typeName, required this.cats});

  @override
  Widget build(BuildContext context) {
    int tot = 0, cor = 0;
    for (final s in cats.values) {
      tot += s.total;
      cor += s.correct;
    }
    final acc = tot > 0 ? (cor / tot * 100).toInt() : 0;
    final frac = tot > 0 ? cor / tot : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Row(
              children: [
                Text(typeName, style: AppText.h3.copyWith(color: Colors.white)),
                const Spacer(),
                SizedBox(
                  width: 38,
                  height: 38,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: frac.toDouble(),
                        strokeWidth: 3,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.gold,
                        ),
                      ),
                      Text(
                        '$acc%',
                        style: AppText.caption.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Rows
          if (cats.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Belum ada data', style: AppText.bodySm),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: cats.entries
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (e) => Padding(
                        padding: EdgeInsets.only(
                          bottom: e.key < cats.length - 1 ? 14 : 0,
                        ),
                        child: _CatRow(cat: e.value.key, stat: e.value.value),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _CatRow extends StatelessWidget {
  final String cat;
  final _CatStat stat;
  const _CatRow({required this.cat, required this.stat});

  static const _palette = [
    AppColors.info,
    AppColors.success,
    AppColors.warning,
    AppColors.error,
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
  ];
  Color get _c => _palette[cat.hashCode.abs() % _palette.length];

  @override
  Widget build(BuildContext context) {
    final acc = stat.total > 0 ? stat.correct / stat.total : 0.0;
    final pct = (acc * 100).toInt();
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            cat,
            style: AppText.label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.bFull,
            child: LinearProgressIndicator(
              value: acc.toDouble(),
              minHeight: 7,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(_c),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 68,
          child: Text(
            '$pct% · ${stat.correct}/${stat.total}',
            textAlign: TextAlign.right,
            style: AppText.caption.copyWith(fontSize: 10),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _GoldChip extends StatelessWidget {
  final String text;
  const _GoldChip(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.gold.withOpacity(0.12),
      borderRadius: AppRadius.bFull,
      border: Border.all(color: AppColors.gold.withOpacity(0.4)),
    ),
    child: Text(
      text,
      style: AppText.label.copyWith(color: AppColors.gold, fontSize: 11),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class _CatStat {
  int total = 0;
  int correct = 0;
}
