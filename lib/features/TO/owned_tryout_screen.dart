// lib/features/tryout/screens/my_tryouts_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/features/TO/tryout_detail_screen.dart';

class MyTryoutsScreen extends StatefulWidget {
  const MyTryoutsScreen({super.key});

  @override
  State<MyTryoutsScreen> createState() => _MyTryoutsScreenState();
}

class _MyTryoutsScreenState extends State<MyTryoutsScreen> {
  String _filter = 'all';
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildFilterChips(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar / icon area
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1CB0F6), Color(0xFF0F7FD4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1CB0F6).withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Try Out Saya',
                style: AppTextStyles.headingLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              Text(
                'Lanjutkan perjalanan belajarmu 🚀',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF8A94A6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Filter chips ─────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    const chips = [
      ('all', 'Semua'),
      ('active', 'Aktif'),
      ('pending', 'Pending'),
    ];

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: chips.map((c) {
          final selected = _filter == c.$1;
          return GestureDetector(
            onTap: () => setState(() => _filter = c.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF1CB0F6) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1CB0F6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  c.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF8A94A6),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────────
  Widget _buildList() {
    Query query = FirebaseFirestore.instance
        .collection('user_tryouts')
        .where('userId', isEqualTo: _uid);

    if (_filter == 'active') query = query.where('isActive', isEqualTo: true);
    if (_filter == 'pending') query = query.where('isActive', isEqualTo: false);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF1CB0F6),
              strokeWidth: 3,
            ),
          );
        }
        if (snap.hasError) {
          return _EmptyState(
            icon: Icons.error_outline_rounded,
            color: const Color(0xFFFF4B4B),
            title: 'Terjadi Kesalahan',
            subtitle: snap.error.toString(),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _emptyStateForFilter();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _TryoutCard(userTryoutDoc: data, docId: docs[i].id);
          },
        );
      },
    );
  }

  Widget _emptyStateForFilter() {
    return switch (_filter) {
      'pending' => const _EmptyState(
        icon: Icons.check_circle_rounded,
        color: Color(0xFF58CC02),
        title: 'Tidak Ada Pending Review',
        subtitle: 'Semua tryout sudah diverifikasi admin',
      ),
      'active' => const _EmptyState(
        icon: Icons.hourglass_empty_rounded,
        color: Color(0xFFFF9600),
        title: 'Belum Ada Tryout Aktif',
        subtitle: 'Tryout yang sudah diverifikasi akan muncul di sini',
      ),
      _ => const _EmptyState(
        icon: Icons.bookmark_border_rounded,
        color: Color(0xFF1CB0F6),
        title: 'Belum Ada Try Out',
        subtitle: 'Beli try out di Marketplace untuk memulai',
      ),
    };
  }
}

// =============================================================================
// Card
// =============================================================================
class _TryoutCard extends StatelessWidget {
  final Map<String, dynamic> userTryoutDoc;
  final String docId;

  const _TryoutCard({required this.userTryoutDoc, required this.docId});

  // Gradient presets per status
  static const _gradients = {
    'pending': [Color(0xFFFFB347), Color(0xFFFF6B35)],
    'done': [Color(0xFF43E97B), Color(0xFF38F9D7)],
    'active': [Color(0xFF1CB0F6), Color(0xFF0F7FD4)],
    'notStarted': [Color(0xFF667EEA), Color(0xFF764BA2)],
  };

  @override
  Widget build(BuildContext context) {
    final tryoutId = userTryoutDoc['tryoutId'] as String? ?? '';
    final isActive = userTryoutDoc['isActive'] as bool? ?? false;
    final proofStatus =
        userTryoutDoc['proofStatus'] as String? ?? 'pending_review';
    final subtestProgress =
        userTryoutDoc['subtestProgress'] as Map<String, dynamic>? ?? {};

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('tryouts')
          .doc(tryoutId)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox.shrink();
        }

        final t = snap.data!.data() as Map<String, dynamic>;
        final title = t['title'] as String? ?? 'Untitled';
        final examTypeName = t['examTypeName'] as String? ?? '';
        final totalQuestions = t['totalQuestions'] as int? ?? 0;
        final totalMinutes = t['totalEstimatedMinutes'] as int? ?? 0;
        final subtests = t['subtests'] as List<dynamic>? ?? [];
        final subTestCount = subtests.length;

