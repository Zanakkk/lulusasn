// lib/features/tryout/screens/tryout_marketplace_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

import '../../app/routes.dart';

final currencyFormatter = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

/// 🛒 TRYOUT MARKETPLACE - Halaman Beli TryOut
///
/// Menampilkan SEMUA tryout yang tersedia untuk dibeli
/// User bisa lihat detail dan beli tryout yang belum dimiliki
class TryoutMarketplaceScreen extends StatefulWidget {
  const TryoutMarketplaceScreen({super.key});

  @override
  State<TryoutMarketplaceScreen> createState() =>
      _TryoutMarketplaceScreenState();
}

class _TryoutMarketplaceScreenState extends State<TryoutMarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'all'; // all | free | premium
  String _searchQuery = '';

  // Current user ID
  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedFilter = 'all';
            break;
          case 1:
            _selectedFilter = 'free';
            break;
          case 2:
            _selectedFilter = 'premium';
            break;
        }
      });
    }
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
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [_buildHeader(), _buildSearchBar(), _buildTabBar()];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMarketplaceList('all'),
              _buildMarketplaceList('free'),
              _buildMarketplaceList('premium'),
            ],
          ),
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
            colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
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
                    Icons.shopping_bag_rounded,
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
                        'Marketplace Try Out',
                        style: AppTextStyles.headingLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Pilih try out yang sesuai dengan kebutuhanmu',
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
        color: const Color(0xFF58CC02),
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
                    hintText: 'Cari try out...',
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
  // TAB BAR
  // ==========================================================================
  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyTabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF58CC02),
          unselectedLabelColor: const Color(0xFF777777),
          labelStyle: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          indicator: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF58CC02), width: 3),
            ),
          ),
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Gratis'),
            Tab(text: 'Premium'),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // MARKETPLACE LIST
  // ==========================================================================
  Widget _buildMarketplaceList(String filter) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tryouts')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView();
        }

        var docs = snapshot.data?.docs ?? [];

        // Filter by premium status
        if (filter == 'free') {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isPremium'] == false;
          }).toList();
        } else if (filter == 'premium') {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isPremium'] == true;
          }).toList();
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString().toLowerCase();
            final description = (data['description'] ?? '')
                .toString()
                .toLowerCase();
            final examTypeName = (data['examTypeName'] ?? '')
                .toString()
                .toLowerCase();

            return title.contains(_searchQuery) ||
                description.contains(_searchQuery) ||
                examTypeName.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return _buildEmptyView();
        }

        return _buildGrid(docs);
      },
    );
  }

  Widget _buildGrid(List<QueryDocumentSnapshot> docs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;

        if (constraints.maxWidth > 1200) {
          crossAxisCount = 3;
          childAspectRatio = 0.85;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
          childAspectRatio = 0.8;
        } else {
          crossAxisCount = 1;
          childAspectRatio = 0.95;
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: GridView.builder(
            padding: EdgeInsets.all(AppSpacing.lg),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: AppSpacing.lg,
              mainAxisSpacing: AppSpacing.lg,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _MarketplaceTryoutCard(
                tryoutId: doc.id,
                data: data,
                userId: userId,
              );
            },
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Color(0xFF58CC02)),
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
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.xl * 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: Color(0xFF58CC02),
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            Text(
              'Belum Ada Try Out',
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Try out akan segera ditambahkan!',
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
            onTap: () => _handleCardTap(context, isOwned),
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
                            onTap: () => _handleCardTap(context, isOwned),
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

/// 🛍️ TRYOUT PURCHASE SCREEN - Halaman Pembelian Try Out
///
/// Desain modern dengan 2 opsi:
/// 1. FREE - Upload 3 bukti promosi
/// 2. BAYAR - Coming soon (QRIS/Payment Gateway)
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
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedOption = 'free';
  bool _isProcessing = false;

  Uint8List? _followProofBytes;
  Uint8List? _storyProofBytes;
  Uint8List? _tagProofBytes;

  String? _followProofName;
  String? _storyProofName;
  String? _tagProofName;

  // TAMBAHAN: untuk menyimpan URL upload
  String? _followProofUrl;
  String? _storyProofUrl;
  String? _tagProofUrl;

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ... initState, dispose, build tetap sama ...

  // ==========================================================================
  // FILE PICKER
  // ==========================================================================
  Future<void> _pickImage(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        final name = file.name;

        if (bytes != null) {
          // Compress gambar dulu
          final compressedBytes = await _compressImage(bytes);

          setState(() {
            switch (type) {
              case 'follow':
                _followProofBytes = compressedBytes;
                _followProofName = name;
                break;
              case 'story':
                _storyProofBytes = compressedBytes;
                _storyProofName = name;
                break;
              case 'tag':
                _tagProofBytes = compressedBytes;
                _tagProofName = name;
                break;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error memilih gambar: $e');
      }
    }
  }

  // ==========================================================================
  // COMPRESS IMAGE
  // ==========================================================================
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    try {
      // Decode image
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return bytes;

      // Resize jika terlalu besar (max width/height 1200px)
      if (image.width > 1200 || image.height > 1200) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? 1200 : null,
          height: image.height > image.width ? 1200 : null,
        );
      }

      // Compress dengan quality 85 (balance antara size & kualitas)
      final compressed = img.encodeJpg(image, quality: 85);

      return Uint8List.fromList(compressed);
    } catch (e) {
      // Kalau gagal compress, return original
      return bytes;
    }
  }

  // ==========================================================================
  // UPLOAD TO FIREBASE STORAGE
  // ==========================================================================
  Future<String?> _uploadToFirebase({
    required Uint8List bytes,
    required String fileName,
    required String proofType,
  }) async {
    try {
      // Path: tryout_proofs/{userId}/{tryoutId}/{proofType}_{timestamp}.jpg
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path =
          'tryout_proofs/$userId/${widget.tryoutId}/${proofType}_$timestamp.jpg';

      final ref = FirebaseStorage.instance.ref().child(path);

      // Upload dengan metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'tryoutId': widget.tryoutId,
          'proofType': proofType,
          'originalName': fileName,
        },
      );

      await ref.putData(bytes, metadata);

      // Dapatkan download URL
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error upload to Firebase: $e');
      return null;
    }
  }

  // ==========================================================================
  // SUBMIT - DENGAN UPLOAD
  // ==========================================================================
  Future<void> _handleSubmit() async {
    if (_selectedOption != 'free') return;

    setState(() => _isProcessing = true);

    try {
      // 1. Upload semua gambar ke Firebase Storage
      String? followUrl;
      String? storyUrl;
      String? tagUrl;

      if (_followProofBytes != null) {
        followUrl = await _uploadToFirebase(
          bytes: _followProofBytes!,
          fileName: _followProofName ?? 'follow.jpg',
          proofType: 'follow',
        );
      }

      if (_storyProofBytes != null) {
        storyUrl = await _uploadToFirebase(
          bytes: _storyProofBytes!,
          fileName: _storyProofName ?? 'story.jpg',
          proofType: 'story',
        );
      }

      if (_tagProofBytes != null) {
        tagUrl = await _uploadToFirebase(
          bytes: _tagProofBytes!,
          fileName: _tagProofName ?? 'tag.jpg',
          proofType: 'tag',
        );
      }

      // Validasi semua berhasil upload
      if (followUrl == null || storyUrl == null || tagUrl == null) {
        throw Exception('Gagal upload gambar. Silakan coba lagi.');
      }

      // 2. Simpan ke Firestore dengan URL
      await FirebaseFirestore.instance
          .collection('user_tryouts')
          .doc('${userId}_tryout_${widget.tryoutId}')
          .set({
            'userId': userId,
            'tryoutId': widget.tryoutId,
            'purchaseMethod': 'free_promotion',
            'purchasedAt': FieldValue.serverTimestamp(),
            'lastAccessedAt': FieldValue.serverTimestamp(),
            'promotionProofs': {
              'followProof': followUrl,
              'storyProof': storyUrl,
              'tagProof': tagUrl,
              'status':
                  'pending_review', // pending_review | approved | rejected
              'submittedAt': FieldValue.serverTimestamp(),
            },
            'subtestProgress': {},
            'totalAttempts': 0,
            'isActive': false, // Belum aktif, menunggu approval admin
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        await _showSuccessDialog();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ==========================================================================
  // SUCCESS DIALOG - UPDATE MESSAGE
  // ==========================================================================
  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF58CC02),
                  size: 64,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              Text(
                'Berhasil Terkirim!',
                style: AppTextStyles.headingLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Bukti promosi kamu sedang ditinjau oleh admin.\nKamu akan mendapat notifikasi jika sudah disetujui.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF777777),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF58CC02),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFF46A302),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'Oke, Mengerti!',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
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

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive: tentukan apakah desktop/tablet/mobile
                      final isDesktop = constraints.maxWidth > 1200;
                      final isTablet =
                          constraints.maxWidth > 600 &&
                          constraints.maxWidth <= 1200;

                      return Center(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: isDesktop
                                ? 800
                                : (isTablet ? 600 : double.infinity),
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.all(
                              isDesktop ? AppSpacing.xxl : AppSpacing.xl,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTryoutInfoCard(),
                                SizedBox(height: AppSpacing.xl),
                                _buildOptionSelector(),
                                SizedBox(height: AppSpacing.xl),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  child: _selectedOption == 'free'
                                      ? _buildFreeOptionContent()
                                      : _buildPaidOptionContent(),
                                ),
                                SizedBox(height: AppSpacing.xxl),
                                _buildActionButton(),
                                SizedBox(height: AppSpacing.lg),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // APP BAR tidak berubah
  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5), width: 2)),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 24,
                  color: Color(0xFF4B4B4B),
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dapatkan Try Out',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
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
          ),
        ],
      ),
    );
  }

  // Sisanya sama, hanya ubah _buildFreeOptionContent untuk grid di desktop
  Widget _buildFreeOptionContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        if (isDesktop) {
          // GRID untuk Desktop
          return Column(
            key: const ValueKey('free'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              SizedBox(height: AppSpacing.xl),
              // Grid 3 kolom
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildUploadCard(
                      number: 1,
                      title: 'Follow Instagram',
                      description: 'Follow @lulusasn',
                      icon: Icons.person_add_rounded,
                      color: const Color(0xFFE4405F),
                      imageBytes: _followProofBytes,
                      imageName: _followProofName,
                      onTap: () => _pickImage('follow'),
                      onRemove: () => setState(() {
                        _followProofBytes = null;
                        _followProofName = null;
                      }),
                    ),
                  ),
                  SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: _buildUploadCard(
                      number: 2,
                      title: 'Share Story',
                      description: 'Screenshot story',
                      icon: Icons.auto_stories_rounded,
                      color: const Color(0xFFAC45E6),
                      imageBytes: _storyProofBytes,
                      imageName: _storyProofName,
                      onTap: () => _pickImage('story'),
                      onRemove: () => setState(() {
                        _storyProofBytes = null;
                        _storyProofName = null;
                      }),
                    ),
                  ),
                  SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: _buildUploadCard(
                      number: 3,
                      title: 'Tag 3 Teman',
                      description: 'Screenshot komentar',
                      icon: Icons.alternate_email_rounded,
                      color: const Color(0xFF1CB0F6),
                      imageBytes: _tagProofBytes,
                      imageName: _tagProofName,
                      onTap: () => _pickImage('tag'),
                      onRemove: () => setState(() {
                        _tagProofBytes = null;
                        _tagProofName = null;
                      }),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // VERTIKAL untuk Mobile/Tablet
          return Column(
            key: const ValueKey('free'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              SizedBox(height: AppSpacing.xl),
              _buildUploadCard(
                number: 1,
                title: 'Follow Akun Instagram',
                description: 'Follow @lulusasn di Instagram',
                icon: Icons.person_add_rounded,
                color: const Color(0xFFE4405F),
                imageBytes: _followProofBytes,
                imageName: _followProofName,
                onTap: () => _pickImage('follow'),
                onRemove: () => setState(() {
                  _followProofBytes = null;
                  _followProofName = null;
                }),
              ),
              SizedBox(height: AppSpacing.lg),
              _buildUploadCard(
                number: 2,
                title: 'Share di Instagram Story',
                description: 'Screenshot story yang sudah di-share',
                icon: Icons.auto_stories_rounded,
                color: const Color(0xFFAC45E6),
                imageBytes: _storyProofBytes,
                imageName: _storyProofName,
                onTap: () => _pickImage('story'),
                onRemove: () => setState(() {
                  _storyProofBytes = null;
                  _storyProofName = null;
                }),
              ),
              SizedBox(height: AppSpacing.lg),
              _buildUploadCard(
                number: 3,
                title: 'Tag 3 Teman di Komentar',
                description: 'Screenshot komentar dengan 3 tag teman',
                icon: Icons.alternate_email_rounded,
                color: const Color(0xFF1CB0F6),
                imageBytes: _tagProofBytes,
                imageName: _tagProofName,
                onTap: () => _pickImage('tag'),
                onRemove: () => setState(() {
                  _tagProofBytes = null;
                  _tagProofName = null;
                }),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFFFD700),
              size: 24,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dapatkan Try Out Gratis!',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFD4A800),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Upload 3 bukti promosi untuk mendapatkan akses penuh',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF777777),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TRYOUT INFO CARD
  // ==========================================================================
  Widget _buildTryoutInfoCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isPremium
              ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
              : [const Color(0xFF58CC02), const Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                (widget.isPremium
                        ? const Color(0xFFFFA500)
                        : const Color(0xFF46A302))
                    .withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 24,
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.isPremium ? Icons.star_rounded : Icons.bolt_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        widget.isPremium ? 'PREMIUM' : 'GRATIS',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
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
              height: 1.2,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            widget.tryoutDescription,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.95),
              height: 1.4,
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
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOptionTab(
              label: 'Gratis',
              icon: Icons.celebration_rounded,
              value: 'free',
              gradient: const LinearGradient(
                colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
              ),
            ),
          ),
          SizedBox(width: 6),
          Expanded(
            child: _buildOptionTab(
              label: 'Bayar',
              icon: Icons.credit_card_rounded,
              value: 'paid',
              gradient: const LinearGradient(
                colors: [Color(0xFF1CB0F6), Color(0xFF0F9CD9)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTab({
    required String label,
    required IconData icon,
    required String value,
    required Gradient gradient,
  }) {
    final isSelected = _selectedOption == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedOption = value),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            gradient: isSelected ? gradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF777777),
                size: 20,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF777777),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard({
    required int number,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required Uint8List? imageBytes,
    required String? imageName,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final isUploaded = imageBytes != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUploaded ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUploaded ? color : const Color(0xFFE5E5E5),
              width: 2,
            ),
            boxShadow: [
              if (isUploaded)
                BoxShadow(
                  color: color.withOpacity(0.1),
                  offset: const Offset(0, 4),
                  blurRadius: 16,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Number badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isUploaded
                            ? [color, color.withOpacity(0.8)]
                            : [
                                const Color(0xFFE5E5E5),
                                const Color(0xFFCCCCCC),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: AppTextStyles.headingSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),

                  // Title & description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF777777),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status icon
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isUploaded
                          ? color.withOpacity(0.1)
                          : const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isUploaded ? Icons.check_rounded : icon,
                      color: isUploaded ? color : const Color(0xFF777777),
                      size: 24,
                    ),
                  ),
                ],
              ),

              // Upload preview or button
              if (isUploaded) ...[
                SizedBox(height: AppSpacing.md),
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    children: [
                      // Image preview
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          imageBytes,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),

                      // File info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: color,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Berhasil diupload',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (imageName != null) ...[
                              SizedBox(height: 2),
                              Text(
                                imageName,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF777777),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Remove button
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFFFF4B4B),
                        iconSize: 20,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFFF4B4B,
                          ).withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SizedBox(height: AppSpacing.md),
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE5E5E5),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_rounded,
                        color: const Color(0xFF777777),
                        size: 40,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Tap untuk upload gambar',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF777777),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'PNG, JPG, JPEG',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // PAID OPTION CONTENT
  // ==========================================================================
  Widget _buildPaidOptionContent() {
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
            child: Icon(
              Icons.construction_rounded,
              size: 64,
              color: const Color(0xFF1CB0F6),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          Text(
            'Coming Soon',
            style: AppTextStyles.headingLarge.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Metode pembayaran sedang dalam pengembangan',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF777777),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.lg),
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildFeatureItem(
                  icon: Icons.qr_code_rounded,
                  text: 'QRIS Payment',
                  color: const Color(0xFF1CB0F6),
                ),
                SizedBox(height: AppSpacing.sm),
                _buildFeatureItem(
                  icon: Icons.credit_card_rounded,
                  text: 'Credit Card',
                  color: const Color(0xFF9333EA),
                ),
                SizedBox(height: AppSpacing.sm),
                _buildFeatureItem(
                  icon: Icons.account_balance_rounded,
                  text: 'Bank Transfer',
                  color: const Color(0xFFFF9600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4B4B4B),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // ACTION BUTTON
  // ==========================================================================
  Widget _buildActionButton() {
    final canProceed = _selectedOption == 'free'
        ? (_followProofBytes != null &&
              _storyProofBytes != null &&
              _tagProofBytes != null)
        : false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton(
        onPressed: canProceed && !_isProcessing ? _handleSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF58CC02),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE5E5E5),
          disabledForegroundColor: const Color(0xFF999999),
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: canProceed
                  ? const Color(0xFF46A302)
                  : const Color(0xFFCCCCCC),
              width: 2,
            ),
          ),
        ),
        child: _isProcessing
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    canProceed ? Colors.white : const Color(0xFF999999),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedOption == 'free'
                        ? Icons.check_circle_rounded
                        : Icons.lock_rounded,
                    size: 24,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    _selectedOption == 'free'
                        ? 'Dapatkan Try Out Gratis'
                        : 'Belum Tersedia',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFFF4B4B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }
}

