// ============================================================================
// lib/admin/pages/user_management_screen.dart
// User Management — Admin Panel
// Luluzzz Design System | Navy · Gold · White
// ============================================================================

// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';

// ============================================================================
// SCREEN UTAMA
// ============================================================================
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterGoal = 'all'; // all | cpns | lpdp | ...
  String _filterRole = 'all'; // all | admin | user
  DocumentSnapshot? _selectedUser;

  // Ambil semua exam_types untuk filter goal
  final _examTypesStream = FirebaseFirestore.instance
      .collection('exam_types')
      .where('isActive', isEqualTo: true)
      .orderBy('order')
      .snapshots();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          // ── PANEL KIRI: List ──────────────────────────────────────────────
          SizedBox(
            width: 420,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  _buildLeftHeader(),
                  _buildSearchBar(),
                  _buildFilterRow(),
                  Expanded(child: _buildUserList()),
                ],
              ),
            ),
          ),

          // ── PANEL KANAN: Detail ───────────────────────────────────────────
          Expanded(
            child: _selectedUser == null
                ? _buildEmptyState()
                : _UserDetailPanel(
                    key: ValueKey(_selectedUser!.id),
                    userDoc: _selectedUser!,
                    onClose: () => setState(() => _selectedUser = null),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header Panel Kiri ─────────────────────────────────────────────────────
  Widget _buildLeftHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.navy),
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.gold, size: 13),
              AppSpacing.hxs,
              Text(
                'Admin Panel',
                style: AppText.caption.copyWith(color: AppColors.gold),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.white.withOpacity(0.35),
                  size: 13,
                ),
              ),
              Text(
                'User Management',
                style: AppText.caption.copyWith(
                  color: AppColors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          AppSpacing.vsm,
          Text(
            'User Management',
            style: AppText.h1.copyWith(color: AppColors.white),
          ),
          AppSpacing.vxs,
          // Live stats
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (_, snap) {
              final total = snap.data?.docs.length ?? 0;
              final admins =
                  snap.data?.docs
                      .where((d) => (d.data() as Map)['admin'] == true)
                      .length ??
                  0;
              return Row(
                children: [
                  _headerChip('$total Total', Icons.people_rounded),
                  AppSpacing.hsm,
                  _headerChip(
                    '$admins Admin',
                    Icons.admin_panel_settings_rounded,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _headerChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.08),
        borderRadius: AppRadius.bFull,
        border: Border.all(color: AppColors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.gold),
          AppSpacing.hxs,
          Text(
            label,
            style: AppText.label.copyWith(color: AppColors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      color: AppColors.surface,
      child: TextField(
        controller: _searchCtrl,
        style: AppText.body,
        decoration: InputDecoration(
          hintText: 'Cari nama atau email...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          isDense: true,
        ),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase().trim()),
      ),
    );
  }

  // ── Filter Row ────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Filter Role
          _FilterChipRow(
            selected: _filterRole,
            options: const [
              {'val': 'all', 'label': 'Semua'},
              {'val': 'admin', 'label': 'Admin'},
              {'val': 'user', 'label': 'User'},
            ],
            onSelect: (v) => setState(() => _filterRole = v),
          ),
          AppSpacing.hsm,
          // Divider
          Container(width: 1, height: 20, color: AppColors.border),
          AppSpacing.hsm,
          // Filter Goal dari exam_types
          StreamBuilder<QuerySnapshot>(
            stream: _examTypesStream,
            builder: (_, snap) {
              final types = snap.data?.docs ?? [];
              final options = <Map<String, String>>[
                {'val': 'all', 'label': 'Semua'},
                ...types.map(
                  (t) => {
                    'val': (t.data() as Map<String, dynamic>)['name']
                        .toString()
                        .toLowerCase(),
                    'label': (t.data() as Map<String, dynamic>)['name']
                        .toString(),
                  },
                ),
              ];
              return _FilterChipRow(
                selected: _filterGoal,
                options: options,
                onSelect: (v) => setState(() => _filterGoal = v),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── User List ─────────────────────────────────────────────────────────────
  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snap.data!.docs;

        // Filter role
        if (_filterRole == 'admin') {
          docs = docs.where((d) => (d.data() as Map)['admin'] == true).toList();
        } else if (_filterRole == 'user') {
          docs = docs.where((d) => (d.data() as Map)['admin'] != true).toList();
        }

        // Filter goal
        if (_filterGoal != 'all') {
          docs = docs
              .where(
                (d) =>
                    ((d.data() as Map)['goal'] ?? '')
                        .toString()
                        .toLowerCase() ==
                    _filterGoal,
              )
              .toList();
        }

        // Search
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map;
            final name = (data['displayName'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || email.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search_rounded,
                  size: 48,
                  color: AppColors.textHint,
                ),
                AppSpacing.vsm,
                Text('Tidak ada user ditemukan', style: AppText.bodySm),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final doc = docs[i];
            return _UserListTile(
              doc: doc,
              isSelected: _selectedUser?.id == doc.id,
              onTap: () => setState(() => _selectedUser = doc),
            );
          },
        );
      },
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      color: AppColors.bg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: AppShadow.md,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 48,
                color: AppColors.textHint,
              ),
            ),
            AppSpacing.vlg,
            Text(
              'Pilih User',
              style: AppText.h3.copyWith(color: AppColors.textSecondary),
            ),
            AppSpacing.vsm,
            Text(
              'Pilih user di sisi kiri untuk melihat detail.',
              style: AppText.bodySm,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Chip Row ───────────────────────────────────────────────────────────
class _FilterChipRow extends StatelessWidget {
  final String selected;
  final List<Map<String, String>> options;
  final ValueChanged<String> onSelect;

  const _FilterChipRow({
    required this.selected,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((o) {
        final isActive = selected == o['val'];
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => onSelect(o['val']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.surfaceAlt,
                borderRadius: AppRadius.bFull,
              ),
              child: Text(
                o['label']!,
                style: AppText.label.copyWith(
                  fontSize: 11,
                  color: isActive ? AppColors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================================
// WIDGET: USER LIST TILE
// ============================================================================
class _UserListTile extends StatelessWidget {
  final DocumentSnapshot doc;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserListTile({
    required this.doc,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['displayName'] ?? 'Anonymous';
    final email = data['email'] ?? '-';
    final isAdmin = data['admin'] == true;
    final goal = (data['goal'] ?? '').toString().toUpperCase();
    final lastLogin = (data['lastLoginAt'] as Timestamp?)?.toDate();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.bMd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.softBg(AppColors.primary)
                : AppColors.surface,
            borderRadius: AppRadius.bMd,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              _UserAvatar(
                photoUrl: data['photoURL'],
                name: name,
                isSelected: isSelected,
                size: 40,
              ),
              AppSpacing.hmd,
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppText.bodyLg.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppGradient.gold,
                              borderRadius: AppRadius.bFull,
                            ),
                            child: Text(
                              'ADMIN',
                              style: AppText.label.copyWith(
                                color: AppColors.primary,
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                    AppSpacing.vxs,
                    Text(
                      email,
                      style: AppText.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppSpacing.hsm,
              // Goal chip + last login
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (goal.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softBg(AppColors.info),
                        borderRadius: AppRadius.bFull,
                      ),
                      child: Text(
                        goal,
                        style: AppText.label.copyWith(
                          color: AppColors.info,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  if (lastLogin != null) ...[
                    AppSpacing.vxs,
                    Text(
                      DateFormat('dd MMM').format(lastLogin),
                      style: AppText.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PANEL KANAN: USER DETAIL
// ============================================================================
class _UserDetailPanel extends StatefulWidget {
  final DocumentSnapshot userDoc;
  final VoidCallback onClose;

  const _UserDetailPanel({
    required this.userDoc,
    required this.onClose,
    super.key,
  });

  @override
  State<_UserDetailPanel> createState() => _UserDetailPanelState();
}

class _UserDetailPanelState extends State<_UserDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _isTogglingAdmin = false;

  Map<String, dynamic> get data =>
      widget.userDoc.data() as Map<String, dynamic>;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _toggleAdmin() async {
    final current = data['admin'] == true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: current ? 'Cabut Hak Admin?' : 'Jadikan Admin?',
        message: current
            ? 'User ini tidak lagi memiliki akses admin panel.'
            : 'User ini akan memiliki akses penuh ke admin panel.',
        confirmLabel: current ? 'Cabut' : 'Jadikan Admin',
        confirmColor: current ? AppColors.error : AppColors.success,
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isTogglingAdmin = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userDoc.id)
          .update({'admin': !current});
    } finally {
      if (mounted) setState(() => _isTogglingAdmin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder agar data live (misal admin toggle)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userDoc.id)
          .snapshots(),
      builder: (_, snap) {
        final liveData = snap.data?.data() as Map<String, dynamic>? ?? data;
        final name = liveData['displayName'] ?? 'Anonymous';
        final email = liveData['email'] ?? '-';
        final isAdmin = liveData['admin'] == true;
        final goal = (liveData['goal'] ?? '').toString().toUpperCase();
        final createdAt = (liveData['createdAt'] as Timestamp?)?.toDate();
        final lastLogin = (liveData['lastLoginAt'] as Timestamp?)?.toDate();

        return Container(
          color: AppColors.bg,
          child: Column(
            children: [
              // ── Top Bar ─────────────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(gradient: AppGradient.navy),
                padding: const EdgeInsets.fromLTRB(28, 44, 28, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar besar
                        _UserAvatar(
                          photoUrl: liveData['photoURL'],
                          name: name,
                          size: 56,
                          isSelected: true,
                        ),
                        AppSpacing.hmd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: AppText.h2.copyWith(
                                        color: AppColors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isAdmin)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: AppGradient.gold,
                                        borderRadius: AppRadius.bFull,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.admin_panel_settings_rounded,
                                            size: 11,
                                            color: AppColors.primary,
                                          ),
                                          AppSpacing.hxs,
                                          Text(
                                            'ADMIN',
                                            style: AppText.label.copyWith(
                                              color: AppColors.primary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              AppSpacing.vxs,
                              Text(
                                email,
                                style: AppText.body.copyWith(
                                  color: AppColors.white.withOpacity(0.55),
                                ),
                              ),
                              AppSpacing.vxs,
                              Row(
                                children: [
                                  if (goal.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.white.withOpacity(0.1),
                                        borderRadius: AppRadius.bFull,
                                      ),
                                      child: Text(
                                        goal,
                                        style: AppText.label.copyWith(
                                          color: AppColors.gold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    AppSpacing.hsm,
                                  ],
                                  if (createdAt != null)
                                    Text(
                                      'Bergabung ${DateFormat('dd MMM yyyy').format(createdAt)}',
                                      style: AppText.caption.copyWith(
                                        color: AppColors.white.withOpacity(
                                          0.45,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Close
                        IconButton(
                          onPressed: widget.onClose,
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.vmd,
                    // Quick info bar
                    Row(
                      children: [
                        _infoChip(
                          Icons.login_rounded,
                          lastLogin != null
                              ? 'Login ${DateFormat('dd MMM, HH:mm').format(lastLogin)}'
                              : 'Belum pernah login',
                        ),
                        AppSpacing.hsm,
                        _infoChip(
                          Icons.fingerprint_rounded,
                          '${widget.userDoc.id.substring(0, 8)}...',
                        ),
                      ],
                    ),
                    AppSpacing.vmd,
                    // TabBar
                    TabBar(
                      controller: _tabs,
                      indicatorColor: AppColors.gold,
                      indicatorWeight: 2.5,
                      labelStyle: AppText.label.copyWith(
                        color: AppColors.white,
                      ),
                      unselectedLabelStyle: AppText.label.copyWith(
                        color: AppColors.white.withOpacity(0.45),
                      ),
                      tabs: const [
                        Tab(text: 'Tryout'),
                        Tab(text: 'Hasil'),
                        Tab(text: 'Akun'),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Tab Content ──────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _TryoutTab(userId: widget.userDoc.id),
                    _ResultsTab(userId: widget.userDoc.id),
                    _AccountTab(
                      userDoc: widget.userDoc,
                      liveData: liveData,
                      isTogglingAdmin: _isTogglingAdmin,
                      onToggleAdmin: _toggleAdmin,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.07),
        borderRadius: AppRadius.bFull,
        border: Border.all(color: AppColors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.white.withOpacity(0.5)),
          AppSpacing.hxs,
          Text(
            label,
            style: AppText.label.copyWith(
              color: AppColors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 1: TRYOUT — daftar tryout yg diikuti user
// ============================================================================
class _TryoutTab extends StatefulWidget {
  final String userId;
  const _TryoutTab({required this.userId});

  @override
  State<_TryoutTab> createState() => _TryoutTabState();
}

class _TryoutTabState extends State<_TryoutTab> {
  // Cache nama tryout agar tidak re-fetch tiap rebuild
  final Map<String, String> _tryoutNameCache = {};

  Future<String> _getTryoutName(String tryoutId) async {
    if (_tryoutNameCache.containsKey(tryoutId)) {
      return _tryoutNameCache[tryoutId]!;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tryouts')
          .doc(tryoutId)
          .get();
      final name = (doc.data()?['title'] ?? tryoutId).toString();
      _tryoutNameCache[tryoutId] = name;
      print('[LuluzzAdmin][TryoutTab] Fetched tryout: $tryoutId → $name');
      return name;
    } catch (e) {
      print('[LuluzzAdmin][TryoutTab] ❌ Gagal fetch tryout $tryoutId: $e');
      return tryoutId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // ✅ FIX: hapus orderBy → tidak butuh composite index
      // sort dilakukan di client di bawah
      stream: FirebaseFirestore.instance
          .collection('user_tryouts')
          .where('userId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (_, snap) {
        if (snap.hasError) {
          print('[LuluzzAdmin][TryoutTab] ❌ Stream error: ${snap.error}');
          print(snap.stackTrace);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: AppColors.error,
                ),
                AppSpacing.vsm,
                Text('Error memuat tryout', style: AppText.bodySm),
                AppSpacing.vxs,
                SelectableText(
                  snap.error.toString(),
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ✅ Sort di client (desc by lastAttemptAt)
        final docs = List<QueryDocumentSnapshot>.from(snap.data!.docs)
          ..sort((a, b) {
            final aT =
                ((a.data() as Map)['lastAttemptAt'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                0;
            final bT =
                ((b.data() as Map)['lastAttemptAt'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                0;
            return bT.compareTo(aT);
          });

        print(
          '[LuluzzAdmin][TryoutTab] userId=${widget.userId} → ${docs.length} tryout ditemukan',
        );

        if (docs.isEmpty) {
          return _EmptyTab(
            icon: Icons.quiz_rounded,
            label: 'Belum ada tryout diikuti',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => AppSpacing.vsm,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final proofStatus = d['proofStatus'] ?? '-';
            final isActive = d['isActive'] == true;
            final lastAttempt = (d['lastAttemptAt'] as Timestamp?)?.toDate();
            final subtestProgress =
                d['subtestProgress'] as Map<String, dynamic>? ?? {};
            final tryoutId = d['tryoutId'] ?? '';

            final Color statusColor = switch (proofStatus) {
              'approved' => AppColors.success,
              'rejected' => AppColors.error,
              'pending_review' => AppColors.warning,
              _ => AppColors.textSecondary,
            };

            // ✅ FIX: FutureBuilder tetap dipakai tapi dengan cache
            // sehingga tidak re-fetch setelah data sudah ada
            return FutureBuilder<String>(
              future: _getTryoutName(tryoutId),
              builder: (_, tSnap) {
                final tryoutName = tSnap.data ?? tryoutId;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.bMd,
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadow.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child:
                                tSnap.connectionState == ConnectionState.waiting
                                ? Container(
                                    height: 14,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceAlt,
                                      borderRadius: AppRadius.bSm,
                                    ),
                                  )
                                : Text(
                                    tryoutName,
                                    style: AppText.bodyLg.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                          AppSpacing.hsm,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softBg(statusColor),
                              borderRadius: AppRadius.bFull,
                            ),
                            child: Text(
                              switch (proofStatus) {
                                'approved' => 'Disetujui',
                                'rejected' => 'Ditolak',
                                'pending_review' => 'Pending',
                                _ => proofStatus,
                              },
                              style: AppText.label.copyWith(
                                color: statusColor,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          AppSpacing.hxs,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.softBg(AppColors.success)
                                  : AppColors.surfaceAlt,
                              borderRadius: AppRadius.bFull,
                            ),
                            child: Text(
                              isActive ? 'Aktif' : 'Nonaktif',
                              style: AppText.label.copyWith(
                                color: isActive
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (lastAttempt != null) ...[
                        AppSpacing.vxs,
                        Text(
                          'Terakhir dikerjakan: ${DateFormat('dd MMM yyyy, HH:mm').format(lastAttempt)}',
                          style: AppText.caption,
                        ),
                      ],
                      if (subtestProgress.isNotEmpty) ...[
                        AppSpacing.vsm,
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: subtestProgress.entries.map((e) {
                            final sub = e.value as Map<String, dynamic>;
                            final score = sub['bestScore'] ?? 0;
                            final attempts = sub['attempts'] ?? 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: AppRadius.bSm,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    e.key,
                                    style: AppText.label.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  AppSpacing.hxs,
                                  Text(
                                    '$score pts · ${attempts}x',
                                    style: AppText.caption,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// TAB 2: HASIL — exam_results user
// ============================================================================
class _ResultsTab extends StatelessWidget {
  final String userId;
  const _ResultsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: hapus orderBy → tidak butuh composite index
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exam_results')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (_, snap) {
        if (snap.hasError) {
          print('[LuluzzAdmin][ResultsTab] ❌ Stream error: ${snap.error}');
          print(snap.stackTrace);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: AppColors.error,
                ),
                AppSpacing.vsm,
                Text('Error memuat hasil ujian', style: AppText.bodySm),
                AppSpacing.vxs,
                SelectableText(
                  snap.error.toString(),
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ✅ Sort di client (desc by completedAt)
        final docs = List<QueryDocumentSnapshot>.from(snap.data!.docs)
          ..sort((a, b) {
            final aT =
                ((a.data() as Map)['completedAt'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                0;
            final bT =
                ((b.data() as Map)['completedAt'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                0;
            return bT.compareTo(aT);
          });

        print(
          '[LuluzzAdmin][ResultsTab] userId=$userId → ${docs.length} hasil ditemukan',
        );

        if (docs.isEmpty) {
          return _EmptyTab(
            icon: Icons.bar_chart_rounded,
            label: 'Belum ada hasil ujian',
          );
        }

        // Group by tryoutId untuk summary
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final tid = data['tryoutId'] ?? 'unknown';
          grouped.putIfAbsent(tid, () => []).add(data);
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Summary stats
            _ResultSummary(docs: docs),
            AppSpacing.vlg,
            Text('Riwayat Pengerjaan', style: AppText.h3),
            AppSpacing.vsm,
            ...docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              final score = data['score'] ?? 0;
              final subtest = data['subtestId'] ?? '-';
              final total = data['totalQuestions'] ?? 0;
              final correct = data['correctAnswers'] ?? 0;
              final wrong = data['wrongAnswers'] ?? 0;
              final completedAt = (data['completedAt'] as Timestamp?)?.toDate();
              final dur = data['totalTimeSeconds'] ?? 0;
              final catScores =
                  data['categoryScores'] as Map<String, dynamic>? ?? {};

              // Score color
              final Color scoreColor = score >= 70
                  ? AppColors.success
                  : score >= 50
                  ? AppColors.warning
                  : AppColors.error;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.bMd,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadow.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Score circle
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.softBg(scoreColor),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: scoreColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$score',
                              style: AppText.h3.copyWith(color: scoreColor),
                            ),
                          ),
                        ),
                        AppSpacing.hmd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.softBg(
                                        AppColors.primary,
                                      ),
                                      borderRadius: AppRadius.bFull,
                                    ),
                                    child: Text(
                                      subtest,
                                      style: AppText.label.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  AppSpacing.hsm,
                                  Text(
                                    '$correct benar · $wrong salah · $total soal',
                                    style: AppText.caption,
                                  ),
                                ],
                              ),
                              AppSpacing.vxs,
                              if (completedAt != null)
                                Text(
                                  '${DateFormat('dd MMM yyyy, HH:mm').format(completedAt)} · ${_formatDuration(dur)}',
                                  style: AppText.caption,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (catScores.isNotEmpty) ...[
                      AppSpacing.vsm,
                      const Divider(height: 1, color: AppColors.border),
                      AppSpacing.vsm,
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: catScores.entries.map((e) {
                          final cat = e.value as Map<String, dynamic>;
                          final pct = cat['percentage'] ?? 0;
                          final Color pctColor = pct >= 70
                              ? AppColors.success
                              : pct >= 50
                              ? AppColors.warning
                              : AppColors.error;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: AppRadius.bSm,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  e.key,
                                  style: AppText.label.copyWith(fontSize: 11),
                                ),
                                AppSpacing.hxs,
                                Text(
                                  '$pct%',
                                  style: AppText.label.copyWith(
                                    color: pctColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  String _formatDuration(int secs) {
    if (secs < 60) return '${secs}d';
    return '${secs ~/ 60}m ${secs % 60}d';
  }
}

// ── Result Summary Cards ──────────────────────────────────────────────────────
class _ResultSummary extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  const _ResultSummary({required this.docs});

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) return const SizedBox.shrink();
    final scores = docs
        .map((d) => (d.data() as Map<String, dynamic>)['score'] as num? ?? 0)
        .toList();
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    final best = scores.reduce((a, b) => a > b ? a : b);
    final attempts = docs.length;

    return Row(
      children: [
        _SummaryCard(
          label: 'Total Sesi',
          value: '$attempts',
          icon: Icons.repeat_rounded,
          color: AppColors.info,
        ),
        AppSpacing.hmd,
        _SummaryCard(
          label: 'Nilai Terbaik',
          value: '$best',
          icon: Icons.emoji_events_rounded,
          color: AppColors.warning,
        ),
        AppSpacing.hmd,
        _SummaryCard(
          label: 'Rata-rata',
          value: avg.toStringAsFixed(1),
          icon: Icons.analytics_rounded,
          color: AppColors.success,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.bMd,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadow.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.softBg(color),
                borderRadius: AppRadius.bSm,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            AppSpacing.hsm,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.caption),
                Text(value, style: AppText.h2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 3: AKUN — info akun + toggle admin
// ============================================================================
class _AccountTab extends StatelessWidget {
  final DocumentSnapshot userDoc;
  final Map<String, dynamic> liveData;
  final bool isTogglingAdmin;
  final VoidCallback onToggleAdmin;

  const _AccountTab({
    required this.userDoc,
    required this.liveData,
    required this.isTogglingAdmin,
    required this.onToggleAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = liveData['admin'] == true;
    final settings = liveData['settings'] as Map<String, dynamic>? ?? {};
    final createdAt = (liveData['createdAt'] as Timestamp?)?.toDate();
    final lastLogin = (liveData['lastLoginAt'] as Timestamp?)?.toDate();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // ── Info Akun ──────────────────────────────────────────────────────
        _SectionCard(
          title: 'Informasi Akun',
          icon: Icons.person_rounded,
          children: [
            _InfoRow('User ID', userDoc.id, canCopy: true),
            _InfoRow('Display Name', liveData['displayName'] ?? '-'),
            _InfoRow('Email', liveData['email'] ?? '-'),
            _InfoRow(
              'Goal',
              (liveData['goal'] ?? '-').toString().toUpperCase(),
            ),
            _InfoRow(
              'Bergabung',
              createdAt != null
                  ? DateFormat('dd MMMM yyyy').format(createdAt)
                  : '-',
            ),
            _InfoRow(
              'Terakhir Login',
              lastLogin != null
                  ? DateFormat('dd MMM yyyy, HH:mm').format(lastLogin)
                  : '-',
            ),
          ],
        ),
        AppSpacing.vmd,

        // ── Pengaturan ─────────────────────────────────────────────────────
        _SectionCard(
          title: 'Pengaturan User',
          icon: Icons.settings_rounded,
          children: [
            _SettingRow('Dark Mode', settings['darkMode'] == true),
            _SettingRow('Notifikasi', settings['notifications'] == true),
            _SettingRow('Sound', settings['soundEnabled'] == true),
          ],
        ),
        AppSpacing.vmd,

        // ── Kontrol Admin ──────────────────────────────────────────────────
        _SectionCard(
          title: 'Kontrol Admin',
          icon: Icons.security_rounded,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hak Admin',
                          style: AppText.bodyLg.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.vxs,
                        Text(
                          isAdmin
                              ? 'User ini memiliki akses penuh ke admin panel.'
                              : 'User ini tidak memiliki akses admin panel.',
                          style: AppText.bodySm,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.hmd,
                  if (isTogglingAdmin)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    Switch(
                      value: isAdmin,
                      onChanged: (_) => onToggleAdmin(),
                      activeColor: AppColors.primary,
                    ),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.vmd,

        // ── Danger Zone ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.softBg(AppColors.error),
            borderRadius: AppRadius.bMd,
            border: Border.all(color: AppColors.error.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                  AppSpacing.hxs,
                  Text(
                    'Danger Zone',
                    style: AppText.label.copyWith(color: AppColors.error),
                  ),
                ],
              ),
              AppSpacing.vsm,
              Text(
                'Aksi berikut bersifat permanen dan tidak dapat dibatalkan.',
                style: AppText.bodySm.copyWith(color: AppColors.error),
              ),
              AppSpacing.vsm,
              // Info only — delete user biasanya butuh Cloud Function
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.bSm,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    AppSpacing.hsm,
                    Expanded(
                      child: Text(
                        'Untuk menghapus akun user, gunakan Firebase Console atau Cloud Function.',
                        style: AppText.bodySm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                AppSpacing.hxs,
                Text(
                  title,
                  style: AppText.label.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool canCopy;

  const _InfoRow(this.label, this.value, {this.canCopy = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: AppText.bodySm)),
          Expanded(
            child: Text(
              value,
              style: AppText.body.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (canCopy)
            InkWell(
              onTap: () {
                // clipboard
              },
              borderRadius: AppRadius.bSm,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Setting Row ───────────────────────────────────────────────────────────────
class _SettingRow extends StatelessWidget {
  final String label;
  final bool value;

  const _SettingRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: value
                  ? AppColors.softBg(AppColors.success)
                  : AppColors.surfaceAlt,
              borderRadius: AppRadius.bFull,
            ),
            child: Text(
              value ? 'Aktif' : 'Nonaktif',
              style: AppText.label.copyWith(
                color: value ? AppColors.success : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty Tab ─────────────────────────────────────────────────────────────────
class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textHint),
          AppSpacing.vsm,
          Text(label, style: AppText.bodySm),
        ],
      ),
    );
  }
}

// ── User Avatar ───────────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final bool isSelected;
  final double size;

  const _UserAvatar({
    required this.photoUrl,
    required this.name,
    required this.size,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: AppRadius.bMd,
        gradient: hasPhoto ? null : AppGradient.navy,
        image: hasPhoto
            ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover)
            : null,
        border: isSelected ? Border.all(color: AppColors.gold, width: 2) : null,
      ),
      child: hasPhoto
          ? null
          : Center(
              child: Text(
                initials,
                style: AppText.h3.copyWith(color: AppColors.white),
              ),
            ),
    );
  }
}

// ── Confirm Dialog ────────────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final String title, message, confirmLabel;
  final Color confirmColor;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.bLg),
      title: Text(title, style: AppText.h3),
      content: Text(message, style: AppText.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Batal',
            style: AppText.btnMd.copyWith(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
          ),
          child: Text(confirmLabel, style: AppText.btnMd),
        ),
      ],
    );
  }
}
