// ============================================================================
// lib/admin/pages/promotion_verification_screen.dart
// 2-Screen: TryoutList → UserSubmissionList
// Modern UI — no TabBar, pill filter, card design
// ============================================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:intl/intl.dart';


class PromotionVerificationScreen extends StatelessWidget {
  const PromotionVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Warna abu-abu sangat muda (Slate 50)
      body: Row(
        children: [
          // Jika ini dashboard admin, biasanya ada Sidebar/Nav Rail di sini
          // Kita langsung ke Body utama
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildModernHeader(context),
                _buildStatsOverview(),
                _buildSectionTitle('Daftar Tryout Aktif'),
                _buildTryoutGrid(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. HEADER: Desain yang lebih flat dan elegan
  Widget _buildModernHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(32, 40, 32, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verifikasi Promosi',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelola dan validasi akses tryout gratis user.',
                  style: TextStyle(color: Colors.blueGrey[400], fontSize: 14),
                ),
              ],
            ),
            // User Profile atau Quick Action bisa di sini
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF6C63FF)),
            ),
          ],
        ),
      ),
    );
  }

  // 2. STATS OVERVIEW: Kartu ringkasan di bagian atas
  Widget _buildStatsOverview() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('user_tryouts').snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            final pending = docs.where((d) => (d.data() as Map)['proofStatus'] == 'pending_review').length;
            final total = docs.length;

            return Row(
              children: [
                _statCard('Total Pengajuan', total.toString(), Icons.assignment_ind_rounded, Colors.blue),
                const SizedBox(width: 20),
                _statCard('Menunggu Review', pending.toString(), Icons.pending_actions_rounded, const Color(0xFFFF9600)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 12),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
        ),
      ),
    );
  }

  // 3. TRYOUT GRID: Grid yang lebih bersih
  Widget _buildTryoutGrid(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tryouts')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));

        final docs = snap.data!.docs;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 450,
              mainAxisExtent: 180,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                final d = docs[i];
                final data = d.data() as Map<String, dynamic>;
                return _ModernTryoutCard(
                  tryoutId: d.id,
                  title: data['title'] ?? 'Untitled',
                  examTypeName: data['examTypeName'] ?? 'Kategori',
                  isPremium: data['isPremium'] ?? false,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SubmissionListScreen( // Screen 2 split-screen kita
                      tryoutId: d.id,
                      tryoutTitle: data['title'] ?? 'Untitled',
                    ),
                  )),
                );
              },
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }
}

// 4. KARTU ITEM: Fokus pada keterbacaan dan status
class _ModernTryoutCard extends StatelessWidget {
  final String tryoutId;
  final String title;
  final String examTypeName;
  final bool isPremium;
  final VoidCallback onTap;

