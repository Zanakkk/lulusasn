// lib/features/home/widgets/progress_chart.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';

/// Duolingo-Style Weekly Progress Chart
class ProgressChart extends StatelessWidget {
  final List<DailyProgress> weeklyData;
  final VoidCallback? onTap;

  const ProgressChart({super.key, required this.weeklyData, this.onTap});

  @override
  Widget build(BuildContext context) {
    final data = _ensure7Days(weeklyData);
    final maxExams = _getMaxExams(data);
    final totalExams = _getTotalExams(data);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderPrimary, width: 2),
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
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.show_chart_rounded,
                    color: AppColors.blue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress Mingguan',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalExams ujian',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.gray400,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Chart
            SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((day) => _buildBar(day, maxExams)).toList(),
              ),
            ),

            const SizedBox(height: 12),

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

  // ============================================================================
  // BAR - FIXED OVERFLOW
  // ============================================================================

  Widget _buildBar(DailyProgress day, int maxExams) {
    final isToday = day.isToday;
    final height = maxExams > 0 ? (day.examsCompleted / maxExams) * 100 : 0.0;
    final hasData = day.examsCompleted > 0;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // ✅ Calculate available space
            final availableHeight = constraints.maxHeight;
            final labelHeight = hasData ? 20.0 : 0.0;
            final barMaxHeight = availableHeight - labelHeight - 2; // 2px margin

            // ✅ Calculate actual bar height
            final barHeight = hasData
                ? (height / 100 * barMaxHeight).clamp(12.0, barMaxHeight)
                : 12.0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Count label
                if (hasData)
                  Container(
                    height: 18,
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.blue : AppColors.gray800,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${day.examsCompleted}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                // Bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: barHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: hasData
                        ? (isToday ? AppColors.blue : AppColors.green)
                        : AppColors.gray200,
                    borderRadius: BorderRadius.circular(6),
                    border: isToday
                        ? Border.all(color: AppColors.blue, width: 2)
                        : null,
                  ),
                ),
              ],
            );
          },
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
            color: isToday ? AppColors.blue : AppColors.textSecondary,
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

  const DailyProgress({required this.date, required this.examsCompleted});

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

  factory DailyProgress.fromMap(Map<String, dynamic> data) {
    return DailyProgress(
      date: (data['date'] as DateTime),
      examsCompleted: data['examsCompleted'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'date': date, 'examsCompleted': examsCompleted};
  }
}