        final completed = subtestProgress.values
            .where(
              (v) => (v as Map<String, dynamic>?)?['status'] == 'completed',
            )
            .length;
        final progressRatio = subTestCount > 0 ? completed / subTestCount : 0.0;
        final isDone = progressRatio == 1.0 && subTestCount > 0;
        final notStarted = subtestProgress.isEmpty;

        // Resolve key
        final gradKey = !isActive
            ? 'pending'
            : isDone
            ? 'done'
            : notStarted
            ? 'notStarted'
            : 'active';

        final colors = _gradients[gradKey]!;
        final statusLabel = !isActive
            ? 'Pending Review'
            : isDone
            ? 'Selesai'
            : notStarted
            ? 'Belum Dimulai'
            : 'Sedang Berlangsung';

        final statusIcon = !isActive
            ? Icons.schedule_rounded
            : isDone
            ? Icons.check_circle_rounded
            : notStarted
            ? Icons.play_circle_outline_rounded
            : Icons.pending_rounded;

        return GestureDetector(
          onTap: isActive
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TryoutDetailScreen(tryoutId: tryoutId),
                  ),
                )
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Colored top strip ──────────────────────────────────
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Row: badge + status pill ───────────────────
                        Row(
                          children: [
                            // Exam type badge
                            if (examTypeName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colors[0].withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  examTypeName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: colors[0],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            // Status pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: colors),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusIcon,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusLabel,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // ── Title ──────────────────────────────────────
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 12),

                        // ── Stats row ──────────────────────────────────
                        Row(
                          children: [
                            _MiniStat(
                              icon: Icons.quiz_rounded,
                              label: '$totalQuestions soal',
                              color: const Color(0xFF1CB0F6),
                            ),
                            const SizedBox(width: 10),
                            _MiniStat(
                              icon: Icons.timer_rounded,
                              label: '$totalMinutes mnt',
                              color: const Color(0xFFFF9600),
                            ),
                            const SizedBox(width: 10),
                            _MiniStat(
                              icon: Icons.layers_rounded,
                              label: '$subTestCount subtes',
                              color: const Color(0xFF58CC02),
                            ),
                            const Spacer(),
                            // CTA button
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: colors),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors[0].withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  isDone ? 'Review' : 'Lanjut',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // ── Progress bar (only when in progress) ───────
                        if (isActive &&
                            subTestCount > 0 &&
                            !isDone &&
                            !notStarted) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: progressRatio,
                                    minHeight: 6,
                                    backgroundColor: colors[0].withOpacity(
                                      0.15,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colors[0],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$completed/$subTestCount',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colors[0],
                                ),
                              ),
                            ],
                          ),
                        ],

                        // ── Pending banner ─────────────────────────────
                        if (!isActive) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8F0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFFDDB3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: Color(0xFFFF9600),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  proofStatus == 'pending_review'
                                      ? 'Bukti pembayaran sedang diverifikasi admin'
                                      : 'Menunggu verifikasi admin',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFB36B00),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Mini Stat widget
// =============================================================================
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF8A94A6),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Empty state (unchanged logic, slight restyle)
// =============================================================================
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Color(0xFF8A94A6)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Bottom sheet daftar subtes
// =============================================================================
class _SubtestsSheet extends StatelessWidget {
  final String tryoutTitle;
  final List<dynamic> subtests;
  final Map<String, dynamic> subtestProgress;
  final String tryoutId;
  final String docId;

