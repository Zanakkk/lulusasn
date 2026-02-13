// lib/features/tryout/screens/my_tryouts_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/features/TO/tryout_detail_screen.dart';

/// 📚 MY TRYOUTS - Halaman TryOut yang Dimiliki User
///
/// Menampilkan hanya tryout yang sudah dibeli/dimiliki oleh user
/// Dan sudah diverifikasi oleh admin (isActive: true)
class MyTryoutsScreen extends StatefulWidget {
  const MyTryoutsScreen({super.key});

  @override
  State<MyTryoutsScreen> createState() => _MyTryoutsScreenState();
}

class _MyTryoutsScreenState extends State<MyTryoutsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all'; // all | active | pending | in_progress | not_started

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase().trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            _buildMyTryoutsList(),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================
  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1CB0F6), Color(0xFF0F9CD9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.book_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Try Out Saya',
                        style: AppTextStyles.headingLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Lanjutkan perjalanan belajarmu',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SEARCH BAR
  // ==========================================================================
  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        color: const Color(0xFF1CB0F6),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F7F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              SizedBox(height: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _handleSearch,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Cari try out saya...',
                    hintStyle: AppTextStyles.bodyLarge.copyWith(
                      color: const Color(0xFFAFAFAF),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF777777),
                      size: 24,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF777777),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _handleSearch('');
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // FILTER CHIPS
  // ==========================================================================
  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'Semua',
                value: 'all',
                icon: Icons.grid_view_rounded,
              ),
              SizedBox(width: AppSpacing.sm),
              _buildFilterChip(
                label: 'Aktif',
                value: 'active',
                icon: Icons.check_circle_rounded,
              ),
              SizedBox(width: AppSpacing.sm),
              _buildFilterChip(
                label: 'Pending Review',
                value: 'pending',
                icon: Icons.schedule_rounded,
              ),
              SizedBox(width: AppSpacing.sm),
              _buildFilterChip(
                label: 'Sedang Dikerjakan',
                value: 'in_progress',
                icon: Icons.pending_actions_rounded,
              ),
              SizedBox(width: AppSpacing.sm),
              _buildFilterChip(
                label: 'Belum Dimulai',
                value: 'not_started',
                icon: Icons.play_circle_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _filterStatus == value;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : const Color(0xFF777777),
          ),
          SizedBox(width: AppSpacing.xs),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF1CB0F6),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF777777),
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF1CB0F6) : const Color(0xFFE5E5E5),
        width: 2,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    );
  }

  // ==========================================================================
  // MY TRYOUTS LIST
  // ==========================================================================
  Widget _buildMyTryoutsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_tryouts')
          .where('userId', isEqualTo: userId)
          .orderBy('lastAccessedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: _buildErrorView(snapshot.error.toString()),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(child: _buildLoadingView());
        }

        var docs = snapshot.data?.docs ?? [];

        // ✅ Filter by isActive and status
        if (_filterStatus == 'active') {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isActive'] == true;
          }).toList();
        } else if (_filterStatus == 'pending') {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final promotionProofs = data['promotionProofs'] as Map<String, dynamic>?;
            return data['isActive'] == false &&
                promotionProofs?['status'] == 'pending_review';
          }).toList();
        } else if (_filterStatus == 'in_progress') {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final subtestProgress =
                data['subtestProgress'] as Map<String, dynamic>? ?? {};
            return data['isActive'] == true && subtestProgress.isNotEmpty;
          }).toList();
        } else if (_filterStatus == 'not_started') {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final subtestProgress =
                data['subtestProgress'] as Map<String, dynamic>? ?? {};
            return data['isActive'] == true && subtestProgress.isEmpty;
          }).toList();
        }

        if (docs.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyView());
        }

        return SliverPadding(
          padding: EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: _OwnedTryoutCard(
                  userTryoutId: doc.id,
                  data: data,
                  userId: userId,
                ),
              );
            }, childCount: docs.length),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // LOADING, ERROR, EMPTY VIEWS
  // ==========================================================================
  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF1CB0F6)),
              strokeWidth: 3,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Memuat try out...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
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
              error,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF777777),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    String title;
    String subtitle;
    IconData icon;
    Color iconColor;

    switch (_filterStatus) {
      case 'pending':
        title = 'Tidak Ada Pending Review';
        subtitle = 'Semua tryout sudah diverifikasi';
        icon = Icons.check_circle_rounded;
        iconColor = const Color(0xFF58CC02);
        break;
      case 'active':
        title = 'Belum Ada Tryout Aktif';
        subtitle = 'Tryout yang sudah diverifikasi akan muncul di sini';
        icon = Icons.hourglass_empty_rounded;
        iconColor = const Color(0xFFFF9600);
        break;
      case 'not_started':
        title = 'Belum Ada Try Out Baru';
        subtitle = 'Semua try out sudah dimulai!';
        icon = Icons.celebration_rounded;
        iconColor = const Color(0xFF58CC02);
        break;
      case 'in_progress':
        title = 'Belum Ada Try Out Dikerjakan';
        subtitle = 'Mulai mengerjakan try out untuk melihatnya di sini';
        icon = Icons.pending_actions_rounded;
        iconColor = const Color(0xFFFF9600);
        break;
      default:
        title = 'Belum Ada Try Out';
        subtitle = 'Beli try out di Marketplace untuk memulai';
        icon = Icons.bookmark_border_rounded;
        iconColor = const Color(0xFF1CB0F6);
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.xl * 1.5),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 80,
                color: iconColor,
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF777777),
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
// 📖 OWNED TRYOUT CARD
// ==============================================================================
class _OwnedTryoutCard extends StatelessWidget {
  final String userTryoutId;
  final Map<String, dynamic> data;
  final String userId;

