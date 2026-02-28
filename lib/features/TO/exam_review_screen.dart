// lib/features/tryout/screens/exam_review_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';

// ─── FIRESTORE STRATEGY ───────────────────────────────────────────────────────
// 1. exam_results/{resultId}  → 1 read
// 2. tryouts/{tryoutId}       → 1 read (ambil subtest + questions)
// TOTAL: 2 reads, tidak ada stream (data statis — hasil ujian tidak berubah)
// ─────────────────────────────────────────────────────────────────────────────

class ExamReviewScreen extends StatefulWidget {
  final String resultId;
  const ExamReviewScreen({super.key, required this.resultId});

  @override
  State<ExamReviewScreen> createState() => _ExamReviewScreenState();
}

class _ExamReviewScreenState extends State<ExamReviewScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _result;
  List<Map<String, dynamic>> _questions = [];
  String _filter = 'all';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
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
      // 1. Fetch result
      final rSnap = await FirebaseFirestore.instance
          .collection('exam_results')
          .doc(widget.resultId)
          .get();
      if (!rSnap.exists) throw Exception('Hasil ujian tidak ditemukan');
      final resultData = rSnap.data()!;

      // 2. Fetch tryout (untuk soal + kunci jawaban)
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

      final qList = subtest['questions'] as List<dynamic>;
      final answers = resultData['answers'] as List<dynamic>;

      // Merge soal + jawaban user
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

  // ── Filter ─────────────────────────────────────────────────────────────────
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

  // ── Score semantics ────────────────────────────────────────────────────────
  _ScoreInfo get _scoreInfo {
    final s = _result?['score'] as int? ?? 0;
    if (s >= 80) {
      return _ScoreInfo(
        s,
        'Luar Biasa!',
        Icons.emoji_events_rounded,
        AppColors.success,
      );
    }
    if (s >= 60) {
      return _ScoreInfo(s, 'Bagus!', Icons.thumb_up_rounded, AppColors.info);
    }
    if (s >= 40) {
      return _ScoreInfo(
        s,
        'Cukup Baik',
        Icons.psychology_rounded,
        AppColors.warning,
      );
    }
    return _ScoreInfo(
      s,
      'Perlu Belajar Lagi',
      Icons.auto_awesome_rounded,
      AppColors.error,
    );
  }

  // ============================================================================
  // BUILD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _scaffold(_buildLoading());
    if (_error != null) return _scaffold(_buildError());

    return _scaffold(
      FadeTransition(
        opacity: _fadeAnim,
        child: LayoutBuilder(
          builder: (ctx, box) {
            return box.maxWidth > 1024 ? _buildDesktop() : _buildMobile();
          },
        ),
      ),
    );
  }

  Scaffold _scaffold(Widget body) =>
      Scaffold(backgroundColor: AppColors.bg, body: body);

  // ============================================================================
  // DESKTOP
  // ============================================================================
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
                    // Left — score + category
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
                    // Right — filter + questions
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

  // ============================================================================
  // MOBILE
  // ============================================================================
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

  // ============================================================================
  // SLIVER APP BAR
  // ============================================================================
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
          if (_result != null)
            Text(
              'Skor: ${_result!['score']} · ${_result!['totalQuestions']} Soal',
              style: AppText.caption.copyWith(
                color: AppColors.white.withOpacity(0.6),
              ),
            ),
        ],
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppGradient.navy),
      ),
    );
  }

  // ============================================================================
  // SCORE CARD
  // ============================================================================
  Widget _buildScoreCard() {
    final si = _scoreInfo;
    final total = _result?['totalQuestions'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradient.navy,
        borderRadius: AppRadius.bLg,
        boxShadow: AppShadow.lg,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Icon + score
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${si.score}',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: si.color,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
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
              // Circular progress
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: si.score / 100,
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

          // Breakdown row
          Row(
            children: [
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
                  value: '${_result?['unanswered'] ?? 0}',
                  color: AppColors.textSecondary,
                ),
              ),
              _VertDivider(),
              Expanded(
                child: _ScoreStat(
                  icon: Icons.quiz_rounded,
                  label: 'Total',
                  value: '$total',
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TIME CARD
  // ============================================================================
  Widget _buildTimeCard() {
    final completedAt = (_result?['completedAt'] as Timestamp?)?.toDate();
    final totalSec = _result?['totalTimeSeconds'] as int? ?? 0;
    final min = totalSec ~/ 60;
    final sec = totalSec % 60;

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

  // ============================================================================
  // CATEGORY CARD
  // ============================================================================
  Widget _buildCategoryCard() {
    final cats = _result?['categoryScores'] as Map<String, dynamic>? ?? {};
    if (cats.isEmpty) return const SizedBox.shrink();

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
          ...cats.entries.map((e) {
            final d = e.value as Map<String, dynamic>;
            final correct = d['correct'] as int? ?? 0;
            final total = d['total'] as int? ?? 1;
            final pct = d['percentage'] as int? ?? 0;

            final barColor = pct >= 80
                ? AppColors.success
                : pct >= 60
                ? AppColors.info
                : pct >= 40
                ? AppColors.warning
                : AppColors.error;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text('$correct/$total', style: AppText.caption),
                      AppSpacing.hxs,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softBg(barColor),
                          borderRadius: AppRadius.bFull,
                        ),
                        child: Text(
                          '$pct%',
                          style: AppText.label.copyWith(
                            color: barColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vxs,
                  ClipRRect(
                    borderRadius: AppRadius.bFull,
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      color: barColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================================================
  // FILTER BAR
  // ============================================================================
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

  // ============================================================================
  // QUESTIONS LIST
  // ============================================================================
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
        final globalIdx = _questions.indexOf(q);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _QuestionCard(question: q, number: globalIdx + 1),
        );
      }).toList(),
    );
  }

  // ============================================================================
  // LOADING & ERROR
  // ============================================================================
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
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
  }

  Widget _buildError() {
    return Center(
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
}

// ============================================================================
// QUESTION CARD (ExpansionTile-based)
// ============================================================================
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

  @override
  Widget build(BuildContext context) {
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

    final _QStatus status = userAnswer == null
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

    final diffColor = switch (difficulty.toLowerCase()) {
      'easy' => AppColors.success,
      'hard' => AppColors.error,
      _ => AppColors.warning,
    };
    final diffLabel = switch (difficulty.toLowerCase()) {
      'easy' => 'Mudah',
      'hard' => 'Sulit',
      _ => 'Sedang',
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bLg,
        border: Border.all(color: status.color.withOpacity(0.25), width: 1.5),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        children: [
          // ── Header (tap to expand) ─────────────────────────────────────
          InkWell(
            onTap: _toggle,
            borderRadius: _expanded
                ? const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg),
                  )
                : AppRadius.bLg,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.softBg(status.color),
                borderRadius: _expanded
                    ? const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.lg),
                      )
                    : AppRadius.bLg,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: status.color,
                      borderRadius: AppRadius.bSm,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.number}',
                        style: AppText.label.copyWith(
                          color: AppColors.white,
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
                        // Status + tags
                        Row(
                          children: [
                            Icon(status.icon, size: 13, color: status.color),
                            AppSpacing.hxs,
                            Text(
                              status.label,
                              style: AppText.label.copyWith(
                                color: status.color,
                              ),
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
                        // Question preview
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
                        if (qImage != null &&
                            qImage.isNotEmpty &&
                            _expanded) ...[
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
                  RotationTransition(
                    turns: _arrowAnim,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: status.color,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded body ──────────────────────────────────────────────
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
                  // Options
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
                            // Badge strip
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
                                  // Label box
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

                  // Explanation
                  if (expShort.isNotEmpty || expFull.isNotEmpty) ...[
                    AppSpacing.vmd,
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.softBg(AppColors.info),
                        borderRadius: AppRadius.bMd,
                        border: Border.all(
                          color: AppColors.info.withOpacity(0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
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
                                  style: AppText.label.copyWith(
                                    color: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (expShort.isNotEmpty)
                            _ExpBlock('Ringkasan', expShort, AppColors.info),
                          if (expFull.isNotEmpty)
                            _ExpBlock(
                              'Penjelasan Lengkap',
                              expFull,
                              AppColors.primary,
                            ),
                          AppSpacing.vsm,
                        ],
                      ),
                    ),
                  ],
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
// SMALL WIDGETS
// ============================================================================

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
  final String label;
  final String value;
  final Color color;
  const _ScoreStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Text(
          label,
          style: AppText.caption.copyWith(
            color: AppColors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
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
  final String title;
  final String text;
  final Color color;
  const _ExpBlock(this.title, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

// Helper classes
class _ScoreInfo {
  final int score;
  final String label;
  final IconData icon;
  final Color color;
  const _ScoreInfo(this.score, this.label, this.icon, this.color);
}

class _QStatus {
  final String label;
  final IconData icon;
  final Color color;
  const _QStatus(this.label, this.icon, this.color);
}
