// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class ExamType {
  final String id;
  String name;
  String description;
  List<String> categories;
  int order;
  bool isActive;
  final DateTime? createdAt;

  ExamType({
    required this.id,
    required this.name,
    this.description = '',
    required this.categories,
    this.order = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory ExamType.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ExamType(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      categories: List<String>.from(d['categories'] ?? []),
      order: d['order'] ?? 0,
      isActive: d['isActive'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap({bool isNew = false}) => {
    'name': name,
    'description': description,
    'categories': categories,
    'order': order,
    'isActive': isActive,
    'createdAt': isNew
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(createdAt ?? DateTime.now()),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _db = FirebaseFirestore.instance;

  // Gunakan Stream agar UI otomatis update tanpa perlu reload manual
  late final Stream<List<ExamType>> _stream = _db
      .collection('exam_types')
      .orderBy('order')
      .snapshots()
      .map((s) => s.docs.map(ExamType.fromFirestore).toList());

  // ── Firebase ops ──────────────────────────────────────────────
  Future<void> _add(ExamType t) async {
    final ref = _db.collection('exam_types');
    final count = await ref.count().get();
    t.order = count.count ?? 0;
    await ref.add(t.toMap(isNew: true));
    _snack('${t.name} berhasil ditambahkan', success: true);
  }

  Future<void> _update(ExamType t) async {
    await _db.collection('exam_types').doc(t.id).update(t.toMap());
    _snack('Berhasil diperbarui', success: true);
  }

  Future<void> _toggle(ExamType t) =>
      _db.collection('exam_types').doc(t.id).update({'isActive': !t.isActive});

  Future<void> _delete(ExamType t) async {
    await _db.collection('exam_types').doc(t.id).delete();
    _snack('${t.name} dihapus');
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppText.bodyLg.copyWith(color: AppColors.white),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────
  void _openDialog({ExamType? editing}) {
    showDialog(
      context: context,
      barrierColor: AppColors.primary.withOpacity(0.4),
      builder: (_) => _ExamTypeDialog(
        editing: editing,
        onSave: (t) => editing == null ? _add(t) : _update(t),
      ),
    );
  }

  void _confirmDelete(ExamType t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bLg),
        title: Text('Hapus Tipe Ujian?', style: AppText.h3),
        content: Text(
          'Yakin menghapus "${t.name}"?\nTindakan ini tidak dapat dibatalkan.',
          style: AppText.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: AppText.btnMd.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _delete(t);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
              minimumSize: const Size(80, 42),
            ),
            child: Text('Hapus', style: AppText.btnMd),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDesktop = AppResponsive.isDesktop(context);
    final isTablet = AppResponsive.isTablet(context);
    final hPad = isDesktop
        ? 48.0
        : isTablet
        ? 32.0
        : 20.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(context),
      floatingActionButton: _buildFAB(),
      body: StreamBuilder<List<ExamType>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snap.hasError) {
            return _ErrorState(error: snap.error.toString());
          }

          final list = snap.data ?? [];

          final cols = isDesktop
              ? 3
              : isTablet
              ? 2
              : 1;

          return CustomScrollView(
            slivers: [
              // ── Hero banner ──────────────────────────────────
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 0),
                sliver: SliverToBoxAdapter(
                  child: _HeroBanner(total: list.length),
                ),
              ),

              // ── Empty state ──────────────────────────────────
              if (list.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 120),
                  sliver: const SliverToBoxAdapter(child: _EmptyState()),
                )
              else
                // ── Grid ─────────────────────────────────────
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 120),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      // Biarkan Flutter hitung tinggi otomatis per item
                      childAspectRatio: isDesktop
                          ? 1.15
                          : isTablet
                          ? 1.05
                          : 1.3,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _ExamTypeCard(
                        examType: list[i],
                        onEdit: () => _openDialog(editing: list[i]),
                        onToggle: () => _toggle(list[i]),
                        onDelete: () => _confirmDelete(list[i]),
                      ),
                      childCount: list.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.border,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: AppGradient.navy,
              borderRadius: AppRadius.bSm,
            ),
            child: const Icon(
              Icons.category_rounded,
              color: AppColors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text('Kelola Kategori Ujian', style: AppText.h2),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _openDialog(),
      backgroundColor: AppColors.primary,
      elevation: 2,
      icon: const Icon(Icons.add_rounded, color: AppColors.white),
      label: Text('Tambah Tipe Ujian', style: AppText.btnMd),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final int total;
  const _HeroBanner({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppGradient.navy,
        borderRadius: AppRadius.bXl,
        boxShadow: AppShadow.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppGradient.gold,
                    borderRadius: AppRadius.bFull,
                  ),
                  child: Text(
                    'Admin Panel',
                    style: AppText.label.copyWith(
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tipe Ujian & Kategori',
                  style: AppText.h1.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kelola tipe ujian dan kategori soal secara fleksibel\ndan dinamis tanpa deployment ulang.',
                  style: AppText.bodySm.copyWith(
                    color: AppColors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Stat box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.08),
              borderRadius: AppRadius.bLg,
              border: Border.all(color: AppColors.white.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Text(
                  '$total',
                  style: AppText.display.copyWith(color: AppColors.white),
                ),
                Text(
                  'Tipe Ujian',
                  style: AppText.caption.copyWith(
                    color: AppColors.white.withOpacity(0.6),
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

// ─────────────────────────────────────────────────────────────────────────────
// EXAM TYPE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ExamTypeCard extends StatelessWidget {
  final ExamType examType;
  final VoidCallback onEdit, onToggle, onDelete;

  const _ExamTypeCard({
    required this.examType,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = examType.isActive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bLg,
        border: Border.all(
          color: active ? AppColors.border : AppColors.border.withOpacity(0.5),
        ),
        boxShadow: active ? AppShadow.sm : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon box
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: active
                        ? AppGradient.navy
                        : const LinearGradient(
                            colors: [Color(0xFFB0B8C8), Color(0xFFB0B8C8)],
                          ),
                    borderRadius: AppRadius.bSm,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              examType.name,
                              style: AppText.h3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.softBg(AppColors.success)
                                  : AppColors.softBg(AppColors.textHint),
                              borderRadius: AppRadius.bFull,
                            ),
                            child: Text(
                              active ? 'Aktif' : 'Nonaktif',
                              style: AppText.label.copyWith(
                                fontSize: 10,
                                color: active
                                    ? AppColors.success
                                    : AppColors.textHint,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (examType.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          examType.description,
                          style: AppText.bodySm,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Menu
                _CardMenu(
                  onEdit: onEdit,
                  onToggle: onToggle,
                  onDelete: onDelete,
                  isActive: active,
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border),

          // ── Categories ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kategori Soal',
                  style: AppText.label.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                examType.categories.isEmpty
                    ? Text('—', style: AppText.bodySm)
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: examType.categories
                            .map((c) => _CategoryChip(label: c))
                            .toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softBg(AppColors.primary),
        borderRadius: AppRadius.bFull,
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: AppText.label.copyWith(color: AppColors.primary, fontSize: 11),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD POPUP MENU
// ─────────────────────────────────────────────────────────────────────────────
class _CardMenu extends StatelessWidget {
  final VoidCallback onEdit, onToggle, onDelete;
  final bool isActive;
  const _CardMenu({
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: AppColors.textSecondary,
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
      color: AppColors.surface,
      elevation: 4,
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'toggle') onToggle();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        _menuItem('edit', Icons.edit_outlined, 'Edit', AppColors.textPrimary),
        _menuItem(
          'toggle',
          isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          isActive ? 'Nonaktifkan' : 'Aktifkan',
          AppColors.textPrimary,
        ),
        const PopupMenuDivider(height: 1),
        _menuItem(
          'delete',
          Icons.delete_outline_rounded,
          'Hapus',
          AppColors.error,
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
    String val,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem(
      value: val,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label, style: AppText.body.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _ExamTypeDialog extends StatefulWidget {
  final ExamType? editing;
  final Future<void> Function(ExamType) onSave;

  const _ExamTypeDialog({this.editing, required this.onSave});

  @override
  State<_ExamTypeDialog> createState() => _ExamTypeDialogState();
}

class _ExamTypeDialogState extends State<_ExamTypeDialog> {
  late final _nameCtrl = TextEditingController(text: widget.editing?.name);
  late final _descCtrl = TextEditingController(
    text: widget.editing?.description,
  );
  final _catCtrl = TextEditingController();
  late final List<String> _cats = List.from(widget.editing?.categories ?? []);
  bool _saving = false;

  bool get _isEdit => widget.editing != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  void _addCat() {
    final v = _catCtrl.text.trim().toUpperCase();
    if (v.isEmpty || _cats.contains(v)) return;
    setState(() {
      _cats.add(v);
      _catCtrl.clear();
    });
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _err('Nama tipe ujian wajib diisi');
      return;
    }
    if (_cats.isEmpty) {
      _err('Tambahkan minimal 1 kategori');
      return;
    }

    setState(() => _saving = true);

    final t = widget.editing ?? ExamType(id: '', name: '', categories: []);
    t.name = name;
    t.description = _descCtrl.text.trim();
    t.categories = _cats;

    try {
      await widget.onSave(t);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _err('Error: $e');
      }
    }
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.bXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppGradient.navy,
                      borderRadius: AppRadius.bSm,
                    ),
                    child: Icon(
                      _isEdit ? Icons.edit_outlined : Icons.add_rounded,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEdit ? 'Edit Tipe Ujian' : 'Tambah Tipe Ujian',
                    style: AppText.h2,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    iconSize: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Name
              Text('Nama Tipe Ujian', style: AppText.label),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                style: AppText.bodyLg,
                decoration: const InputDecoration(
                  hintText: 'Contoh: CPNS, PCPM, TBS LPDP',
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text('Deskripsi', style: AppText.label),
              const SizedBox(height: 6),
              TextField(
                controller: _descCtrl,
                style: AppText.body,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Opsional — jelaskan tipe ujian ini',
                ),
              ),
              const SizedBox(height: 20),

              // Categories
              Text('Kategori Soal', style: AppText.label),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _catCtrl,
                      style: AppText.body,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: TWK, TIU, TKP',
                      ),
                      onSubmitted: (_) => _addCat(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AddButton(onTap: _addCat),
                ],
              ),

              if (_cats.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _cats.map((c) {
                    return Chip(
                      label: Text(
                        c,
                        style: AppText.label.copyWith(color: AppColors.primary),
                      ),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      deleteIconColor: AppColors.textSecondary,
                      onDeleted: () => setState(() => _cats.remove(c)),
                      backgroundColor: AppColors.softBg(AppColors.primary),
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 28),
              Divider(color: AppColors.border),
              const SizedBox(height: 16),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        textStyle: AppText.btnMd.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: AppText.btnMd.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isEdit ? 'Simpan Perubahan' : 'Tambahkan',
                              style: AppText.btnMd,
                            ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// ADD CATEGORY BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppGradient.navy,
          borderRadius: AppRadius.bMd,
        ),
        child: const Icon(Icons.add_rounded, color: AppColors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bXl,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.layers_outlined,
              size: 40,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada tipe ujian',
            style: AppText.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Tekan tombol "+ Tambah Tipe Ujian" untuk memulai',
            style: AppText.bodySm,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR STATE
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text('Gagal memuat data', style: AppText.h3),
            const SizedBox(height: 6),
            Text(error, style: AppText.bodySm, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
