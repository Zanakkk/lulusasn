// lib/features/main_navigation/widgets/app_bar_widget.dart

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lulusasn/core/services/firebase_service.dart';
import 'package:lulusasn/app/routes.dart';

/// Global App Bar - Duolingo Style
///
/// Features:
/// - Real-time energy tracking with auto-save to Firestore
/// - Streak display with animations
/// - Profile menu with logout
/// - Premium status indicator
/// - Responsive design (mobile/tablet/desktop)
///
/// Usage:
/// ```dart
/// appBar: const GlobalAppBar()
/// ```
class GlobalAppBar extends StatefulWidget implements PreferredSizeWidget {
  const GlobalAppBar({super.key});

  @override
  State<GlobalAppBar> createState() => _GlobalAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(72);
}

class _GlobalAppBarState extends State<GlobalAppBar> {
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  Timer? _energyTimer;

  // User data
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initUserDataStream();
    _startEnergyRegenTimer();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _energyTimer?.cancel();
    super.dispose();
  }

  // ============================================================================
  // FIRESTORE REAL-TIME STREAM
  // ============================================================================

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
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            debugPrint('Error streaming user data: $error');
            setState(() => _isLoading = false);
          },
        );
  }

  // ============================================================================
  // ENERGY REGENERATION TIMER
  // ============================================================================

  void _startEnergyRegenTimer() {
    _energyTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || _userData == null) return;

      final isPremium = _userData!['isPremium'] as bool? ?? false;
      if (isPremium) return; // Premium users have unlimited energy

      final energyData = _userData!['energy'] as Map<String, dynamic>?;
      if (energyData == null) return;

      final current = energyData['current'] as int? ?? 0;
      final max = energyData['max'] as int? ?? 5;
      final regenRate = energyData['regenRate'] as int? ?? 10; // minutes
      final lastRegen = (energyData['lastRegen'] as Timestamp?)?.toDate();

      if (lastRegen == null || current >= max) return;

      final now = DateTime.now();
      final minutesSinceRegen = now.difference(lastRegen).inMinutes;
      final energyToAdd = minutesSinceRegen ~/ regenRate;

      if (energyToAdd > 0) {
        final newEnergy = (current + energyToAdd).clamp(0, max);
        await _updateEnergyInFirestore(newEnergy, now);
      } else {
        // Just update UI for countdown animation
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _updateEnergyInFirestore(int newEnergy, DateTime now) async {
    final userId = FirebaseService.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseService.instance.firestore
          .collection('users')
          .doc(userId)
          .update({
            'energy.current': newEnergy,
            'energy.lastRegen': Timestamp.fromDate(now),
          });
    } catch (e) {
      debugPrint('Error updating energy: $e');
    }
  }

  // ============================================================================
  // BUILD UI
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      toolbarHeight: isMobile ? 64 : 72,
      automaticallyImplyLeading: false,
      title: _buildLogo(isMobile),
      actions: [
        if (!_isLoading && _userData != null) ...[
          _buildStreakWidget(isMobile),
          const SizedBox(width: 8),
          _buildEnergyWidget(isMobile),
          const SizedBox(width: 12),
        ],
        _buildProfileMenu(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLogo(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/Logo.jpg',
        height: isMobile ? 28 : 32,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return Text(
            'LULUS',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          );
        },
      ),
    );
  }

  // ============================================================================
  // STREAK WIDGET
  // ============================================================================

  Widget _buildStreakWidget(bool isMobile) {
    final streak = _userData!['streak'] as int? ?? 0;
    final longestStreak = _userData!['longestStreak'] as int? ?? 0;

    return GestureDetector(
      onTap: () => _showStreakDialog(streak, longestStreak),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF4E6), Color(0xFFFFEDD5)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF9500), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9500).withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: const Color(0xFFFF9500),
              size: isMobile ? 18 : 20,
            ),
            const SizedBox(width: 6),
            Text(
              '$streak',
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF3C3C3C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // ENERGY WIDGET
  // ============================================================================

  Widget _buildEnergyWidget(bool isMobile) {
    final isPremium = _userData!['isPremium'] as bool? ?? false;
    final energyData = _userData!['energy'] as Map<String, dynamic>?;

    if (energyData == null) return const SizedBox.shrink();

    final current = energyData['current'] as int? ?? 0;
    final max = energyData['max'] as int? ?? 5;
    final regenRate = energyData['regenRate'] as int? ?? 10;
    final lastRegen = (energyData['lastRegen'] as Timestamp?)?.toDate();

    final isFull = current >= max;
    String timeText = '';
    double progress = 0.0;

    if (!isPremium && !isFull && lastRegen != null) {
      final now = DateTime.now();
      final secondsSinceRegen = now.difference(lastRegen).inSeconds;
      final secondsPerEnergy = regenRate * 60;
      final secondsInCycle = secondsSinceRegen % secondsPerEnergy;
      final secondsRemaining = secondsPerEnergy - secondsInCycle;

      final minutes = secondsRemaining ~/ 60;
      final seconds = secondsRemaining % 60;
      timeText =
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      progress = secondsInCycle / secondsPerEnergy;
    }

    return GestureDetector(
      onTap: () => _showEnergyDialog(
        isPremium,
        current,
        max,
        timeText,
        progress,
        regenRate,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          gradient: isPremium
              ? const LinearGradient(
                  colors: [Color(0xFFFFFBF0), Color(0xFFFFF5D6)],
                )
              : const LinearGradient(colors: [Colors.white, Color(0xFFFFFAFA)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPremium
                ? const Color(0xFFFFD700)
                : const Color(0xFFE5E5E5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isPremium ? const Color(0xFFFFD700) : Colors.black)
                  .withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPremium ? Icons.bolt_rounded : Icons.favorite_rounded,
              color: isPremium
                  ? const Color(0xFFFFD700)
                  : const Color(0xFFFF4B4B),
              size: isMobile ? 20 : 22,
            ),
            const SizedBox(width: 8),
            if (isPremium)
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ).createShader(bounds),
                child: Text(
                  '∞',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$current',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3C3C3C),
                      height: 1.0,
                    ),
                  ),
                  if (!isFull) ...[
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E5E5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF4B4B),
                                    Color(0xFFFF6B6B),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[500],
                            height: 1.0,
                            letterSpacing: 0.3,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // PROFILE MENU
  // ============================================================================

  Widget _buildProfileMenu() {
    final displayName = _userData?['displayName'] as String? ?? 'User';
    final photoURL = _userData?['photoURL'] as String? ?? '';
    final isPremium = _userData?['isPremium'] as bool? ?? false;

    return PopupMenuButton<String>(
      offset: const Offset(0, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: isPremium
              ? const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                )
              : LinearGradient(colors: [Colors.grey[300]!, Colors.grey[200]!]),
          shape: BoxShape.circle,
          border: Border.all(
            color: isPremium ? const Color(0xFFFFD700) : Colors.grey[400]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isPremium ? const Color(0xFFFFD700) : Colors.grey)
                  .withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: photoURL.isEmpty
            ? Icon(
                Icons.person_rounded,
                size: 20,
                color: isPremium ? Colors.white : Colors.grey[700],
              )
            : ClipOval(
                child: Image.network(
                  photoURL,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.person_rounded,
                    size: 20,
                    color: isPremium ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3C3C3C),
                ),
              ),
              if (isPremium) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 12),
              const Text(
                'Profil',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 20,
                color: Color(0xFFFF4B4B),
              ),
              const SizedBox(width: 12),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF4B4B),
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'profile') {
          Navigator.pushNamed(context, AppRoutes.profile);
        } else if (value == 'logout') {
          _showLogoutDialog();
        }
      },
    );
  }

  // ============================================================================
  // DIALOGS
  // ============================================================================

  void _showStreakDialog(int streak, int longestStreak) {
    final now = DateTime.now();
    final lastActiveDate = _userData!['lastActiveDate'] as String? ?? '';
    final isActiveToday =
        lastActiveDate ==
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFF4E6), Color(0xFFFFEDD5)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9500), Color(0xFFFF6B00)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9500).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$streak',
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3C3C3C),
                            height: 1.0,
                            letterSpacing: -2,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            'hari',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Streak Saat Ini',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            Icons.emoji_events_rounded,
                            const Color(0xFFFFD700),
                            '$longestStreak',
                            'Terlama',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            isActiveToday
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                            isActiveToday
                                ? const Color(0xFF58CC02)
                                : const Color(0xFFFFA500),
                            isActiveToday ? 'Aktif' : 'Belum',
                            'Hari Ini',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF58CC02),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnergyDialog(
    bool isPremium,
    int current,
    int max,
    String timeText,
    double progress,
    int regenRate,
  ) {
    showDialog(
      context: context,
      builder: (context) => _EnergyDialog(
        isPremium: isPremium,
        current: current,
        max: max,
        timeText: timeText,
        progress: progress,
        regenRate: regenRate,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF3C3C3C),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseService.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3C3C3C),
            ),
          ),
          const SizedBox(height: 2),
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
}

