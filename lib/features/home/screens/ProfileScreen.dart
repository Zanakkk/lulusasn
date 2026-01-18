// lib/features/profile/screens/profile_screen.dart

// ignore_for_file: file_names, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lulusasn/core/services/firebase_service.dart';
import 'package:lulusasn/app/routes.dart';

import '../../seed/seedscreen.dart';

/// Profile Screen - Duolingo Style
///
/// Features:
/// - User info dengan avatar dan premium badge
/// - Stats overview (XP, Level, Streak)
/// - Progress bars untuk setiap kategori
/// - Settings quick access
/// - Premium upgrade CTA
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<QuerySnapshot>? _examsSubscription;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _calculatedStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initUserDataStream();
    _initExamsStream();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _examsSubscription?.cancel();
    super.dispose();
  }

  void _initUserDataStream() {
    final userId = FirebaseService.instance.currentUser?.uid;
    if (userId == null) return;

    _userSubscription = FirebaseService.instance.firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted && snapshot.exists) {
              setState(() {
                _userData = snapshot.data();
                if (_calculatedStats != null) _isLoading = false;
              });
            }
          },
          onError: (error) {
            debugPrint('Error streaming user data: $error');
            setState(() => _isLoading = false);
          },
        );
  }

  void _initExamsStream() {
    final userId = FirebaseService.instance.currentUser?.uid;
    if (userId == null) return;

    _examsSubscription = FirebaseService.instance.firestore
        .collection('users')
        .doc(userId)
        .collection('exams')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() {
                _calculatedStats = _calculateStatsFromExams(snapshot.docs);
                if (_userData != null) _isLoading = false;
              });
            }
          },
          onError: (error) {
            debugPrint('Error streaming exams data: $error');
            setState(() {
              _calculatedStats = _getEmptyStats();
              if (_userData != null) _isLoading = false;
            });
          },
        );
  }

  Map<String, dynamic> _calculateStatsFromExams(
    List<QueryDocumentSnapshot> examDocs,
  ) {
    if (examDocs.isEmpty) return _getEmptyStats();

    int totalExams = examDocs.length;
    int totalQuestions = 0;
    int totalCorrect = 0;

    Map<String, Map<String, int>> categoryStats = {
      'TWK': {'total': 0, 'correct': 0},
      'TIU': {'total': 0, 'correct': 0},
      'TKP': {'total': 0, 'correct': 0},
    };

    for (var doc in examDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final answers = data['answers'] as List<dynamic>? ?? [];

      for (var answer in answers) {
        final answerMap = answer as Map<String, dynamic>;
        final category = answerMap['category'] as String? ?? '';
        final isCorrect = answerMap['isCorrect'] as bool? ?? false;

        totalQuestions++;
        if (isCorrect) totalCorrect++;

        if (categoryStats.containsKey(category)) {
          categoryStats[category]!['total'] =
              (categoryStats[category]!['total'] ?? 0) + 1;
          if (isCorrect) {
            categoryStats[category]!['correct'] =
                (categoryStats[category]!['correct'] ?? 0) + 1;
          }
        }
      }
    }

    return {
      'totalExams': totalExams,
      'totalQuestions': totalQuestions,
      'totalCorrect': totalCorrect,
      'byCategory': categoryStats,
    };
  }

  Map<String, dynamic> _getEmptyStats() {
    return {
      'totalExams': 0,
      'totalQuestions': 0,
      'totalCorrect': 0,
      'byCategory': {
        'TWK': {'total': 0, 'correct': 0},
        'TIU': {'total': 0, 'correct': 0},
        'TKP': {'total': 0, 'correct': 0},
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Color(0xFF58CC02),
          ),
        ),
      );
    }

    if (_userData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8FA),
        body: Center(child: Text('Data tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  _buildCategoryProgress(),
                  const SizedBox(height: 24),
                  _buildEnergySection(),
                  const SizedBox(height: 24),
                  if (!(_userData!['isPremium'] as bool? ?? false))
                    _buildPremiumCTA(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // APP BAR
  // ============================================================================

  Widget _buildAppBar() {
    final displayName = _userData!['displayName'] as String? ?? 'User';
    final photoURL = _userData!['photoURL'] as String? ?? '';
    final isPremium = _userData!['isPremium'] as bool? ?? false;
    final email = _userData!['email'] as String? ?? '';
    final createdAt = (_userData!['createdAt'] as Timestamp?)?.toDate();
    final memberSince = createdAt != null
        ? 'Bergabung ${_formatDate(createdAt)}'
        : 'Member baru';

    return SliverAppBar(
      automaticallyImplyLeading: false, // ⬅️ ini kuncinya
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPremium
                  ? [const Color(0xFFFFFBF0), const Color(0xFFFFF5D6)]
                  : [const Color(0xFF58CC02), const Color(0xFF46A302)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: photoURL.isEmpty
                            ? Container(
                                color: Colors.white,
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 60,
                                  color: isPremium
                                      ? const Color(0xFFFFD700)
                                      : const Color(0xFF58CC02),
                                ),
                              )
                            : Image.network(
                                photoURL,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.white,
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 60,
                                    color: Color(0xFF58CC02),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (isPremium)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isPremium ? const Color(0xFF3C3C3C) : Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPremium
                        ? const Color(0xFF666666)
                        : Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                // Member since
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPremium
                        ? const Color(0xFFFFD700).withOpacity(0.2)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    memberSince,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isPremium ? const Color(0xFF3C3C3C) : Colors.white,
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
  // STATS CARDS
  // ============================================================================

  Widget _buildStatsCards() {
    final xp = _userData!['xp'] as int? ?? 0;
    final level = _userData!['level'] as int? ?? 1;
    final streak = _userData!['streak'] as int? ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.auto_awesome_rounded,
            label: 'XP',
            value: '$xp',
            gradient: const LinearGradient(
              colors: [Color(0xFF58CC02), Color(0xFF46A302)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up_rounded,
            label: 'Level',
            value: '$level',
            gradient: const LinearGradient(
              colors: [Color(0xFF1CB0F6), Color(0xFF0A8FDB)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Streak',
            value: '$streak',
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9500), Color(0xFFFF6B00)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF3C3C3C),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // CATEGORY PROGRESS
  // ============================================================================

  Widget _buildCategoryProgress() {
    final stats = _calculatedStats ?? _getEmptyStats();
    final byCategory = stats['byCategory'] as Map<String, dynamic>;
    final totalExams = stats['totalExams'] as int;
    final totalCorrect = stats['totalCorrect'] as int;
    final totalQuestions = stats['totalQuestions'] as int;
    final overallAccuracy = totalQuestions > 0
        ? (totalCorrect / totalQuestions * 100).toInt()
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                  color: const Color(0xFF1CB0F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFF1CB0F6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Statistik Latihan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3C3C3C),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SeedDataScreen()),
                  );
                },
                child: Text('seed'),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.statistics),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1CB0F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Detail',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1CB0F6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Overall stats
          Row(
            children: [
              Expanded(child: _buildMiniStat('Ujian', '$totalExams')),
              const SizedBox(width: 12),
              Expanded(child: _buildMiniStat('Soal', '$totalQuestions')),
              const SizedBox(width: 12),
              Expanded(child: _buildMiniStat('Akurasi', '$overallAccuracy%')),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
          const SizedBox(height: 20),
          // Category breakdown
          _buildCategoryItem('TWK', byCategory['TWK'] as Map<String, dynamic>?),
          const SizedBox(height: 12),
          _buildCategoryItem('TIU', byCategory['TIU'] as Map<String, dynamic>?),
          const SizedBox(height: 12),
          _buildCategoryItem('TKP', byCategory['TKP'] as Map<String, dynamic>?),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3C3C3C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String category, Map<String, dynamic>? data) {
    final total = data?['total'] as int? ?? 0;
    final correct = data?['correct'] as int? ?? 0;
    final accuracy = total > 0 ? (correct / total * 100).toInt() : 0;

    Color categoryColor;
    switch (category) {
      case 'TWK':
        categoryColor = const Color(0xFFFF4B4B);
        break;
      case 'TIU':
        categoryColor = const Color(0xFF1CB0F6);
        break;
      case 'TKP':
        categoryColor = const Color(0xFF58CC02);
        break;
      default:
        categoryColor = Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: categoryColor,
              ),
            ),
            Text(
              '$accuracy%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3C3C3C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E5E5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: total > 0 ? (accuracy / 100) : 0,
            child: Container(
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$correct benar dari $total soal',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // ENERGY SECTION
  // ============================================================================

  Widget _buildEnergySection() {
    final energy = _userData!['energy'] as Map<String, dynamic>?;
    final current = energy?['current'] as int? ?? 0;
    final max = energy?['max'] as int? ?? 5;
    final totalUsed = energy?['totalUsed'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEFEF), Color(0xFFFFE5E5)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF4B4B), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF4B4B), Color(0xFFFF6B6B)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Energy',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3C3C3C),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: current / max,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF4B4B), Color(0xFFFF6B6B)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$current / $max',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3C3C3C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Total digunakan: $totalUsed energy',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
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
  // SETTINGS SECTION
  // ============================================================================

  // ============================================================================
  // PREMIUM CTA
  // ============================================================================

  Widget _buildPremiumCTA() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.premium),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFBF0), Color(0xFFFFF5D6)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD700), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade ke PRO',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3C3C3C),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Unlimited energy & fitur eksklusif',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFFFFD700),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