  const _OwnedTryoutCard({
    required this.userTryoutId,
    required this.data,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final tryoutId = data['tryoutId'] ?? '';
    final subtestProgress =
        data['subtestProgress'] as Map<String, dynamic>? ?? {};
    final totalAttempts = data['totalAttempts'] ?? 0;
    final isActive = data['isActive'] ?? false;
    final promotionProofs = data['promotionProofs'] as Map<String, dynamic>?;
    final reviewStatus = promotionProofs?['status'] ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tryouts')
          .doc(tryoutId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final tryoutData = snapshot.data!.data() as Map<String, dynamic>;
        final title = tryoutData['title'] ?? 'Untitled';
        final description = tryoutData['description'] ?? '';
        final isPremium = tryoutData['isPremium'] ?? false;
        final examTypeName = tryoutData['examTypeName'] ?? 'Ujian';
        final totalQuestions = tryoutData['totalQuestions'] ?? 0;
        final totalMinutes = tryoutData['totalEstimatedMinutes'] ?? 0;

        // Get subtests
        final subtests = tryoutData['subtests'] as List<dynamic>? ?? [];
        final subTestCount = subtests.length;

        // Calculate progress
        int completedSubtests = 0;
        for (var entry in subtestProgress.entries) {
          final subtestData = entry.value as Map<String, dynamic>;
          if (subtestData['status'] == 'completed') {
            completedSubtests++;
          }
        }

        final progress = subTestCount > 0
            ? ((completedSubtests / subTestCount) * 100).toInt()
            : 0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isActive
                ? () => _showSubtestsBottomSheet(
              context,
              tryoutData,
              subtestProgress,
            )
                : null,
            borderRadius: BorderRadius.circular(20),
            child: Opacity(
              opacity: isActive ? 1.0 : 0.6, // ✅ Dim if not active
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: !isActive
                        ? const Color(0xFFFF9600) // Orange for pending
                        : progress == 100
                        ? const Color(0xFF58CC02)
                        : const Color(0xFF1CB0F6),
                    width: 3,
                  ),
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
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: !isActive
                              ? [
                            const Color(0xFFFF9600),
                            const Color(0xFFFF7700),
                          ] // Orange gradient for pending
                              : progress == 100
                              ? [
                            const Color(0xFF58CC02),
                            const Color(0xFF4CAF50),
                          ]
                              : isPremium
                              ? [
                            const Color(0xFFFFD700),
                            const Color(0xFFFFA500),
                          ]
                              : [
                            const Color(0xFF1CB0F6),
                            const Color(0xFF0F9CD9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(17),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Exam Type Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 14,
                                  color: !isActive
                                      ? const Color(0xFFFF9600)
                                      : progress == 100
                                      ? const Color(0xFF58CC02)
                                      : isPremium
                                      ? const Color(0xFFFFD700)
                                      : const Color(0xFF1CB0F6),
                                ),
                                SizedBox(width: AppSpacing.xs),
                                Text(
                                  examTypeName,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: !isActive
                                        ? const Color(0xFFFF9600)
                                        : progress == 100
                                        ? const Color(0xFF58CC02)
                                        : isPremium
                                        ? const Color(0xFFFFD700)
                                        : const Color(0xFF1CB0F6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Status Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  !isActive
                                      ? Icons.schedule_rounded
                                      : progress == 100
                                      ? Icons.check_circle_rounded
                                      : subtestProgress.isEmpty
                                      ? Icons.play_circle_outline_rounded
                                      : Icons.pending_rounded,
                                  size: 14,
                                  color: !isActive
                                      ? const Color(0xFFFF9600)
                                      : progress == 100
                                      ? const Color(0xFF58CC02)
                                      : subtestProgress.isEmpty
                                      ? const Color(0xFF1CB0F6)
                                      : const Color(0xFFFF9600),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  !isActive
                                      ? 'Pending Review'
                                      : progress == 100
                                      ? 'Selesai'
                                      : subtestProgress.isEmpty
                                      ? 'Belum Dimulai'
                                      : 'Sedang Dikerjakan',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: !isActive
                                        ? const Color(0xFFFF9600)
                                        : progress == 100
                                        ? const Color(0xFF58CC02)
                                        : subtestProgress.isEmpty
                                        ? const Color(0xFF1CB0F6)
                                        : const Color(0xFFFF9600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ Pending Review Warning (if not active)
                    if (!isActive)
                      Container(
                        padding: EdgeInsets.all(AppSpacing.md),
                        color: const Color(0xFFFF9600).withOpacity(0.1),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: const Color(0xFFFF9600),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                reviewStatus == 'pending_review'
                                    ? 'Menunggu verifikasi admin untuk mengaktifkan tryout'
                                    : 'Tryout belum aktif',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFFFF9600),
                                  fontWeight: FontWeight.w600,
                                ),
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
                          // Title
                          Text(
                            title,
                            style: AppTextStyles.headingSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppSpacing.xs),

                          // Description
                          Text(
                            description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: const Color(0xFF777777),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppSpacing.md),

                          // Progress Bar (only if active)
                          if (isActive)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Progress',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF777777),
                                      ),
                                    ),
                                    Text(
                                      '$completedSubtests/$subTestCount subtes',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1CB0F6),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: AppSpacing.xs),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress / 100,
                                    backgroundColor: const Color(0xFFE5E5E5),
                                    valueColor: AlwaysStoppedAnimation(
                                      progress == 100
                                          ? const Color(0xFF58CC02)
                                          : const Color(0xFF1CB0F6),
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.md),
                              ],
                            ),

                          // Stats
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              _buildStatChip(
                                icon: Icons.quiz_rounded,
                                label: '$totalQuestions soal',
                                color: const Color(0xFF1CB0F6),
                              ),
                              _buildStatChip(
                                icon: Icons.timer_rounded,
                                label: '$totalMinutes mnt',
                                color: const Color(0xFFFF9600),
                              ),
                              if (isActive && totalAttempts > 0)
                                _buildStatChip(
                                  icon: Icons.refresh_rounded,
                                  label: '$totalAttempts percobaan',
                                  color: const Color(0xFF9333EA),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Footer - Action Button
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE5E5E5), width: 2),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isActive
                              ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TryoutDetailScreen(
                                  tryoutId: tryoutId,
                                ),
                              ),
                            );
                          }
                              : null, // ✅ Disabled if not active
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isActive
                                ? Colors.grey.shade400
                                : progress == 100
                                ? const Color(0xFF58CC02)
                                : const Color(0xFF1CB0F6),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: !isActive
                                    ? Colors.grey.shade500
                                    : progress == 100
                                    ? const Color(0xFF46A302)
                                    : const Color(0xFF0F9CD9),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                !isActive
                                    ? Icons.lock_rounded
                                    : progress == 100
                                    ? Icons.bar_chart_rounded
                                    : Icons.play_arrow_rounded,
                                size: 20,
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Text(
                                !isActive
                                    ? 'Menunggu Verifikasi'
                                    : progress == 100
                                    ? 'Lihat Hasil'
                                    : 'Mulai / Lanjutkan',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSubtestsBottomSheet(
      BuildContext context,
      Map<String, dynamic> tryoutData,
      Map<String, dynamic> subtestProgress,
      ) {
    final subtests = tryoutData['subtests'] as List<dynamic>? ?? [];
    final tryoutId = data['tryoutId'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              // Handle bar
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

              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  children: [
                    Text(
                      'Pilih Subtes',
                      style: AppTextStyles.headingMedium.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      tryoutData['title'] ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF777777),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // Subtests list
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: subtests.length,
                  separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final subtest = subtests[index] as Map<String, dynamic>;
                    final subtestId = 'subtest_$index';
                    final subtestName = subtest['name'] ?? 'Subtes ${index + 1}';
                    final category = subtest['category'] ?? 'N/A';
                    final questionCount = subtest['questionCount'] ?? 0;
                    final estimatedMinutes = subtest['estimatedMinutes'] ?? 0;

                    // Get progress
                    final progress =
                    subtestProgress[subtestId] as Map<String, dynamic>?;
                    final status = progress?['status'] ?? 'not_started';
                    final attempts = progress?['attempts'] ?? 0;
                    final bestScore = progress?['bestScore'] ?? 0;

                    return _SubtestListTile(
                      subtestId: subtestId,
                      subtestIndex: index,
                      subtestName: subtestName,
                      category: category,
                      questionCount: questionCount,
                      estimatedMinutes: estimatedMinutes,
                      status: status,
                      attempts: attempts,
                      bestScore: bestScore,
                      onTap: () {
                        Navigator.pop(context);
                        _startExam(context, tryoutId, subtestId, subtest);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startExam(
      BuildContext context,
      String tryoutId,
      String subtestId,
      Map<String, dynamic> subtestData,
      ) {
    // Update lastAccessedAt
    FirebaseFirestore.instance
        .collection('user_tryouts')
        .doc(userTryoutId)
        .update({'lastAccessedAt': FieldValue.serverTimestamp()});
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TryoutDetailScreen(tryoutId: tryoutId),
      ),
    );
  }

  Widget _buildStatChip({
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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
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
}

// (Sisanya sama - _SubtestListTile tidak berubah)

// ==============================================================================
// 📝 SUBTEST LIST TILE
// ==============================================================================
class _SubtestListTile extends StatelessWidget {
  final String subtestId;
  final int subtestIndex;
  final String subtestName;
  final String category;
  final int questionCount;
  final int estimatedMinutes;
  final String status;
  final int attempts;
  final int bestScore;
  final VoidCallback onTap;

  const _SubtestListTile({
    required this.subtestId,
    required this.subtestIndex,
    required this.subtestName,
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
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'completed':
        statusColor = const Color(0xFF58CC02);
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Selesai';
        break;
      case 'in_progress':
        statusColor = const Color(0xFFFF9600);
        statusIcon = Icons.pending_rounded;
        statusText = 'Sedang Dikerjakan';
        break;
      default:
        statusColor = const Color(0xFF1CB0F6);
        statusIcon = Icons.play_circle_outline_rounded;
        statusText = 'Mulai';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Number badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${subtestIndex + 1}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),

                // Subtest name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtestName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        category,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSpacing.sm),

            // Stats
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _buildStatChip(
                  icon: Icons.quiz_rounded,
                  label: '$questionCount soal',
                  color: const Color(0xFF1CB0F6),
                ),
                _buildStatChip(
                  icon: Icons.timer_rounded,
                  label: '$estimatedMinutes mnt',
                  color: const Color(0xFFFF9600),
                ),
                if (attempts > 0)
                  _buildStatChip(
                    icon: Icons.refresh_rounded,
                    label: '$attempts x',
                    color: const Color(0xFF9333EA),
                  ),
                if (bestScore > 0)
                  _buildStatChip(
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

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
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
