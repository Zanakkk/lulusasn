// lib/features/profile/screens/statistics_screen.dart

// ignore_for_file: deprecated_member_use, file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/features/home/widgets/progress_chart.dart';

/// Statistics Screen - Duolingo Style
///
/// Responsive design:
/// - Mobile: < 600px (single column)
/// - Tablet: 600-1024px (2 columns grid)
/// - Desktop: > 1024px (max width 1200px, 2-3 columns)
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  StatisticsData? _stats;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final examsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('exams')
          .orderBy('completedAt', descending: true)
          .get();

      final stats = StatisticsData.fromExams(examsSnapshot.docs);

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _ResponsiveLayout(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _stats == null
                    ? _buildEmptyState()
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Statistik', style: AppTextStyles.headingMedium),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _ResponsiveGrid(
          children: [
            // Overview Cards
            _OverviewSection(stats: _stats!),

            const SizedBox(height: AppSpacing.lg),

            // Weekly Progress
            _WeeklyProgressSection(stats: _stats!),

            const SizedBox(height: AppSpacing.lg),

            // Category Performance
            _CategoryPerformanceSection(stats: _stats!),

            const SizedBox(height: AppSpacing.lg),

            // Streak & Time
            _buildTwoColumns(
              _StreakCard(streak: _stats!.currentStreak),
              _StudyTimeCard(totalMinutes: _stats!.totalStudyMinutes),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Recent Performance
            _RecentPerformanceSection(recentExams: _stats!.recentExams),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoColumns(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          children: [
            left,
            const SizedBox(height: AppSpacing.lg),
            right,
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.insert_chart_outlined_rounded,
                size: 60,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Belum Ada Data', style: AppTextStyles.headingMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Mulai latihan untuk melihat statistik',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// RESPONSIVE LAYOUT
// ==============================================================================

class _ResponsiveLayout extends StatelessWidget {
  final Widget child;

  const _ResponsiveLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1024) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

// ==============================================================================
// OVERVIEW SECTION
// ==============================================================================

class _OverviewSection extends StatelessWidget {
  final StatisticsData stats;

  const _OverviewSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        if (isTablet) {
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.md) / 2,
                child: _StatCard(
                  icon: Icons.quiz_rounded,
                  label: 'Total Ujian',
                  value: '${stats.totalExams}',
                  color: AppColors.blue,
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.md) / 2,
                child: _StatCard(
                  icon: Icons.star_rounded,
                  label: 'Rata-rata Skor',
                  value: stats.averageScore.toStringAsFixed(0),
                  color: AppColors.gold,
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.md) / 2,
                child: _StatCard(
                  icon: Icons.check_circle_rounded,
                  label: 'Akurasi',
                  value: '${(stats.accuracy * 100).toStringAsFixed(0)}%',
                  color: AppColors.green,
                ),
              ),
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.md) / 2,
                child: _StatCard(
                  icon: Icons.emoji_events_rounded,
                  label: 'Total XP',
                  value: '${stats.totalXP}',
                  color: AppColors.purple,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _StatCard(
              icon: Icons.quiz_rounded,
              label: 'Total Ujian',
              value: '${stats.totalExams}',
              color: AppColors.blue,
            ),
            const SizedBox(height: AppSpacing.md),
            _StatCard(
              icon: Icons.star_rounded,
              label: 'Rata-rata Skor',
              value: stats.averageScore.toStringAsFixed(0),
              color: AppColors.gold,
            ),
            const SizedBox(height: AppSpacing.md),
            _StatCard(
              icon: Icons.check_circle_rounded,
              label: 'Akurasi',
              value: '${(stats.accuracy * 100).toStringAsFixed(0)}%',
              color: AppColors.green,
            ),
            const SizedBox(height: AppSpacing.md),
            _StatCard(
              icon: Icons.emoji_events_rounded,
              label: 'Total XP',
              value: '${stats.totalXP}',
              color: AppColors.purple,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.displaySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// WEEKLY PROGRESS SECTION
// ==============================================================================

class _WeeklyProgressSection extends StatelessWidget {
  final StatisticsData stats;

  const _WeeklyProgressSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ProgressChart(weeklyData: stats.weeklyProgress);
  }
}

// ==============================================================================
// CATEGORY PERFORMANCE SECTION
// ==============================================================================

class _CategoryPerformanceSection extends StatelessWidget {
  final StatisticsData stats;

  const _CategoryPerformanceSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.category_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Performa per Kategori',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (stats.categoryStats.containsKey('TWK'))
            _CategoryItem(
              category: 'TWK',
              title: 'Wawasan Kebangsaan',
              data: stats.categoryStats['TWK']!,
              color: AppColors.twk,
            ),
          if (stats.categoryStats.containsKey('TIU'))
            _CategoryItem(
              category: 'TIU',
              title: 'Intelegensia Umum',
              data: stats.categoryStats['TIU']!,
              color: AppColors.tiu,
            ),
          if (stats.categoryStats.containsKey('TKP'))
            _CategoryItem(
              category: 'TKP',
              title: 'Karakteristik Pribadi',
              data: stats.categoryStats['TKP']!,
              color: AppColors.tkp,
            ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String category;
  final String title;
  final CategoryStats data;
  final Color color;

  const _CategoryItem({
    required this.category,
    required this.title,
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color, width: 2),
                ),
                child: Text(
                  category,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${data.totalExams} ujian',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akurasi',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${(data.accuracy * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rata-rata Skor',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      data.averageScore.toStringAsFixed(0),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: data.accuracy,
              minHeight: 8,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// STREAK CARD
// ==============================================================================

class _StreakCard extends StatelessWidget {
  final int streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withOpacity(0.15),
            AppColors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange, width: 3),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.orange,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$streak Hari',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Streak Belajar',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pertahankan! 🔥',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// STUDY TIME CARD
// ==============================================================================

class _StudyTimeCard extends StatelessWidget {
  final int totalMinutes;

  const _StudyTimeCard({required this.totalMinutes});

  @override
  Widget build(BuildContext context) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blue.withOpacity(0.15),
            AppColors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue, width: 3),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.blue,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            hours > 0 ? '${hours}j ${minutes}m' : '${minutes}m',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Total Waktu Belajar',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Konsistensi adalah kunci! ⏱️',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// RECENT PERFORMANCE SECTION
// ==============================================================================

class _RecentPerformanceSection extends StatelessWidget {
  final List<ExamSummary> recentExams;

  const _RecentPerformanceSection({required this.recentExams});

  @override
  Widget build(BuildContext context) {
    if (recentExams.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppColors.purple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Performa Terkini',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...recentExams.take(5).map((exam) => _RecentExamItem(exam: exam)),
        ],
      ),
    );
  }
}

class _RecentExamItem extends StatelessWidget {
  final ExamSummary exam;

  const _RecentExamItem({required this.exam});

  Color get _categoryColor {
    switch (exam.category) {
      case 'TWK':
        return AppColors.twk;
      case 'TIU':
        return AppColors.tiu;
      case 'TKP':
        return AppColors.tkp;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _categoryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _categoryColor, width: 2),
              ),
              child: Text(
                exam.category,
                style: AppTextStyles.labelSmall.copyWith(
                  color: _categoryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${exam.correct}/${exam.total} benar',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    exam.formattedDate,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getScoreColor(exam.accuracy).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(exam.accuracy * 100).toStringAsFixed(0)}%',
                style: AppTextStyles.labelMedium.copyWith(
                  color: _getScoreColor(exam.accuracy),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double accuracy) {
    if (accuracy >= 0.8) return AppColors.green;
    if (accuracy >= 0.6) return AppColors.blue;
    if (accuracy >= 0.4) return AppColors.orange;
    return AppColors.error;
  }
}

// ==============================================================================
// DATA MODELS
// ==============================================================================

class StatisticsData {
  final int totalExams;
  final double averageScore;
  final double accuracy;
  final int totalXP;
  final int currentStreak;
  final int totalStudyMinutes;
  final List<DailyProgress> weeklyProgress;
  final Map<String, CategoryStats> categoryStats;
  final List<ExamSummary> recentExams;

  StatisticsData({
    required this.totalExams,
    required this.averageScore,
    required this.accuracy,
    required this.totalXP,
    required this.currentStreak,
    required this.totalStudyMinutes,
    required this.weeklyProgress,
    required this.categoryStats,
    required this.recentExams,
  });

  factory StatisticsData.fromExams(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return StatisticsData(
        totalExams: 0,
        averageScore: 0,
        accuracy: 0,
        totalXP: 0,
        currentStreak: 0,
        totalStudyMinutes: 0,
        weeklyProgress: [],
        categoryStats: {},
        recentExams: [],
      );
    }

    int totalScore = 0;
    int totalCorrect = 0;
    int totalQuestions = 0;
    int totalXP = 0;
    int totalMinutes = 0;
    final categoryData = <String, List<Map<String, dynamic>>>{};
    final dailyData = <String, int>{};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final results = data['results'] as Map<String, dynamic>?;

      if (results != null) {
        final byCategory = results['byCategory'] as Map<String, dynamic>?;
        if (byCategory != null) {
          byCategory.forEach((category, catData) {
            final catMap = catData as Map<String, dynamic>;
            totalScore += (catMap['totalScore'] as num?)?.toInt() ?? 0;
            totalCorrect += (catMap['correct'] as num?)?.toInt() ?? 0;
            totalQuestions += (catMap['total'] as num?)?.toInt() ?? 0;

            categoryData.putIfAbsent(category, () => []);
            categoryData[category]!.add(catMap);
          });
        }
      }

      totalXP += (data['xpEarned'] as num?)?.toInt() ?? 0;
      totalMinutes += (data['duration'] as num?)?.toInt() ?? 0;

      // Daily progress
      final completedAt = data['completedAt'] as Timestamp?;
      if (completedAt != null) {
        final date = completedAt.toDate();
        final dateKey = '${date.year}-${date.month}-${date.day}';
        dailyData[dateKey] = (dailyData[dateKey] ?? 0) + 1;
      }
    }

    final categoryStats = <String, CategoryStats>{};
    categoryData.forEach((category, dataList) {
      int catTotalScore = 0;
      int catTotalCorrect = 0;
      int catTotalQuestions = 0;

      for (final catMap in dataList) {
        catTotalScore += (catMap['totalScore'] as num?)?.toInt() ?? 0;
        catTotalCorrect += (catMap['correct'] as num?)?.toInt() ?? 0;
        catTotalQuestions += (catMap['total'] as num?)?.toInt() ?? 0;
      }

      categoryStats[category] = CategoryStats(
        totalExams: dataList.length,
        averageScore: catTotalQuestions > 0
            ? catTotalScore / dataList.length
            : 0,
        accuracy: catTotalQuestions > 0
            ? catTotalCorrect / catTotalQuestions
            : 0,
      );
    });

    // Calculate weekly progress
    final weeklyProgress = _calculateWeeklyProgress(dailyData);

    // Calculate streak
    final streak = _calculateStreak(docs);

    // Get recent exams
    final recentExams = docs.take(5).map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ExamSummary.fromMap(data);
    }).toList();

    return StatisticsData(
      totalExams: docs.length,
      averageScore: docs.isNotEmpty ? totalScore / docs.length : 0,
      accuracy: totalQuestions > 0 ? totalCorrect / totalQuestions : 0,
      totalXP: totalXP,
      currentStreak: streak,
      totalStudyMinutes: totalMinutes,
      weeklyProgress: weeklyProgress,
      categoryStats: categoryStats,
      recentExams: recentExams,
    );
  }

  static List<DailyProgress> _calculateWeeklyProgress(
    Map<String, int> dailyData,
  ) {
    final now = DateTime.now();
    final List<DailyProgress> result = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final examsCompleted = dailyData[dateKey] ?? 0;

      result.add(DailyProgress(date: date, examsCompleted: examsCompleted));
    }

    return result;
  }

  static int _calculateStreak(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final uniqueDates = <DateTime>{};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final completedAt = data['completedAt'] as Timestamp?;
      if (completedAt != null) {
        final date = completedAt.toDate();
        final dateOnly = DateTime(date.year, date.month, date.day);
        uniqueDates.add(dateOnly);
      }
    }

    final sortedDates = uniqueDates.toList()..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime expectedDate = today;

    for (final date in sortedDates) {
      if (date.isAtSameMomentAs(expectedDate)) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (date.isBefore(expectedDate)) {
        break;
      }
    }

    return streak;
  }
}

// ==============================================================================
// CATEGORY STATS MODEL
// ==============================================================================

class CategoryStats {
  final int totalExams;
  final double averageScore;
  final double accuracy;

  CategoryStats({
    required this.totalExams,
    required this.averageScore,
    required this.accuracy,
  });
}

// ==============================================================================
// EXAM SUMMARY MODEL
// ==============================================================================

class ExamSummary {
  final String category;
  final int correct;
  final int total;
  final double accuracy;
  final DateTime completedAt;

  ExamSummary({
    required this.category,
    required this.correct,
    required this.total,
    required this.accuracy,
    required this.completedAt,
  });

  factory ExamSummary.fromMap(Map<String, dynamic> data) {
    final results = data['results'] as Map<String, dynamic>? ?? {};
    final correctCount = (results['correctCount'] as num?)?.toInt() ?? 0;
    final totalQuestions = (results['totalQuestions'] as num?)?.toInt() ?? 0;
    final completedAt =
        (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return ExamSummary(
      category: data['category'] as String? ?? 'N/A',
      correct: correctCount,
      total: totalQuestions,
      accuracy: totalQuestions > 0 ? correctCount / totalQuestions : 0,
      completedAt: completedAt,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(completedAt);

    if (difference.inDays == 0) {
      return 'Hari ini ${DateFormat.Hm().format(completedAt)}';
    } else if (difference.inDays == 1) {
      return 'Kemarin ${DateFormat.Hm().format(completedAt)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return DateFormat('dd MMM yyyy').format(completedAt);
    }
  }
}