  const _ModernTryoutCard({
    required this.tryoutId, required this.title,
    required this.examTypeName, required this.isPremium, required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_tryouts')
          .where('tryoutId', isEqualTo: tryoutId)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final pending = docs.where((d) => (d.data() as Map)['proofStatus'] == 'pending_review').length;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: pending > 0 ? const Color(0xFF6C63FF).withOpacity(0.3) : const Color(0xFFE2E8F0),
                width: pending > 0 ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        examTypeName.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6C63FF)),
                      ),
                    ),
                    const Spacer(),
                    if (isPremium) const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Text('${docs.length} Users', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      ],
                    ),
                    if (pending > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFFF4B4B), borderRadius: BorderRadius.circular(20)),
                        child: Text('$pending Pending', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// TRYOUT SUMMARY CARD (Screen 1)
// ============================================================================
class _TryoutSummaryCard extends StatelessWidget {
  final String tryoutId;
  final String title;
  final String examTypeName;
  final bool isPremium;
  final VoidCallback onTap;

  const _TryoutSummaryCard({
    required this.tryoutId,
    required this.title,
    required this.examTypeName,
    required this.isPremium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_tryouts')
          .where('tryoutId', isEqualTo: tryoutId)
          .snapshots(),
      builder: (_, snap) {
        final all = snap.data?.docs ?? [];
        final pending = all.where((d) =>
        (d.data() as Map)['proofStatus'] == 'pending_review').length;
        final approved = all.where((d) =>
        (d.data() as Map)['proofStatus'] == 'approved').length;
        final rejected = all.where((d) =>
        (d.data() as Map)['proofStatus'] == 'rejected').length;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16, offset: const Offset(0, 4))],
                border: pending > 0
                    ? Border.all(color: const Color(0xFFFF9600).withOpacity(0.4), width: 2)
                    : Border.all(color: Colors.transparent, width: 2),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPremium
                            ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                            : [const Color(0xFF6C63FF), const Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                        isPremium ? Icons.star_rounded : Icons.bolt_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (examTypeName.isNotEmpty)
                          Text(examTypeName,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF6C63FF),
                                  fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(title,
                            style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        // Stats chips
                        Wrap(spacing: 6, children: [
                          _StatPill(label: '$pending menunggu',
                              color: const Color(0xFFFF9600), show: pending > 0),
                          _StatPill(label: '$approved disetujui',
                              color: const Color(0xFF10B981), show: true),
                          _StatPill(label: '$rejected ditolak',
                              color: const Color(0xFFFF4B4B), show: rejected > 0),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF6C63FF), size: 16),
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

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool show;
  const _StatPill({required this.label, required this.color, required this.show});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ============================================================================
// SCREEN 2: SUBMISSION LIST PER TRYOUT (SPLIT-SCREEN MODE)
// ============================================================================
class SubmissionListScreen extends StatefulWidget {
  final String tryoutId;
  final String tryoutTitle;
  const SubmissionListScreen({
    super.key, required this.tryoutId, required this.tryoutTitle});

  @override
  State<SubmissionListScreen> createState() => _SubmissionListScreenState();
}

class _SubmissionListScreenState extends State<SubmissionListScreen> {
  String _filter = 'pending_review';
  QueryDocumentSnapshot? _selectedDoc; // Dokumen yang sedang aktif di panel kanan

  static const _filters = [
    {'val': 'pending_review', 'label': 'Menunggu',  'color': Color(0xFFFF9600)},
    {'val': 'approved',       'label': 'Disetujui', 'color': Color(0xFF10B981)},
    {'val': 'rejected',       'label': 'Ditolak',   'color': Color(0xFFFF4B4B)},
    {'val': 'all',            'label': 'Semua',     'color': Color(0xFF6C63FF)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: // ══════════════════════════════════════════════════════
// DI DALAM ROW PADA SubmissionListScreen
// ══════════════════════════════════════════════════════
      Row(
        children: [
          // PANEL KIRI: LIST & FILTER
          Expanded(
            flex: 1, // Diatur menjadi 1
            child: Container(
              // Tambahkan border kanan agar pemisah terlihat jelas
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
              ),
              child: Column(
                children: [
                  _buildHeader(context),
                  _buildFilterPills(),
                  Expanded(child: _buildList()),
                ],
              ),
            ),
          ),

          // PANEL KANAN: REVIEW DETAIL
          Expanded(
            flex: 1, // Diatur menjadi 1 agar sama besar (50/50)
            child: Container(
              color: Colors.white,
              // Hapus width: 480 karena sudah menggunakan Expanded
              child: _selectedDoc == null
                  ? _buildEmptySelection()
                  : _ReviewPanelDetail(
                key: ValueKey(_selectedDoc!.id),
                doc: _selectedDoc!,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)]),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daftar Pengajuan', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                Text(widget.tryoutTitle,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _filters.map((f) {
          final isActive = _filter == f['val'];
          final color = f['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: ChoiceChip(
                label: Text(f['label'] as String),
                selected: isActive,
                onSelected: (val) => setState(() => _filter = f['val'] as String),
                selectedColor: color,
                labelStyle: TextStyle(
                    color: isActive ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12
                ),
                backgroundColor: color.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: isActive ? color : color.withOpacity(0.2)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList() {
    var q = FirebaseFirestore.instance
        .collection('user_tryouts')
        .where('tryoutId', isEqualTo: widget.tryoutId);
    if (_filter != 'all') q = q.where('proofStatus', isEqualTo: _filter);

    return StreamBuilder<QuerySnapshot>(
      stream: q.orderBy('submittedAt', descending: true).snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("Tidak ada data"));

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final doc = docs[i];
            final isSelected = _selectedDoc?.id == doc.id;
            return _SimpleUserCard(
              doc: doc,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedDoc = doc),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptySelection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.touch_app_rounded, size: 64, color: Colors.blueGrey[50]),
        const SizedBox(height: 16),
        const Text("Pilih pengajuan di sisi kiri\nuntuk melihat bukti detail",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ============================================================================
// WIDGET: SIMPLE USER CARD (KIRI)
// ============================================================================
class _SimpleUserCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final bool isSelected;
  final VoidCallback onTap;

  const _SimpleUserCard({required this.doc, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['proofStatus'] ?? 'pending_review';

    Color statusColor = const Color(0xFFFF9600);
    if (status == 'approved') statusColor = const Color(0xFF10B981);
    if (status == 'rejected') statusColor = const Color(0xFFFF4B4B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.1), blurRadius: 10)] : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSelected ? const Color(0xFF6C63FF) : Colors.grey[100],
              child: Icon(Icons.person_rounded, color: isSelected ? Colors.white : Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['userId'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy · HH:mm').format((data['submittedAt'] as Timestamp).toDate()),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET: REVIEW PANEL DETAIL (KANAN - FIXED)
// ============================================================================
class _ReviewPanelDetail extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const _ReviewPanelDetail({required this.doc, super.key});

  @override
  State<_ReviewPanelDetail> createState() => _ReviewPanelDetailState();
}

class _ReviewPanelDetailState extends State<_ReviewPanelDetail> {
  bool _isProcessing = false;

  Map<String, dynamic> get data => widget.doc.data() as Map<String, dynamic>;
  Map<String, dynamic> get proofs => data['promotionProofs'] ?? {};

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance.collection('user_tryouts').doc(widget.doc.id).update({
        'proofStatus': newStatus,
        'isActive': newStatus == 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = data['proofStatus'] ?? 'pending_review';
    final isApproved = status == 'approved';

    return Column(
      children: [
        // Header Panel
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Review Pengajuan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text("User ID: ${data['userId']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),

        // Scrollable Images
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildProofItem("BUKTI FOLLOW", proofs['followProof'], const Color(0xFFE4405F)),
              _buildProofItem("BUKTI STORY", proofs['storyProof'], const Color(0xFFAC45E6)),
              _buildProofItem("BUKTI TAG", proofs['tagProof'], const Color(0xFF3B82F6)),
            ],
          ),
        ),

        // Bottom Actions
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[100]!)),
          ),
          child: Column(
            children: [
              if (_isProcessing)
                const LinearProgressIndicator()
              else if (status == 'pending_review') ...[
                Row(
                  children: [
                    Expanded(
                      child: _actionBtn("Tolak", const Color(0xFFFF4B4B), () => _updateStatus('rejected'), true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionBtn("Setujui", const Color(0xFF10B981), () => _updateStatus('approved'), false),
                    ),
                  ],
                ),
              ] else ...[
                _actionBtn(
                    isApproved ? "Cabut Akses (Reject)" : "Aktifkan Kembali",
                    isApproved ? const Color(0xFFFF4B4B) : const Color(0xFF10B981),
                        () => _updateStatus(isApproved ? 'rejected' : 'approved'),
                    true
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProofItem(String label, String? url, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          // Anda bisa menaikkan height menjadi 400-500 jika ingin gambar sangat besar
          height: 450,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: url == null || url.isEmpty
              ? const Center(child: Text("Gambar tidak tersedia"))
              : ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InteractiveViewer(
              // User bisa zoom in/out di area yang luas ini
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.contain, // Contain agar gambar asli terlihat utuh tanpa terpotong
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onPressed, bool isOutlined) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: isOutlined
          ? OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      )
          : ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}