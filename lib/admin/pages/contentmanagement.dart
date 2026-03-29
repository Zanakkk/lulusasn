// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import 'CreateTO.dart';

// ============================================================================
// SCREEN UTAMA
// ============================================================================
class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({super.key});
  @override
  State<ContentManagementScreen> createState() =>
      _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all';
  final TextEditingController _searchCtrl = TextEditingController();

  String? _selectedTryoutId;
  _RightPanelMode _panelMode = _RightPanelMode.empty;

  final Map<String, Map<String, dynamic>> _fullDocCache = {};
  bool _isPanelLoading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _deleteTryout(String id, String title) async {
    final confirm = await _showConfirmDialog(
      title: 'Hapus Tryout?',
      message: '"$title" akan dihapus permanen beserta semua soal.',
      confirmLabel: 'Hapus',
      confirmColor: AppColors.error,
    );
    if (confirm != true || !mounted) return;
    try {
      await FirebaseFirestore.instance.collection('tryouts').doc(id).delete();
      _invalidateCache(id);
      if (mounted && _selectedTryoutId == id)
        setState(() {
          _selectedTryoutId = null;
          _panelMode = _RightPanelMode.empty;
        });
      _showSnack('Tryout "$title" berhasil dihapus', isError: false);
    } catch (e) {
      _showSnack('Gagal menghapus: $e', isError: true);
    }
  }

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
  }) => showDialog<bool>(
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

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
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
          Expanded(child: _buildRightPanel()),
        ],
      ),
    );
  }

  // ── LEFT HEADER ────────────────────────────────────────────────────────────
  Widget _buildLeftHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.navy),
      padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  _fullDocCache.clear();
                },
              ),
            ],
          ),
          AppSpacing.vsm,
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tryouts')
                .snapshots(),
            builder: (_, snap) {
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

  Widget _statChip(String label, IconData icon) => Container(
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

  // ── SEARCH & FILTER ────────────────────────────────────────────────────────
  Widget _buildSearchAndFilter() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        children: [
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
                activeColor: AppColors.success,
                onTap: () => setState(() => _filterStatus = 'active'),
              ),
              AppSpacing.hxs,
              _FilterChip(
                label: 'Nonaktif',
                selected: _filterStatus == 'inactive',
                activeColor: AppColors.textSecondary,
                onTap: () => setState(() => _filterStatus = 'inactive'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TRYOUT LIST ────────────────────────────────────────────────────────────
  Widget _buildTryoutList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tryouts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (snap.hasError) return _ErrorState(error: snap.error.toString());
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        var docs = snap.data!.docs;
        if (_filterStatus == 'active')
          docs = docs
              .where((d) => (d.data() as Map)['isActive'] == true)
              .toList();
        else if (_filterStatus == 'inactive')
          docs = docs
              .where((d) => (d.data() as Map)['isActive'] != true)
              .toList();
        if (_searchQuery.isNotEmpty)
          docs = docs.where((d) {
            final t = ((d.data() as Map)['title'] ?? '')
                .toString()
                .toLowerCase();
            return t.contains(_searchQuery);
          }).toList();
        if (docs.isEmpty)
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
        return ListView.separated(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _TryoutListCard(
              id: doc.id,
              data: data,
              isSelected: _selectedTryoutId == doc.id,
              onTap: () => _selectTryout(doc.id, _RightPanelMode.detail),
              onEdit: () => _selectTryout(doc.id, _RightPanelMode.edit),
              onEditQuestions: () =>
                  _selectTryout(doc.id, _RightPanelMode.editQuestions),
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

  // ── RIGHT PANEL ────────────────────────────────────────────────────────────
  Widget _buildRightPanel() {
    if (_selectedTryoutId == null) return _buildEmptyRight();
    if (_isPanelLoading)
      return const Center(child: CircularProgressIndicator());
    final fullDoc = _fullDocCache[_selectedTryoutId];
    if (fullDoc == null) return _buildEmptyRight();

    return switch (_panelMode) {
      _RightPanelMode.detail => _DetailPanel(
        data: fullDoc,
        onEdit: () => setState(() => _panelMode = _RightPanelMode.edit),
        onEditQuestions: () =>
            setState(() => _panelMode = _RightPanelMode.editQuestions),
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
      // ✅ PANEL BARU: editor soal
      _RightPanelMode.editQuestions => _EditQuestionsPanel(
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

  Widget _buildEmptyRight() => Container(
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

enum _RightPanelMode { empty, detail, edit, editQuestions, preview }

// ============================================================================
// WIDGET: TRYOUT LIST CARD — tambah tombol "Edit Soal"
// ============================================================================
class _TryoutListCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final bool isSelected;
  final VoidCallback onTap,
      onEdit,
      onEditQuestions,
      onPreview,
      onToggleActive,
      onDelete;

  const _TryoutListCard({
    required this.id,
    required this.data,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onEditQuestions,
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
              Row(
                children: [
                  if (createdAt != null)
                    Expanded(
                      child: Text(
                        DateFormat('dd MMM yyyy').format(createdAt),
                        style: AppText.caption.copyWith(fontSize: 10),
                      ),
                    ),
                  _IconAction(
                    icon: Icons.visibility_rounded,
                    color: AppColors.info,
                    tooltip: 'Preview',
                    onTap: onPreview,
                  ),
                  _IconAction(
                    icon: Icons.edit_rounded,
                    color: AppColors.primary,
                    tooltip: 'Edit Tryout',
                    onTap: onEdit,
                  ),
                  // ✅ Tombol baru: edit soal
                  _IconAction(
                    icon: Icons.edit_note_rounded,
                    color: AppColors.warning,
                    tooltip: 'Edit Soal',
                    onTap: onEditQuestions,
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
// ✅ PANEL BARU: EDIT QUESTIONS
// ============================================================================
class _EditQuestionsPanel extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onSaved;
  final VoidCallback onClose;

  const _EditQuestionsPanel({
    required this.docId,
    required this.data,
    required this.onSaved,
    required this.onClose,
  });

  @override
  State<_EditQuestionsPanel> createState() => _EditQuestionsPanelState();
}

class _EditQuestionsPanelState extends State<_EditQuestionsPanel> {
  late List<Map<String, dynamic>> _subtests;
  int _activeSubtest = 0;
  int? _editingIdx; // index soal yang sedang di-expand
  bool _isSaving = false;
  bool _isDirty = false; // ada perubahan belum disimpan

  @override
  void initState() {
    super.initState();
    // Deep copy agar tidak mutasi cache
    _subtests = (widget.data['subtests'] as List<dynamic>? ?? []).map((s) {
      final sub = Map<String, dynamic>.from(s as Map);
      // Deep copy questions
      if (sub['questions'] is List) {
        sub['questions'] = (sub['questions'] as List)
            .map((q) => Map<String, dynamic>.from(q as Map))
            .toList();
      } else {
        sub['questions'] = <Map<String, dynamic>>[];
      }
      return sub;
    }).toList();
  }

  List<Map<String, dynamic>> get _currentQuestions {
    if (_subtests.isEmpty || _activeSubtest >= _subtests.length) return [];
    return (_subtests[_activeSubtest]['questions'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  void _markDirty() => setState(() {
    _isDirty = true;
  });

  // ── Save ke Firestore ──────────────────────────────────────────────────────
  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      // Update HANYA field subtests (questions ikut di dalamnya)
      await FirebaseFirestore.instance
          .collection('tryouts')
          .doc(widget.docId)
          .update({
            'subtests': _subtests
                .map(
                  (s) => {
                    ...s,
                    'questionCount': (s['questions'] as List?)?.length ?? 0,
                  },
                )
                .toList(),
            'totalQuestions': _subtests.fold<int>(
              0,
              (sum, s) => sum + ((s['questions'] as List?)?.length ?? 0),
            ),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      setState(() {
        _isDirty = false;
        _isSaving = false;
      });
      widget.onSaved();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  // ── Upload gambar ke Firebase Storage ─────────────────────────────────────
  Future<String?> _uploadImage() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res == null) return null;
    try {
      final f = res.files.first;
      final ref = FirebaseStorage.instance.ref(
        'questions/${DateTime.now().millisecondsSinceEpoch}_${f.name}',
      );
      final snap = await ref.putData(f.bytes!);
      return await snap.ref.getDownloadURL();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload gagal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      return null;
    }
  }

  // ── Tambah soal baru ───────────────────────────────────────────────────────
  void _addQuestion() {
    final sub = _subtests[_activeSubtest];
    final isLikert = sub['type'] == 'likert';
    final qs = _currentQuestions;
    qs.add({
      'question': '',
      'type': isLikert ? 'likert' : 'objective',
      'category': sub['category'] ?? '',
      'difficulty': 'medium',
      'package': '',
      'options': ['', '', '', '', ''],
      if (isLikert) 'scores': [1, 2, 3, 4, 5] else 'correctIndex': 0,
      'explanationShort': '',
      'explanationFull': '',
      'tags': <String>[],
      'questionImage': null,
      'optionImages': [null, null, null, null, null],
    });
    setState(() {
      _subtests[_activeSubtest]['questions'] = qs;
      _editingIdx = qs.length - 1;
      _isDirty = true;
    });
  }

  // ── Hapus soal ─────────────────────────────────────────────────────────────
  void _deleteQuestion(int i) {
    final qs = _currentQuestions;
    qs.removeAt(i);
    setState(() {
      _subtests[_activeSubtest]['questions'] = qs;
      if (_editingIdx == i)
        _editingIdx = null;
      else if (_editingIdx != null && _editingIdx! > i)
        _editingIdx = _editingIdx! - 1;
      _isDirty = true;
    });
  }

  // ============================================================================
  // BUILD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(gradient: AppGradient.navy),
            padding: const EdgeInsets.fromLTRB(24, 44, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                                  gradient: AppGradient.gold,
                                  borderRadius: AppRadius.bFull,
                                ),
                                child: Text(
                                  'EDIT SOAL',
                                  style: AppText.label.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              if (_isDirty) ...[
                                AppSpacing.hsm,
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.2),
                                    borderRadius: AppRadius.bFull,
                                    border: Border.all(
                                      color: AppColors.warning.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    'Ada perubahan belum disimpan',
                                    style: AppText.caption.copyWith(
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          AppSpacing.vxs,
                          Text(
                            widget.data['title'] ?? '',
                            style: AppText.h2.copyWith(color: AppColors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.hsm,
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
                      label: _isSaving ? 'Menyimpan...' : 'Simpan Soal',
                      icon: Icons.save_rounded,
                      onTap: _isSaving || !_isDirty ? null : _save,
                    ),
                  ],
                ),
                AppSpacing.vmd,
                // ── Subtest tabs ─────────────────────────────────────────────
                if (_subtests.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _subtests.asMap().entries.map((e) {
                        final i = e.key;
                        final sub = e.value;
                        final qCount = (sub['questions'] as List?)?.length ?? 0;
                        final isActive = i == _activeSubtest;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _activeSubtest = i;
                              _editingIdx = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.gold
                                    : AppColors.white.withOpacity(0.1),
                                borderRadius: AppRadius.bMd,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    sub['name'] ?? 'Subtes ${i + 1}',
                                    style: AppText.label.copyWith(
                                      color: isActive
                                          ? AppColors.primary
                                          : AppColors.white,
                                    ),
                                  ),
                                  AppSpacing.hxs,
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.primary.withOpacity(0.15)
                                          : AppColors.white.withOpacity(0.15),
                                      borderRadius: AppRadius.bFull,
                                    ),
                                    child: Text(
                                      '$qCount',
                                      style: AppText.caption.copyWith(
                                        color: isActive
                                            ? AppColors.primary
                                            : AppColors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // ── Question list + editor ──────────────────────────────────────────
          Expanded(
            child: _subtests.isEmpty
                ? Center(child: Text('Tidak ada subtes', style: AppText.bodySm))
                : _buildQuestionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionList() {
    final qs = _currentQuestions;

    return Column(
      children: [
        // ── Toolbar ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Text(
                '${qs.length} soal',
                style: AppText.label.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Tambah Soal'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: AppText.btnSm,
                ),
              ),
            ],
          ),
        ),

        // ── List soal ─────────────────────────────────────────────────────────
        Expanded(
          child: qs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.quiz_outlined,
                        size: 40,
                        color: AppColors.textHint,
                      ),
                      AppSpacing.vsm,
                      Text(
                        'Belum ada soal. Klik "Tambah Soal" untuk mulai.',
                        style: AppText.bodySm,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: qs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final q = qs[i];
                    final isEditing = _editingIdx == i;
                    return _QuestionRow(
                      question: q,
                      index: i,
                      isEditing: isEditing,
                      onToggle: () =>
                          setState(() => _editingIdx = isEditing ? null : i),
                      onDelete: () => _deleteQuestion(i),
                      onChanged: _markDirty,
                      onUploadQuestionImage: () async {
                        final url = await _uploadImage();
                        if (url != null)
                          setState(() {
                            q['questionImage'] = url;
                            _isDirty = true;
                          });
                      },
                      onRemoveQuestionImage: () => setState(() {
                        q['questionImage'] = null;
                        _isDirty = true;
                      }),
                      onUploadOptionImage: (optIdx) async {
                        final url = await _uploadImage();
                        if (url != null)
                          setState(() {
                            final imgs = List<dynamic>.from(
                              q['optionImages'] as List? ??
                                  List.filled(5, null),
                            );
                            while (imgs.length <= optIdx) imgs.add(null);
                            imgs[optIdx] = url;
                            q['optionImages'] = imgs;
                            _isDirty = true;
                          });
                      },
                      onRemoveOptionImage: (optIdx) => setState(() {
                        final imgs = List<dynamic>.from(
                          q['optionImages'] as List? ?? List.filled(5, null),
                        );
                        while (imgs.length <= optIdx) imgs.add(null);
                        imgs[optIdx] = null;
                        q['optionImages'] = imgs;
                        _isDirty = true;
                      }),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ============================================================================
// WIDGET: _QuestionRow — row collapsed + form expanded
// ============================================================================
class _QuestionRow extends StatefulWidget {
  final Map<String, dynamic> question;
  final int index;
  final bool isEditing;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  final VoidCallback onUploadQuestionImage;
  final VoidCallback onRemoveQuestionImage;
  final Function(int) onUploadOptionImage;
  final Function(int) onRemoveOptionImage;

  const _QuestionRow({
    required this.question,
    required this.index,
    required this.isEditing,
    required this.onToggle,
    required this.onDelete,
    required this.onChanged,
    required this.onUploadQuestionImage,
    required this.onRemoveQuestionImage,
    required this.onUploadOptionImage,
    required this.onRemoveOptionImage,
  });

  @override
  State<_QuestionRow> createState() => _QuestionRowState();
}

class _QuestionRowState extends State<_QuestionRow> {
  late final TextEditingController _qCtrl;
  late final TextEditingController _exShortCtrl;
  late final TextEditingController _exFullCtrl;
  late final TextEditingController _tagsCtrl;
  late final TextEditingController _pkgCtrl;
  late final List<TextEditingController> _optCtrl;
  late final List<TextEditingController> _scoreCtrl;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _qCtrl = TextEditingController(text: q['question'] as String? ?? '');
    _exShortCtrl = TextEditingController(
      text: q['explanationShort'] as String? ?? '',
    );
    _exFullCtrl = TextEditingController(
      text: q['explanationFull'] as String? ?? '',
    );
    _tagsCtrl = TextEditingController(
      text: ((q['tags'] as List?)?.cast<String>() ?? []).join(', '),
    );
    _pkgCtrl = TextEditingController(text: q['package'] as String? ?? '');
    final opts = (q['options'] as List?)?.cast<String>() ?? [];
    _optCtrl = List.generate(
      5,
      (i) => TextEditingController(text: i < opts.length ? opts[i] : ''),
    );
    final scores = (q['scores'] as List?)?.cast<int>() ?? [1, 2, 3, 4, 5];
    _scoreCtrl = List.generate(
      5,
      (i) => TextEditingController(
        text: i < scores.length ? scores[i].toString() : '0',
      ),
    );
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _exShortCtrl.dispose();
    _exFullCtrl.dispose();
    _tagsCtrl.dispose();
    _pkgCtrl.dispose();
    for (final c in _optCtrl) c.dispose();
    for (final c in _scoreCtrl) c.dispose();
    super.dispose();
  }

  void _sync() {
    final q = widget.question;
    q['question'] = _qCtrl.text.trim();
    q['explanationShort'] = _exShortCtrl.text.trim();
    q['explanationFull'] = _exFullCtrl.text.trim();
    q['package'] = _pkgCtrl.text.trim();
    q['tags'] = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    q['options'] = _optCtrl.map((c) => c.text.trim()).toList();
    if (q['type'] == 'likert') {
      q['scores'] = _scoreCtrl.map((c) => int.tryParse(c.text) ?? 0).toList();
    }
    widget.onChanged();
  }

  String _safeDifficulty(dynamic v) {
    const valid = ['easy', 'medium', 'hard'];
    final s = v?.toString() ?? '';
    return valid.contains(s) ? s : 'medium';
  }

  String _safeType(dynamic v) {
    const valid = ['objective', 'likert'];
    final s = v?.toString() ?? '';
    return valid.contains(s) ? s : 'objective';
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final isLikert = q['type'] == 'likert';
    final qImg = q['questionImage'] as String?;
    final optImgs =
        (q['optionImages'] as List?)?.cast<dynamic>() ?? List.filled(5, null);
    final correctIdx = q['correctIndex'] as int? ?? 0;
    final qText = (q['question'] as String?)?.trim() ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: widget.isEditing
            ? AppColors.softBg(AppColors.primary)
            : AppColors.surface,
        borderRadius: AppRadius.bMd,
        border: Border.all(
          color: widget.isEditing ? AppColors.primary : AppColors.border,
          width: widget.isEditing ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Collapsed header ────────────────────────────────────────────────
          InkWell(
            onTap: widget.onToggle,
            borderRadius: widget.isEditing
                ? const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.md),
                    topRight: Radius.circular(AppRadius.md),
                  )
                : AppRadius.bMd,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Nomor
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.isEditing
                          ? AppColors.primary
                          : AppColors.surfaceAlt,
                      borderRadius: AppRadius.bSm,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: AppText.label.copyWith(
                          color: widget.isEditing
                              ? AppColors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.hsm,
                  Expanded(
                    child: Text(
                      qText.isEmpty
                          ? '(soal kosong — klik untuk mengisi)'
                          : qText,
                      style: AppText.bodySm.copyWith(
                        color: qText.isEmpty
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                        fontStyle: qText.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppSpacing.hsm,
                  // Tipe pill
                  _CMSPill(
                    label: isLikert ? 'Likert' : 'Obj',
                    color: isLikert ? AppColors.warning : AppColors.success,
                  ),
                  AppSpacing.hxs,
                  // Gambar indicator
                  if (qImg != null && qImg.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.image_rounded,
                        size: 14,
                        color: AppColors.info,
                      ),
                    ),
                  // Hapus
                  InkWell(
                    onTap: widget.onDelete,
                    borderRadius: AppRadius.bFull,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  AppSpacing.hxs,
                  Icon(
                    widget.isEditing
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded editor ─────────────────────────────────────────────────
          if (widget.isEditing)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSpacing.vmd,

                  // Baris meta
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      SizedBox(
                        width: 200,
                        child: _CMSField(
                          label: 'Package',
                          ctrl: _pkgCtrl,
                          onChanged: (_) => _sync(),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: _CMSDropdown<String>(
                          label: 'Kesulitan',
                          value: _safeDifficulty(q['difficulty']),
                          items: const ['easy', 'medium', 'hard'],
                          itemLabel: (v) => switch (v) {
                            'easy' => 'Mudah',
                            'medium' => 'Menengah',
                            _ => 'Sulit',
                          },
                          onChanged: (v) {
                            q['difficulty'] = v!;
                            _sync();
                          },
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: _CMSDropdown<String>(
                          label: 'Tipe',
                          value: _safeType(q['type']),
                          items: const ['objective', 'likert'],
                          itemLabel: (v) =>
                              v == 'objective' ? 'Objektif' : 'Likert',
                          onChanged: (v) {
                            q['type'] = v!;
                            _sync();
                          },
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vmd,

                  // Teks soal
                  _CMSField(
                    label: 'Teks Soal *',
                    ctrl: _qCtrl,
                    maxLines: 4,
                    onChanged: (_) => _sync(),
                    hint: 'Tulis teks soal di sini…',
                  ),
                  AppSpacing.vsm,

                  // Gambar soal
                  _CMSImageRow(
                    label: 'Gambar Soal',
                    url: qImg,
                    onUpload: widget.onUploadQuestionImage,
                    onRemove: widget.onRemoveQuestionImage,
                  ),
                  AppSpacing.vmd,

                  // Opsi
                  Text('Opsi Jawaban', style: AppText.label),
                  AppSpacing.vxs,
                  ...List.generate(5, (i) {
                    final optImg = i < optImgs.length
                        ? optImgs[i] as String?
                        : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CMSOptionRow(
                        index: i,
                        ctrl: _optCtrl[i],
                        scoreCtrl: _scoreCtrl[i],
                        isLikert: isLikert,
                        isCorrect: !isLikert && correctIdx == i,
                        imageUrl: optImg,
                        onChanged: (_) => _sync(),
                        onSetCorrect: isLikert
                            ? null
                            : () {
                                setState(() => q['correctIndex'] = i);
                                _sync();
                              },
                        onUploadImage: () => widget.onUploadOptionImage(i),
                        onRemoveImage: () => widget.onRemoveOptionImage(i),
                      ),
                    );
                  }),
                  AppSpacing.vmd,

                  // Penjelasan
                  Row(
                    children: [
                      Expanded(
                        child: _CMSField(
                          label: 'Penjelasan Singkat',
                          ctrl: _exShortCtrl,
                          maxLines: 2,
                          onChanged: (_) => _sync(),
                          hint: 'Ringkasan…',
                        ),
                      ),
                      AppSpacing.hsm,
                      Expanded(
                        child: _CMSField(
                          label: 'Penjelasan Lengkap',
                          ctrl: _exFullCtrl,
                          maxLines: 2,
                          onChanged: (_) => _sync(),
                          hint: 'Detail pembahasan…',
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vsm,
                  _CMSField(
                    label: 'Tags (pisah koma)',
                    ctrl: _tagsCtrl,
                    onChanged: (_) => _sync(),
                    hint: 'pancasila, uud1945',
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
// SMALL WIDGETS KHUSUS CMS
// ============================================================================

class _CMSField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final String? hint;

  const _CMSField({
    required this.label,
    required this.ctrl,
    this.maxLines = 1,
    this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppText.caption.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        onChanged: onChanged,
        style: AppText.bodySm,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
        ),
      ),
    ],
  );
}

class _CMSDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _CMSDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeVal = items.contains(value)
        ? value
        : (items.isNotEmpty ? items.first : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        DropdownButtonFormField<T>(
          value: safeVal,
          items: items
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(itemLabel(i), style: AppText.bodySm),
                ),
              )
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.expand_more_rounded, size: 16),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _CMSOptionRow extends StatelessWidget {
  final int index;
  final TextEditingController ctrl;
  final TextEditingController scoreCtrl;
  final bool isLikert, isCorrect;
  final String? imageUrl;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSetCorrect;
  final VoidCallback onUploadImage, onRemoveImage;

  const _CMSOptionRow({
    required this.index,
    required this.ctrl,
    required this.scoreCtrl,
    required this.isLikert,
    required this.isCorrect,
    required this.imageUrl,
    required this.onChanged,
    required this.onSetCorrect,
    required this.onUploadImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(65 + index);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Huruf / jawaban benar toggle
        GestureDetector(
          onTap: onSetCorrect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCorrect ? AppColors.success : AppColors.surfaceAlt,
              borderRadius: AppRadius.bSm,
              border: Border.all(
                color: isCorrect ? AppColors.success : AppColors.border,
              ),
            ),
            child: Center(
              child: Text(
                letter,
                style: AppText.label.copyWith(
                  color: isCorrect ? AppColors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        AppSpacing.hsm,
        // Teks opsi
        Expanded(
          flex: 4,
          child: TextFormField(
            controller: ctrl,
            onChanged: onChanged,
            style: AppText.bodySm,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Opsi $letter…',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
          ),
        ),
        // Skor likert
        if (isLikert) ...[
          AppSpacing.hsm,
          SizedBox(
            width: 56,
            child: TextFormField(
              controller: scoreCtrl,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: AppText.bodySm.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: '0',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.bMd,
                  borderSide: BorderSide(
                    color: AppColors.warning.withOpacity(0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.bMd,
                  borderSide: const BorderSide(color: AppColors.warning),
                ),
              ),
            ),
          ),
        ],
        // Gambar opsi
        AppSpacing.hsm,
        SizedBox(
          width: 48,
          height: 40,
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.bSm,
                      child: Image.network(
                        imageUrl!,
                        width: 48,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image_rounded, size: 20),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: InkWell(
                        onTap: onRemoveImage,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: AppColors.error,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 10,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: onUploadImage,
                  borderRadius: AppRadius.bSm,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: AppRadius.bSm,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _CMSImageRow extends StatelessWidget {
  final String label;
  final String? url;
  final VoidCallback onUpload, onRemove;

  const _CMSImageRow({
    required this.label,
    required this.url,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(label, style: AppText.label),
      AppSpacing.hsm,
      if (url != null && url!.isNotEmpty) ...[
        Stack(
          children: [
            ClipRRect(
              borderRadius: AppRadius.bSm,
              child: Image.network(
                url!,
                height: 56,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('❌'),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: InkWell(
                onTap: onRemove,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: AppColors.error,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 11,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        AppSpacing.hsm,
        TextButton.icon(
          onPressed: onUpload,
          icon: const Icon(Icons.swap_horiz_rounded, size: 14),
          label: const Text('Ganti'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.info,
            textStyle: AppText.btnSm,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ] else
        OutlinedButton.icon(
          onPressed: onUpload,
          icon: const Icon(Icons.add_a_photo_rounded, size: 14),
          label: const Text('Upload Gambar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: AppText.btnSm,
          ),
        ),
    ],
  );
}

class _CMSPill extends StatelessWidget {
  final String label;
  final Color color;
  const _CMSPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.softBg(color),
      borderRadius: AppRadius.bFull,
    ),
    child: Text(
      label,
      style: AppText.caption.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

// ============================================================================
// DETAIL, EDIT, PREVIEW PANELS — tidak berubah dari versi sebelumnya
// ============================================================================

class _DetailPanel extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit, onEditQuestions, onPreview, onClose;

  const _DetailPanel({
    required this.data,
    required this.onEdit,
    required this.onEditQuestions,
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
                Row(
                  children: [
                    _GoldButton(
                      label: 'Edit Tryout',
                      icon: Icons.edit_rounded,
                      onTap: onEdit,
                    ),
                    AppSpacing.hsm,
                    // ✅ Tombol Edit Soal di detail panel
                    _GoldButton(
                      label: 'Edit Soal',
                      icon: Icons.edit_note_rounded,
                      onTap: onEditQuestions,
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
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
                Text('Daftar Subtes', style: AppText.h3),
                AppSpacing.vsm,
                ...subtests.asMap().entries.map(
                  (e) => _SubtestDetailCard(
                    index: e.key,
                    data: e.value as Map<String, dynamic>,
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

class _EditPanel extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onSaved, onClose;

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
  late bool _isActive, _isFlexible;
  bool _isSaving = false;
  late List<Map<String, dynamic>> _subtests;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.data['title'] ?? '');
    _descCtrl = TextEditingController(text: widget.data['description'] ?? '');
    _priceCtrl = TextEditingController(
      text: (widget.data['price'] ?? 0).toString(),
    );
    _isActive = widget.data['isActive'] == true;
    _isFlexible = widget.data['isFlexibleDate'] == true;
    _subtests = (widget.data['subtests'] as List<dynamic>? ?? [])
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();
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
      await FirebaseFirestore.instance
          .collection('tryouts')
          .doc(widget.docId)
          .update({
            'title': _titleCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
            'price': int.tryParse(_priceCtrl.text) ?? 0,
            'isActive': _isActive,
            'isFlexibleDate': _isFlexible,
            'subtests': _subtests,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      widget.onSaved();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.bg,
    child: Column(
      children: [
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
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
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
              _SectionCard(
                title: 'Metadata Subtes',
                icon: Icons.layers_rounded,
                subtitle:
                    'Edit nama & deskripsi. Soal dikelola via "Edit Soal".',
                children: _subtests
                    .asMap()
                    .entries
                    .map(
                      (e) => _SubtestEditRow(
                        index: e.key,
                        data: e.value,
                        onChanged: (upd) =>
                            setState(() => _subtests[e.key] = upd),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

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
  final Map<int, int?> _answers = {};

  List<dynamic> get subtests => widget.data['subtests'] as List<dynamic>? ?? [];
  List<dynamic> get currentQuestions {
    if (subtests.isEmpty || _selectedSubtest >= subtests.length) return [];
    final sub = subtests[_selectedSubtest];
    if (sub is! Map) return [];
    return (sub as Map<String, dynamic>)['questions'] as List<dynamic>? ?? [];
  }

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.bg,
    child: Column(
      children: [
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
              if (subtests.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: subtests.asMap().entries.map((e) {
                      final i = e.key;
                      final sub = e.value as Map<String, dynamic>;
                      final isSel = i == _selectedSubtest;
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
                              color: isSel
                                  ? AppColors.gold
                                  : AppColors.white.withOpacity(0.1),
                              borderRadius: AppRadius.bMd,
                            ),
                            child: Text(
                              sub['name'] ?? 'Subtes ${i + 1}',
                              style: AppText.label.copyWith(
                                color: isSel
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

// ============================================================================
// PREVIEW AREA (tidak berubah)
// ============================================================================
class _QuestionPreviewArea extends StatelessWidget {
  final List<dynamic> questions;
  final int currentIndex;
  final Map<int, int?> answers;
  final Function(int, int) onAnswerSelected;
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
    if (questions.isEmpty || currentIndex >= questions.length)
      return const Center(child: Text('Tidak ada soal'));
    final q = questions[currentIndex];
    if (q is! Map) return const Center(child: Text('Format soal tidak valid'));
    final qData = q as Map<String, dynamic>;
    final isLikert = qData['type'] == 'likert';
    final options = qData['options'] as List<dynamic>? ?? [];
    final correctIdx = qData['correctIndex'] as int?;
    final selected = answers[currentIndex];

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
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
              Text(
                qData['question'] ?? '',
                style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w600),
              ),
              if (qData['questionImage'] != null &&
                  (qData['questionImage'] as String).isNotEmpty) ...[
                AppSpacing.vsm,
                ClipRRect(
                  borderRadius: AppRadius.bMd,
                  child: Image.network(
                    qData['questionImage'],
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ],
              AppSpacing.vmd,
              ...options.asMap().entries.map((e) {
                final i = e.key;
                final opt = e.value.toString();
                final isSel = selected == i;
                final isCorr = !isLikert && correctIdx == i;
                Color border = AppColors.border, bg = AppColors.surface;
                if (isSel && isCorr) {
                  border = AppColors.success;
                  bg = AppColors.softBg(AppColors.success);
                } else if (isSel && !isCorr && !isLikert) {
                  border = AppColors.error;
                  bg = AppColors.softBg(AppColors.error);
                } else if (isSel) {
                  border = AppColors.primary;
                  bg = AppColors.softBg(AppColors.primary);
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => onAnswerSelected(currentIndex, i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: AppRadius.bMd,
                        border: Border.all(color: border, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSel ? border : AppColors.surfaceAlt,
                              borderRadius: AppRadius.bSm,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + i),
                                style: AppText.label.copyWith(
                                  color: isSel
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
                          if (!isLikert && isSel)
                            Icon(
                              isCorr
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: isCorr
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
              if (selected != null &&
                  (qData['explanationShort'] as String? ?? '').isNotEmpty) ...[
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
                        minimumSize: const Size(120, 40),
                      ),
                    )
                  else
                    const SizedBox(width: 120),
                  const Spacer(),
                  if (currentIndex < questions.length - 1)
                    ElevatedButton.icon(
                      onPressed: () => onNavigate(currentIndex + 1),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('Berikutnya'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 40),
                      ),
                    )
                  else
                    const SizedBox(width: 120),
                ],
              ),
            ],
          ),
        ),
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
                    final isAns = answers.containsKey(i);
                    final isCur = i == currentIndex;
                    return GestureDetector(
                      onTap: () => onNavigate(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          color: isCur
                              ? AppColors.primary
                              : isAns
                              ? AppColors.softBg(AppColors.success)
                              : AppColors.surfaceAlt,
                          borderRadius: AppRadius.bSm,
                          border: Border.all(
                            color: isCur
                                ? AppColors.primary
                                : isAns
                                ? AppColors.success
                                : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: AppText.label.copyWith(
                              fontSize: 10,
                              color: isCur
                                  ? AppColors.white
                                  : isAns
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
// SHARED SMALL WIDGETS
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
  Widget build(BuildContext context) => GestureDetector(
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
          Text(label, style: AppText.label.copyWith(color: AppColors.primary)),
        ],
      ),
    ),
  );
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
  Widget build(BuildContext context) => GestureDetector(
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
  Widget build(BuildContext context) => Container(
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
  Widget build(BuildContext context) => Tooltip(
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

class _TopStat extends StatelessWidget {
  final String label;
  final IconData icon;
  const _TopStat(this.label, this.icon);
  @override
  Widget build(BuildContext context) => Container(
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

class _InfoCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _InfoCard(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
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

class _InfoRow extends StatelessWidget {
  final String label, value;
  final bool canCopy;
  const _InfoRow(this.label, this.value, {this.canCopy = false});
  @override
  Widget build(BuildContext context) => Padding(
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

class _SubtestDetailCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;
  const _SubtestDetailCard({required this.index, required this.data});
  @override
  Widget build(BuildContext context) {
    final qCount = (data['questions'] as List<dynamic>?)?.length ?? 0;
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
                    _MetaChip('$qCount soal', AppColors.warning),
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
  Widget build(BuildContext context) => Container(
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
  Widget build(BuildContext context) => Column(
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: value ? AppColors.softBg(AppColors.success) : AppColors.surfaceAlt,
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
  Widget build(BuildContext context) => Container(
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

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final Color? textColor;
  const _LegendRow(this.color, this.label, {this.textColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: AppRadius.bSm),
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

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});
  @override
  Widget build(BuildContext context) => Center(
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