// lib/core/services/tryout_purchase_service.dart

class TryoutPurchaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================================
  // PURCHASE TRYOUT
  // ============================================================================

  /// Purchase tryout dengan price
  /// Returns true jika berhasil, throws Exception jika gagal
  Future<bool> purchaseTryout({
    required String tryoutId,
    required int cost, // Harga tryout
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      // Gunakan transaction untuk atomic operation
      return await _firestore.runTransaction<bool>((transaction) async {
        // 1. Get user document
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final userData = userDoc.data()!;
        final currentPrice = userData['price'] as int? ?? 0;
        final ownedTryouts = List<String>.from(userData['ownedTryouts'] ?? []);

        // 2. Check if already owned
        if (ownedTryouts.contains(tryoutId)) {
          throw Exception('Tryout sudah dimiliki');
        }

        // 3. Check if user has enough price
        if (currentPrice < cost) {
          throw Exception(
            'Price tidak cukup. Kamu butuh $cost, tapi hanya punya $currentPrice.',
          );
        }

        // 4. Deduct price and add tryout to owned list
        transaction.update(userRef, {
          'price': currentPrice - cost,
          'ownedTryouts': FieldValue.arrayUnion([tryoutId]),
        });

        // 5. Optional: Create purchase record for audit trail
        final purchaseRef = _firestore.collection('purchases').doc();
        transaction.set(purchaseRef, {
          'userId': userId,
          'tryoutId': tryoutId,
          'cost': cost,
          'purchasedAt': FieldValue.serverTimestamp(),
          'transactionType': 'price',
        });

        // 6. Update tryout owner count (optional analytics)
        final tryoutRef = _firestore.collection('tryouts').doc(tryoutId);
        final tryoutDoc = await transaction.get(tryoutRef);

        if (tryoutDoc.exists) {
          transaction.update(tryoutRef, {
            'ownerCount': FieldValue.increment(1),
          });
        }

        debugPrint('✅ Purchase successful: $tryoutId for $cost price');
        return true;
      });
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase error during purchase: ${e.code} - ${e.message}');
      throw Exception('Terjadi kesalahan: ${e.message}');
    } catch (e) {
      debugPrint('❌ Purchase error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // CHECK OWNERSHIP
  // ============================================================================

  /// Check if user owns a tryout
  Future<bool> checkOwnership(String tryoutId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final ownedTryouts = List<String>.from(
        userDoc.data()?['ownedTryouts'] ?? [],
      );

      return ownedTryouts.contains(tryoutId);
    } catch (e) {
      debugPrint('❌ Check ownership error: $e');
      return false;
    }
  }

  // ============================================================================
  // GET OWNED TRYOUTS
  // ============================================================================

  /// Get all owned tryout IDs
  Future<List<String>> getOwnedTryoutIds() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return [];

      return List<String>.from(userDoc.data()?['ownedTryouts'] ?? []);
    } catch (e) {
      debugPrint('❌ Get owned tryouts error: $e');
      return [];
    }
  }

  // ============================================================================
  // STREAM OWNERSHIP (Real-time)
  // ============================================================================

  /// Stream untuk real-time ownership check
  Stream<bool> watchOwnership(String tryoutId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(false);

    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return false;

      final ownedTryouts = List<String>.from(
        snapshot.data()?['ownedTryouts'] ?? [],
      );

      return ownedTryouts.contains(tryoutId);
    });
  }

  /// Stream untuk list owned tryout IDs
  Stream<List<String>> watchOwnedTryoutIds() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return [];

      return List<String>.from(snapshot.data()?['ownedTryouts'] ?? []);
    });
  }

  // ============================================================================
  // GET USER CURRENT PRICE
  // ============================================================================

  /// Get user's current price balance
  Future<int> getCurrentPrice() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return 0;

      return userDoc.data()?['price'] as int? ?? 0;
    } catch (e) {
      debugPrint('❌ Get current price error: $e');
      return 0;
    }
  }

  /// Stream user's current price balance
  Stream<int> watchCurrentPrice() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return 0;

      return snapshot.data()?['price'] as int? ?? 0;
    });
  }
}
