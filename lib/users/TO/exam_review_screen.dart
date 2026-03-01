// lib/features/tryout/screens/exam_review_screen.dart
// ignore_for_file: deprecated_member_use, unused_local_variable, unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';

// ═══════════════════════════════════════════════════════════════
// PATCH 1 — _ScoreInfo: tambah field earnedScore & maxScore
// Ganti class _ScoreInfo lama dengan ini
// ═══════════════════════════════════════════════════════════════
class _ScoreInfo {
  final int score; // pct (untuk warna & circular indicator)
  final int
  earnedScore; // raw earned (objective: correctAnswers, likert: likertEarned)
  final int
  maxScore; // raw max   (objective: totalQuestions,  likert: likertMax)
  final String label;
  final IconData icon;
  final Color color;
  const _ScoreInfo(
    this.score,
    this.earnedScore,
    this.maxScore,
    this.label,
    this.icon,
    this.color,
  );
}

class ExamReviewScreen extends StatefulWidget {
  final String resultId;
  const ExamReviewScreen({super.key, required this.resultId});

  @override
  State<ExamReviewScreen> createState() => _ExamReviewScreenState();
}

class _ExamReviewScreenState extends State<ExamReviewScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _result;

  Map<String, dynamic>? _scoringConfig; // tambah ini
  List<Map<String, dynamic>> _questions = [];
  String _filter = 'all';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rSnap = await FirebaseFirestore.instance
          .collection('exam_results')
          .doc(widget.resultId)
          .get();
      if (!rSnap.exists) throw Exception('Hasil ujian tidak ditemukan');
      final resultData = rSnap.data()!;

      final tSnap = await FirebaseFirestore.instance
          .collection('tryouts')
          .doc(resultData['tryoutId'] as String)
          .get();
      if (!tSnap.exists) throw Exception('Data tryout tidak ditemukan');

      final subtests = tSnap.data()!['subtests'] as List<dynamic>;
      final subtestId = resultData['subtestId'] as String;
      final subtest =
          subtests.firstWhere(
                (s) => ((s as Map)['id'] ?? s['name']) == subtestId,
                orElse: () => null,
              )
              as Map<String, dynamic>?;
      if (subtest == null) throw Exception('Subtest tidak ditemukan');

      _scoringConfig = subtest['scoringConfig'] as Map<String, dynamic>?;

      final qList = subtest['questions'] as List<dynamic>;
      final answers = resultData['answers'] as List<dynamic>;

      _questions = List.generate(qList.length, (i) {
        final q = Map<String, dynamic>.from(qList[i] as Map);
        final a = answers[i] as Map<String, dynamic>;
        return {
          ...q,
          'userAnswer': a['userAnswer'],
          'isCorrect': a['isCorrect'] ?? false,
        };
      });

      _result = resultData;
      _fadeCtrl.forward();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Hitung total skor likert yang diraih user ─────────────────────────────────
  // Untuk tiap soal likert: ambil scores[userAnswer], jika tidak dijawab = 0
  int get _likertEarnedScore {
    int total = 0;
    for (final q in _questions) {
      if (q['type'] != 'likert') continue;
      final ua = q['userAnswer'] as int?;
      final scores =
          (q['scores'] as List<dynamic>?)
              ?.map((s) => (s as num).toInt())
              .toList() ??
          [];
      if (ua != null && ua < scores.length) total += scores[ua];
    }
    return total;
  }

  // ── Hitung total skor maksimum likert (pilih nilai tertinggi tiap soal) ────────
  int get _likertMaxScore {
    int total = 0;
    for (final q in _questions) {
      if (q['type'] != 'likert') continue;
      final scores =
          (q['scores'] as List<dynamic>?)
              ?.map((s) => (s as num).toInt())
              .toList() ??
          [];
      if (scores.isEmpty) continue;
      total += scores.reduce((a, b) => a > b ? a : b);
    }
    return total;
  }

  // ── Hitung skor diraih per kategori untuk likert ──────────────────────────────
  Map<String, Map<String, int>> get _likertCategoryScores {
    final Map<String, Map<String, int>> result = {};
    for (final q in _questions) {
      if (q['type'] != 'likert') continue;
      final cat = q['category'] as String? ?? 'Lainnya';
      final ua = q['userAnswer'] as int?;
      final scores =
          (q['scores'] as List<dynamic>?)
              ?.map((s) => (s as num).toInt())
              .toList() ??
          [];
      final max = scores.isEmpty ? 0 : scores.reduce((a, b) => a > b ? a : b);
      final earned = (ua != null && ua < scores.length) ? scores[ua] : 0;

      result.putIfAbsent(cat, () => {'earned': 0, 'max': 0});
      result[cat]!['earned'] = result[cat]!['earned']! + earned;
      result[cat]!['max'] = result[cat]!['max']! + max;
    }
    return result;
  }

  List<Map<String, dynamic>> get _filtered => _questions.where((q) {
    final ok = q['isCorrect'] == true;
    final ua = q['userAnswer'];
    return switch (_filter) {
      'correct' => ok,
      'wrong' => !ok && ua != null,
      'unanswered' => ua == null,
      _ => true,
    };
  }).toList();

  int get _correctCount =>
      _questions.where((q) => q['isCorrect'] == true).length;
  int get _wrongCount => _questions
      .where((q) => q['isCorrect'] != true && q['userAnswer'] != null)
      .length;
  int get _unansweredCount =>
      _questions.where((q) => q['userAnswer'] == null).length;

  /// Skor per jawaban benar (default 1 jika tidak ada config)
  int get _correctScore =>
      (_scoringConfig?['correctScore'] as num?)?.toInt() ?? 1;

  /// Skor total yang diraih user = correctAnswers × correctScore
  int get _earnedScore {
    final correct = _result?['correctAnswers'] as int? ?? 0;
    return correct * _correctScore;
  }

  /// Skor maksimum = totalQuestions × correctScore
  int get _maxPossibleScore {
    final total = _result?['totalQuestions'] as int? ?? 0;
    return total * _correctScore;
  }
  // ═══════════════════════════════════════════════════════════════
  // PATCH 2 — getter _scoreInfo
  // Ganti getter _scoreInfo lama dengan ini
  // ═══════════════════════════════════════════════════════════════

  _ScoreInfo get _scoreInfo {
    final hasLikert = _questions.any((q) => q['type'] == 'likert');
    final hasObjective = _questions.any((q) => q['type'] != 'likert');

    int s, earned, max;

    if (hasLikert && !hasObjective) {
      // ── Murni likert ──────────────────────────────────────────────────
      max = _likertMaxScore;
      earned = _likertEarnedScore;
      s = max > 0 ? (earned / max * 100).round() : 0;
    } else {
      // ── Objective (atau campuran) ─────────────────────────────────────
      earned = _earnedScore; // correctAnswers × correctScore
      max = _maxPossibleScore; // totalQuestions × correctScore
      s = max > 0 ? (earned / max * 100).round() : 0;
    }

    if (s >= 80) {
      return _ScoreInfo(
        s,
        earned,
        max,
        'Luar Biasa!',
        Icons.emoji_events_rounded,
        AppColors.success,
      );
    }
    if (s >= 60) {
      return _ScoreInfo(
        s,
        earned,
        max,
        'Bagus!',
        Icons.thumb_up_rounded,
        AppColors.info,
      );
    }
    if (s >= 40) {
      return _ScoreInfo(
        s,
        earned,
        max,
        'Cukup Baik',
        Icons.psychology_rounded,
        AppColors.warning,
      );
    }
    return _ScoreInfo(
      s,
      earned,
      max,
      'Perlu Belajar Lagi',
      Icons.auto_awesome_rounded,
      AppColors.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _scaffold(_buildLoading());
    if (_error != null) return _scaffold(_buildError());
    return _scaffold(
      FadeTransition(
        opacity: _fadeAnim,
        child: LayoutBuilder(
          builder: (ctx, box) =>
              box.maxWidth > 1024 ? _buildDesktop() : _buildMobile(),
        ),
      ),
    );
  }

  Scaffold _scaffold(Widget body) =>
      Scaffold(backgroundColor: AppColors.bg, body: body);

  // ── Desktop ────────────────────────────────────────────────────────────────
  Widget _buildDesktop() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 320,
                      child: Column(
                        children: [
                          _buildScoreCard(),
                          AppSpacing.vmd,
                          _buildTimeCard(),
                          AppSpacing.vmd,
                          _buildCategoryCard(),
                        ],
                      ),
                    ),
                    AppSpacing.hlg,
                    Expanded(
                      child: Column(
                        children: [
                          _buildFilterBar(),
                          AppSpacing.vmd,
                          _buildQuestionsList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile ─────────────────────────────────────────────────────────────────
  Widget _buildMobile() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildScoreCard(),
              AppSpacing.vmd,
              _buildTimeCard(),
              AppSpacing.vmd,
              _buildCategoryCard(),
              AppSpacing.vmd,
              _buildFilterBar(),
              AppSpacing.vmd,
              _buildQuestionsList(),
            ]),
          ),
        ),
      ],
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.15),
            borderRadius: AppRadius.bSm,
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.white,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Ujian',
            style: AppText.h3.copyWith(color: AppColors.white),
          ),

          // ═══════════════════════════════════════════════════════════════
          // PATCH 3 — _buildAppBar subtitle
          // Ganti baris subtitle ini:
          //   'Skor: ${_result!['score']} · ${_result!['totalQuestions']} Soal',
          // Dengan ini:
          // ═══════════════════════════════════════════════════════════════
          if (_result != null)
            Builder(
              builder: (_) {
                final si = _scoreInfo;
                return Text(
                  '${si.earnedScore} / ${si.maxScore} poin · ${_result!['totalQuestions']} Soal',
                  style: AppText.caption.copyWith(
                    color: AppColors.white.withOpacity(0.6),
                  ),
                );
              },
            ),
        ],
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppGradient.navy),
      ),
    );
  }

  // ── Score Card ─────────────────────────────────────────────────────────────

  Widget _buildScoreCard() {
    final si = _scoreInfo;
    final total = _result?['totalQuestions'] as int? ?? 0;
    final hasLikert = _questions.any((q) => q['type'] == 'likert');
    final hasObjective = _questions.any((q) => q['type'] != 'likert');
    final earned = _likertEarnedScore;
    final max = _likertMaxScore;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradient.navy,
        borderRadius: AppRadius.bLg,
        boxShadow: AppShadow.lg,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: si.color.withOpacity(0.2),
                  borderRadius: AppRadius.bMd,
                  border: Border.all(color: si.color.withOpacity(0.4)),
                ),
                child: Icon(si.icon, color: si.color, size: 28),
              ),
              AppSpacing.hmd,

              // ═══════════════════════════════════════════════════════════════
              // PATCH 4 — _buildScoreCard: angka besar & circular progress
              // Ganti blok Column(...) yang berisi Text('${si.score}', ...) dengan ini:
              // ═══════════════════════════════════════════════════════════════
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Angka besar: earned / max
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${si.earnedScore}',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: si.color,
                          height: 1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        ' / ${si.maxScore}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: si.color.withOpacity(0.6),
                          height: 1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    si.label,
                    style: AppText.bodyLg.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: si.maxScore > 0 ? si.earnedScore / si.maxScore : 0,
                      strokeWidth: 6,
                      backgroundColor: AppColors.white.withOpacity(0.1),
                      color: si.color,
                    ),
                    Text(
                      '${si.score}%',
                      style: AppText.label.copyWith(
                        color: AppColors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vmd,
          Divider(color: AppColors.white.withOpacity(0.1), height: 1),
          AppSpacing.vmd,

          Row(
            children: [
              if (hasLikert && !hasObjective) ...[
                // ── Murni Likert: Terjawab | Kosong | Total ──────────────────────
                Expanded(
                  child: _ScoreStat(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Terjawab',
                    value: '${_questions.length - _unansweredCount}',
                    color: AppColors.info,
                  ),
                ),
                _VertDivider(),
                Expanded(
                  child: _ScoreStat(
                    icon: Icons.radio_button_unchecked_rounded,
                    label: 'Kosong',
                    value: '$_unansweredCount',
                    color: AppColors.textSecondary,
                  ),
                ),
                _VertDivider(),
                Expanded(
                  child: _ScoreStat(
                    icon: Icons.quiz_rounded,
                    label: 'Total',
                    value: '${_result?['totalQuestions'] ?? 0}',
                    color: AppColors.gold,
                  ),
                ),
              ] else ...[
                // ── Objective: Benar | Salah | Kosong | Total ────────────────────
                Expanded(
                  child: _ScoreStat(
                    icon: Icons.check_circle_rounded,
                    label: 'Benar',
                    value: '${_result?['correctAnswers'] ?? 0}',
                    color: AppColors.success,
                  ),
                ),
                _VertDivider(),
                Expanded(
                  child: _ScoreStat(
                    icon: Icons.cancel_rounded,
                    label: 'Salah',
                    value: '${_result?['wrongAnswers'] ?? 0}',
                    color: AppColors.error,
                  ),
                ),
                _VertDivider(),
                Expanded(
                  child: _ScoreStat(
                    icon: Icons.radio_button_unchecked_rounded,
                    label: 'Kosong',
                    value: '$_unansweredCount',
                    color: AppColors.textSecondary,
                  ),
                ),
                _VertDivider(),
                Expanded(
                  child: _ScoreStat(
                    icon: Icons.quiz_rounded,
                    label: 'Total',
                    value: '${_result?['totalQuestions'] ?? 0}',
                    color: AppColors.gold,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Time Card ──────────────────────────────────────────────────────────────
  Widget _buildTimeCard() {
    final completedAt = (_result?['completedAt'] as Timestamp?)?.toDate();
    final totalSec = _result?['totalTimeSeconds'] as int? ?? 0;
    final min = totalSec ~/ 60, sec = totalSec % 60;
    return _Card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.softBg(AppColors.info),
              borderRadius: AppRadius.bSm,
            ),
            child: const Icon(
              Icons.timer_rounded,
              color: AppColors.info,
              size: 18,
            ),
          ),
          AppSpacing.hmd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Waktu Pengerjaan', style: AppText.bodySm),
                Text(
                  '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
                  style: AppText.h3.copyWith(
                    color: AppColors.info,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (completedAt != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Selesai', style: AppText.caption),
                Text(
                  DateFormat('dd MMM, HH:mm').format(completedAt),
                  style: AppText.label.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Category Card ──────────────────────────────────────────────────────────

  Widget _buildCategoryCard() {
    final likertCats = _likertCategoryScores;
    // Ambil juga categoryScores dari result untuk soal objective
    final objCats = _result?['categoryScores'] as Map<String, dynamic>? ?? {};

    // Gabung semua kategori yang ada
    final allCats = {...objCats.keys, ...likertCats.keys}.toSet();
    if (allCats.isEmpty) return const SizedBox.shrink();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.softBg(AppColors.info),
                  borderRadius: AppRadius.bSm,
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: AppColors.info,
                  size: 15,
                ),
              ),
              AppSpacing.hsm,
              Text('Performa Per Kategori', style: AppText.label),
            ],
          ),
          AppSpacing.vmd,
          ...allCats.map((cat) {
            final isLikertCat = likertCats.containsKey(cat);

            if (isLikertCat) {
              // ── Likert: tampilkan earned / max poin ──────────────────────────
              final earned = likertCats[cat]!['earned']!;
              final max = likertCats[cat]!['max']!;
              final pct = max > 0 ? (earned / max * 100).round() : 0;
              final barColor = pct >= 80
                  ? AppColors.success
                  : pct >= 60
                  ? AppColors.info
                  : pct >= 40
                  ? AppColors.warning
                  : AppColors.error;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cat,
                            style: AppText.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softBg(barColor),
                            borderRadius: AppRadius.bFull,
                            border: Border.all(
                              color: barColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '$earned / $max poin  ·  $pct%',
                            style: AppText.label.copyWith(
                              color: barColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vxs,
                    ClipRRect(
                      borderRadius: AppRadius.bFull,
                      child: LinearProgressIndicator(
                        value: max > 0 ? earned / max : 0,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        color: barColor,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // ── Objective: tampilkan poin diraih / poin maks per kategori ────────
              final d = objCats[cat] as Map<String, dynamic>;
              final correct = d['correct'] as int? ?? 0;
              final total = d['total'] as int? ?? 1;
              final cs = _correctScore; // misal: 5
              final catEarned = correct * cs;
              final catMax = total * cs;
              final pct = catMax > 0 ? (catEarned / catMax * 100).round() : 0;
              final barColor = pct >= 80
                  ? AppColors.success
                  : pct >= 60
                  ? AppColors.info
                  : pct >= 40
                  ? AppColors.warning
                  : AppColors.error;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cat,
                            style: AppText.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softBg(barColor),
                            borderRadius: AppRadius.bFull,
                            border: Border.all(
                              color: barColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '$catEarned / $catMax poin  ·  $pct%',
                            style: AppText.label.copyWith(
                              color: barColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vxs,
                    ClipRRect(
                      borderRadius: AppRadius.bFull,
                      child: LinearProgressIndicator(
                        value: catMax > 0 ? catEarned / catMax : 0,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        color: barColor,
                      ),
                    ),
                  ],
                ),
              );
            }
          }),
        ],
      ),
    );
  }

  // ── Filter Bar ─────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    final filters = [
      ('all', 'Semua', _questions.length, AppColors.primary),
      ('correct', 'Benar', _correctCount, AppColors.success),
      ('wrong', 'Salah', _wrongCount, AppColors.error),
      ('unanswered', 'Kosong', _unansweredCount, AppColors.textSecondary),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.sm,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: filters.map((f) {
          final active = _filter == f.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _filter = f.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.softBg(f.$4) : Colors.transparent,
                  borderRadius: AppRadius.bSm,
                  border: active
                      ? Border.all(color: f.$4.withOpacity(0.3))
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      '${f.$3}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: active ? f.$4 : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      f.$2,
                      style: AppText.label.copyWith(
                        fontSize: 10,
                        color: active ? f.$4 : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Questions List ─────────────────────────────────────────────────────────
  Widget _buildQuestionsList() {
    final qs = _filtered;
    if (qs.isEmpty) {
      return _Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                const Icon(
                  Icons.filter_list_off_rounded,
                  size: 40,
                  color: AppColors.textHint,
                ),
                AppSpacing.vsm,
                Text('Tidak ada soal', style: AppText.bodySm),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: qs.map((q) {
        final idx = _questions.indexOf(q);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _QuestionCard(question: q, number: idx + 1),
        );
      }).toList(),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────
  Widget _buildLoading() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: AppGradient.navy,
            shape: BoxShape.circle,
          ),
          child: const CircularProgressIndicator(
            color: AppColors.gold,
            strokeWidth: 3,
          ),
        ),
        AppSpacing.vlg,
        Text('Memuat Hasil Ujian...', style: AppText.h3),
      ],
    ),
  );

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError() => Center(
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
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 44,
            ),
          ),
          AppSpacing.vlg,
          Text('Gagal Memuat', style: AppText.h2),
          AppSpacing.vsm,
          Text(
            _error ?? '',
            style: AppText.bodySm,
            textAlign: TextAlign.center,
          ),
          AppSpacing.vxl,
          SizedBox(
            width: 140,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
              ),
              child: const Text('Kembali'),
            ),
          ),
        ],
      ),
    ),
  );
}

