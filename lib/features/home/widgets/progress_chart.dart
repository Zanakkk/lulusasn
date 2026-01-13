// lib/features/home/widgets/progress_chart.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';

/// Weekly Progress Chart Widget
///
/// Menampilkan:
/// - Bar chart 7 hari terakhir
/// - Total exams per hari
/// - Visual comparison antar hari
/// - Hari ini highlighted
class ProgressChart extends StatelessWidget {
  final List<DailyProgress> weeklyData;
  final VoidCallback? onTap;

  const ProgressChart({
    super.key,
    required this.weeklyData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure 7 days of data
    final data = _ensure7Days(weeklyData);
    final maxExams = _getMaxExams(data);
    final totalExams = _getTotalExams(data);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.paddingMD,
        decoration: BoxDecoration(
          color: AppColors.blue.withOpacity(0.05),
          border: Border.all(color: AppColors.black, width: AppSpacing.borderThick),
          boxShadow: const [
            BoxShadow(
              color: AppColors.black,
              offset: AppSpacing.shadowMedium,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: AppSpacing.paddingSM,
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    border: Border.all(color: AppColors.black, width: AppSpacing.borderThin),
                  ),
                  child: const Icon(
                    Icons.show_chart,
                    color: AppColors.white,
                    size: AppSpacing.iconMD,
                  ),
                ),
                AppSpacing.horizontalGapMD,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROGRESS MINGGUAN',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$totalExams UJIAN',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            AppSpacing.verticalGapLG,

            // Chart
            SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((day) => _buildBar(day, maxExams)).toList(),
              ),
            ),

            AppSpacing.verticalGapMD,

            // Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: data.map((day) => _buildDayLabel(day)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // BAR
  // ============================================================================

  Widget _buildBar(DailyProgress day, int maxExams) {
    final isToday = day.isToday;
    final height = maxExams > 0 ? (day.examsCompleted / maxExams) * 100 : 0.0;
    final color = isToday ? AppColors.blue : AppColors.textTertiary;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Count label
            if (day.examsCompleted > 0)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                decoration: BoxDecoration(
                  color: isToday ? AppColors.blue : AppColors.black,
                  border: Border.all(color: AppColors.black, width: 1),
                ),
                child: Text(
                  '${day.examsCompleted}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),

            // Bar
            Container(
              height: height.clamp(8.0, 100.0),
              decoration: BoxDecoration(
                color: color,
                border: Border.all(
                  color: AppColors.black,
                  width: isToday ? AppSpacing.borderMedium : AppSpacing.borderThin,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // DAY LABEL
  // ============================================================================

  Widget _buildDayLabel(DailyProgress day) {
    final isToday = day.isToday;

    return Expanded(
      child: Center(
        child: Text(
          day.dayLabel,
          style: AppTextStyles.labelSmall.copyWith(
            color: isToday ? AppColors.blue : AppColors.textSecondary,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  List<DailyProgress> _ensure7Days(List<DailyProgress> data) {
    if (data.length >= 7) {
      return data.sublist(data.length - 7);
    }

    final result = <DailyProgress>[];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final existing = data.firstWhere(
            (d) => _isSameDay(d.date, date),
        orElse: () => DailyProgress(date: date, examsCompleted: 0),
      );
      result.add(existing);
    }

    return result;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _getMaxExams(List<DailyProgress> data) {
    if (data.isEmpty) return 0;
    return data.map((d) => d.examsCompleted).reduce((a, b) => a > b ? a : b);
  }

  int _getTotalExams(List<DailyProgress> data) {
    return data.fold(0, (sum, d) => sum + d.examsCompleted);
  }
}

// ==============================================================================
// DAILY PROGRESS MODEL
// ==============================================================================

class DailyProgress {
  final DateTime date;
  final int examsCompleted;

  const DailyProgress({
    required this.date,
    required this.examsCompleted,
  });

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String get dayLabel {
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return days[date.weekday % 7];
  }

  // Factory untuk create dari Firestore
  factory DailyProgress.fromMap(Map<String, dynamic> data) {
    return DailyProgress(
      date: (data['date'] as DateTime),
      examsCompleted: data['examsCompleted'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'examsCompleted': examsCompleted,
    };
  }
}