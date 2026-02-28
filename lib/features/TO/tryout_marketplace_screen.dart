// lib/features/tryout/screens/tryout_marketplace_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

// lib/features/tryout/screens/tryout_marketplace_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/constants/text_styles.dart';

// lib/features/tryout/screens/tryout_marketplace_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/constants/text_styles.dart';

final currencyFormatter = NumberFormat.currency(
  symbol: 'Rp ',
  decimalDigits: 0,
);

class TryoutMarketplaceScreen extends StatefulWidget {
  const TryoutMarketplaceScreen({super.key});

  @override
  State<TryoutMarketplaceScreen> createState() =>
      _TryoutMarketplaceScreenState();
}

class _TryoutMarketplaceScreenState extends State<TryoutMarketplaceScreen> {
  String _filter = 'all'; // all | free | premium
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _handleSearch(String q) =>
      setState(() => _searchQuery = q.toLowerCase().trim());

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
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
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF58CC02), Color(0xFF3DA800)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF58CC02).withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Marketplace',
                style: AppTextStyles.headingLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              Text(
                'Temukan try out terbaik untukmu 🎯',
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

  // ── Search bar ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _handleSearch,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            hintText: 'Cari try out...',
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFB0BAC9)),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFFB0BAC9),
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _handleSearch('');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFFB0BAC9),
                      size: 18,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  // ── Filter chips ─────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    const chips = [
      ('all', 'Semua', Icons.grid_view_rounded),
      ('free', 'Gratis', Icons.card_giftcard_rounded),
      ('premium', 'Premium', Icons.workspace_premium_rounded),
    ];

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: chips.map((c) {
          final sel = _filter == c.$1;
          const green = Color(0xFF58CC02);
          return GestureDetector(
            onTap: () => setState(() => _filter = c.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: sel ? green : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: sel
                        ? green.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: sel ? 8 : 4,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    c.$3,
                    size: 13,
                    color: sel ? Colors.white : const Color(0xFF8A94A6),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    c.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : const Color(0xFF8A94A6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────────
  Widget _buildList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tryouts')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF58CC02),
              strokeWidth: 3,
            ),
          );
        }
        if (snap.hasError) {
          return _buildStatusView(
            icon: Icons.error_outline_rounded,
            color: const Color(0xFFFF4B4B),
            title: 'Terjadi Kesalahan',
            subtitle: snap.error.toString(),
          );
        }

        var docs = snap.data?.docs ?? [];

        if (_filter == 'free') {
          docs = docs
              .where(
                (d) => (d.data() as Map<String, dynamic>)['isPremium'] == false,
              )
              .toList();
        } else if (_filter == 'premium') {
          docs = docs
              .where(
                (d) => (d.data() as Map<String, dynamic>)['isPremium'] == true,
              )
              .toList();
        }

        if (_searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return ['title', 'description', 'examTypeName'].any(
              (k) => (data[k] ?? '').toString().toLowerCase().contains(
                _searchQuery,
              ),
            );
          }).toList();
        }

        if (docs.isEmpty) {
          return _buildStatusView(
            icon: Icons.shopping_bag_outlined,
            color: const Color(0xFF58CC02),
            title: 'Belum Ada Try Out',
            subtitle: 'Try out akan segera ditambahkan!',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: const Color(0xFF58CC02),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _MarketplaceCard(
                tryoutId: docs[i].id,
                data: data,
                userId: userId,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusView({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Center(
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
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8A94A6)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Marketplace Card
// =============================================================================
class _MarketplaceCard extends StatelessWidget {
  final String tryoutId;
  final Map<String, dynamic> data;
  final String userId;

  const _MarketplaceCard({
    required this.tryoutId,
    required this.data,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Untitled';
    final description = data['description'] as String? ?? '';
    final examTypeName = data['examTypeName'] as String? ?? '';
    final isPremium = data['isPremium'] as bool? ?? false;
    final price = data['price'] as int? ?? 0;
    final totalQuestions = data['totalQuestions'] as int? ?? 0;
    final totalMinutes = data['totalEstimatedMinutes'] as int? ?? 0;
    final subtests = data['subtests'] as List<dynamic>? ?? [];

    // Check ownership
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('user_tryouts')
          .where('userId', isEqualTo: userId)
          .where('tryoutId', isEqualTo: tryoutId)
          .limit(1)
          .get(),
      builder: (context, snap) {
        final owned = (snap.data?.docs.isNotEmpty) ?? false;

        final colors = isPremium
            ? [const Color(0xFFFFB347), const Color(0xFFFF6B35)]
            : [const Color(0xFF43E97B), const Color(0xFF38F9D7)];

        return GestureDetector(
          onTap: () {
            if (!owned) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TryoutPurchaseScreen(
                    tryoutId: tryoutId,
                    tryoutTitle: title,
                    tryoutDescription: description,
                    isPremium: isPremium,
                    energyCost: price,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('✅ Kamu sudah memiliki Try Out ini!'),
                  backgroundColor: const Color(0xFF58CC02),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
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
                  // Colored top strip
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row: exam badge + premium/free pill
                        Row(
                          children: [
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
                            // Premium / Gratis pill
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
                                    isPremium
                                        ? Icons.workspace_premium_rounded
                                        : Icons.card_giftcard_rounded,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isPremium ? 'Premium' : 'Gratis',
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

                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8A94A6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 10),

                        // Stats row
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
                              label: '${subtests.length} subtes',
                              color: const Color(0xFF58CC02),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Price + CTA row
                        Row(
                          children: [
                            // Price
                            Text(
                              isPremium
                                  ? currencyFormatter.format(price)
                                  : 'GRATIS',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: colors[0],
                              ),
                            ),
                            const Spacer(),
                            // CTA button
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                gradient: owned
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF8A94A6),
                                          Color(0xFF6B7280),
                                        ],
                                      )
                                    : LinearGradient(colors: colors),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (owned
                                                ? const Color(0xFF8A94A6)
                                                : colors[0])
                                            .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                owned ? 'Dimiliki' : 'Beli Sekarang',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
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
// Mini Stat widget (reusable)
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
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8A94A6),
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// 🛒 MARKETPLACE TRYOUT CARD
// ==============================================================================
class _MarketplaceTryoutCard extends StatelessWidget {
  final String tryoutId;
  final Map<String, dynamic> data;
  final String userId;

  const _MarketplaceTryoutCard({
    required this.tryoutId,
    required this.data,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled';
    final description = data['description'] ?? '';
    final isPremium = data['isPremium'] ?? false;
    final examTypeName = data['examTypeName'] ?? 'Ujian';
    final totalQuestions = data['totalQuestions'] ?? 0;
    final totalMinutes = data['totalEstimatedMinutes'] ?? 0;
    final subTestCount = data['subTestCount'] ?? 0;
    final price = data['price'] ?? 1;

    // Cek apakah user sudah memiliki tryout ini
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_tryouts')
          .doc('${userId}_tryout_$tryoutId')
          .snapshots(),
      builder: (context, snapshot) {
        final isOwned = snapshot.hasData && snapshot.data!.exists;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _handleCardTap(context, isOwned);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOwned
                      ? const Color(0xFF58CC02)
                      : const Color(0xFFE5E5E5),
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
                        colors: isPremium
                            ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                            : [
                                const Color(0xFF58CC02),
                                const Color(0xFF4CAF50),
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
                        // Exam Type
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
                                color: isPremium
                                    ? const Color(0xFFFFD700)
                                    : const Color(0xFF58CC02),
                              ),
                              SizedBox(width: AppSpacing.xs),
                              Text(
                                examTypeName,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isPremium
                                      ? const Color(0xFFFFD700)
                                      : const Color(0xFF58CC02),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Owned Badge
                        if (isOwned)
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
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: Color(0xFF58CC02),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Dimiliki',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF58CC02),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Padding(
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
                          SizedBox(height: AppSpacing.sm),

                          const Spacer(),

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
                              _buildStatChip(
                                icon: Icons.layers_rounded,
                                label: '$subTestCount subtes',
                                color: const Color(0xFF58CC02),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Footer - Price & Action
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFE5E5E5), width: 1.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // PRICE SECTION
                        if (!isOwned)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Biaya',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF888888),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.money,
                                    size: 18,
                                    color: isPremium
                                        ? const Color(0xFFFFD700)
                                        : const Color(0xFF58CC02),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    currencyFormatter.format(price),
                                    style: AppTextStyles.headingSmall.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: isPremium
                                          ? const Color(0xFFFFD700)
                                          : const Color(0xFF58CC02),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                        // CTA BUTTON
                        Flexible(
                          child: InkWell(
                            onTap: () {
                              _handleCardTap(context, isOwned);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: isOwned
                                    ? const Color(0xFF1CB0F6)
                                    : const Color(0xFF58CC02),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isOwned
                                      ? const Color(0xFF0F9CD9)
                                      : const Color(0xFF46A302),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (isOwned
                                                ? const Color(0xFF0F9CD9)
                                                : const Color(0xFF46A302))
                                            .withOpacity(0.25),
                                    offset: const Offset(0, 3),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isOwned
                                        ? Icons.play_arrow_rounded
                                        : Icons.shopping_cart_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isOwned ? 'Mulai' : 'Beli Sekarang',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Di dalam _handleCardTap method

  void _handleCardTap(BuildContext context, bool isOwned) {
    if (isOwned) {
      // Sudah punya -> ke halaman My Tryouts atau langsung detail
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Kamu sudah memiliki Try Out ini!'),
          backgroundColor: const Color(0xFF58CC02),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      // Belum punya -> NAVIGASI ke TryoutPurchaseScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TryoutPurchaseScreen(
            tryoutId: tryoutId,
            tryoutTitle: data['title'] ?? 'Untitled',
            tryoutDescription: data['description'] ?? '',
            isPremium: data['isPremium'] ?? false,
            energyCost: data['price'] ?? 1,
          ),
        ),
      );
    }
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

// ==============================================================================
// STICKY TAB BAR DELEGATE
// ==============================================================================
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFF7F7F7),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE5E5E5), width: 2),
          ),
        ),
        child: tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}

// lib/features/tryout/screens/tryout_purchase_screen.dart
//
// ARSITEKTUR KUNCI:
// - ValueNotifier<UploadState> → rebuild minimal, hanya widget notifikasi
// - Upload berjalan async tanpa memblokir UI
// - Notifikasi floating di kanan bawah via Stack + Positioned
// - Tidak ada dialog blocking selama proses upload

// ignore_for_file: use_build_context_synchronously

// =============================================================================
// MODEL - State upload yg jelas & terpisah
// =============================================================================

enum UploadStage { idle, compressing, uploading, saving, done, error }

class UploadState {
  final UploadStage stage;
  final double progress; // 0.0 – 1.0
  final String message;

  const UploadState({
    this.stage = UploadStage.idle,
    this.progress = 0.0,
    this.message = '',
  });

  bool get isActive =>
      stage != UploadStage.idle &&
      stage != UploadStage.done &&
      stage != UploadStage.error;

  bool get isError => stage == UploadStage.error;
  bool get isDone => stage == UploadStage.done;
}

// Model bukti per-slot upload
class ProofSlot {
  final String type; // 'follow' | 'story' | 'tag'
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  Uint8List? bytes;
  String? fileName;

  ProofSlot({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  bool get hasFile => bytes != null;

  void clear() {
    bytes = null;
    fileName = null;
  }
}

// =============================================================================
// SCREEN UTAMA
// =============================================================================

class TryoutPurchaseScreen extends StatefulWidget {
  final String tryoutId;
  final String tryoutTitle;
  final String tryoutDescription;
  final bool isPremium;
  final int energyCost;

  const TryoutPurchaseScreen({
    super.key,
    required this.tryoutId,
    required this.tryoutTitle,
    required this.tryoutDescription,
    required this.isPremium,
    required this.energyCost,
  });

  @override
  State<TryoutPurchaseScreen> createState() => _TryoutPurchaseScreenState();
}

class _TryoutPurchaseScreenState extends State<TryoutPurchaseScreen>
    with SingleTickerProviderStateMixin {
  // ── Animasi masuk halaman ──────────────────────────────────────────────────
  late final AnimationController _enterAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // ── State upload – ValueNotifier agar rebuild MINIMAL ────────────────────
  final ValueNotifier<UploadState> _uploadState = ValueNotifier(
    const UploadState(),
  );

  // ── Pilihan metode ─────────────────────────────────────────────────────────
  String _selectedOption = 'free';

  // ── Slot bukti upload ──────────────────────────────────────────────────────
  late final List<ProofSlot> _slots;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ==========================================================================
  @override
  void initState() {
    super.initState();
    _initSlots();
    _initAnimation();
  }

  void _initSlots() {
    _slots = [
      ProofSlot(
        type: 'follow',
        title: 'Follow Instagram',
        description: 'Follow @luluzzz lalu screenshot',
        icon: Icons.person_add_rounded,
        color: const Color(0xFFE4405F),
      ),
      ProofSlot(
        type: 'story',
        title: 'Share di Story',
        description: 'Share & screenshot story-mu',
        icon: Icons.auto_stories_rounded,
        color: const Color(0xFFAC45E6),
      ),
      ProofSlot(
        type: 'tag',
        title: 'Tag 3 Teman',
        description: 'Tag di komentar & screenshot',
        icon: Icons.alternate_email_rounded,
        color: const Color(0xFF1CB0F6),
      ),
    ];
  }

  void _initAnimation() {
    _enterAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _enterAnim, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterAnim, curve: Curves.easeOutCubic));
    _enterAnim.forward();
  }

  @override
  void dispose() {
    _enterAnim.dispose();
    _uploadState.dispose();
    super.dispose();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        // Stack: konten + notifikasi floating (kanan bawah)
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _buildBody(),
                    ),
                  ),
                ),
              ],
            ),

            // ── Notifikasi floating kanan bawah ──────────────────────────
            _buildFloatingNotification(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth > 1200
            ? 800.0
            : constraints.maxWidth > 600
            ? 600.0
            : double.infinity;

        return Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxW),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTryoutInfoCard(),
                  SizedBox(height: AppSpacing.xl),
                  _buildOptionSelector(),
                  SizedBox(height: AppSpacing.xl),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOut,
                    child: _selectedOption == 'free'
                        ? _buildFreeContent()
                        : _buildPaidContent(),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  _buildSubmitButton(),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // APP BAR
  // ==========================================================================

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          _IconBtn(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dapatkan Try Out',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Pilih metode yang kamu inginkan',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF777777),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // INFO CARD TRYOUT
  // ==========================================================================

  Widget _buildTryoutInfoCard() {
    final isPremium = widget.isPremium;
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
              : [const Color(0xFF58CC02), const Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
                child: Icon(
                  isPremium ? Icons.star_rounded : Icons.bolt_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPremium ? 'PREMIUM' : 'GRATIS',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            widget.tryoutTitle,
            style: AppTextStyles.headingMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            widget.tryoutDescription,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // OPTION SELECTOR (Free vs Paid)
  // ==========================================================================

  Widget _buildOptionSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OptionTab(
              label: 'Gratis',
              icon: Icons.celebration_rounded,
              isSelected: _selectedOption == 'free',
              gradient: const LinearGradient(
                colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
              ),
              onTap: () => setState(() => _selectedOption = 'free'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _OptionTab(
              label: 'Bayar',
              icon: Icons.credit_card_rounded,
              isSelected: _selectedOption == 'paid',
              gradient: const LinearGradient(
                colors: [Color(0xFF1CB0F6), Color(0xFF0F9CD9)],
              ),
              onTap: () => setState(() => _selectedOption = 'paid'),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // KONTEN GRATIS – Upload 3 bukti
  // ==========================================================================

  Widget _buildFreeContent() {
    return Column(
      key: const ValueKey('free'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info banner
        _InfoBanner(
          icon: Icons.info_outline_rounded,
          color: const Color(0xFFFFD700),
          title: 'Dapatkan Try Out Gratis!',
          subtitle: 'Upload 3 bukti promosi untuk mendapatkan akses penuh.',
        ),
        SizedBox(height: AppSpacing.lg),

        // Slot upload – responsive grid
        LayoutBuilder(
          builder: (ctx, c) {
            if (c.maxWidth > 700) {
              // Desktop: 3 kolom sejajar
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _slots.map((slot) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: slot == _slots.last ? 0 : AppSpacing.md,
                      ),
                      child: _ProofUploadCard(
                        slot: slot,
                        onPick: () => _pickImage(slot),
                        onRemove: () => setState(() => slot.clear()),
                      ),
                    ),
                  );
                }).toList(),
              );
            }
            // Mobile: vertikal
            return Column(
              children: _slots.map((slot) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: slot == _slots.last ? 0 : AppSpacing.md,
                  ),
                  child: _ProofUploadCard(
                    slot: slot,
                    onPick: () => _pickImage(slot),
                    onRemove: () => setState(() => slot.clear()),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ==========================================================================
  // KONTEN BAYAR – Coming soon
  // ==========================================================================

  Widget _buildPaidContent() {
    return Container(
      key: const ValueKey('paid'),
      padding: EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: const Color(0xFF1CB0F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.construction_rounded,
              size: 64,
              color: Color(0xFF1CB0F6),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          Text(
            'Coming Soon',
            style: AppTextStyles.headingLarge.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Metode pembayaran sedang dalam pengembangan.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF777777),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.lg),
          ...[
            (Icons.qr_code_rounded, 'QRIS Payment', const Color(0xFF1CB0F6)),
            (Icons.credit_card_rounded, 'Credit Card', const Color(0xFF9333EA)),
            (
              Icons.account_balance_rounded,
              'Bank Transfer',
              const Color(0xFFFF9600),
            ),
          ].map(
            (e) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: e.$3.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(e.$1, size: 20, color: e.$3),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    e.$2,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SUBMIT BUTTON
  // ==========================================================================

  Widget _buildSubmitButton() {
    final allUploaded = _slots.every((s) => s.hasFile);
    final canSubmit = _selectedOption == 'free' && allUploaded;

    return ValueListenableBuilder<UploadState>(
      valueListenable: _uploadState,
      builder: (_, state, __) {
        final isLoading = state.isActive;

        return ElevatedButton(
          onPressed: (canSubmit && !isLoading) ? _handleSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF58CC02),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE5E5E5),
            disabledForegroundColor: const Color(0xFF999999),
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: canSubmit && !isLoading
                    ? const Color(0xFF46A302)
                    : const Color(0xFFCCCCCC),
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
              ] else
                Icon(
                  _selectedOption == 'free'
                      ? Icons.check_circle_rounded
                      : Icons.lock_rounded,
                  size: 22,
                ),
              SizedBox(width: AppSpacing.sm),
              Text(
                _selectedOption == 'free'
                    ? (isLoading ? 'Mengirim...' : 'Dapatkan Try Out Gratis')
                    : 'Belum Tersedia',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // FLOATING NOTIFICATION – kanan bawah, non-blocking
  // ==========================================================================

  Widget _buildFloatingNotification() {
    return ValueListenableBuilder<UploadState>(
      valueListenable: _uploadState,
      builder: (_, state, __) {
        // Sembunyikan jika idle
        if (state.stage == UploadStage.idle) return const SizedBox.shrink();

        return Positioned(
          bottom: 24,
          right: 24,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _FloatingNotificationCard(
              key: ValueKey(state.stage),
              state: state,
              onDismiss: state.isError || state.isDone
                  ? () => _uploadState.value =
                        const UploadState() // reset ke idle
                  : null,
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // LOGIC – Pick & compress image
  // ==========================================================================

  Future<void> _pickImage(ProofSlot slot) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) return;

      // Tunjukkan notif "kompres"
      _uploadState.value = const UploadState(
        stage: UploadStage.compressing,
        message: 'Memproses gambar...',
        progress: 0.1,
      );

      // Kompresi di background tanpa lock UI
      final compressed = await _compressImage(file.bytes!);

      setState(() {
        slot.bytes = compressed;
        slot.fileName = file.name;
      });

      _uploadState.value = const UploadState(
        stage: UploadStage.done,
        message: '✅ Gambar siap!',
        progress: 1,
      );

      // Auto dismiss setelah 2 detik
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _uploadState.value = const UploadState();
    } catch (e, stackTrace) {
      print('ERROR UPLOAD: $e');
      print('STACK: $stackTrace');
      _uploadState.value = UploadState(
        stage: UploadStage.error,
        message: 'Gagal: $e', // ← tampilkan error aslinya
      );
    }
  }

  // ==========================================================================
  // LOGIC – Submit (upload + simpan Firestore)
  // ==========================================================================

  Future<void> _handleSubmit() async {
    _uploadState.value = const UploadState(
      stage: UploadStage.uploading,
      message: 'Mengunggah bukti 1/3...',
      progress: 0.05,
    );

    try {
      // Upload 3 file secara berurutan dengan progres
      final urls = <String>[];
      for (var i = 0; i < _slots.length; i++) {
        final slot = _slots[i];
        _uploadState.value = UploadState(
          stage: UploadStage.uploading,
          message: 'Mengunggah bukti ${i + 1}/3...',
          progress: i / 3 * 0.9,
        );

        final url = await _uploadFile(
          bytes: slot.bytes!,
          fileName: slot.fileName ?? '${slot.type}.jpg',
          proofType: slot.type,
          onProgress: (p) {
            _uploadState.value = UploadState(
              stage: UploadStage.uploading,
              message: 'Mengunggah bukti ${i + 1}/3...',
              progress: (i / 3 + p / 3) * 0.9,
            );
          },
        );

        if (url == null) throw Exception('Gagal upload ${slot.title}');
        urls.add(url);
      }

      // Simpan ke Firestore
      _uploadState.value = const UploadState(
        stage: UploadStage.saving,
        message: 'Menyimpan data...',
        progress: 0.95,
      );

      await FirebaseFirestore.instance
          .collection('user_tryouts')
          .doc('${_userId}_tryout_${widget.tryoutId}')
          .set({
            'userId': _userId,
            'tryoutId': widget.tryoutId,
            'proofStatus': 'pending_review',
            'submittedAt': FieldValue.serverTimestamp(),
            'promotionProofs': {
              'followProof': urls[0],
              'storyProof': urls[1],
              'tagProof': urls[2],
            },
            'isActive': false,
          });

      _uploadState.value = const UploadState(
        stage: UploadStage.done,
        message: '✅ Berhasil! Bukti sedang ditinjau admin.',
        progress: 1.0,
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _uploadState.value = UploadState(
        stage: UploadStage.error,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ==========================================================================
  // HELPER – Upload satu file
  // ==========================================================================

  Future<String?> _uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String proofType,
    required void Function(double) onProgress,
  }) async {
    try {
      final path =
          'tryout_proofs/$_userId/${widget.tryoutId}/${proofType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(path);
      final task = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      task.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) {
          onProgress(snap.bytesTransferred / snap.totalBytes);
        }
      });

      await task;
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // HELPER – Kompres gambar (async, tidak lock UI)
  // ==========================================================================

  /// Kompres via Canvas API browser — non-blocking, tidak menyentuh main isolate.
  /// Jauh lebih cepat dari package:image untuk Flutter Web.
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      // Decode bytes → Blob → Object URL
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Load ke HTMLImageElement (async, browser handle di thread sendiri)
      final htmlImg = html.ImageElement();
      htmlImg.src = url;
      await htmlImg.onLoad.first; // tunggu load selesai, tidak block UI

      html.Url.revokeObjectUrl(url);

      // Hitung ukuran target (max 1200px)
      final maxSize = 1200;
      var w = htmlImg.naturalWidth ?? 0;
      var h = htmlImg.naturalHeight ?? 0;
      if (w == 0 || h == 0) return bytes;

      if (w > maxSize || h > maxSize) {
        if (w >= h) {
          h = (h * maxSize / w).round();
          w = maxSize;
        } else {
          w = (w * maxSize / h).round();
          h = maxSize;
        }
      }

      // Gambar ke Canvas (native GPU-accelerated, tidak block UI)
      final canvas = html.CanvasElement(width: w, height: h);
      final ctx = canvas.context2D;
      ctx.drawImageScaled(htmlImg, 0, 0, w, h);

      // Export ke JPEG blob
      final completer = Completer<Uint8List>();
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
      final base64 = dataUrl.split(',').last;
      completer.complete(base64Decode(base64));

      return completer.future;
    } catch (_) {
      return bytes; // fallback: kembalikan original
    }
  }
}

// =============================================================================
// WIDGET – Floating Notification Card (kanan bawah)
// =============================================================================

class _FloatingNotificationCard extends StatelessWidget {
  final UploadState state;
  final VoidCallback? onDismiss;

  const _FloatingNotificationCard({
    super.key,
    required this.state,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isError = state.isError;
    final isDone = state.isDone;
    final accentColor = isError
        ? const Color(0xFFFF4B4B)
        : isDone
        ? const Color(0xFF58CC02)
        : const Color(0xFF6C63FF);

    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isError
              ? const Color(0xFFFFF5F5)
              : isDone
              ? const Color(0xFFF0FFF4)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris atas: ikon + pesan + tombol dismiss
            Row(
              children: [
                // Ikon status
                if (isError)
                  Icon(
                    Icons.error_outline_rounded,
                    color: accentColor,
                    size: 22,
                  )
                else if (isDone)
                  Icon(Icons.check_circle_rounded, color: accentColor, size: 22)
                else
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: accentColor,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.message,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isError
                          ? const Color(0xFFCC0000)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (onDismiss != null)
                  GestureDetector(
                    onTap: onDismiss,
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: const Color(0xFF999999),
                    ),
                  ),
              ],
            ),

            // Progress bar – hanya tampil saat uploading/saving
            if (state.isActive && state.progress > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 6,
                  backgroundColor: accentColor.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(accentColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(state.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGET – ProofUploadCard (slot upload per bukti)
// =============================================================================

class _ProofUploadCard extends StatelessWidget {
  final ProofSlot slot;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ProofUploadCard({
    required this.slot,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: slot.hasFile ? slot.color : const Color(0xFFE5E5E5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Nomor badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: slot.hasFile ? slot.color : const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    slot.hasFile ? Icons.check_rounded : slot.icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      slot.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Area preview / tombol upload
          if (slot.hasFile) _buildPreview() else _buildUploadArea(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            slot.bytes!,
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        // Tombol hapus di pojok kanan atas
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        // Label nama file di bawah
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
            ),
            child: Text(
              slot.fileName ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: () {
        try {
          onPick();
        } catch (e) {
          print('onPick error: $e');
        }
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: slot.color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: slot.color.withOpacity(0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, color: slot.color, size: 36),
            const SizedBox(height: 6),
            Text(
              'Tap untuk upload',
              style: TextStyle(
                color: slot.color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'JPG, PNG',
              style: TextStyle(color: Color(0xFF999999), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGET – Reusable kecil
// =============================================================================

class _OptionTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Gradient gradient;
  final VoidCallback onTap;

  const _OptionTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF777777),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF777777),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5), width: 1.5),
        ),
        child: Icon(icon, size: 22, color: const Color(0xFF4B4B4B)),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 12,
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
