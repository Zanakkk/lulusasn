// lib/features/tryout/screens/tryout_detail_screen.dart

// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/widgets/brutalist_button.dart';
import 'package:lulusasn/features/TO/ExamScreen.dart';
import 'package:lulusasn/features/TO/exam_review_screen.dart';

/// Tryout Detail Screen - Duolingo Style
///
/// Features:
/// - Detail tryout info (title, description, stats)
/// - List of subtests dengan status progress
/// - Purchase/Start CTA
/// - Responsive layout
/// - Clean Duolingo design
class TryoutDetailScreen extends StatefulWidget {
  final String tryoutId;

  const TryoutDetailScreen({super.key, required this.tryoutId});

  @override
  State<TryoutDetailScreen> createState() => _TryoutDetailScreenState();
}

class _TryoutDetailScreenState extends State<TryoutDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _tryoutData;
  Map<String, dynamic>? _userProgress;
  String? _error;
  bool _isReloading = false;

  StreamSubscription<DocumentSnapshot>? _progressSubscription; // ← TAMBAH INI

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToProgress(); // ← TAMBAH INI
  }

  @override
  void dispose() {
    _progressSubscription?.cancel(); // ← TAMBAH INI
    super.dispose();
  }

  void _listenToProgress() {
    try {
      final String currentUserId = getCurrentUserIdSafe();

      final userTryoutRef = FirebaseFirestore.instance
          .collection('user_tryouts')
          .doc('${currentUserId}_tryout_${widget.tryoutId}');

      // ✅ REAL-TIME LISTENER
      _progressSubscription = userTryoutRef.snapshots().listen((snapshot) {
        if (snapshot.exists && mounted) {
          setState(() {
            _userProgress = snapshot.data();
          });
        }
      });
    } catch (e) {
      debugPrint('Error listening to progress: $e');
    }
  }

  String getCurrentUserIdSafe() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid;
    }
    throw Exception('User not logged in');
  }

  Future<void> _loadData({bool isReload = false}) async {
    setState(() {
      if (isReload) {
        _isReloading = true;
      } else {
        _isLoading = true;
      }
      _error = null;
    });

    try {
      final String currentUserId = getCurrentUserIdSafe();

      // ✅ Load tryout data
      final tryoutDoc = await FirebaseFirestore.instance
          .collection('tryouts')
          .doc(widget.tryoutId)
          .get();

      if (!tryoutDoc.exists) {
        throw Exception('Try out tidak ditemukan');
      }

      final tryoutData = tryoutDoc.data()!;

      // ✅ Load user progress
      final userTryoutRef = FirebaseFirestore.instance
          .collection('user_tryouts')
          .doc('${currentUserId}_tryout_${widget.tryoutId}');

      final userTryoutDoc = await userTryoutRef.get();

      // ✅ HANYA CREATE jika belum ada, JANGAN overwrite kalau sudah ada
      if (!userTryoutDoc.exists) {
        final subtests = tryoutData['subtests'] as List<dynamic>? ?? [];
        final Map<String, dynamic> subtestProgress = {};

        for (var subtest in subtests) {
          final subtestId = subtest['id'] ?? subtest['name'];
          subtestProgress[subtestId] = {
            'status': 'not_started',
            'attempts': 0,
            'bestScore': null,
            'lastAttemptAt': null,
          };
        }

        // ✅ CREATE document baru (hanya sekali)
        await userTryoutRef.set({
          'userId': currentUserId,
          'tryoutId': widget.tryoutId,
          'status': 'not_started',
          'totalAttempts': 0,
          'bestScore': null,
          'lastAttemptAt': null,
          'subtestProgress': subtestProgress,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // ✅ READ ulang setelah ensure dokumen ada
      final finalUserTryoutDoc = await userTryoutRef.get();

      setState(() {
        _tryoutData = tryoutData;
        _userProgress = finalUserTryoutDoc.data();
        _isLoading = false;
        _isReloading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isReloading = false;
      });
    }
  }

  void _handleStartSubtest(Map<String, dynamic> subtest) {
    HapticFeedback.mediumImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamSessionScreen(
          tryoutId: widget.tryoutId,
          subtestId: subtest['id'] ?? subtest['name'],
          subtestData: subtest,
        ),
      ),
    ).then((_) {
      // ✅ RELOAD dengan isReload: true untuk mini loading
      _loadData(isReload: true);
    });
  }

  void _handleReviewSubtest(Map<String, dynamic> subtest) async {
    HapticFeedback.mediumImpact();

    try {
      final String currentUserId = getCurrentUserIdSafe();
      final subtestId = subtest['id'] ?? subtest['name'];

      // Get latest result for this subtest
      final results = await FirebaseFirestore.instance
          .collection('exam_results')
          .where('userId', isEqualTo: currentUserId)
          .where('tryoutId', isEqualTo: widget.tryoutId)
          .where('subtestId', isEqualTo: subtestId)
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();

      if (results.docs.isEmpty) {
        throw Exception('Belum ada hasil ujian untuk subtest ini');
      }

      final resultId = results.docs.first.id;

      // Navigate to review screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamReviewScreen(resultId: resultId),
        ),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Error: ${e.toString().replaceAll('Exception: ', '')}',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF4B4B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(AppSpacing.md),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF58CC02)),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: _buildErrorView(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          _buildResponsiveLayout(),

          // ✅ MINI LOADING INDICATOR untuk reload
          if (_isReloading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: const Color(0xFFE5E5E5),
                valueColor: AlwaysStoppedAnimation(Color(0xFF58CC02)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResponsiveLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1024;

        if (isDesktop) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  // ==========================================================================
  // MOBILE/TABLET LAYOUT
  // ==========================================================================
  Widget _buildMobileLayout() {
    return RefreshIndicator(
      onRefresh: () => _loadData(isReload: true),
      color: const Color(0xFF58CC02),
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeaderSection(),
                _buildStatsSection(),
                _buildDescriptionSection(),
                _buildSubtestsSection(),
                SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // DESKTOP LAYOUT
  // ==========================================================================
  Widget _buildDesktopLayout() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl * 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column - Info
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildHeaderSection(),
                          _buildDescriptionSection(),
                          _buildStatsSection(),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.xl),
                    // Right Column - Subtests
                    Expanded(
                      flex: 3,
                      child: Column(children: [_buildSubtestsSection()]),
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

  // ==========================================================================
  // APP BAR
  // ==========================================================================
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFF58CC02),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Detail Try Out',
        style: AppTextStyles.headingMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ==========================================================================
  // HEADER SECTION
  // ==========================================================================
  Widget _buildHeaderSection() {
    final title = _tryoutData?['title'] ?? 'Untitled';
    final examTypeName = _tryoutData?['examTypeName'] ?? 'Ujian';
    final isPremium = _tryoutData?['isPremium'] ?? false;

    return Container(
      margin: EdgeInsets.all(AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
              : [const Color(0xFF58CC02), const Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPremium ? const Color(0xFFFFA500) : const Color(0xFF46A302),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (isPremium ? const Color(0xFFFFA500) : const Color(0xFF46A302))
                    .withOpacity(0.3),
            offset: const Offset(0, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPremium
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF58CC02),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 18,
                      color: isPremium
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF58CC02),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      examTypeName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isPremium
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF58CC02),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPremium
                        ? const Color(0xFFFFD700)
                        : const Color(0xFF58CC02),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPremium ? Icons.star_rounded : Icons.check_circle,
                      size: 18,
                      color: isPremium
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF58CC02),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      isPremium ? 'Premium' : 'Gratis',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isPremium
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF58CC02),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          // Title
          Text(
            title,
            style: AppTextStyles.headingLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 28,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // STATS SECTION
  // ==========================================================================
  Widget _buildStatsSection() {
    final totalQuestions = _tryoutData?['totalQuestions'] ?? 0;
    final totalMinutes = _tryoutData?['totalEstimatedMinutes'] ?? 0;
    final subTestCount = _tryoutData?['subTestCount'] ?? 0;
    final totalAttempts = _tryoutData?['totalAttempts'] ?? 0;
    final averageScore = _tryoutData?['averageScore'] ?? 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFF1CB0F6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFF1CB0F6),
                  size: 24,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Text(
                'Statistik Try Out',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          // Stats Grid
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _buildStatCard(
                icon: Icons.quiz_rounded,
                label: 'Total Soal',
                value: '$totalQuestions',
                color: const Color(0xFF1CB0F6),
              ),
              _buildStatCard(
                icon: Icons.timer_rounded,
                label: 'Durasi',
                value: '$totalMinutes mnt',
                color: const Color(0xFFFF9600),
              ),
              _buildStatCard(
                icon: Icons.layers_rounded,
                label: 'Subtes',
                value: '$subTestCount',
                color: const Color(0xFF58CC02),
              ),
              if (totalAttempts > 0)
                _buildStatCard(
                  icon: Icons.people_rounded,
                  label: 'Peserta',
                  value: '$totalAttempts',
                  color: const Color(0xFF9333EA),
                ),
              if (averageScore > 0)
                _buildStatCard(
                  icon: Icons.star_rounded,
                  label: 'Rata-rata',
                  value: averageScore.toStringAsFixed(1),
                  color: const Color(0xFFFFD700),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.headingMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF777777),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // DESCRIPTION SECTION
  // ==========================================================================
  Widget _buildDescriptionSection() {
    final description = _tryoutData?['description'] ?? '';

    if (description.isEmpty) return const SizedBox();

    return Container(
      margin: EdgeInsets.all(AppSpacing.lg),
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Color(0xFF58CC02),
                  size: 24,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Text(
                'Deskripsi',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF4B4B4B),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SUBTESTS SECTION
  // ==========================================================================
  Widget _buildSubtestsSection() {
    final subtests = _tryoutData?['subtests'] as List<dynamic>? ?? [];

    if (subtests.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9600).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.list_alt_rounded,
                    color: Color(0xFFFF9600),
                    size: 24,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Text(
                  'Daftar Subtes (${subtests.length})',
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 2, color: Color(0xFFE5E5E5)),

          // Subtest List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: subtests.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final subtest = subtests[index] as Map<String, dynamic>;
              return _buildSubtestCard(subtest, index + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubtestCard(Map<String, dynamic> subtest, int number) {
    final name = subtest['name'] ?? 'Untitled';
    final description = subtest['description'] ?? '';
    final category = subtest['category'] ?? 'N/A';
    final difficulty = subtest['difficulty'] ?? 'medium';
    final estimatedMinutes = subtest['estimatedMinutes'] ?? 0;
    final questionCount = subtest['questionCount'] ?? 0;
    final subtestId = subtest['id'] ?? name;

    // Get progress
    Map<String, dynamic>? subtestMap;
    if (_userProgress != null) {
      subtestMap = _userProgress!['subtestProgress'] as Map<String, dynamic>?;
    }

    final progress = subtestMap?[subtestId];
    final status = progress?['status']?.toString() ?? 'not_started';
    final bestScore = progress?['bestScore'] is int
        ? progress!['bestScore']
        : int.tryParse(progress?['bestScore']?.toString() ?? '');
    final attempts = progress?['attempts'] is int
        ? progress!['attempts']
        : int.tryParse(progress?['attempts']?.toString() ?? '') ?? 0;

    // ✅ LOGIK SEQUENTIAL UNLOCK
    bool isUnlocked = number == 1; // Subtes pertama selalu unlock

    if (number > 1) {
      // Cek apakah subtes sebelumnya sudah completed
      final subtests = _tryoutData?['subtests'] as List<dynamic>? ?? [];
      if (number - 2 < subtests.length) {
        final prevSubtest = subtests[number - 2] as Map<String, dynamic>;
        final prevSubtestId = prevSubtest['id'] ?? prevSubtest['name'];
        final prevProgress = subtestMap?[prevSubtestId];
        final prevStatus = prevProgress?['status']?.toString() ?? 'not_started';

        isUnlocked = prevStatus == 'completed';
      }
    }

    // Status colors & icons
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (!isUnlocked) {
      // 🔒 LOCKED STATE
      statusColor = const Color(0xFFBBBBBB);
      statusIcon = Icons.lock_rounded;
      statusText = 'Terkunci';
    } else if (status == 'completed') {
      // ✅ COMPLETED STATE
      statusColor = const Color(0xFF58CC02);
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Selesai';
    } else if (status == 'in_progress') {
      // 🔄 IN PROGRESS STATE
      statusColor = const Color(0xFF1CB0F6);
      statusIcon = Icons.play_circle_rounded;
      statusText = 'Sedang Dikerjakan';
    } else {
      // 🟢 UNLOCKED BUT NOT STARTED
      statusColor = const Color(0xFF58CC02);
      statusIcon = Icons.radio_button_unchecked_rounded;
      statusText = 'Siap Dikerjakan';
    }

    // Difficulty color
    Color difficultyColor;
    switch (difficulty) {
      case 'easy':
        difficultyColor = const Color(0xFF58CC02);
        break;
      case 'hard':
        difficultyColor = const Color(0xFFFF4B4B);
        break;
      default:
        difficultyColor = const Color(0xFFFF9600);
    }

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.6, // Dim kalau locked
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? const Color(0xFFE5E5E5)
                : const Color(0xFFCCCCCC),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  // Number Badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor, width: 2),
                    ),
                    child: Center(
                      child: isUnlocked
                          ? Text(
                              '$number',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.headingSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isUnlocked ? null : const Color(0xFF999999),
                          ),
                        ),
                        if (description.isNotEmpty)
                          Text(
                            description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: const Color(0xFF777777),
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

            // Content
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags Row
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _buildSubtestTag(
                        icon: Icons.category_rounded,
                        label: category,
                        color: const Color(0xFF1CB0F6),
                      ),
                      _buildSubtestTag(
                        icon: Icons.trending_up_rounded,
                        label: difficulty == 'easy'
                            ? 'Mudah'
                            : difficulty == 'hard'
                            ? 'Sulit'
                            : 'Menengah',
                        color: difficultyColor,
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),

                  // Stats Row
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        size: 16,
                        color: const Color(0xFF777777),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        '$questionCount soal',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFF777777),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Icon(
                        Icons.timer_rounded,
                        size: 16,
                        color: const Color(0xFF777777),
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        '$estimatedMinutes menit',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFF777777),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: AppSpacing.md),

                  // Status Container
                  Container(
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusText,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (bestScore != null)
                                Text(
                                  'Skor Terbaik: $bestScore/100',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (attempts > 0)
                                Text(
                                  'Percobaan: $attempts kali',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xFF777777),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (!isUnlocked)
                                Text(
                                  'Selesaikan subtes sebelumnya',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xFF999999),
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: DuolingoButton.primary(
                          text: status == 'completed' ? 'ULANGI' : 'MULAI',
                          onPressed: isUnlocked
                              ? () => _handleStartSubtest(subtest)
                              : null, // Disable kalau locked
                        ),
                      ),
                      if (status == 'completed') ...[
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: DuolingoButton.secondary(
                            text: 'REVIEW',
                            onPressed: () => _handleReviewSubtest(subtest),
                          ),
                        ),
                      ],
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

  Widget _buildSubtestTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


  // ==========================================================================
  // ERROR VIEW
  // ==========================================================================
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4B4B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Color(0xFFFF4B4B),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Terjadi Kesalahan',
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? 'Unknown error',
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF777777),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            DuolingoButton.primary(
              text: 'KEMBALI',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
