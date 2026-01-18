// lib/features/leaderboard/screens/leaderboard_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';

/// Leaderboard Screen - Duolingo Style
///
/// Responsive design:
/// - Mobile: < 600px (single column)
/// - Tablet: 600-1024px (optimized spacing)
/// - Desktop: > 1024px (max width 800px, centered)
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<LeaderboardUser> _xpLeaderboard = [];
  List<LeaderboardUser> _streakLeaderboard = [];
  LeaderboardUser? _currentUser;
  int _currentUserXPRank = 0;
  int _currentUserStreakRank = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      // ✅ Query top 100 by XP
      final xpSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('xp', descending: true)
          .limit(100)
          .get();

      // ✅ Query top 100 by Streak
      final streakSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('streak', descending: true)
          .limit(100)
          .get();

      final xpUsers = xpSnapshot.docs
          .asMap()
          .entries
          .map((entry) => LeaderboardUser.fromDoc(entry.value, entry.key + 1))
          .toList();

      final streakUsers = streakSnapshot.docs
          .asMap()
          .entries
          .map((entry) => LeaderboardUser.fromDoc(entry.value, entry.key + 1))
          .toList();

      // ✅ Find current user & calculate rank
      LeaderboardUser? currentUser;
      int xpRank = 0;
      int streakRank = 0;

      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final userXP = (userData['xp'] as num?)?.toInt() ?? 0;
          final userStreak = (userData['streak'] as num?)?.toInt() ?? 0;

          // Calculate XP rank
          final higherXP = await FirebaseFirestore.instance
              .collection('users')
              .where('xp', isGreaterThan: userXP)
              .get();
          xpRank = higherXP.docs.length + 1;

          // Calculate Streak rank
          final higherStreak = await FirebaseFirestore.instance
              .collection('users')
              .where('streak', isGreaterThan: userStreak)
              .get();
          streakRank = higherStreak.docs.length + 1;

          currentUser = LeaderboardUser.fromDoc(userDoc, xpRank);
        }
      }

      if (mounted) {
        setState(() {
          _xpLeaderboard = xpUsers;
          _streakLeaderboard = streakUsers;
          _currentUser = currentUser;
          _currentUserXPRank = xpRank;
          _currentUserStreakRank = streakRank;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
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
              _buildTabBar(),
              if (_currentUser != null) _buildCurrentUserCard(),
              Expanded(child: _buildContent()),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.premiumGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('Leaderboard', style: AppTextStyles.headingMedium),
          const Spacer(),
          IconButton(
            onPressed: _loadLeaderboard,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: AppTextStyles.labelLarge,
        tabs: const [
          Tab(text: 'Top XP'),
          Tab(text: 'Top Streak'),
        ],
      ),
    );
  }

  Widget _buildCurrentUserCard() {
    final currentRank = _tabController.index == 0
        ? _currentUserXPRank
        : _currentUserStreakRank;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 3),
      ),
      child: Row(
        children: [
          _buildRankBadge(currentRank, isCurrentUser: true),
          const SizedBox(width: AppSpacing.md),
          _buildAvatar(_currentUser!.displayName, size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser!.displayName,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Peringkat Kamu',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    _tabController.index == 0
                        ? Icons.star_rounded
                        : Icons.local_fire_department_rounded,
                    color: _tabController.index == 0
                        ? AppColors.gold
                        : AppColors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _tabController.index == 0
                        ? '${_currentUser!.totalXP}'
                        : '${_currentUser!.currentStreak}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: _tabController.index == 0
                          ? AppColors.gold
                          : AppColors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                _tabController.index == 0 ? 'XP' : 'Hari',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildLeaderboardList(_xpLeaderboard, type: LeaderboardType.xp),
        _buildLeaderboardList(_streakLeaderboard, type: LeaderboardType.streak),
      ],
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardUser> users, {required LeaderboardType type}) {
    if (users.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final isCurrentUser = user.userId == FirebaseAuth.instance.currentUser?.uid;

          return _LeaderboardItem(
            user: user,
            isCurrentUser: isCurrentUser,
            type: type,
          );
        },
      ),
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
                Icons.emoji_events_outlined,
                size: 60,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Belum Ada Data', style: AppTextStyles.headingMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Leaderboard akan muncul setelah ada aktivitas',
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

  Widget _buildRankBadge(int rank, {bool isCurrentUser = false}) {
    Color color;
    IconData? icon;

    if (rank == 1) {
      color = AppColors.gold;
      icon = Icons.emoji_events_rounded;
    } else if (rank == 2) {
      color = AppColors.gray400;
      icon = Icons.emoji_events_rounded;
    } else if (rank == 3) {
      color = const Color(0xFFCD7F32); // Bronze
      icon = Icons.emoji_events_rounded;
    } else {
      color = isCurrentUser ? AppColors.primary : AppColors.gray600;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: color, size: 24)
            : Text(
          '$rank',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String displayName, {double size = 40}) {
    // ✅ Generate avatar dari initial nama
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'U';

    final colors = [
      AppColors.primary,
      AppColors.blue,
      AppColors.green,
      AppColors.orange,
      AppColors.purple,
      AppColors.twk,
      AppColors.tiu,
      AppColors.tkp,
    ];

    final colorIndex = displayName.hashCode % colors.length;
    final backgroundColor = colors[colorIndex.abs()];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: backgroundColor, width: 2),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: backgroundColor,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// LEADERBOARD ITEM
// ==============================================================================

enum LeaderboardType { xp, streak }

class _LeaderboardItem extends StatelessWidget {
  final LeaderboardUser user;
  final bool isCurrentUser;
  final LeaderboardType type;

  const _LeaderboardItem({
    required this.user,
    required this.isCurrentUser,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser ? AppColors.primary : AppColors.border,
          width: isCurrentUser ? 3 : 2,
        ),
        boxShadow: isCurrentUser
            ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Row(
        children: [
          _buildRankBadge(user.rank),
          const SizedBox(width: AppSpacing.md),
          _buildAvatar(user.displayName),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Icon(Icons.quiz_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${user.totalExams} ujian',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (type == LeaderboardType.xp && user.currentStreak > 0) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.local_fire_department_rounded,
                          size: 14, color: AppColors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${user.currentStreak}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    type == LeaderboardType.xp
                        ? Icons.star_rounded
                        : Icons.local_fire_department_rounded,
                    color: type == LeaderboardType.xp
                        ? AppColors.gold
                        : AppColors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    type == LeaderboardType.xp
                        ? '${user.totalXP}'
                        : '${user.currentStreak}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: type == LeaderboardType.xp
                          ? AppColors.gold
                          : AppColors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                type == LeaderboardType.xp ? 'XP' : 'Hari',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    IconData? icon;

    if (rank == 1) {
      color = AppColors.gold;
      icon = Icons.emoji_events_rounded;
    } else if (rank == 2) {
      color = AppColors.gray400;
      icon = Icons.emoji_events_rounded;
    } else if (rank == 3) {
      color = const Color(0xFFCD7F32);
      icon = Icons.emoji_events_rounded;
    } else {
      color = isCurrentUser ? AppColors.primary : AppColors.gray600;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: color, size: 24)
            : Text(
          '$rank',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String displayName) {
    final initial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'U';

    final colors = [
      AppColors.primary,
      AppColors.blue,
      AppColors.green,
      AppColors.orange,
      AppColors.purple,
      AppColors.twk,
      AppColors.tiu,
      AppColors.tkp,
    ];

    final colorIndex = displayName.hashCode % colors.length;
    final backgroundColor = colors[colorIndex.abs()];

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: backgroundColor, width: 2),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: backgroundColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
              constraints: const BoxConstraints(maxWidth: 800),
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }
}

// ==============================================================================
// LEADERBOARD USER MODEL
// ==============================================================================

class LeaderboardUser {
  final String userId;
  final String displayName;
  final int totalXP;
  final int totalExams;
  final int currentStreak;
  final int rank;

  LeaderboardUser({
    required this.userId,
    required this.displayName,
    required this.totalXP,
    required this.totalExams,
    required this.currentStreak,
    required this.rank,
  });

  factory LeaderboardUser.fromDoc(DocumentSnapshot doc, int rank) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final stats = data['stats'] as Map<String, dynamic>? ?? {};

    return LeaderboardUser(
      userId: doc.id,
      displayName: data['displayName'] as String? ?? 'User',
      totalXP: (data['xp'] as num?)?.toInt() ?? 0,
      totalExams: (stats['totalExams'] as num?)?.toInt() ?? 0,
      currentStreak: (data['streak'] as num?)?.toInt() ?? 0,
      rank: rank,
    );
  }
}