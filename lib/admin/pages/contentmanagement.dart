// ============================================================================
// lib/admin/pages/content_management_screen.dart
// Content Management — Admin Panel
// Luluzzz Design System | Navy · Gold · White
// Strategy:
//   - Satu StreamBuilder utama untuk list tryout (minimal reads)
//   - Edit in-place dengan optimistic UI
//   - Questions lazy-load hanya saat dibutuhkan (tidak ikut di list query)
//   - Preview mode reuse widget yang sama dengan user-facing
// ============================================================================

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import 'CreateTO.dart';

// ─── FIRESTORE STRATEGY ───────────────────────────────────────────────────────
// tryouts collection dokumen struktur:
// {
//   title, description, examTypeId, examTypeName, price, isActive,
//   isFlexibleDate, startDate, endDate, totalQuestions, subTestCount,
//   totalEstimatedMinutes, createdAt, updatedAt,
//   subtests: [ { name, category, type, questionCount, questions:[...] } ]
// }
//
// READ strategy:
//   List view  → ambil semua field KECUALI subtests[].questions (field besar)
//                Gunakan select() jika Firestore SDK mendukung,
//                atau struktur subcollection jika dokumen > 1MB.
//   Edit/Preview → fetch satu dokumen penuh (lazy, hanya saat dipilih)
//
// WRITE strategy:
//   Toggle aktif → update 1 field saja (isActive)
//   Edit metadata → update field tanpa menyentuh subtests.questions
//   Delete → deleteDocument (cascade otomatis karena embedded)
// ─────────────────────────────────────────────────────────────────────────────

