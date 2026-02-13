// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/constants/text_styles.dart';

/// Model untuk Exam Type (Tipe Ujian)
class ExamType {
  String id;
  String name;
  String description;
  List<String> categories;
  int order;
  bool isActive;
  DateTime? createdAt;

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
    final data = doc.data() as Map<String, dynamic>;
    return ExamType(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'categories': categories,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}

/// Screen untuk manajemen kategori ujian
class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _firestore = FirebaseFirestore.instance;
  List<ExamType> _examTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExamTypes();
  }

  Future<void> _loadExamTypes() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore
          .collection('exam_types')
          .orderBy('order')
          .get();

      setState(() {
        _examTypes = snapshot.docs
            .map((doc) => ExamType.fromFirestore(doc))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat data: $e'),
            backgroundColor: const Color(0xFFFF4B4B),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF58CC02),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kelola Kategori Ujian',
          style: AppTextStyles.headingMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: AppSpacing.xl),
            _buildExamTypesList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExamTypeDialog,
        backgroundColor: const Color(0xFF58CC02),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Tambah Tipe Ujian',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1CB0F6), Color(0xFF1A8FCC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.category_rounded,
              color: Color(0xFF1CB0F6),
              size: 32,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipe Ujian & Kategori',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Kelola tipe ujian dan kategori soal secara fleksibel',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamTypesList() {
    if (_examTypes.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: _examTypes.map((examType) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildExamTypeCard(examType),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: const Color(0xFFAFAFAF),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Belum ada tipe ujian',
            style: AppTextStyles.headingSmall.copyWith(
              color: const Color(0xFF777777),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Klik tombol + untuk menambah tipe ujian baru',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFFAFAFAF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamTypeCard(ExamType examType) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: examType.isActive
              ? const Color(0xFFE5E5E5)
              : const Color(0xFFAFAFAF),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: examType.isActive
                  ? const Color(0xFF58CC02).withOpacity(0.1)
                  : const Color(0xFFF7F7F7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: examType.isActive
                        ? const Color(0xFF58CC02)
                        : const Color(0xFFAFAFAF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        examType.name,
                        style: AppTextStyles.headingSmall.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (examType.description.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          examType.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF777777),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditExamTypeDialog(examType);
                    } else if (value == 'toggle') {
                      _toggleExamTypeStatus(examType);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(examType);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded, size: 20),
                          SizedBox(width: AppSpacing.sm),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            examType.isActive
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(examType.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_rounded,
                            size: 20,
                            color: Color(0xFFFF4B4B),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          const Text(
                            'Hapus',
                            style: TextStyle(color: Color(0xFFFF4B4B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Categories
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kategori Soal',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF777777),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: examType.categories.map((category) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1CB0F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF1CB0F6),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        category,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF1CB0F6),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExamTypeDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final categoryController = TextEditingController();
    final categories = <String>[];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Tambah Tipe Ujian Baru',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Tipe Ujian',
                          hintText: 'Contoh: CPNS, PCPM, TBS LPDP',
                          filled: true,
                          fillColor: const Color(0xFFF7F7F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E5E5),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi (opsional)',
                          hintText: 'Jelaskan tipe ujian ini',
                          filled: true,
                          fillColor: const Color(0xFFF7F7F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E5E5),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        'Kategori Soal',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: categoryController,
                              decoration: InputDecoration(
                                hintText: 'Contoh: TWK, TIU, TKP',
                                filled: true,
                                fillColor: const Color(0xFFF7F7F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E5E5),
                                    width: 2,
                                  ),
                                ),
                              ),
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  setDialogState(() {
                                    categories.add(value.trim().toUpperCase());
                                    categoryController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          IconButton(
                            onPressed: () {
                              if (categoryController.text.trim().isNotEmpty) {
                                setDialogState(() {
                                  categories.add(
                                    categoryController.text.trim().toUpperCase(),
                                  );
                                  categoryController.clear();
                                });
                              }
                            },
                            icon: const Icon(Icons.add_circle_rounded),
                            color: const Color(0xFF58CC02),
                          ),
                        ],
                      ),
                      if (categories.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: categories.map((cat) {
                            return Chip(
                              label: Text(cat),
                              deleteIcon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                              ),
                              onDeleted: () {
                                setDialogState(() {
                                  categories.remove(cat);
                                });
                              },
                              backgroundColor: const Color(0xFF1CB0F6).withOpacity(0.1),
                              side: const BorderSide(
                                color: Color(0xFF1CB0F6),
                                width: 2,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'BATAL',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF777777),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nama tipe ujian wajib diisi'),
                          backgroundColor: Color(0xFFFF4B4B),
                        ),
                      );
                      return;
                    }

                    if (categories.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tambahkan minimal 1 kategori'),
                          backgroundColor: Color(0xFFFF4B4B),
                        ),
                      );
                      return;
                    }

                    final newExamType = ExamType(
                      id: '',
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      categories: categories,
                      order: _examTypes.length,
                      createdAt: DateTime.now(),
                    );

                    await _saveExamType(newExamType);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF58CC02),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'SIMPAN',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditExamTypeDialog(ExamType examType) {
    final nameController = TextEditingController(text: examType.name);
    final descController = TextEditingController(text: examType.description);
    final categoryController = TextEditingController();
    final categories = List<String>.from(examType.categories);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Edit Tipe Ujian',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Tipe Ujian',
                          filled: true,
                          fillColor: const Color(0xFFF7F7F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi',
                          filled: true,
                          fillColor: const Color(0xFFF7F7F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        'Kategori Soal',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: categoryController,
                              decoration: InputDecoration(
                                hintText: 'Tambah kategori',
                                filled: true,
                                fillColor: const Color(0xFFF7F7F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  setDialogState(() {
                                    categories.add(value.trim().toUpperCase());
                                    categoryController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          IconButton(
                            onPressed: () {
                              if (categoryController.text.trim().isNotEmpty) {
                                setDialogState(() {
                                  categories.add(
                                    categoryController.text.trim().toUpperCase(),
                                  );
                                  categoryController.clear();
                                });
                              }
                            },
                            icon: const Icon(Icons.add_circle_rounded),
                            color: const Color(0xFF58CC02),
                          ),
                        ],
                      ),
                      if (categories.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: categories.map((cat) {
                            return Chip(
                              label: Text(cat),
                              deleteIcon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                              ),
                              onDeleted: () {
                                setDialogState(() {
                                  categories.remove(cat);
                                });
                              },
                              backgroundColor: const Color(0xFF1CB0F6).withOpacity(0.1),
                              side: const BorderSide(
                                color: Color(0xFF1CB0F6),
                                width: 2,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('BATAL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    examType.name = nameController.text.trim();
                    examType.description = descController.text.trim();
                    examType.categories = categories;

                    await _updateExamType(examType);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF58CC02),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('SIMPAN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(ExamType examType) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Hapus Tipe Ujian?'),
          content: Text(
            'Yakin ingin menghapus "${examType.name}"? '
                'Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BATAL'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _deleteExamType(examType);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B4B),
                foregroundColor: Colors.white,
              ),
              child: const Text('HAPUS'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveExamType(ExamType examType) async {
    try {
      await _firestore.collection('exam_types').add(examType.toMap());
      await _loadExamTypes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${examType.name} berhasil ditambahkan'),
            backgroundColor: const Color(0xFF58CC02),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF4B4B),
          ),
        );
      }
    }
  }

  Future<void> _updateExamType(ExamType examType) async {
    try {
      await _firestore
          .collection('exam_types')
          .doc(examType.id)
          .update(examType.toMap());

      await _loadExamTypes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Berhasil diupdate'),
            backgroundColor: const Color(0xFF58CC02),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF4B4B),
          ),
        );
      }
    }
  }

  Future<void> _toggleExamTypeStatus(ExamType examType) async {
    try {
      await _firestore
          .collection('exam_types')
          .doc(examType.id)
          .update({'isActive': !examType.isActive});

      await _loadExamTypes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF4B4B),
          ),
        );
      }
    }
  }

  Future<void> _deleteExamType(ExamType examType) async {
    try {
      await _firestore.collection('exam_types').doc(examType.id).delete();
      await _loadExamTypes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Berhasil dihapus'),
            backgroundColor: const Color(0xFF58CC02),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF4B4B),
          ),
        );
      }
    }
  }
}