// ============================================================================
// ENERGY DIALOG - Stateful dengan Real-time Countdown
// ============================================================================

class _EnergyDialog extends StatefulWidget {
  final bool isPremium;
  final int current;
  final int max;
  final String timeText;
  final double progress;
  final int regenRate;

  const _EnergyDialog({
    required this.isPremium,
    required this.current,
    required this.max,
    required this.timeText,
    required this.progress,
    required this.regenRate,
  });

  @override
  State<_EnergyDialog> createState() => _EnergyDialogState();
}

class _EnergyDialogState extends State<_EnergyDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    if (!widget.isPremium && widget.current < widget.max) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: widget.isPremium
                  ? _buildPremiumContent()
                  : _buildFreeContent(),
            ),
            _buildCloseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isPremium
              ? [const Color(0xFFFFFBF0), const Color(0xFFFFF5D6)]
              : [const Color(0xFFFFEFEF), const Color(0xFFFFE5E5)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              widget.isPremium ? Icons.bolt_rounded : Icons.favorite_rounded,
              color: widget.isPremium
                  ? const Color(0xFFFFD700)
                  : const Color(0xFFFF4B4B),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isPremium ? 'Unlimited Energy' : 'Energy System',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3C3C3C),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  widget.isPremium ? 'Premium Member' : 'Free Member',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.all_inclusive_rounded,
            size: 48,
            color: Color(0xFFFFD700),
          ),
          const SizedBox(height: 16),
          const Text(
            'Energy Tanpa Batas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3C3C3C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Latihan sepuasnya tanpa batas waktu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeContent() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${widget.current}',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3C3C3C),
                letterSpacing: -2,
                height: 1.0,
              ),
            ),
            Text(
              ' / ${widget.max}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widget.current / widget.max,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF4B4B), Color(0xFFFF6B6B)],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                      widget.max,
                      (i) => Icon(
                        i < widget.current
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: i < widget.current
                            ? Colors.white
                            : Colors.grey[400],
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.autorenew_rounded,
                      color: Color(0xFF58CC02),
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.regenRate} min',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3C3C3C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Per Energy',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.current < widget.max) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFFFF4B4B),
                        size: 28,
                      ),
                      const SizedBox(height: 8),

                      _LiveCountdown(
                        regenRate: widget.regenRate,
                      ), // ✅ LIVE UPDATE
                      const SizedBox(height: 2),
                      Text(
                        'Berikutnya',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.premium);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBF0), Color(0xFFFFF5D6)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Upgrade ke PRO',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3C3C3C),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF58CC02),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Tutup',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// LIVE COUNTDOWN WIDGET - Update setiap detik
// ============================================================================

class _LiveCountdown extends StatefulWidget {
  final int regenRate;

  const _LiveCountdown({required this.regenRate});

  @override
  State<_LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<_LiveCountdown> {
  late Timer _timer;
  String _timeText = '00:00';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(_updateTime);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() async {
    final userId = FirebaseService.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await FirebaseService.instance.firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists || !mounted) return;

      final userData = doc.data()!;
      final energyData = userData['energy'] as Map<String, dynamic>?;
      if (energyData == null) return;

      final lastRegen = (energyData['lastRegen'] as Timestamp?)?.toDate();
      if (lastRegen == null) return;

      final now = DateTime.now();
      final secondsSinceRegen = now.difference(lastRegen).inSeconds;
      final secondsPerEnergy = widget.regenRate * 60;
      final secondsInCycle = secondsSinceRegen % secondsPerEnergy;
      final secondsRemaining = secondsPerEnergy - secondsInCycle;

      final minutes = secondsRemaining ~/ 60;
      final seconds = secondsRemaining % 60;

      setState(() {
        _timeText =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      });
    } catch (e) {
      debugPrint('Error updating countdown: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _timeText,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF3C3C3C),
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