// ============================================================================
// SCREEN UTAMA
// ============================================================================
class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  State<ContentManagementScreen> createState() =>
      _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  String _searchQuery = '';
  String _filterStatus = 'all'; // all | active | inactive
  final TextEditingController _searchCtrl = TextEditingController();

  // Panel kanan
  String? _selectedTryoutId;
  _RightPanelMode _panelMode = _RightPanelMode.empty;

  // Cache dokumen penuh (dengan questions) agar tidak re-fetch
  final Map<String, Map<String, dynamic>> _fullDocCache = {};

  // Loading state untuk panel kanan
  bool _isPanelLoading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Fetch dokumen penuh (dengan questions) – lazy, dikache
  Future<Map<String, dynamic>?> _fetchFullDoc(String id) async {
    if (_fullDocCache.containsKey(id)) return _fullDocCache[id];
    final snap = await FirebaseFirestore.instance
        .collection('tryouts')
        .doc(id)
        .get();
    if (!snap.exists) return null;
    final data = snap.data()!..['__id'] = snap.id;
    _fullDocCache[id] = data;
    return data;
  }

  void _invalidateCache(String id) => _fullDocCache.remove(id);

  Future<void> _selectTryout(String id, _RightPanelMode mode) async {
    if (_selectedTryoutId == id && _panelMode == mode) return;
    setState(() {
      _selectedTryoutId = id;
      _panelMode = mode;
      _isPanelLoading = true;
    });
    await _fetchFullDoc(id);
    if (mounted) setState(() => _isPanelLoading = false);
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> _deleteTryout(String id, String title) async {
    final confirm = await _showConfirmDialog(
      title: 'Hapus Tryout?',
      message: '"$title" akan dihapus permanen beserta semua soal di dalamnya.',
      confirmLabel: 'Hapus',
      confirmColor: AppColors.error,
    );
    if (confirm != true || !mounted) return;

    try {
      await FirebaseFirestore.instance.collection('tryouts').doc(id).delete();
      _invalidateCache(id);
      if (mounted && _selectedTryoutId == id) {
        setState(() {
          _selectedTryoutId = null;
          _panelMode = _RightPanelMode.empty;
        });
      }
      _showSnack('Tryout "$title" berhasil dihapus', isError: false);
    } catch (e) {
      _showSnack('Gagal menghapus: $e', isError: true);
    }
  }

  // ── Toggle aktif ───────────────────────────────────────────────────────────
  Future<void> _toggleActive(String id, bool current) async {
    try {
      await FirebaseFirestore.instance.collection('tryouts').doc(id).update({
        'isActive': !current,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _invalidateCache(id);
    } catch (e) {
      _showSnack('Gagal mengubah status: $e', isError: true);
    }
  }

  // ── UI Helpers ─────────────────────────────────────────────────────────────
  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppText.body.copyWith(color: AppColors.white),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bLg),
        title: Text(title, style: AppText.h3),
        content: Text(message, style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: AppText.body.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel, style: AppText.btnMd),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // BUILD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          // ── PANEL KIRI ──────────────────────────────────────────────────────
          SizedBox(
            width: 400,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  _buildLeftHeader(),
                  _buildSearchAndFilter(),
                  Expanded(child: _buildTryoutList()),
                ],
              ),
            ),
          ),

          // ── PANEL KANAN ─────────────────────────────────────────────────────
          Expanded(child: _buildRightPanel()),
        ],
      ),
    );
  }

  // ============================================================================
  // LEFT PANEL — Header
  // ============================================================================
  Widget _buildLeftHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.navy),
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.gold, size: 12),
              AppSpacing.hxs,
              Text(
                'Admin',
                style: AppText.caption.copyWith(color: AppColors.gold),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.white.withOpacity(0.35),
                size: 12,
              ),
              Text(
                'Content',
                style: AppText.caption.copyWith(
                  color: AppColors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          AppSpacing.vsm,
          Row(
            children: [
              Expanded(
                child: Text(
                  'Content Management',
                  style: AppText.h2.copyWith(color: AppColors.white),
                ),
              ),
              // Tombol buat tryout baru
              _GoldButton(
                label: 'Buat Baru',
                icon: Icons.add_rounded,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateTryoutScreen(),
                    ),
                  );
                  // invalidate semua cache setelah kembali
                  _fullDocCache.clear();
                },
              ),
            ],
          ),
          AppSpacing.vsm,
          // Live stats
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tryouts')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Row(children: [_statChip('...', Icons.quiz_rounded)]);
              }

              if (snap.hasError) {
                return Row(
                  children: [_statChip('0 Tryout', Icons.quiz_rounded)],
                );
              }

              final total = snap.data?.docs.length ?? 0;

              return Row(
                children: [_statChip('$total Tryout', Icons.quiz_rounded)],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.08),
        borderRadius: AppRadius.bFull,
        border: Border.all(color: AppColors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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

  // ============================================================================
  // LEFT PANEL — Search & Filter
  // ============================================================================
  Widget _buildSearchAndFilter() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchCtrl,
            style: AppText.body,
            decoration: InputDecoration(
              hintText: 'Cari judul tryout...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 17,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 15,
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
                vertical: 8,
              ),
              isDense: true,
            ),
            onChanged: (v) =>
                setState(() => _searchQuery = v.toLowerCase().trim()),
          ),
          AppSpacing.vsm,
          // Filter chips
          Row(
            children: [
              _FilterChip(
                label: 'Semua',
                selected: _filterStatus == 'all',
                onTap: () => setState(() => _filterStatus = 'all'),
              ),
              AppSpacing.hxs,
              _FilterChip(
                label: 'Aktif',
                selected: _filterStatus == 'active',
                onTap: () => setState(() => _filterStatus = 'active'),
                activeColor: AppColors.success,
              ),
              AppSpacing.hxs,
              _FilterChip(
                label: 'Nonaktif',
                selected: _filterStatus == 'inactive',
                onTap: () => setState(() => _filterStatus = 'inactive'),
                activeColor: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // LEFT PANEL — Tryout List
  // ============================================================================
  Widget _buildTryoutList() {
    // ── EFFICIENT READ: hanya ambil metadata, bukan questions ────────────────
    // Firestore tidak support field exclusion secara native,
    // tapi karena kita embed questions di dalam subtests array,
    // dokumen kecil (<100KB) masih ok untuk list.
    // Jika dokumen > 1MB, pisahkan questions ke subcollection.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tryouts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (snap.hasError) {
          return _ErrorState(error: snap.error.toString());
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snap.data!.docs;

        // Filter status
        if (_filterStatus == 'active') {
          docs = docs
              .where((d) => (d.data() as Map)['isActive'] == true)
              .toList();
        } else if (_filterStatus == 'inactive') {
          docs = docs
              .where((d) => (d.data() as Map)['isActive'] != true)
              .toList();
        }

        // Search
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            final title = ((d.data() as Map)['title'] ?? '')
                .toString()
                .toLowerCase();
            return title.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: AppColors.textHint,
                ),
                AppSpacing.vsm,
                Text('Tidak ada tryout ditemukan', style: AppText.bodySm),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final isSelected = _selectedTryoutId == doc.id;

            return _TryoutListCard(
              id: doc.id,
              data: data,
              isSelected: isSelected,
              onTap: () => _selectTryout(doc.id, _RightPanelMode.detail),
              onEdit: () => _selectTryout(doc.id, _RightPanelMode.edit),
              onPreview: () => _selectTryout(doc.id, _RightPanelMode.preview),
              onToggleActive: () =>
                  _toggleActive(doc.id, data['isActive'] == true),
              onDelete: () =>
                  _deleteTryout(doc.id, data['title'] ?? 'Tryout ini'),
            );
          },
        );
      },
    );
  }

  // ============================================================================
  // RIGHT PANEL
  // ============================================================================
  Widget _buildRightPanel() {
    if (_selectedTryoutId == null) {
      return _buildEmptyRight();
    }

    if (_isPanelLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final fullDoc = _fullDocCache[_selectedTryoutId];
    if (fullDoc == null) {
      return _buildEmptyRight();
    }

    return switch (_panelMode) {
      _RightPanelMode.detail => _DetailPanel(
        data: fullDoc,
        onEdit: () => setState(() => _panelMode = _RightPanelMode.edit),
        onPreview: () => setState(() => _panelMode = _RightPanelMode.preview),
        onClose: () => setState(() {
          _selectedTryoutId = null;
          _panelMode = _RightPanelMode.empty;
        }),
      ),
      _RightPanelMode.edit => _EditPanel(
        docId: _selectedTryoutId!,
        data: fullDoc,
        onSaved: () {
          _invalidateCache(_selectedTryoutId!);
          _selectTryout(_selectedTryoutId!, _RightPanelMode.detail);
        },
        onClose: () => setState(() => _panelMode = _RightPanelMode.detail),
      ),
      _RightPanelMode.preview => _PreviewPanel(
        data: fullDoc,
        onClose: () => setState(() => _panelMode = _RightPanelMode.detail),
      ),
      _RightPanelMode.empty => _buildEmptyRight(),
    };
  }

  Widget _buildEmptyRight() {
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
                Icons.quiz_rounded,
                size: 44,
                color: AppColors.textHint,
              ),
            ),
            AppSpacing.vlg,
            Text(
              'Pilih Tryout',
              style: AppText.h3.copyWith(color: AppColors.textSecondary),
            ),
            AppSpacing.vsm,
            Text(
              'Pilih tryout di kiri untuk melihat detail,\nedit, atau preview.',
              style: AppText.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Enum panel mode ───────────────────────────────────────────────────────────
enum _RightPanelMode { empty, detail, edit, preview }

// ============================================================================
// WIDGET: TRYOUT LIST CARD
// ============================================================================
class _TryoutListCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _TryoutListCard({
    required this.id,
    required this.data,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onPreview,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Tanpa Judul';
    final isActive = data['isActive'] == true;
    final examTypeName = data['examTypeName'] ?? '';
    final totalQ = data['totalQuestions'] ?? 0;
    final subCount = data['subTestCount'] ?? 0;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Title + status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppText.bodyLg.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppSpacing.hxs,
                  // Status badge
                  GestureDetector(
                    onTap: onToggleActive,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
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
                  ),
                ],
              ),
              AppSpacing.vxs,
              // Row 2: Metadata chips
              Row(
                children: [
                  if (examTypeName.isNotEmpty) ...[
                    _MetaChip(examTypeName, AppColors.info),
                    AppSpacing.hxs,
                  ],
                  _MetaChip('$subCount subtes', AppColors.primary),
                  AppSpacing.hxs,
                  _MetaChip('$totalQ soal', AppColors.warning),
                ],
              ),
              AppSpacing.vxs,
              // Row 3: Actions + date
              Row(
                children: [
                  if (createdAt != null)
                    Expanded(
                      child: Text(
                        DateFormat('dd MMM yyyy').format(createdAt),
                        style: AppText.caption.copyWith(fontSize: 10),
                      ),
                    ),
                  // Action buttons (compact)
                  _IconAction(
                    icon: Icons.visibility_rounded,
                    color: AppColors.info,
                    tooltip: 'Preview',
                    onTap: onPreview,
                  ),
                  _IconAction(
                    icon: Icons.edit_rounded,
                    color: AppColors.primary,
                    tooltip: 'Edit',
                    onTap: onEdit,
                  ),
                  _IconAction(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.error,
                    tooltip: 'Hapus',
                    onTap: onDelete,
                  ),
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
// RIGHT PANEL: DETAIL
// ============================================================================
class _DetailPanel extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onClose;

  const _DetailPanel({
    required this.data,
    required this.onEdit,
    required this.onPreview,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? '-';
    final desc = data['description'] ?? '-';
    final isActive = data['isActive'] == true;
    final examTypeName = data['examTypeName'] ?? '-';
    final totalQ = data['totalQuestions'] ?? 0;
    final subCount = data['subTestCount'] ?? 0;
    final totalMin = data['totalEstimatedMinutes'] ?? 0;
    final price = data['price'] ?? 0;
    final isFlexible = data['isFlexibleDate'] == true;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
    final subtests = (data['subtests'] as List<dynamic>? ?? []);

    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          // ── Top Bar ──────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(gradient: AppGradient.navy),
            padding: const EdgeInsets.fromLTRB(24, 44, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppText.h2.copyWith(color: AppColors.white),
                        maxLines: 2,
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vsm,
                Text(
                  desc,
                  style: AppText.body.copyWith(
                    color: AppColors.white.withOpacity(0.55),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.vmd,
                // Stats row
                Row(
                  children: [
                    _TopStat('$totalQ Soal', Icons.quiz_rounded),
                    AppSpacing.hsm,
                    _TopStat('$subCount Subtes', Icons.layers_rounded),
                    AppSpacing.hsm,
                    _TopStat('${totalMin}m', Icons.timer_rounded),
                    AppSpacing.hsm,
                    _TopStat('Rp $price', Icons.attach_money_rounded),
                  ],
                ),
                AppSpacing.vmd,
                // Action buttons
                Row(
                  children: [
                    _GoldButton(
                      label: 'Edit',
                      icon: Icons.edit_rounded,
                      onTap: onEdit,
                    ),
                    AppSpacing.hsm,
                    _OutlineButton(
                      label: 'Preview',
                      icon: Icons.visibility_rounded,
                      onTap: onPreview,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Info cards row
                Row(
                  children: [
                    _InfoCard(
                      'Tipe Ujian',
                      examTypeName,
                      Icons.school_rounded,
                      AppColors.info,
                    ),
                    AppSpacing.hmd,
                    _InfoCard(
                      'Status',
                      isActive ? 'Aktif' : 'Nonaktif',
                      Icons.toggle_on_rounded,
                      isActive ? AppColors.success : AppColors.textSecondary,
                    ),
                    AppSpacing.hmd,
                    _InfoCard(
                      'Periode',
                      isFlexible ? 'Bebas' : 'Terjadwal',
                      Icons.calendar_today_rounded,
                      AppColors.warning,
                    ),
                  ],
                ),
                AppSpacing.vmd,

                // Timestamps
                if (createdAt != null)
                  _InfoRow(
                    'Dibuat',
                    DateFormat('dd MMM yyyy, HH:mm').format(createdAt),
                  ),
                if (updatedAt != null)
                  _InfoRow(
                    'Diperbarui',
                    DateFormat('dd MMM yyyy, HH:mm').format(updatedAt),
                  ),
                _InfoRow('ID Dokumen', data['__id'] ?? '-', canCopy: true),

                AppSpacing.vmd,

                // Subtests list
                Text('Daftar Subtes', style: AppText.h3),
                AppSpacing.vsm,
                ...subtests.asMap().entries.map((e) {
                  final i = e.key;
                  final sub = e.value as Map<String, dynamic>;
                  return _SubtestDetailCard(index: i, data: sub);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RIGHT PANEL: EDIT
// ============================================================================
class _EditPanel extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onSaved;
  final VoidCallback onClose;

  const _EditPanel({
    required this.docId,
    required this.data,
    required this.onSaved,
    required this.onClose,
  });

  @override
  State<_EditPanel> createState() => _EditPanelState();
}

class _EditPanelState extends State<_EditPanel> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late bool _isActive;
  late bool _isFlexible;
  bool _isSaving = false;

  // Subtes editing — hanya nama & deskripsi, TIDAK menyentuh questions
  late List<Map<String, dynamic>> _subtests;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.data['title'] ?? '');
    _descCtrl = TextEditingController(text: widget.data['description'] ?? '');
    _priceCtrl = TextEditingController(
      text: (widget.data['price'] ?? 1).toString(),
    );
    _isActive = widget.data['isActive'] == true;
    _isFlexible = widget.data['isFlexibleDate'] == true;

    // Deep copy subtests (hanya metadata, bukan questions)
    _subtests = (widget.data['subtests'] as List<dynamic>? ?? []).map((s) {
      final sub = Map<String, dynamic>.from(s as Map);
      return sub;
    }).toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    try {
      // ── SMART UPDATE: hanya update field metadata ──────────────────────
      // subtests.questions TIDAK disentuh karena kita tidak load/edit mereka
      // Firestore update() hanya update field yang disebutkan
      final subtestsMeta = _subtests.map((s) {
        // Pertahankan questions yang ada, hanya update metadata
        return {
          ...s, // include questions yang sudah ada
          'name': s['name'],
          'description': s['description'],
          'category': s['category'],
          'difficulty': s['difficulty'],
          'estimatedMinutes': s['estimatedMinutes'],
          'type': s['type'],
          // 'questions' tetap dipertahankan dari data original
        };
      }).toList();

      await FirebaseFirestore.instance
          .collection('tryouts')
          .doc(widget.docId)
          .update({
            'title': _titleCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
            'price': int.tryParse(_priceCtrl.text) ?? 1,
            'isActive': _isActive,
            'isFlexibleDate': _isFlexible,
            'subtests': subtestsMeta,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(gradient: AppGradient.navy),
            padding: const EdgeInsets.fromLTRB(24, 44, 24, 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Tryout',
                        style: AppText.h2.copyWith(color: AppColors.white),
                      ),
                      Text(
                        widget.data['title'] ?? '',
                        style: AppText.body.copyWith(
                          color: AppColors.white.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: widget.onClose,
                  child: Text(
                    'Batal',
                    style: AppText.body.copyWith(
                      color: AppColors.white.withOpacity(0.6),
                    ),
                  ),
                ),
                AppSpacing.hsm,
                _GoldButton(
                  label: _isSaving ? 'Menyimpan...' : 'Simpan',
                  icon: Icons.save_rounded,
                  onTap: _isSaving ? null : _save,
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ── Metadata tryout ───────────────────────────────────────
                _SectionCard(
                  title: 'Informasi Tryout',
                  icon: Icons.description_rounded,
                  children: [
                    _EditField(label: 'Judul', controller: _titleCtrl),
                    AppSpacing.vmd,
                    _EditField(
                      label: 'Deskripsi',
                      controller: _descCtrl,
                      maxLines: 3,
                    ),
                    AppSpacing.vmd,
                    _EditField(
                      label: 'Harga',
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                    ),
                    AppSpacing.vmd,
                    Row(
                      children: [
                        Expanded(
                          child: _SwitchRow(
                            label: 'Status Aktif',
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                          ),
                        ),
                        AppSpacing.hmd,
                        Expanded(
                          child: _SwitchRow(
                            label: 'Tanggal Bebas',
                            value: _isFlexible,
                            onChanged: (v) => setState(() => _isFlexible = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                AppSpacing.vmd,

                // ── Subtes metadata ───────────────────────────────────────
                _SectionCard(
                  title: 'Metadata Subtes',
                  icon: Icons.layers_rounded,
                  subtitle:
                      'Edit nama & deskripsi. Soal dikelola via upload Excel.',
                  children: [
                    ..._subtests.asMap().entries.map((e) {
                      final i = e.key;
                      final sub = e.value;
                      return _SubtestEditRow(
                        index: i,
                        data: sub,
                        onChanged: (updated) {
                          setState(() => _subtests[i] = updated);
                        },
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RIGHT PANEL: PREVIEW
// ============================================================================
class _PreviewPanel extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onClose;

  const _PreviewPanel({required this.data, required this.onClose});

  @override
  State<_PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<_PreviewPanel> {
  int _selectedSubtest = 0;
  int _currentQuestion = 0;
  final Map<int, int?> _answers = {}; // questionIndex → answerIndex

  List<dynamic> get subtests => widget.data['subtests'] as List<dynamic>? ?? [];

  List<dynamic> get currentQuestions {
    if (subtests.isEmpty) return [];
    if (_selectedSubtest >= subtests.length) return [];
    final sub = subtests[_selectedSubtest];
    if (sub is! Map) return [];
    return (sub as Map<String, dynamic>)['questions'] as List<dynamic>? ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          // Preview Header
          Container(
            decoration: const BoxDecoration(gradient: AppGradient.navy),
            padding: const EdgeInsets.fromLTRB(24, 44, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                            Icons.visibility_rounded,
                            size: 11,
                            color: AppColors.primary,
                          ),
                          AppSpacing.hxs,
                          Text(
                            'PREVIEW MODE',
                            style: AppText.label.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vsm,
                Text(
                  widget.data['title'] ?? '',
                  style: AppText.h2.copyWith(color: AppColors.white),
                ),
                AppSpacing.vmd,
                // Subtest tabs
                if (subtests.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: subtests.asMap().entries.map((e) {
                        final i = e.key;
                        final sub = e.value as Map<String, dynamic>;
                        final isSelected = i == _selectedSubtest;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedSubtest = i;
                              _currentQuestion = 0;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.gold
                                    : AppColors.white.withOpacity(0.1),
                                borderRadius: AppRadius.bMd,
                              ),
                              child: Text(
                                sub['name'] ?? 'Subtes ${i + 1}',
                                style: AppText.label.copyWith(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                AppSpacing.vsm,
              ],
            ),
          ),

          // Question Area
          Expanded(
            child: currentQuestions.isEmpty
                ? Center(child: Text('Tidak ada soal', style: AppText.bodySm))
                : _QuestionPreviewArea(
                    questions: currentQuestions,
                    currentIndex: _currentQuestion,
                    answers: _answers,
                    onAnswerSelected: (qi, ai) =>
                        setState(() => _answers[qi] = ai),
                    onNavigate: (i) => setState(() => _currentQuestion = i),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET: QUESTION PREVIEW AREA
// ============================================================================
class _QuestionPreviewArea extends StatelessWidget {
  final List<dynamic> questions;
  final int currentIndex;
  final Map<int, int?> answers;
  final Function(int qi, int ai) onAnswerSelected;
  final Function(int) onNavigate;

  const _QuestionPreviewArea({
    required this.questions,
    required this.currentIndex,
    required this.answers,
    required this.onAnswerSelected,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    // Tambahkan di awal build(), sebelum akses q
    if (questions.isEmpty || currentIndex >= questions.length) {
      return const Center(child: Text('Tidak ada soal untuk ditampilkan'));
    }
    final q = questions[currentIndex];
    if (q is! Map) return const Center(child: Text('Format soal tidak valid'));
    final qData = q as Map<String, dynamic>;
    final isLikert = qData['type'] == 'likert';
    final options = qData['options'] as List<dynamic>? ?? [];
    final correctIndex = qData['correctIndex'] as int?;
    final selectedAnswer = answers[currentIndex];

    return Row(
      children: [
        // ── Question content ─────────────────────────────────────────────
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Progress
              Row(
                children: [
                  Text(
                    '${currentIndex + 1} / ${questions.length}',
                    style: AppText.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.hsm,
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppRadius.bFull,
                      child: LinearProgressIndicator(
                        value: (currentIndex + 1) / questions.length,
                        minHeight: 4,
                        backgroundColor: AppColors.border,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.vmd,

              // Category chip
              if (qData['category'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softBg(AppColors.info),
                    borderRadius: AppRadius.bFull,
                  ),
                  child: Text(
                    qData['category'].toString(),
                    style: AppText.label.copyWith(color: AppColors.info),
                  ),
                ),
              AppSpacing.vmd,

              // Question text
              Text(
                qData['question'] ?? '',
                style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w600),
              ),
              AppSpacing.vmd,

              // Options
              ...options.asMap().entries.map((e) {
                final i = e.key;
                final opt = e.value.toString();
                final isSelected = selectedAnswer == i;
                final isCorrect = !isLikert && correctIndex == i;

                Color borderColor = AppColors.border;
                Color bgColor = AppColors.surface;
                if (isSelected && isCorrect) {
                  borderColor = AppColors.success;
                  bgColor = AppColors.softBg(AppColors.success);
                } else if (isSelected && !isCorrect && !isLikert) {
                  borderColor = AppColors.error;
                  bgColor = AppColors.softBg(AppColors.error);
                } else if (isSelected) {
                  borderColor = AppColors.primary;
                  bgColor = AppColors.softBg(AppColors.primary);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => onAnswerSelected(currentIndex, i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: AppRadius.bMd,
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? borderColor
                                  : AppColors.surfaceAlt,
                              borderRadius: AppRadius.bSm,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + i),
                                style: AppText.label.copyWith(
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          AppSpacing.hmd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(opt, style: AppText.body),
                                if (isLikert && qData['scores'] != null) ...[
                                  AppSpacing.vxs,
                                  Text(
                                    'Skor: ${(qData['scores'] as List)[i]}',
                                    style: AppText.caption.copyWith(
                                      color: AppColors.info,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!isLikert && isSelected)
                            Icon(
                              isCorrect
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: isCorrect
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Explanation (show after answered)
              if (selectedAnswer != null &&
                  qData['explanationShort'] != null &&
                  (qData['explanationShort'] as String).isNotEmpty) ...[
                AppSpacing.vmd,
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.softBg(AppColors.info),
                    borderRadius: AppRadius.bMd,
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_rounded,
                        color: AppColors.info,
                        size: 16,
                      ),
                      AppSpacing.hsm,
                      Expanded(
                        child: Text(
                          qData['explanationShort'].toString(),
                          style: AppText.bodySm.copyWith(color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Navigation buttons
              AppSpacing.vmd,
              Row(
                children: [
                  if (currentIndex > 0)
                    OutlinedButton.icon(
                      onPressed: () => onNavigate(currentIndex - 1),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Sebelumnya'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(
                          120,
                          40,
                        ), // ← fix infinite width
                      ),
                    )
                  else
                    const SizedBox(
                      width: 120,
                    ), // placeholder agar layout stabil
                  const Spacer(),
                  if (currentIndex < questions.length - 1)
                    ElevatedButton.icon(
                      onPressed: () => onNavigate(currentIndex + 1),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('Berikutnya'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(
                          120,
                          40,
                        ), // ← fix infinite width
                      ),
                    )
                  else
                    const SizedBox(width: 120),
                ],
              ),
            ],
          ),
        ),

        // ── Question navigator sidebar ────────────────────────────────────
        Container(
          width: 180,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(left: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Navigator',
                  style: AppText.label.copyWith(color: AppColors.textSecondary),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1,
                  ),
                  itemCount: questions.length,
                  itemBuilder: (_, i) {
                    final isAnswered = answers.containsKey(i);
                    final isCurrent = i == currentIndex;
                    return GestureDetector(
                      onTap: () => onNavigate(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primary
                              : isAnswered
                              ? AppColors.softBg(AppColors.success)
                              : AppColors.surfaceAlt,
                          borderRadius: AppRadius.bSm,
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.primary
                                : isAnswered
                                ? AppColors.success
                                : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: AppText.label.copyWith(
                              fontSize: 10,
                              color: isCurrent
                                  ? AppColors.white
                                  : isAnswered
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Legend
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _LegendRow(AppColors.primary, 'Soal sekarang'),
                    _LegendRow(AppColors.success, 'Sudah dijawab'),
                    _LegendRow(
                      AppColors.surfaceAlt,
                      'Belum dijawab',
                      textColor: AppColors.textSecondary,
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

// ============================================================================
// SMALL REUSABLE WIDGETS
// ============================================================================

class _GoldButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _GoldButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: onTap != null
              ? AppGradient.gold
              : const LinearGradient(
                  colors: [Color(0xFFB0B8C8), Color(0xFFB0B8C8)],
                ),
          borderRadius: AppRadius.bMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            AppSpacing.hxs,
            Text(
              label,
              style: AppText.label.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.1),
          borderRadius: AppRadius.bMd,
          border: Border.all(color: AppColors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.white),
            AppSpacing.hxs,
            Text(label, style: AppText.label.copyWith(color: AppColors.white)),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? activeColor;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surfaceAlt,
          borderRadius: AppRadius.bFull,
        ),
        child: Text(
          label,
          style: AppText.label.copyWith(
            fontSize: 11,
            color: selected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MetaChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.softBg(color),
        borderRadius: AppRadius.bFull,
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.bSm,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _TopStat extends StatelessWidget {
  final String label;
  final IconData icon;
  const _TopStat(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.08),
        borderRadius: AppRadius.bMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.bMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            AppSpacing.vsm,
            Text(
              value,
              style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(label, style: AppText.caption),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool canCopy;

  const _InfoRow(this.label, this.value, {this.canCopy = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: AppText.bodySm)),
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
              onTap: () => Clipboard.setData(ClipboardData(text: value)),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.copy_rounded,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubtestDetailCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;

  const _SubtestDetailCard({required this.index, required this.data});

  @override
  Widget build(BuildContext context) {
    final questions = (data['questions'] as List<dynamic>?)?.length ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppGradient.navy,
              borderRadius: AppRadius.bSm,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppText.label.copyWith(color: AppColors.white),
              ),
            ),
          ),
          AppSpacing.hmd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? '-',
                  style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    _MetaChip(data['category'] ?? '-', AppColors.info),
                    AppSpacing.hxs,
                    _MetaChip(data['type'] ?? '-', AppColors.primary),
                    AppSpacing.hxs,
                    _MetaChip('$questions soal', AppColors.warning),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    this.subtitle,
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
                Icon(icon, size: 15, color: AppColors.primary),
                AppSpacing.hxs,
                Text(
                  title,
                  style: AppText.label.copyWith(color: AppColors.primary),
                ),
                if (subtitle != null) ...[
                  AppSpacing.hsm,
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: AppText.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;

  const _EditField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.label.copyWith(color: AppColors.textSecondary),
        ),
        AppSpacing.vxs,
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppText.body,
          decoration: const InputDecoration(isDense: true),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: value
            ? AppColors.softBg(AppColors.success)
            : AppColors.surfaceAlt,
        borderRadius: AppRadius.bMd,
        border: Border.all(color: value ? AppColors.success : AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.success,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _SubtestEditRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const _SubtestEditRow({
    required this.index,
    required this.data,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subtes ${index + 1}',
            style: AppText.label.copyWith(color: AppColors.primary),
          ),
          AppSpacing.vsm,
          TextFormField(
            initialValue: data['name'] ?? '',
            style: AppText.body,
            decoration: const InputDecoration(
              hintText: 'Nama subtes',
              isDense: true,
            ),
            onChanged: (v) => onChanged({...data, 'name': v}),
          ),
          AppSpacing.vsm,
          TextFormField(
            initialValue: data['description'] ?? '',
            style: AppText.body,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Deskripsi (opsional)',
              isDense: true,
            ),
            onChanged: (v) => onChanged({...data, 'description': v}),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final Color? textColor;

  const _LegendRow(this.color, this.label, {this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.bSm,
            ),
          ),
          AppSpacing.hxs,
          Text(
            label,
            style: AppText.caption.copyWith(color: textColor, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.error,
            ),
            AppSpacing.vsm,
            Text('Gagal memuat data', style: AppText.bodyLg),
            AppSpacing.vxs,
            SelectableText(error, style: AppText.caption),
          ],
        ),
      ),
    );
  }
}
