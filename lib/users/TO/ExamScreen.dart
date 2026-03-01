// lib/features/tryout/screens/exam_session_screen.dart
// ignore_for_file: deprecated_member_use, curly_braces_in_flow_control_structures, unused_local_variable

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/theme.dart';

class ExamSessionScreen extends StatefulWidget {
  final String tryoutId;
  final String subtestId;
  final Map<String, dynamic> subtestData;

  const ExamSessionScreen({
    super.key,
    required this.tryoutId,
    required this.subtestId,
    required this.subtestData,
  });

  @override
  State<ExamSessionScreen> createState() => _ExamSessionScreenState();
}

class _ExamSessionScreenState extends State<ExamSessionScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _questions = [];
  final Map<int, int> _answers = {};
  int _currentQuestionIndex = 0;
  final PageController _pageController = PageController();

  // Timer
  Timer? _timer;
  int _remainingSeconds = 0;
  late int _totalSeconds;

  // Session
  String? _sessionId;
  DateTime? _startTime;

  // Animations
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _showNavigator = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadAndStart();
  }

  void _initAnimations() {
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideCtrl = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAndStart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final qList = widget.subtestData['questions'] as List<dynamic>?;
      if (qList == null || qList.isEmpty)
        throw Exception('Tidak ada soal di subtes ini');
      _questions = qList
          .map((q) => Map<String, dynamic>.from(q as Map))
          .toList();
      _totalSeconds = (widget.subtestData['estimatedMinutes'] ?? 30) * 60;
      _remainingSeconds = _totalSeconds;
      _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      _startTime = DateTime.now();
      _startTimer();
      _fadeCtrl.forward();
      _slideCtrl.forward();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        t.cancel();
        _showTimeUpDialog();
      }
    });
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _goToQuestion(int index) {
    if (index < 0 || index >= _questions.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentQuestionIndex = index;
      _showNavigator = false;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
    _fadeCtrl.reset();
    _slideCtrl.reset();
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  void _selectAnswer(int optionIndex) {
    HapticFeedback.mediumImpact();
    setState(() => _answers[_currentQuestionIndex] = optionIndex);
  }

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submitExam() async {
    try {
      HapticFeedback.heavyImpact();
      final endTime = DateTime.now();
      final totalSecs = endTime.difference(_startTime!).inSeconds;

      // ── Ambil konfigurasi ──────────────────────────────────────────────────
      final rawCfg =
          widget.subtestData['scoringConfig'] as Map<String, dynamic>?;
      final correctPt = (rawCfg?['correctScore'] as num?)?.toDouble() ?? 1.0;
      final wrongPt = (rawCfg?['wrongScore'] as num?)?.toDouble() ?? 0.0;
      final emptyPt = (rawCfg?['emptyScore'] as num?)?.toDouble() ?? 0.0;

      final subtestType = widget.subtestData['type'] as String? ?? 'objective';
      final isLikert = subtestType == 'likert';

      // ── Hitung skor ────────────────────────────────────────────────────────
      int correct = 0, wrong = 0;
      double earnedScore = 0;
      double maxScore = 0;

      final Map<String, Map<String, dynamic>> catScores = {};
      final List<Map<String, dynamic>> detailed = [];

      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final ua = _answers[i]; // null = tidak dijawab
        final cat = q['category'] as String? ?? 'N/A';

        catScores.putIfAbsent(
          cat,
          () => {'correct': 0, 'total': 0, 'earnedScore': 0.0, 'maxScore': 0.0},
        );
        catScores[cat]!['total'] = (catScores[cat]!['total'] as int) + 1;

        if (isLikert) {
          // ── Likert: skor dari scores[userAnswer] ─────────────────────────
          final scores =
              (q['scores'] as List<dynamic>?)
                  ?.map((s) => (s as num).toDouble())
                  .toList() ??
              [];
          final qMax = scores.isEmpty
              ? 0.0
              : scores.reduce((a, b) => a > b ? a : b);
          final qEarned = (ua != null && ua < scores.length) ? scores[ua] : 0.0;

          earnedScore += qEarned;
          maxScore += qMax;
          catScores[cat]!['earnedScore'] =
              (catScores[cat]!['earnedScore'] as double) + qEarned;
          catScores[cat]!['maxScore'] =
              (catScores[cat]!['maxScore'] as double) + qMax;

          detailed.add({
            'questionId': q['id'] ?? 'q_$i',
            'userAnswer': ua,
            'earnedScore': qEarned,
            'isCorrect': true, // likert tidak ada benar/salah
          });
        } else {
          // ── Objective: pakai scoringConfig ───────────────────────────────
          final ca = q['correctIndex'] as int?;
          final isOk = ua != null && ua == ca;
          double qPt;
          if (ua == null) {
            qPt = emptyPt;
          } else if (isOk) {
            qPt = correctPt;
            correct++;
            catScores[cat]!['correct'] =
                (catScores[cat]!['correct'] as int) + 1;
          } else {
            qPt = wrongPt;
            wrong++;
          }

          earnedScore += qPt;
          // Skor maks objective = semua soal dijawab benar
          maxScore += correctPt;
          catScores[cat]!['earnedScore'] =
              (catScores[cat]!['earnedScore'] as double) + qPt;
          catScores[cat]!['maxScore'] =
              (catScores[cat]!['maxScore'] as double) + correctPt;

          detailed.add({
            'questionId': q['id'] ?? 'q_$i',
            'userAnswer': ua,
            'correctAnswer': ca,
            'isCorrect': isOk,
          });
        }
      }

      // ── Persentase skor (0–100) ────────────────────────────────────────────
      final scorePct = maxScore > 0
          ? ((earnedScore / maxScore) * 100).round()
          : 0;

      // ── Format categoryScores ──────────────────────────────────────────────
      final catFormatted = catScores.map((k, v) {
        final cMax = (v['maxScore'] as double);
        final cEarned = (v['earnedScore'] as double);
        return MapEntry(k, {
          'correct': v['correct'],
          'total': v['total'],
          'earnedScore': cEarned,
          'maxScore': cMax,
          'percentage': cMax > 0 ? ((cEarned / cMax) * 100).round() : 0,
        });
      });

      // ── Simpan exam_results ────────────────────────────────────────────────
      final resultId = 'result_${DateTime.now().millisecondsSinceEpoch}';
      await FirebaseFirestore.instance
          .collection('exam_results')
          .doc(resultId)
          .set({
            'userId': _userId,
            'tryoutId': widget.tryoutId,
            'subtestId': widget.subtestId,
            'sessionId': _sessionId,
            'type': subtestType,
            'totalQuestions': _questions.length,
            'correctAnswers': correct,
            'wrongAnswers': wrong,
            'unanswered': _questions.length - _answers.length,
            'score': scorePct,
            'earnedScore': earnedScore,
            'maxScore': maxScore,
            'categoryScores': catFormatted,
            'startedAt': Timestamp.fromDate(_startTime!),
            'completedAt': Timestamp.fromDate(endTime),
            'totalTimeSeconds': totalSecs,
            'answers': detailed,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // ── Update user_tryouts ────────────────────────────────────────────────
      final progressRef = FirebaseFirestore.instance
          .collection('user_tryouts')
          .doc('${_userId}_tryout_${widget.tryoutId}');
      final snap = await progressRef.get();

      if (snap.exists) {
        final cur =
            ((snap.data()!['subtestProgress']
                    as Map<String, dynamic>?)?[widget.subtestId]
                as Map<String, dynamic>?) ??
            {};
        final bestPct = cur['bestScore'] as int? ?? 0;
        final bestEarned = (cur['bestEarnedScore'] as num?)?.toDouble() ?? 0;

        await progressRef.update({
          'subtestProgress.${widget.subtestId}.status': 'completed',
          'subtestProgress.${widget.subtestId}.attempts': FieldValue.increment(
            1,
          ),
          // simpan persentase terbaik
          'subtestProgress.${widget.subtestId}.bestScore': scorePct > bestPct
              ? scorePct
              : bestPct,
          // simpan earned/max terbaik (berdasarkan earned absolut)
          'subtestProgress.${widget.subtestId}.bestEarnedScore':
              earnedScore > bestEarned ? earnedScore : bestEarned,
          'subtestProgress.${widget.subtestId}.bestMaxScore': maxScore,
          'subtestProgress.${widget.subtestId}.lastAttemptAt':
              FieldValue.serverTimestamp(),
          'lastAttemptAt': FieldValue.serverTimestamp(),
          'totalAttempts': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await progressRef.set({
          'userId': _userId,
          'tryoutId': widget.tryoutId,
          'subtestProgress': {
            widget.subtestId: {
              'status': 'completed',
              'attempts': 1,
              'bestScore': scorePct,
              'bestEarnedScore': earnedScore,
              'bestMaxScore': maxScore,
              'lastAttemptAt': FieldValue.serverTimestamp(),
            },
          },
          'lastAttemptAt': FieldValue.serverTimestamp(),
          'totalAttempts': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        final msg = isLikert
            ? 'Selesai! Skor kamu: ${earnedScore.toInt()} / ${maxScore.toInt()}'
            : 'Selesai! Skor kamu: $scorePct';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.white),
                AppSpacing.hsm,
                Text(msg, style: AppText.body.copyWith(color: AppColors.white)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: AppText.body.copyWith(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
          ),
        );
      }
    }
  }

  // ============================================================================
  // BUILD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return Scaffold(backgroundColor: AppColors.bg, body: _buildLoading());
    if (_error != null)
      return Scaffold(backgroundColor: AppColors.bg, body: _buildError());

    return WillPopScope(
      onWillPop: () async => (await _confirmExit()) ?? false,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: LayoutBuilder(
          builder: (ctx, box) {
            return box.maxWidth > 900 ? _buildDesktop() : _buildMobile();
          },
        ),
      ),
    );
  }

  // ============================================================================
  // DESKTOP LAYOUT
  // ============================================================================
  Widget _buildDesktop() {
    return SafeArea(
      child: Row(
        children: [
          // ── Sidebar ─────────────────────────────────────────────────────────
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                _buildSidebarHeader(),
                _buildProgressRow(),
                const Divider(height: 1, color: AppColors.border),
                Expanded(child: _buildQuestionGrid()),
                const Divider(height: 1, color: AppColors.border),
                _buildFinishButton(),
              ],
            ),
          ),

          // ── Main Content ────────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildQuestionPages()),
                _buildBottomNav(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MOBILE LAYOUT
  // ============================================================================
  Widget _buildMobile() {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              _buildMobileHeader(),
              Expanded(child: _buildQuestionPages()),
              _buildBottomNav(),
            ],
          ),
          if (_showNavigator) ...[
            GestureDetector(
              onTap: () => setState(() => _showNavigator = false),
              child: Container(color: Colors.black54),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                elevation: 16,
                shadowColor: AppColors.primary.withOpacity(0.2),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.78,
                  height: double.infinity,
                  color: AppColors.surface,
                  child: Column(
                    children: [
                      _buildSidebarHeader(),
                      _buildProgressRow(),
                      const Divider(height: 1, color: AppColors.border),
                      Expanded(child: _buildQuestionGrid()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // SIDEBAR COMPONENTS
  // ============================================================================
  Widget _buildSidebarHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.navy),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: AppRadius.bSm,
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.gold,
                  size: 16,
                ),
              ),
              AppSpacing.hsm,
              Expanded(
                child: Text(
                  'Navigator Soal',
                  style: AppText.label.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),
          AppSpacing.vsm,
          Text(
            widget.subtestData['name'] ?? 'Ujian',
            style: AppText.bodySm.copyWith(
              color: AppColors.white.withOpacity(0.55),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow() {
    final answered = _answers.length;
    final total = _questions.length;
    final pct = total > 0 ? answered / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: [
              _ProgressChip(
                label: '$answered Dijawab',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
              ),
              AppSpacing.hxs,
              _ProgressChip(
                label: '${total - answered} Belum',
                icon: Icons.radio_button_unchecked_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          AppSpacing.vsm,
          ClipRRect(
            borderRadius: AppRadius.bFull,
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: AppColors.border,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _questions.length,
      itemBuilder: (_, i) {
        final isAnswered = _answers.containsKey(i);
        final isCurrent = i == _currentQuestionIndex;

        return GestureDetector(
          onTap: () => _goToQuestion(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.primary
                  : isAnswered
                  ? AppColors.softBg(AppColors.success)
                  : AppColors.surfaceAlt,
              borderRadius: AppRadius.bSm,
              border: Border.all(
                color: isCurrent
                    ? AppColors.primary
                    : isAnswered
                    ? AppColors.success
                    : AppColors.border,
                width: isCurrent ? 2 : 1,
              ),
              boxShadow: isCurrent ? AppShadow.sm : null,
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: AppText.label.copyWith(
                  fontSize: 12,
                  color: isCurrent
                      ? AppColors.white
                      : isAnswered
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinishButton() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showReviewDialog,
          icon: const Icon(Icons.check_rounded, size: 16),
          label: const Text('Selesai & Kumpul'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
            textStyle: AppText.btnMd,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // TOP BAR (Desktop)
  // ============================================================================
  Widget _buildTopBar() {
    final min = _remainingSeconds ~/ 60;
    final sec = _remainingSeconds % 60;
    final isLow = _remainingSeconds < 300;
    final timerColor = isLow ? AppColors.error : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: AppShadow.sm,
      ),
      child: Row(
        children: [
          // Soal counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.softBg(AppColors.primary),
              borderRadius: AppRadius.bMd,
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.quiz_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                AppSpacing.hxs,
                Text(
                  '${_currentQuestionIndex + 1} / ${_questions.length}',
                  style: AppText.label.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          AppSpacing.hsm,

          // Kategori
          if (_questions.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.softBg(AppColors.info),
                borderRadius: AppRadius.bMd,
              ),
              child: Text(
                _questions[_currentQuestionIndex]['category'] ?? 'N/A',
                style: AppText.label.copyWith(
                  color: AppColors.info,
                  fontSize: 11,
                ),
              ),
            ),

          const Spacer(),

          // Timer
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.softBg(timerColor),
              borderRadius: AppRadius.bMd,
              border: Border.all(color: timerColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  isLow ? Icons.timer_off_rounded : Icons.timer_rounded,
                  size: 16,
                  color: timerColor,
                ),
                AppSpacing.hxs,
                Text(
                  '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: timerColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hsm,

          // Exit
          InkWell(
            onTap: () async {
              final ok = await _confirmExit();
              if (ok == true && mounted) Navigator.pop(context);
            },
            borderRadius: AppRadius.bSm,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: AppRadius.bSm,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MOBILE HEADER
  // ============================================================================
  Widget _buildMobileHeader() {
    final min = _remainingSeconds ~/ 60;
    final sec = _remainingSeconds % 60;
    final isLow = _remainingSeconds < 300;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradient.navy,
        boxShadow: AppShadow.md,
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Row(
        children: [
          InkWell(
            onTap: () => setState(() => _showNavigator = true),
            borderRadius: AppRadius.bSm,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.1),
                borderRadius: AppRadius.bSm,
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
          AppSpacing.hmd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Soal ${_currentQuestionIndex + 1} dari ${_questions.length}',
                  style: AppText.bodyLg.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_questions.isNotEmpty)
                  Text(
                    _questions[_currentQuestionIndex]['category'] ?? '',
                    style: AppText.caption.copyWith(
                      color: AppColors.gold,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          // Timer mobile
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isLow
                  ? AppColors.error.withOpacity(0.15)
                  : AppColors.white.withOpacity(0.1),
              borderRadius: AppRadius.bMd,
              border: Border.all(
                color: isLow
                    ? AppColors.error.withOpacity(0.5)
                    : AppColors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_rounded,
                  size: 14,
                  color: isLow ? AppColors.error : AppColors.gold,
                ),
                AppSpacing.hxs,
                Text(
                  '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isLow ? AppColors.error : AppColors.white,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // QUESTION PAGES
  // ============================================================================
  Widget _buildQuestionPages() {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _questions.length,
      onPageChanged: (i) {
        setState(() => _currentQuestionIndex = i);
        _fadeCtrl.reset();
        _slideCtrl.reset();
        _fadeCtrl.forward();
        _slideCtrl.forward();
      },
      itemBuilder: (_, i) => _buildQuestionCard(_questions[i], i),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q, int index) {
    final text = q['question'] as String? ?? '';
    final qImage = q['questionImage'] as String?;
    final options = q['options'] as List<dynamic>? ?? [];
    final optImages = q['optionImages'] as List<dynamic>?;
    final selected = _answers[index];
    final isLikert = q['type'] == 'likert';

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Question Card ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.bLg,
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadow.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nomor soal + kategori
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppGradient.navy,
                                borderRadius: AppRadius.bFull,
                              ),
                              child: Text(
                                'Soal ${index + 1}',
                                style: AppText.label.copyWith(
                                  color: AppColors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            AppSpacing.hxs,
                            if (q['category'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.softBg(AppColors.gold),
                                  borderRadius: AppRadius.bFull,
                                ),
                                child: Text(
                                  q['category'].toString(),
                                  style: AppText.label.copyWith(
                                    color: AppColors.gold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        AppSpacing.vmd,
                        Text(
                          text,
                          style: AppText.bodyLg.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.65,
                            fontSize: 16,
                          ),
                        ),
                        if (qImage != null && qImage.isNotEmpty) ...[
                          AppSpacing.vmd,
                          ClipRRect(
                            borderRadius: AppRadius.bMd,
                            child: Image.network(
                              qImage,
                              fit: BoxFit.contain,
                              loadingBuilder: (_, child, prog) => prog == null
                                  ? child
                                  : Container(
                                      height: 140,
                                      alignment: Alignment.center,
                                      child: const CircularProgressIndicator(
                                        color: AppColors.primary,
                                        strokeWidth: 2,
                                      ),
                                    ),
                              errorBuilder: (_, __, ___) => Container(
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.softBg(AppColors.error),
                                  borderRadius: AppRadius.bSm,
                                ),
                                child: Text(
                                  'Gambar tidak dapat dimuat',
                                  style: AppText.caption.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  AppSpacing.vlg,

                  // ── Options ────────────────────────────────────────────────
                  ...List.generate(options.length, (i) {
                    final label = String.fromCharCode(65 + i);
                    final optText = options[i].toString();
                    final optImg = (optImages != null && i < optImages.length)
                        ? optImages[i] as String?
                        : null;
                    final isSelected = selected == i;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OptionTile(
                        label: label,
                        text: optText,
                        optionImage: optImg,
                        isSelected: isSelected,
                        onTap: () => _selectAnswer(i),
                      ),
                    );
                  }),

                  AppSpacing.vmd,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // BOTTOM NAVIGATION
  // ============================================================================
  Widget _buildBottomNav() {
    final isFirst = _currentQuestionIndex == 0;
    final isLast = _currentQuestionIndex == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: AppShadow.sm,
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Row(
              children: [
                // Prev
                SizedBox(
                  width: 130,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: isFirst
                        ? null
                        : () => _goToQuestion(_currentQuestionIndex - 1),
                    icon: const Icon(Icons.arrow_back_rounded, size: 15),
                    label: const Text('Sebelum'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      disabledForegroundColor: AppColors.textHint,
                      side: BorderSide(
                        color: isFirst ? AppColors.border : AppColors.primary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.bMd,
                      ),
                      textStyle: AppText.btnSm.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                // Progress indicator tengah
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_answers.length}/${_questions.length}',
                          style: AppText.label.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        AppSpacing.vxs,
                        ClipRRect(
                          borderRadius: AppRadius.bFull,
                          child: LinearProgressIndicator(
                            value: _questions.isNotEmpty
                                ? _answers.length / _questions.length
                                : 0,
                            minHeight: 4,
                            backgroundColor: AppColors.border,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Next / Finish
                SizedBox(
                  width: 130,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: isLast
                        ? _showReviewDialog
                        : () => _goToQuestion(_currentQuestionIndex + 1),
                    icon: Icon(
                      isLast
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 15,
                    ),
                    label: Text(isLast ? 'Selesai' : 'Lanjut'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLast
                          ? AppColors.gold
                          : AppColors.primary,
                      foregroundColor: isLast
                          ? AppColors.primary
                          : AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.bMd,
                      ),
                      textStyle: AppText.btnSm,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // DIALOGS
  // ============================================================================
  void _showReviewDialog() {
    final unanswered = _questions.length - _answers.length;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LuluzzDialog(
        icon: Icons.fact_check_rounded,
        iconColor: AppColors.primary,
        title: 'Kumpulkan Jawaban?',
        content: Column(
          children: [
            _ReviewStatRow(
              icon: Icons.check_circle_rounded,
              label: 'Terjawab',
              value: '${_answers.length}',
              color: AppColors.success,
            ),
            AppSpacing.vsm,
            _ReviewStatRow(
              icon: Icons.help_outline_rounded,
              label: 'Belum dijawab',
              value: '$unanswered',
              color: unanswered > 0 ? AppColors.warning : AppColors.success,
            ),
            if (unanswered > 0) ...[
              AppSpacing.vmd,
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.softBg(AppColors.warning),
                  borderRadius: AppRadius.bMd,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                      size: 14,
                    ),
                    AppSpacing.hxs,
                    Expanded(
                      child: Text(
                        '$unanswered soal belum dijawab. Yakin ingin mengumpulkan?',
                        style: AppText.bodySm.copyWith(
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
        cancelLabel: 'Periksa Lagi',
        confirmLabel: 'Kumpulkan',
        confirmColor: AppColors.primary,
        onConfirm: () {
          Navigator.pop(context);
          _submitExam();
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: _LuluzzDialog(
          icon: Icons.timer_off_rounded,
          iconColor: AppColors.error,
          title: 'Waktu Habis!',
          content: Text(
            'Waktu ujian telah berakhir. Jawaban kamu akan dikumpulkan otomatis.',
            style: AppText.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          confirmLabel: 'OK, Kumpulkan',
          confirmColor: AppColors.error,
          onConfirm: () {
            Navigator.pop(context);
            _submitExam();
          },
        ),
      ),
    );
  }

  Future<bool?> _confirmExit() {
    return showDialog<bool>(
      context: context,
      builder: (_) => _LuluzzDialog(
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.warning,
        title: 'Keluar dari Ujian?',
        content: Text(
          'Progres kamu akan hilang dan tidak dapat dikembalikan.',
          style: AppText.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        cancelLabel: 'Lanjutkan Ujian',
        confirmLabel: 'Ya, Keluar',
        confirmColor: AppColors.error,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
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
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppGradient.navy,
              shape: BoxShape.circle,
              boxShadow: AppShadow.lg,
            ),
            child: const CircularProgressIndicator(
              color: AppColors.gold,
              strokeWidth: 3,
            ),
          ),
          AppSpacing.vlg,
          Text(
            'Menyiapkan Soal...',
            style: AppText.h3.copyWith(color: AppColors.textPrimary),
          ),
          AppSpacing.vsm,
          Text('Mohon tunggu sebentar', style: AppText.bodySm),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.softBg(AppColors.error),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
            ),
            AppSpacing.vlg,
            Text('Gagal Memuat Soal', style: AppText.h3),
            AppSpacing.vsm,
            Text(
              _error ?? 'Error tidak diketahui',
              style: AppText.bodySm,
              textAlign: TextAlign.center,
            ),
            AppSpacing.vxl,
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
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
// REUSABLE WIDGETS
// ============================================================================

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final String? optionImage;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.optionImage,
    required this.isSelected,
    required this.onTap,
    // score & isLikert dihapus — tidak relevan saat ujian berlangsung
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.bMd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.softBg(AppColors.primary)
                : AppColors.surface,
            borderRadius: AppRadius.bMd,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? AppShadow.sm : null,
          ),
          child: Row(
            children: [
              // Label box
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
                  borderRadius: AppRadius.bSm,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: AppText.label.copyWith(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              AppSpacing.hmd,
              // Text + image
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: AppText.body.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                    if (optionImage != null && optionImage!.isNotEmpty) ...[
                      AppSpacing.vsm,
                      ClipRRect(
                        borderRadius: AppRadius.bSm,
                        child: Image.network(
                          optionImage!,
                          height: 90,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              Text('Gambar gagal', style: AppText.caption),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected) ...[
                AppSpacing.hmd,
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: AppColors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _ProgressChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.softBg(color),
          borderRadius: AppRadius.bSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            AppSpacing.hxs,
            Flexible(
              child: Text(
                label,
                style: AppText.label.copyWith(color: color, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ReviewStatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.softBg(color),
        borderRadius: AppRadius.bMd,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          AppSpacing.hsm,
          Expanded(child: Text(label, style: AppText.body)),
          Text(value, style: AppText.h3.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Dialog reusable Luluzzz style
class _LuluzzDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget content;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final String? cancelLabel;
  final VoidCallback? onCancel;

  const _LuluzzDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
    this.cancelLabel,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.bLg),
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softBg(iconColor),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            AppSpacing.vmd,
            Text(title, style: AppText.h2, textAlign: TextAlign.center),
            AppSpacing.vmd,
            content,
            AppSpacing.vxl,
            Row(
              children: [
                if (cancelLabel != null && onCancel != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.bMd,
                        ),
                        textStyle: AppText.btnMd.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      child: Text(cancelLabel!),
                    ),
                  ),
                  AppSpacing.hsm,
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.bMd,
                      ),
                      textStyle: AppText.btnMd,
                    ),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