// =============================================================================
// _QuestionCard
// =============================================================================
class _QuestionCard extends StatefulWidget {
  final Map<String, dynamic> question;
  final int number;
  const _QuestionCard({required this.question, required this.number});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _arrowCtrl;
  late Animation<double> _arrowAnim;

  @override
  void initState() {
    super.initState();
    _arrowCtrl = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _arrowAnim = Tween<double>(begin: 0, end: 0.5).animate(_arrowCtrl);
  }

  @override
  void dispose() {
    _arrowCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _arrowCtrl.forward() : _arrowCtrl.reverse();
    HapticFeedback.selectionClick();
  }

  // ── Dispatch ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final type = widget.question['type'] as String? ?? 'objective';
    return type == 'likert' ? _buildLikertCard() : _buildObjectiveCard();
  }

  // ── Shared header builder ───────────────────────────────────────────────────
  Widget _header({
    required Color statusColor,
    required IconData statusIcon,
    required String statusLabel,
    required String questionText,
    required String? qImage,
    required String category,
    required String diffLabel,
    required Color diffColor,
    List<Widget> trailing = const [],
  }) {
    return InkWell(
      onTap: _toggle,
      borderRadius: _expanded
          ? const BorderRadius.vertical(top: Radius.circular(AppRadius.lg))
          : AppRadius.bLg,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.softBg(statusColor),
          borderRadius: _expanded
              ? const BorderRadius.vertical(top: Radius.circular(AppRadius.lg))
              : AppRadius.bLg,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NumberBadge(number: widget.number, color: statusColor),
            AppSpacing.hmd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      AppSpacing.hxs,
                      Text(
                        statusLabel,
                        style: AppText.label.copyWith(color: statusColor),
                      ),
                      AppSpacing.hxs,
                      if (category.isNotEmpty) ...[
                        _Tag(category, AppColors.info),
                        AppSpacing.hxs,
                      ],
                      _Tag(diffLabel, diffColor),
                    ],
                  ),
                  AppSpacing.vxs,
                  Text(
                    questionText,
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    maxLines: _expanded ? 100 : 2,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  if (qImage != null && qImage.isNotEmpty && _expanded) ...[
                    AppSpacing.vsm,
                    ClipRRect(
                      borderRadius: AppRadius.bSm,
                      child: Image.network(
                        qImage,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Text('Gambar gagal', style: AppText.caption),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.hsm,
            ...trailing,
            RotationTransition(
              turns: _arrowAnim,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: statusColor,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Objective Card ──────────────────────────────────────────────────────────
  Widget _buildObjectiveCard() {
    final q = widget.question;
    final isCorrect = q['isCorrect'] == true;
    final userAnswer = q['userAnswer'] as int?;
    final correctAnswer = q['correctIndex'] as int? ?? 0;
    final questionText = q['question'] as String? ?? '';
    final qImage = q['questionImage'] as String?;
    final options = q['options'] as List<dynamic>? ?? [];
    final optImages = q['optionImages'] as List<dynamic>?;
    final category = q['category'] as String? ?? '';
    final difficulty = q['difficulty'] as String? ?? 'medium';
    final expShort = q['explanationShort'] as String? ?? '';
    final expFull = q['explanationFull'] as String? ?? '';

    final status = userAnswer == null
        ? _QStatus(
            'Tidak Dijawab',
            Icons.radio_button_unchecked_rounded,
            AppColors.textSecondary,
          )
        : isCorrect
        ? _QStatus(
            'Jawaban Benar',
            Icons.check_circle_rounded,
            AppColors.success,
          )
        : _QStatus('Jawaban Salah', Icons.cancel_rounded, AppColors.error);

    final diffColor = _diffColor(difficulty);
    final diffLabel = _diffLabel(difficulty);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bLg,
        border: Border.all(color: status.color.withOpacity(0.25), width: 1.5),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        children: [
          _header(
            statusColor: status.color,
            statusIcon: status.icon,
            statusLabel: status.label,
            questionText: questionText,
            qImage: qImage,
            category: category,
            diffLabel: diffLabel,
            diffColor: diffColor,
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...List.generate(options.length, (i) {
                    final label = String.fromCharCode(65 + i);
                    final text = options[i].toString();
                    final img = (optImages != null && i < optImages.length)
                        ? optImages[i] as String?
                        : null;
                    final isUserAns = userAnswer == i;
                    final isCorrectAns = correctAnswer == i;

                    Color? col;
                    String? badge;
                    if (isCorrectAns) {
                      col = AppColors.success;
                      badge = '✓ Jawaban Benar';
                    } else if (isUserAns && !isCorrect) {
                      col = AppColors.error;
                      badge = '✗ Jawaban Anda';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: col != null
                              ? AppColors.softBg(col)
                              : AppColors.surfaceAlt,
                          borderRadius: AppRadius.bMd,
                          border: Border.all(
                            color: col?.withOpacity(0.4) ?? AppColors.border,
                            width: col != null ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (badge != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: col!.withOpacity(0.15),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(AppRadius.md),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCorrectAns
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      size: 12,
                                      color: col,
                                    ),
                                    AppSpacing.hxs,
                                    Text(
                                      badge,
                                      style: AppText.label.copyWith(
                                        color: col,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: col ?? AppColors.border,
                                      borderRadius: AppRadius.bSm,
                                    ),
                                    child: Center(
                                      child: Text(
                                        label,
                                        style: AppText.label.copyWith(
                                          color: col != null
                                              ? AppColors.white
                                              : AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  AppSpacing.hmd,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          text,
                                          style: AppText.body.copyWith(
                                            height: 1.4,
                                          ),
                                        ),
                                        if (img != null && img.isNotEmpty) ...[
                                          AppSpacing.vsm,
                                          ClipRRect(
                                            borderRadius: AppRadius.bSm,
                                            child: Image.network(
                                              img,
                                              height: 80,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  Text(
                                                    'Gambar gagal',
                                                    style: AppText.caption,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (expShort.isNotEmpty || expFull.isNotEmpty) ...[
                    AppSpacing.vmd,
                    _ExplanationBlock(expShort: expShort, expFull: expFull),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Likert Card ─────────────────────────────────────────────────────────────
  Widget _buildLikertCard() {
    final q = widget.question;
    final userAnswer = q['userAnswer'] as int?;
    final questionText = q['question'] as String? ?? '';
    final qImage = q['questionImage'] as String?;
    final options = q['options'] as List<dynamic>? ?? [];
    final scores =
        (q['scores'] as List<dynamic>?)
            ?.map((s) => (s as num).toInt())
            .toList() ??
        [];
    final optImages = q['optionImages'] as List<dynamic>?;
    final category = q['category'] as String? ?? '';
    final difficulty = q['difficulty'] as String? ?? 'medium';
    final expShort = q['explanationShort'] as String? ?? '';
    final expFull = q['explanationFull'] as String? ?? '';

    final earnedScore = (userAnswer != null && userAnswer < scores.length)
        ? scores[userAnswer]
        : null;
    final maxScore = scores.isEmpty
        ? 0
        : scores.reduce((a, b) => a > b ? a : b);
    final answered = userAnswer != null;

    final statusColor = answered ? AppColors.info : AppColors.textSecondary;
    final statusIcon = answered
        ? Icons.bar_chart_rounded
        : Icons.radio_button_unchecked_rounded;
    final statusLabel = answered
        ? 'Dijawab · ${earnedScore ?? 0} poin'
        : 'Tidak Dijawab';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bLg,
        border: Border.all(color: statusColor.withOpacity(0.25), width: 1.5),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        children: [
          _header(
            statusColor: statusColor,
            statusIcon: statusIcon,
            statusLabel: statusLabel,
            questionText: questionText,
            qImage: qImage,
            category: category,
            diffLabel: _diffLabel(difficulty),
            diffColor: _diffColor(difficulty),
            trailing: [
              // Badge "Likert"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.softBg(AppColors.warning),
                  borderRadius: AppRadius.bFull,
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Text(
                  'Likert',
                  style: AppText.label.copyWith(
                    color: AppColors.warning,
                    fontSize: 10,
                  ),
                ),
              ),
              AppSpacing.hsm,
              if (answered) ...[
                _ScoreChip(earned: earnedScore ?? 0, max: maxScore),
                AppSpacing.hsm,
              ],
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LikertScoreBar(
                    scores: scores,
                    optionCount: options.length,
                    userAnswer: userAnswer,
                  ),
                  AppSpacing.vmd,
                  ...List.generate(options.length, (i) {
                    final score = i < scores.length ? scores[i] : 0;
                    final img = (optImages != null && i < optImages.length)
                        ? optImages[i] as String?
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _LikertOptionRow(
                        index: i,
                        text: options[i].toString(),
                        score: score,
                        maxScore: maxScore,
                        isPicked: userAnswer == i,
                        image: img,
                      ),
                    );
                  }),
                  if (expShort.isNotEmpty || expFull.isNotEmpty) ...[
                    AppSpacing.vmd,
                    _ExplanationBlock(expShort: expShort, expFull: expFull),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Color _diffColor(String d) => switch (d.toLowerCase()) {
    'easy' => AppColors.success,
    'hard' => AppColors.error,
    _ => AppColors.warning,
  };
  String _diffLabel(String d) => switch (d.toLowerCase()) {
    'easy' => 'Mudah',
    'hard' => 'Sulit',
    _ => 'Sedang',
  };
}

// =============================================================================
// SMALL WIDGETS
// =============================================================================

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.bLg,
      border: Border.all(color: AppColors.border),
      boxShadow: AppShadow.sm,
    ),
    child: child,
  );
}

class _ScoreStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final String? sub;
  final Color color;

  const _ScoreStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.sub,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: color, size: 18),
      AppSpacing.vxs,
      Text(
        value,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      if (sub != null)
        Text(
          sub!,
          style: AppText.caption.copyWith(
            color: color.withOpacity(0.75),
            fontWeight: FontWeight.w700,
          ),
        ),
      Text(
        label,
        style: AppText.caption.copyWith(
          color: AppColors.white.withOpacity(0.6),
        ),
      ),
    ],
  );
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: AppColors.white.withOpacity(0.1));
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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

class _ExpBlock extends StatelessWidget {
  final String title, text;
  final Color color;
  const _ExpBlock(this.title, this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.bMd,
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.softBg(color),
            borderRadius: AppRadius.bFull,
          ),
          child: Text(
            title,
            style: AppText.label.copyWith(color: color, fontSize: 10),
          ),
        ),
        AppSpacing.vsm,
        Text(
          text,
          style: AppText.body.copyWith(
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _NumberBadge extends StatelessWidget {
  final int number;
  final Color color;
  const _NumberBadge({required this.number, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(color: color, borderRadius: AppRadius.bSm),
    child: Center(
      child: Text(
        '$number',
        style: AppText.label.copyWith(color: AppColors.white, fontSize: 13),
      ),
    ),
  );
}

class _ScoreChip extends StatelessWidget {
  final int earned, max;
  const _ScoreChip({required this.earned, required this.max});
  @override
  Widget build(BuildContext context) {
    final color = _LikertOptionRow._scoreColor(earned, max);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.softBg(color),
        borderRadius: AppRadius.bFull,
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$earned / $max',
        style: AppText.label.copyWith(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ExplanationBlock extends StatelessWidget {
  final String expShort, expFull;
  const _ExplanationBlock({required this.expShort, required this.expFull});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.softBg(AppColors.info),
      borderRadius: AppRadius.bMd,
      border: Border.all(color: AppColors.info.withOpacity(0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.info,
                  borderRadius: AppRadius.bSm,
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: AppColors.white,
                  size: 14,
                ),
              ),
              AppSpacing.hxs,
              Text(
                'Pembahasan',
                style: AppText.label.copyWith(color: AppColors.info),
              ),
            ],
          ),
        ),
        if (expShort.isNotEmpty)
          _ExpBlock('Ringkasan', expShort, AppColors.info),
        if (expFull.isNotEmpty)
          _ExpBlock('Penjelasan Lengkap', expFull, AppColors.primary),
        AppSpacing.vsm,
      ],
    ),
  );
}

class _LikertOptionRow extends StatelessWidget {
  final int index, score, maxScore;
  final String text;
  final bool isPicked;
  final String? image;

  const _LikertOptionRow({
    required this.index,
    required this.text,
    required this.score,
    required this.maxScore,
    required this.isPicked,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    final label = String.fromCharCode(65 + index);
    final barColor = _scoreColor(score, maxScore);
    final barRatio = maxScore > 0 ? score / maxScore : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: isPicked ? AppColors.softBg(barColor) : AppColors.surfaceAlt,
        borderRadius: AppRadius.bMd,
        border: Border.all(
          color: isPicked ? barColor.withOpacity(0.5) : AppColors.border,
          width: isPicked ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPicked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: barColor.withOpacity(0.15),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded, size: 12, color: barColor),
                  AppSpacing.hxs,
                  Text(
                    'Jawaban Anda',
                    style: AppText.label.copyWith(
                      color: barColor,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$score poin',
                    style: AppText.label.copyWith(
                      color: barColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isPicked ? barColor : AppColors.border,
                    borderRadius: AppRadius.bSm,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: AppText.label.copyWith(
                        color: isPicked
                            ? AppColors.white
                            : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                AppSpacing.hmd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text, style: AppText.body.copyWith(height: 1.4)),
                      if (image != null && image!.isNotEmpty) ...[
                        AppSpacing.vsm,
                        ClipRRect(
                          borderRadius: AppRadius.bSm,
                          child: Image.network(
                            image!,
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                Text('Gambar gagal', style: AppText.caption),
                          ),
                        ),
                      ],
                      AppSpacing.vsm,
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: AppRadius.bFull,
                              child: LinearProgressIndicator(
                                value: barRatio,
                                minHeight: 6,
                                backgroundColor: AppColors.border,
                                valueColor: AlwaysStoppedAnimation(barColor),
                              ),
                            ),
                          ),
                          AppSpacing.hsm,
                          Text(
                            '$score',
                            style: AppText.label.copyWith(
                              color: barColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
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
        ],
      ),
    );
  }

  static Color _scoreColor(int score, int max) {
    if (max == 0) return AppColors.textSecondary;
    final r = score / max;
    if (r >= 0.8) return AppColors.success;
    if (r >= 0.6) return const Color(0xFF4CAF50);
    if (r >= 0.4) return AppColors.warning;
    if (r >= 0.2) return const Color(0xFFFF7043);
    return AppColors.error;
  }
}

class _LikertScoreBar extends StatelessWidget {
  final List<int> scores;
  final int optionCount;
  final int? userAnswer;

  const _LikertScoreBar({
    required this.scores,
    required this.optionCount,
    required this.userAnswer,
  });

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) return const SizedBox.shrink();
    final max = scores.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              AppSpacing.hxs,
              Text(
                'Distribusi Skor Opsi',
                style: AppText.label.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          AppSpacing.vsm,
          Row(
            children: List.generate(optionCount, (i) {
              final score = i < scores.length ? scores[i] : 0;
              final isPicked = userAnswer == i;
              final color = _LikertOptionRow._scoreColor(score, max);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < optionCount - 1 ? 6 : 0),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isPicked ? color : AppColors.softBg(color),
                          borderRadius: AppRadius.bSm,
                          border: Border.all(
                            color: color.withOpacity(isPicked ? 1 : 0.4),
                            width: isPicked ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$score',
                            style: AppText.label.copyWith(
                              color: isPicked ? AppColors.white : color,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.vxs,
                      Text(
                        String.fromCharCode(65 + i),
                        style: AppText.caption.copyWith(
                          color: isPicked ? color : AppColors.textHint,
                          fontWeight: isPicked
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _QStatus {
  final String label;
  final IconData icon;
  final Color color;
  const _QStatus(this.label, this.icon, this.color);
}