  const _SubtestsSheet({
    required this.tryoutTitle,
    required this.subtests,
    required this.subtestProgress,
    required this.tryoutId,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: AppSpacing.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Pilih Subtes',
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              tryoutTitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: const Color(0xFF777777),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                itemCount: subtests.length,
                separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                itemBuilder: (ctx, i) {
                  final sub = subtests[i] as Map<String, dynamic>;
                  final sid = 'subtest_$i';
                  final prog =
                      subtestProgress[sid] as Map<String, dynamic>? ?? {};

                  return _SubtestTile(
                    index: i,
                    name: sub['name'] ?? 'Subtes ${i + 1}',
                    category: sub['category'] ?? '',
                    questionCount: sub['questionCount'] as int? ?? 0,
                    estimatedMinutes: sub['estimatedMinutes'] as int? ?? 0,
                    status: prog['status'] as String? ?? 'not_started',
                    attempts: prog['attempts'] as int? ?? 0,
                    bestScore: prog['bestScore'] as int? ?? 0,
                    onTap: () {
                      // Update lastAccessedAt tanpa await (fire & forget)
                      FirebaseFirestore.instance
                          .collection('user_tryouts')
                          .doc(docId)
                          .set({
                            'lastAccessedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));
                      Navigator.pop(ctx);
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) =>
                              TryoutDetailScreen(tryoutId: tryoutId),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Subtest tile di bottom sheet
// =============================================================================
class _SubtestTile extends StatelessWidget {
  final int index;
  final String name;
  final String category;
  final int questionCount;
  final int estimatedMinutes;
  final String status;
  final int attempts;
  final int bestScore;
  final VoidCallback onTap;

  const _SubtestTile({
    required this.index,
    required this.name,
    required this.category,
    required this.questionCount,
    required this.estimatedMinutes,
    required this.status,
    required this.attempts,
    required this.bestScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      'completed' => (
        const Color(0xFF58CC02),
        'Selesai',
        Icons.check_circle_rounded,
      ),
      'in_progress' => (
        const Color(0xFFFF9600),
        'Lanjutkan',
        Icons.pending_rounded,
      ),
      _ => (
        const Color(0xFF1CB0F6),
        'Mulai',
        Icons.play_circle_outline_rounded,
      ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Nomor badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category.isNotEmpty)
                        Text(
                          category,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _StatChip(
                  icon: Icons.quiz_rounded,
                  label: '$questionCount soal',
                  color: const Color(0xFF1CB0F6),
                ),
                _StatChip(
                  icon: Icons.timer_rounded,
                  label: '$estimatedMinutes mnt',
                  color: const Color(0xFFFF9600),
                ),
                if (attempts > 0)
                  _StatChip(
                    icon: Icons.refresh_rounded,
                    label: '${attempts}x',
                    color: const Color(0xFF9333EA),
                  ),
                if (bestScore > 0)
                  _StatChip(
                    icon: Icons.star_rounded,
                    label: '$bestScore',
                    color: const Color(0xFFFFD700),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Reusable widgets kecil
// =============================================================================

class _CardHeader extends StatelessWidget {
  final Color color;
  final String examTypeName;
  final String statusText;
  final IconData statusIcon;

  const _CardHeader({
    required this.color,
    required this.examTypeName,
    required this.statusText,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
      ),
      child: Row(
        children: [
          if (examTypeName.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                examTypeName,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const Spacer(),
          Icon(statusIcon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingBanner extends StatelessWidget {
  final String proofStatus;

  const _PendingBanner({required this.proofStatus});

  @override
  Widget build(BuildContext context) {
    final isPending = proofStatus == 'pending_review';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: const Color(0xFFFF9600).withOpacity(0.08),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: Color(0xFFFF9600),
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              isPending
                  ? 'Menunggu verifikasi admin — biasanya 1×24 jam'
                  : 'Tryout belum aktif',
              style: const TextStyle(
                color: Color(0xFFCC7A00),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double ratio;
  final int completed;
  final int total;
  final Color color;

  const _ProgressBar({
    required this.ratio,
    required this.completed,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF777777),
              ),
            ),
            Text(
              '$completed/$total subtes',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: const Color(0xFFE5E5E5),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _CardFooter extends StatelessWidget {
  final bool isActive;
  final bool isDone;
  final Color color;
  final VoidCallback? onTap;

  const _CardFooter({
    required this.isActive,
    required this.isDone,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(
            !isActive
                ? Icons.lock_outline_rounded
                : isDone
                ? Icons.bar_chart_rounded
                : Icons.play_arrow_rounded,
            size: 18,
          ),
          label: Text(
            !isActive
                ? 'Menunggu Verifikasi'
                : isDone
                ? 'Lihat Hasil'
                : 'Mulai / Lanjutkan',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? color : const Color(0xFFE5E5E5),
            foregroundColor: isActive ? Colors.white : const Color(0xFF999999),
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isActive ? color.withOpacity(0.6) : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
