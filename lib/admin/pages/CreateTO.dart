// ignore_for_file: file_names, deprecated_member_use, avoid_web_libraries_in_flutter, avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle, TextSpan;
import 'dart:html' as html;

import 'createTO/manage_categories_screen.dart';

/// Model untuk Subtes
class SubTest {
  String id;
  String name;
  String description;
  String category; // TWK, TIU, TKP
  String difficulty; // easy, medium, hard
  int estimatedMinutes;
  String type; // objective or likert
  String? fileName;
  int? questionCount;
  List<Map<String, dynamic>>? questions;

  SubTest({
    required this.id,
    this.name = '',
    this.description = '',
    this.category = 'TWK',
    this.difficulty = 'easy',
    this.estimatedMinutes = 15,
    this.type = 'objective',
    this.fileName,
    this.questionCount,
    this.questions,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'estimatedMinutes': estimatedMinutes,
      'type': type,
      'questionCount': questionCount ?? 0,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Screen untuk membuat Try Out baru dengan multi-subtes (Duolingo Style)
class CreateTryoutScreen extends StatefulWidget {
  const CreateTryoutScreen({super.key});

  @override
  State<CreateTryoutScreen> createState() => _CreateTryoutScreenState();
}

class _CreateTryoutScreenState extends State<CreateTryoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers untuk Tryout utama
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '1');

  // Tryout settings
  bool _isActive = true;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFlexibleDate = true; // Tanggal bebas

  // Exam Types & Categories
  List<ExamType> _examTypes = [];
  String? _selectedExamTypeId;
  bool _isLoadingExamTypes = true;

  // Subtes
  final List<SubTest> _subTests = [];
  int _selectedSubTestIndex = 0;

  // Processing state
  // REPLACE / TAMBAHKAN DI SEKITAR BARIS [cite: 12]
  bool _isProcessing = false;
  String? _errorMessage;
  // Hapus atau biarkan variabel lama, tapi tambahkan ini:
  final ValueNotifier<ProcessingStatus?> processStatus = ValueNotifier(null);

  double _parseProgress = 0.0;
  String _parseStatus = '';
  bool _isParsing = false;

  @override
  void initState() {
    super.initState();
    _loadExamTypes();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addSubTest() {
    setState(() {
      _subTests.add(
        SubTest(id: DateTime.now().millisecondsSinceEpoch.toString()),
      );
      _selectedSubTestIndex = _subTests.length - 1;
    });
  }

  void _removeSubTest(int index) {
    if (_subTests.length > 1) {
      setState(() {
        _subTests.removeAt(index);
        if (_selectedSubTestIndex >= _subTests.length) {
          _selectedSubTestIndex = _subTests.length - 1;
        }
      });
    }
  }

  Future<void> _loadExamTypes() async {
    setState(() => _isLoadingExamTypes = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exam_types')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      setState(() {
        _examTypes = snapshot.docs
            .map((doc) => ExamType.fromFirestore(doc))
            .toList();
        _isLoadingExamTypes = false;
      });

      // Tambah subtes default setelah exam types loaded
      if (_subTests.isEmpty) {
        _addSubTest();
      }
    } catch (e) {
      setState(() => _isLoadingExamTypes = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat kategori: $e'),
            backgroundColor: const Color(0xFFFF4B4B),
          ),
        );
      }
    }
  }

  ExamType? _getSelectedExamType() {
    if (_selectedExamTypeId == null) return null;
    try {
      return _examTypes.firstWhere((e) => e.id == _selectedExamTypeId);
    } catch (e) {
      return null;
    }
  }

  List<String> _getAvailableCategories() {
    final examType = _getSelectedExamType();
    return examType?.categories ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        // Gunakan Stack agar notifikasi bisa melayang [cite: 322]
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: AppSpacing.xl),
                  _buildTemplateButtons(),
                  SizedBox(height: AppSpacing.xl),
                  _buildMainForm(),
                ],
              ),
            ),
          ),

          // SISIPKAN: Notifikasi Latar Belakang di sini
          ValueListenableBuilder<ProcessingStatus?>(
            valueListenable: processStatus,
            builder: (context, status, child) {
              if (status == null) return const SizedBox.shrink();
              return _buildBackgroundNotification(
                status,
              ); // Buat widget pembantu ini
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundNotification(ProcessingStatus status) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Material(
        elevation: 10,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: status.isError ? const Color(0xFFFEF2F2) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: status.isError
                  ? Colors.red.withOpacity(0.5)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              if (!status.isError)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF6C63FF),
                  ),
                )
              else
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  status.message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: status.isError
                        ? Colors.red[900]
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
              if (status.isError)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => processStatus.value = null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(Map<String, dynamic> question) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(question['questionImage']),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 4,
          child: CircleAvatar(
            backgroundColor: Colors.red,
            radius: 16,
            child: IconButton(
              icon: const Icon(Icons.delete, size: 16, color: Colors.white),
              onPressed: () {
                setState(() {
                  question['questionImage'] = '';
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleImageUploadForQuestion(
    Map<String, dynamic> question,
  ) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    // Mulai proses background
    processStatus.value = ProcessingStatus(
      message: "Sedang mengunggah gambar...",
    );

    try {
      final file = result.files.first;
      final path =
          'questions/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      // Upload ke Storage
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = ref.putData(file.bytes!);

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      // Update state soal
      setState(() {
        question['questionImage'] = url;
      });

      processStatus.value = ProcessingStatus(
        message: "✅ Gambar berhasil dipasang",
      );
      Future.delayed(
        const Duration(seconds: 2),
        () => processStatus.value = null,
      );
    } catch (e) {
      print(e);
      processStatus.value = ProcessingStatus(
        message: "❌ Gagal upload: $e",
        isError: true,
      );
    }
  }

  // ==========================================================================
  // HEADER - Duolingo Style
  // ==========================================================================
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
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
              Icons.add_circle_rounded,
              size: 40,
              color: Color(0xFF58CC02),
            ),
          ),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buat Try Out Baru',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Isi informasi TO dan tambahkan subtes dengan soal-soal',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.95),
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
  // TEMPLATE BUTTONS - Duolingo Style
  // ==========================================================================
  Widget _buildTemplateButtons() {
    return Column(
      children: [
        // Button ke halaman kategori
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageCategoriesScreen(),
                ),
              );
              // Reload exam types setelah kembali
              _loadExamTypes();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9600).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF9600), width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9600),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.category_rounded,
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
                          'Kelola Kategori Ujian',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF9600),
                          ),
                        ),
                        Text(
                          'Atur tipe ujian & kategori soal (CPNS, PCPM, dll)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF777777),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFFF9600),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: AppSpacing.md),

        // Template buttons
        Row(
          children: [
            Expanded(
              child: _buildTemplateButton(
                label: 'Template TWK/TIU',
                icon: Icons.download_rounded,
                color: const Color(0xFF1CB0F6),
                onTap: _downloadObjectiveTemplate,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildTemplateButton(
                label: 'Template TKP',
                icon: Icons.download_rounded,
                color: const Color(0xFF58CC02),
                onTap: _downloadLikertTemplate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplateButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // MAIN FORM
  // ==========================================================================
  Widget _buildMainForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informasi Tryout Utama
          _buildDuoSection(
            title: 'Informasi Try Out',
            icon: Icons.description_rounded,
            color: const Color(0xFF58CC02),
            children: [
              _buildDuoTextField(
                label: 'Judul Try Out',
                hint: 'Contoh: CPNS 2025 - Paket Simulasi 1',
                controller: _titleController,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Judul wajib diisi' : null,
              ),
              SizedBox(height: AppSpacing.lg),
              _buildDuoTextField(
                label: 'Deskripsi',
                hint: 'Jelaskan materi yang akan diujikan',
                controller: _descriptionController,
                maxLines: 3,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Deskripsi wajib diisi' : null,
              ),
              SizedBox(height: AppSpacing.lg),
              _buildDuoTextField(
                label: 'Biaya',
                hint: '1',
                controller: _priceController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Wajib diisi';
                  if (int.tryParse(v!) == null) return 'Harus angka';
                  return null;
                },
              ),
            ],
          ),

          SizedBox(height: AppSpacing.xl),

          // Pilih Tipe Ujian
          _buildDuoSection(
            title: 'Tipe Ujian',
            icon: Icons.school_rounded,
            color: const Color(0xFFFF9600),
            children: [
              if (_isLoadingExamTypes)
                const Center(child: CircularProgressIndicator())
              else if (_examTypes.isEmpty)
                Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9600).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF9600),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFFF9600),
                        size: 32,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Belum ada tipe ujian',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF9600),
                        ),
                      ),
                      Text(
                        'Silakan tambah tipe ujian terlebih dahulu',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: const Color(0xFF777777),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Tipe Ujian',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4B4B4B),
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E5E5),
                          width: 2,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedExamTypeId,
                          isExpanded: true,
                          hint: Text(
                            'Pilih tipe ujian...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: const Color(0xFFAFAFAF),
                            ),
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF4B4B4B),
                          ),
                          items: _examTypes.map((examType) {
                            return DropdownMenuItem(
                              value: examType.id,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.school_rounded,
                                    color: const Color(0xFFFF9600),
                                    size: 20,
                                  ),
                                  SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          examType.name,
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        Text(
                                          examType.categories.join(', '),
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: const Color(0xFF777777),
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedExamTypeId = value;
                            });
                          },
                        ),
                      ),
                    ),
                    if (_selectedExamTypeId != null) ...[
                      SizedBox(height: AppSpacing.md),
                      Container(
                        padding: EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1CB0F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1CB0F6),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF1CB0F6),
                              size: 20,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Kategori tersedia: ${_getSelectedExamType()?.categories.join(", ") ?? ""}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF1CB0F6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),

          SizedBox(height: AppSpacing.xl),

          // Pengaturan Tanggal
          _buildDuoSection(
            title: 'Periode Pengerjaan',
            icon: Icons.calendar_today_rounded,
            color: const Color(0xFF1CB0F6),
            children: [
              _buildDuoSwitch(
                label: 'Tanggal Bebas',
                subtitle: 'User bisa kerjakan kapan saja',
                value: _isFlexibleDate,
                activeColor: const Color(0xFF58CC02),
                onChanged: (v) => setState(() => _isFlexibleDate = v),
              ),
              if (!_isFlexibleDate) ...[
                SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        label: 'Tanggal Mulai',
                        date: _startDate,
                        onTap: () => _selectDate(true),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildDatePicker(
                        label: 'Tanggal Selesai',
                        date: _endDate,
                        onTap: () => _selectDate(false),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildDuoSwitch(
                      label: 'Aktif',
                      subtitle: 'Tampilkan ke user',
                      value: _isActive,
                      activeColor: const Color(0xFF58CC02),
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: AppSpacing.xl),

          // Subtes Section
          _buildSubTestsSection(),

          SizedBox(height: AppSpacing.xxl),

          // Error Message
          if (_errorMessage != null) ...[
            _buildErrorMessage(),
            SizedBox(height: AppSpacing.lg),
          ],

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  // ==========================================================================
  // SUBTES SECTION
  // ==========================================================================
  Widget _buildSubTestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Text(
                'Subtes',
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _buildAddSubTestButton(),
          ],
        ),
        SizedBox(height: AppSpacing.md),

        // Tabs untuk pilih subtes
        _buildSubTestTabs(),

        SizedBox(height: AppSpacing.lg),

        // Form subtes yang dipilih
        _buildSubTestForm(),
      ],
    );
  }

  Widget _buildAddSubTestButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _addSubTest,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF58CC02),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF58CC02).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Tambah Subtes',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubTestTabs() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _subTests.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedSubTestIndex;
          final subTest = _subTests[index];
          final displayName = subTest.name.isEmpty
              ? 'Subtes ${index + 1}'
              : subTest.name;

          return Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _selectedSubTestIndex = index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF58CC02) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF58CC02)
                          : const Color(0xFFE5E5E5),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.quiz_rounded,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF777777),
                        size: 20,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        displayName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF777777),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_subTests.length > 1) ...[
                        SizedBox(width: AppSpacing.sm),
                        InkWell(
                          onTap: () => _removeSubTest(index),
                          child: Icon(
                            Icons.close_rounded,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF777777),
                            size: 18,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubTestForm() {
    if (_subTests.isEmpty) return const SizedBox();

    final subTest = _subTests[_selectedSubTestIndex];
    final nameController = TextEditingController(text: subTest.name);
    final descController = TextEditingController(text: subTest.description);
    final timeController = TextEditingController(
      text: subTest.estimatedMinutes.toString(),
    );

    return _buildDuoSection(
      title: 'Detail Subtes ${_selectedSubTestIndex + 1}',
      icon: Icons.edit_note_rounded,
      color: const Color(0xFFFF9600),
      children: [
        _buildDuoTextField(
          label: 'Nama Subtes',
          hint: 'Contoh: TWK - Pancasila dan UUD',
          controller: nameController,
          onChanged: (v) => subTest.name = v,
          validator: (v) =>
              v?.isEmpty ?? true ? 'Nama subtes wajib diisi' : null,
        ),
        SizedBox(height: AppSpacing.lg),
        _buildDuoTextField(
          label: 'Deskripsi Subtes',
          hint: 'Jelaskan materi subtes ini',
          controller: descController,
          maxLines: 2,
          onChanged: (v) => subTest.description = v,
        ),
        SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _buildDuoDropdownDynamic(
                label: 'Kategori',
                value: subTest.category,
                items: _getAvailableCategories(),
                icon: Icons.category_rounded,
                onChanged: (v) => setState(() => subTest.category = v!),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildDuoDropdown(
                label: 'Tipe Soal',
                value: subTest.type,
                items: const ['objective', 'likert'],
                icon: Icons.quiz_rounded,
                itemLabels: const {
                  'objective': 'Objektif (A-E)',
                  'likert': 'Likert (Skala)',
                },
                onChanged: (v) => setState(() => subTest.type = v!),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _buildDuoDropdown(
                label: 'Kesulitan',
                value: subTest.difficulty,
                items: const ['easy', 'medium', 'hard'],
                icon: Icons.trending_up_rounded,
                itemLabels: const {
                  'easy': 'Mudah',
                  'medium': 'Menengah',
                  'hard': 'Sulit',
                },
                onChanged: (v) => setState(() => subTest.difficulty = v!),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildDuoTextField(
                label: 'Estimasi (menit)',
                hint: '15',
                controller: timeController,
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final val = int.tryParse(v);
                  if (val != null) subTest.estimatedMinutes = val;
                },
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Wajib diisi';
                  if (int.tryParse(v!) == null) return 'Harus angka';
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        Divider(color: const Color(0xFFE5E5E5), thickness: 1),
        SizedBox(height: AppSpacing.lg),

        // Upload Excel
        _buildSubTestUpload(subTest),
      ],
    );
  }

  Widget _buildSubTestUpload(SubTest subTest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'File Soal Excel',
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: AppSpacing.md),

        if (_isParsing)
          _buildParsingProgress()
        else if (subTest.fileName == null)
          _buildUploadArea(subTest)
        else
          _buildUploadedFileInfo(subTest),
      ],
    );
  }

  Widget _buildParsingProgress() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFF1CB0F6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1CB0F6), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1CB0F6),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  _parseStatus,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF1CB0F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(_parseProgress * 100).toInt()}%',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: const Color(0xFF1CB0F6),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _parseProgress,
              minHeight: 10,
              backgroundColor: const Color(0xFF1CB0F6).withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF1CB0F6),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            _parseProgress < 0.3
                ? '📂 Membaca file Excel...'
                : _parseProgress < 0.6
                ? '🔍 Memvalidasi data soal...'
                : _parseProgress < 0.9
                ? '⚙️ Memproses soal...'
                : '✅ Hampir selesai...',
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea(SubTest subTest) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pickFileForSubTest(subTest),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: const Color(0xFF1CB0F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1CB0F6),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.cloud_upload_rounded,
                size: 48,
                color: const Color(0xFF1CB0F6),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Klik untuk upload Excel',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: const Color(0xFF1CB0F6),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Format: .xlsx atau .xls',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF777777),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedFileInfo(SubTest subTest) {
    return Column(
      children: [
        // File Info Card
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFF58CC02).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF58CC02), width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_rounded,
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
                      subTest.fileName ?? 'File uploaded',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subTest.questionCount != null)
                      Text(
                        '${subTest.questionCount} soal terdeteksi',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFF58CC02),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFFFF4B4B)),
                onPressed: () {
                  setState(() {
                    subTest.fileName = null;
                    subTest.questionCount = null;
                    subTest.questions = null;
                  });
                },
              ),
            ],
          ),
        ),

        // Preview Questions (Collapsible)
        if (subTest.questions != null && subTest.questions!.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          _buildQuestionsPreview(subTest),
        ],
      ],
    );
  }

  Widget _buildQuestionsPreview(SubTest subTest) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: EdgeInsets.all(AppSpacing.md),
          childrenPadding: EdgeInsets.all(AppSpacing.md),
          leading: const Icon(Icons.preview_rounded, color: Color(0xFF1CB0F6)),
          title: Text(
            'Preview Soal',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1CB0F6),
            ),
          ),
          subtitle: Text(
            '${subTest.questions!.length} soal',
            style: AppTextStyles.bodySmall.copyWith(
              color: const Color(0xFF777777),
            ),
          ),
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subTest.questions!.length,
              separatorBuilder: (_, __) => Divider(
                height: AppSpacing.lg,
                color: const Color(0xFFE5E5E5),
              ),
              itemBuilder: (context, index) {
                final q = subTest.questions![index];
                return _buildQuestionPreviewItem(q, index + 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExcelUpload(SubTest subTest) async {
    processStatus.value = ProcessingStatus(message: "Membuka file...");

    try {
      // Logika parsing Excel Anda...
      processStatus.value = ProcessingStatus(
        message: "Sedang memproses soal...",
      );

      // Setelah selesai
      processStatus.value = ProcessingStatus(
        message: "✅ Berhasil memproses ${subTest.questions?.length} soal",
      );
      Future.delayed(
        const Duration(seconds: 3),
        () => processStatus.value = null,
      );
    } catch (e) {
      processStatus.value = ProcessingStatus(
        message: "Gagal: $e",
        isError: true,
      );
    }
  }

  Widget _buildQuestionPreviewItem(Map<String, dynamic> question, int number) {
    final isObjective = question['type'] == 'objective';

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1CB0F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isObjective
                      ? const Color(0xFF58CC02).withOpacity(0.2)
                      : const Color(0xFFFF9600).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  question['category'] ?? 'N/A',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isObjective
                        ? const Color(0xFF58CC02)
                        : const Color(0xFFFF9600),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF777777).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isObjective ? 'Objektif' : 'Likert',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF777777),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),

          // Question Text
          Text(
            question['question'] ?? '',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (question['questionImage'] != null) ...[
            SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                question['questionImage'],
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4B4B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('❌ Gambar tidak dapat dimuat'),
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: AppSpacing.sm),

          // TAMBAHKAN / REPLACE BAGIAN GAMBAR:
          const SizedBox(height: 12),
          if (question['questionImage'] != null &&
              question['questionImage'].isNotEmpty)
            _buildImagePreview(
              question,
            ) // Widget untuk tampilkan & hapus gambar
          else
            OutlinedButton.icon(
              onPressed: () =>
                  _handleImageUploadForQuestion(question), // Method baru
              icon: const Icon(Icons.add_a_photo, size: 18),
              label: const Text("Tambah Gambar"),
            ),

          // Options Preview
          if (question['options'] != null) ...[
            ...List.generate((question['options'] as List).length, (i) {
              final option = question['options'][i];
              final isCorrect = isObjective && question['correctIndex'] == i;

              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? const Color(0xFF58CC02)
                            : Colors.white,
                        border: Border.all(
                          color: isCorrect
                              ? const Color(0xFF58CC02)
                              : const Color(0xFFE5E5E5),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + i), // A, B, C...
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isCorrect
                                ? Colors.white
                                : const Color(0xFF777777),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.toString(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: const Color(0xFF4B4B4B),
                            ),
                          ),
                          if (question['optionImages'] != null &&
                              i < (question['optionImages'] as List).length &&
                              question['optionImages'][i] != null) ...[
                            SizedBox(height: AppSpacing.xs),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                question['optionImages'][i],
                                height: 80,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Text(
                                  '❌ Gambar gagal',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Show score for Likert
                    if (!isObjective && question['scores'] != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1CB0F6).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${question['scores'][i]}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xFF1CB0F6),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // DUO SECTION - Flat Card
  // ==========================================================================
  Widget _buildDuoSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: AppSpacing.md),
              Text(
                title,
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }

  // ==========================================================================
  // DUO TEXT FIELD
  // ==========================================================================
  Widget _buildDuoTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4B4B4B),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: const Color(0xFFAFAFAF)),
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            contentPadding: EdgeInsets.all(AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1CB0F6), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF4B4B), width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF4B4B), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // DUO DROPDOWN
  // ==========================================================================
  Widget _buildDuoDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    Map<String, String>? itemLabels,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4B4B4B),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF4B4B4B),
              ),
              style: AppTextStyles.bodyLarge.copyWith(
                color: const Color(0xFF4B4B4B),
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(itemLabels?[item] ?? item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDuoDropdownDynamic({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    // Jika tidak ada items atau value tidak ada dalam items, set ke item pertama
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4B4B4B),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4B4B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF4B4B), width: 2),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFFF4B4B),
                  size: 20,
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Pilih tipe ujian terlebih dahulu',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFFFF4B4B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Validasi value
    String currentValue = value;
    if (!items.contains(value)) {
      currentValue = items.first;
      // Update value di callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChanged(currentValue);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4B4B4B),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF4B4B4B),
              ),
              style: AppTextStyles.bodyLarge.copyWith(
                color: const Color(0xFF4B4B4B),
              ),
              items: items.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // DUO SWITCH
  // ==========================================================================
  Widget _buildDuoSwitch({
    required String label,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: value ? activeColor.withOpacity(0.1) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? activeColor : const Color(0xFFE5E5E5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: value ? activeColor : const Color(0xFF4B4B4B),
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF777777),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: activeColor),
        ],
      ),
    );
  }

  // ==========================================================================
  // DATE PICKER
  // ==========================================================================
  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4B4B4B),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: const Color(0xFF777777),
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    date == null
                        ? 'Pilih tanggal'
                        : '${date.day}/${date.month}/${date.year}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: date == null
                          ? const Color(0xFFAFAFAF)
                          : const Color(0xFF4B4B4B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // ERROR MESSAGE
  // ==========================================================================
  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4B4B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF4B4B), width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFFF4B4B)),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFFFF4B4B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ACTION BUTTONS
  // ==========================================================================
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildDuoButton(
            text: 'RESET',
            color: const Color(0xFFE5E5E5),
            textColor: const Color(0xFF4B4B4B),
            onPressed: _resetForm,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: _buildDuoButton(
            text: _isProcessing ? 'MENYIMPAN...' : 'SIMPAN TRY OUT',
            color: const Color(0xFF58CC02),
            textColor: Colors.white,
            onPressed: _isProcessing ? null : _saveTryout,
          ),
        ),
      ],
    );
  }

  Widget _buildDuoButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: onPressed == null ? color.withOpacity(0.5) : color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: onPressed == null
                ? null
                : [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              text,
              style: AppTextStyles.bodyLarge.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // FUNCTIONS
  // ==========================================================================

  Future<void> _downloadObjectiveTemplate() async {
    await _exportQuestionsToExcel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Template TWK/TIU berhasil didownload!'),
          backgroundColor: const Color(0xFF58CC02),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _downloadLikertTemplate() async {
    await _exportLikertTemplateToExcel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Template TKP berhasil didownload!'),
          backgroundColor: const Color(0xFF58CC02),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _pickFileForSubTest(SubTest subTest) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, // ✅ PENTING untuk web
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          subTest.fileName = result.files.single.name;
          _errorMessage = null;
        });

        // Parse Excel langsung dari bytes
        await _parseExcelFile(subTest, result.files.single.bytes!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error memilih file: $e';
      });
    }
  }

  /// Parse Excel file dan extract questions

  Future<void> _parseExcelFile(SubTest subTest, List<int> bytes) async {
    setState(() {
      _isParsing = true;
      _parseProgress = 0.0;
      _parseStatus = 'Membaca file Excel...';
    });
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        _parseProgress = 0.1;
        _parseStatus = 'Mendekode file...';
      });
      final excel = Excel.decodeBytes(bytes);

      // Ambil sheet pertama
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) {
        throw Exception('Excel sheet tidak ditemukan');
      }

      final List<Map<String, dynamic>> questions = [];
      setState(() {
        subTest.questions = questions;
        subTest.questionCount = questions.length;
        subTest.fileName =
            subTest.fileName?.replaceFirst('⏳ Sedang memproses...', '') ??
            'file.xlsx'; // ✅ Reset nama
      });
      // Skip header row (index 0), mulai dari row 1
      final totalRows = sheet.rows.length;
      setState(() {
        _parseProgress = 0.2;
        _parseStatus = 'Ditemukan $totalRows baris data...';
      });

      for (int i = 1; i < totalRows; i++) {
        final row = sheet.rows[i];
        if (i % 5 == 0 || i == totalRows - 1) {
          setState(() {
            _parseProgress = 0.2 + (i / totalRows) * 0.7;
            _parseStatus = 'Memproses soal $i dari ${totalRows - 1}...';
          });
          await Future.delayed(Duration.zero);
        }

        // Skip empty rows
        if (row.isEmpty || row.every((cell) => cell?.value == null)) {
          continue;
        }

        // Helper function to get cell value as string
        String getCellValue(int index) {
          if (index >= row.length) return '';
          final cell = row[index];
          if (cell == null || cell.value == null) return '';
          return cell.value.toString().trim();
        }

        final package = getCellValue(0);
        final category = getCellValue(1);
        final difficulty = getCellValue(2);
        final question = getCellValue(3);
        final type = getCellValue(4);

        // Skip jika question kosong
        if (question.isEmpty) continue;

        final tags = getCellValue(18);
        final questionImage = getCellValue(19);
        final optImgA = getCellValue(20);
        final optImgB = getCellValue(21);
        final optImgC = getCellValue(22);
        final optImgD = getCellValue(23);
        final optImgE = getCellValue(24);
        final List<String?> optionImages = [
          optImgA,
          optImgB,
          optImgC,
          optImgD,
          optImgE,
        ].map((e) => e.isNotEmpty ? e : null).toList();

        if (type == 'objective') {
          final optionA = getCellValue(5);
          final optionB = getCellValue(6);
          final optionC = getCellValue(7);
          final optionD = getCellValue(8);
          final optionE = getCellValue(9);
          final correctIndex = getCellValue(10);
          final explanationShort = getCellValue(16);
          final explanationFull = getCellValue(17);

          final List<String?> optionImages = [
            optImgA,
            optImgB,
            optImgC,
            optImgD,
            optImgE,
          ].map((e) => e.isNotEmpty ? e : null).toList();

          questions.add({
            'package': package,
            'category': category,
            'difficulty': difficulty.isEmpty ? 'medium' : difficulty,
            'question': question,
            'type': 'objective',
            'options': [
              optionA,
              optionB,
              optionC,
              optionD,
              optionE,
            ].where((opt) => opt.isNotEmpty).toList(),
            'correctIndex': int.tryParse(correctIndex) ?? 0,
            'explanationShort': explanationShort,
            'explanationFull': explanationFull,
            'tags': tags
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList(),
            'questionImage': questionImage.isNotEmpty ? questionImage : null,
            'optionImages': optionImages,
          });
        } else if (type == 'likert') {
          final scoreA = getCellValue(11);
          final scoreB = getCellValue(12);
          final scoreC = getCellValue(13);
          final scoreD = getCellValue(14);
          final scoreE = getCellValue(15);
          final explanationShort = getCellValue(16);
          final explanationFull = getCellValue(17);
          final tags = getCellValue(18);

          questions.add({
            'package': package,
            'category': category,
            'difficulty': difficulty.isEmpty ? 'medium' : difficulty,
            'question': question,
            'type': 'likert',
            'options': [
              getCellValue(5),
              getCellValue(6),
              getCellValue(7),
              getCellValue(8),
              getCellValue(9),
            ].where((opt) => opt.isNotEmpty).toList(),
            'scores': [
              int.tryParse(scoreA) ?? 0,
              int.tryParse(scoreB) ?? 0,
              int.tryParse(scoreC) ?? 0,
              int.tryParse(scoreD) ?? 0,
              int.tryParse(scoreE) ?? 0,
            ],
            'explanationShort': explanationShort,
            'explanationFull': explanationFull,
            'tags': tags
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList(),
            'questionImage': questionImage.isNotEmpty ? questionImage : null,
            'optionImages': optionImages,
          });
        }
      }

      if (questions.isEmpty) {
        throw Exception('Tidak ada soal yang valid ditemukan di Excel');
      }

      setState(() {
        _parseProgress = 1.0;
        _parseStatus = 'Selesai! ${questions.length} soal berhasil diproses';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        subTest.questions = questions;
        subTest.questionCount = questions.length;
        _isParsing = false;
        _parseProgress = 0.0;
        _parseStatus = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${questions.length} soal berhasil diparse!'),
            backgroundColor: const Color(0xFF58CC02),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error parsing Excel: $e';
        subTest.fileName = null;
        subTest.questionCount = null;
        subTest.questions = null;
        _isParsing = false;
        _parseProgress = 0.0;
        _parseStatus = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error parsing Excel: $e'),
            backgroundColor: const Color(0xFFFF4B4B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF58CC02)),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _priceController.text = '1';

    setState(() {
      _selectedExamTypeId = null;
      _isActive = true;
      _isFlexibleDate = true;
      _startDate = null;
      _endDate = null;
      _subTests.clear();
      _errorMessage = null;
    });

    _addSubTest();
  }

  Future<void> _saveTryout() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Mohon lengkapi semua field yang wajib diisi';
      });
      return;
    }

    // Validasi exam type
    if (_selectedExamTypeId == null) {
      setState(() {
        _errorMessage = 'Silakan pilih tipe ujian terlebih dahulu';
      });
      return;
    }

    // Validasi subtes
    for (var subTest in _subTests) {
      if (subTest.name.isEmpty) {
        setState(() {
          _errorMessage = 'Semua subtes harus memiliki nama';
        });
        return;
      }
      if (subTest.questions == null || subTest.questions!.isEmpty) {
        setState(() {
          _errorMessage = 'Semua subtes harus memiliki soal (upload Excel)';
        });
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Hitung total estimasi waktu
      int totalMinutes = _subTests.fold(
        0,
        (sum, subTest) => sum + subTest.estimatedMinutes,
      );

      // Hitung total soal
      int totalQuestions = _subTests.fold(
        0,
        (sum, subTest) => sum + (subTest.questionCount ?? 0),
      );

      // ========================================================================
      // STRUKTUR FIRESTORE OPTIMAL - SINGLE DOCUMENT
      // ========================================================================
      // tryouts/{tryoutId} {
      //   metadata: {...},
      //   subtests: [
      //     {
      //       metadata: {...},
      //       questions: [...]
      //     }
      //   ]
      // }
      // ========================================================================

      // Build subtests array dengan questions
      final List<Map<String, dynamic>> subtestsData = [];

      for (int i = 0; i < _subTests.length; i++) {
        final subTest = _subTests[i];

        subtestsData.add({
          'name': subTest.name,
          'description': subTest.description,
          'category': subTest.category,
          'difficulty': subTest.difficulty,
          'estimatedMinutes': subTest.estimatedMinutes,
          'type': subTest.type,
          'questionCount': subTest.questionCount ?? 0,
          'order': i,
          'isActive': true,
          'questions':
              subTest.questions ?? [], // ✅ Array questions langsung di sini
        });
      }

      // Simpan semua data dalam 1 dokumen
      final tryoutData = {
        // Metadata tryout
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'examTypeId': _selectedExamTypeId,
        'examTypeName': _getSelectedExamType()?.name ?? '',
        'price': int.parse(_priceController.text),
        'isActive': _isActive,
        'isFlexibleDate': _isFlexibleDate,
        'startDate': _isFlexibleDate ? null : Timestamp.fromDate(_startDate!),
        'endDate': _isFlexibleDate ? null : Timestamp.fromDate(_endDate!),
        'totalEstimatedMinutes': totalMinutes,
        'totalQuestions': totalQuestions,
        'subTestCount': _subTests.length,

        // ✅ Subtests array (dengan questions di dalamnya)
        'subtests': subtestsData,

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // ✅ Single write operation - jauh lebih cepat!
      await firestore.collection('tryouts').add(tryoutData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Try Out "${_titleController.text}" berhasil disimpan!',
            ),
            backgroundColor: const Color(0xFF58CC02),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        _resetForm();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error menyimpan Try Out: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: const Color(0xFFFF4B4B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _exportQuestionsToExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['questions'];

    // Header
    sheet.appendRow([
      TextCellValue('Package'),
      TextCellValue('Category'),
      TextCellValue('Difficulty'),
      TextCellValue('Question'),
      TextCellValue('Type'),
      TextCellValue('Option A'),
      TextCellValue('Option B'),
      TextCellValue('Option C'),
      TextCellValue('Option D'),
      TextCellValue('Option E'),
      TextCellValue('Correct Index'),
      TextCellValue('Score A'),
      TextCellValue('Score B'),
      TextCellValue('Score C'),
      TextCellValue('Score D'),
      TextCellValue('Score E'),
      TextCellValue('Explanation Short'),
      TextCellValue('Explanation Full'),
      TextCellValue('Tags'),
      TextCellValue('Question Image URL'),
      TextCellValue('Option A Image URL'),
      TextCellValue('Option B Image URL'),
      TextCellValue('Option C Image URL'),
      TextCellValue('Option D Image URL'),
      TextCellValue('Option E Image URL'),
    ]);

    // Contoh soal TWK/TIU (Objective)
    final contohSoal = [
      // Soal 1 - TWK biasa
      [
        'CPNS 2025 Paket 1',
        'TWK',
        '20',
        'Sila pertama Pancasila adalah…',
        'objective',
        'Kemanusiaan yang adil dan beradab',
        'Ketuhanan Yang Maha Esa',
        'Persatuan Indonesia',
        'Kerakyatan yang dipimpin oleh hikmat kebijaksanaan',
        'Keadilan sosial bagi seluruh rakyat Indonesia',
        '1',
        '',
        '',
        '',
        '',
        '',
        'Sila pertama adalah Ketuhanan YME',
        'Pancasila memiliki 5 sila. Sila pertama berbunyi Ketuhanan Yang Maha Esa.',
        'pancasila,dasar negara,twk',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
      // Soal 2 - TIU biasa
      [
        'CPNS 2025 Paket 1',
        'TIU',
        '35',
        'Deret angka: 3, 6, 12, 24, … Angka berikutnya adalah?',
        'objective',
        '36',
        '48',
        '42',
        '54',
        '60',
        '1',
        '',
        '',
        '',
        '',
        '',
        'Pola deret dikali 2',
        'Deret ini mengikuti pola perkalian 2. 24×2=48.',
        'deret angka,logika,tiu',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
      // Soal 3 - TWK biasa
      [
        'CPNS 2025 Paket 1',
        'TWK',
        '25',
        'UUD 1945 disahkan pada tanggal?',
        'objective',
        '17 Agustus 1945',
        '18 Agustus 1945',
        '1 Juni 1945',
        '22 Juni 1945',
        '19 Agustus 1945',
        '1',
        '',
        '',
        '',
        '',
        '',
        'UUD 1945 disahkan 18 Agustus 1945',
        'UUD 1945 disahkan oleh PPKI pada 18 Agustus 1945.',
        'uud 1945,sejarah,twk',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
      // Soal 4 - TIU dengan gambar di soal (grafik/diagram)
      [
        'CPNS 2025 Paket 1',
        'TIU',
        '40',
        'Perhatikan diagram batang berikut. Pada bulan manakah penjualan tertinggi?',
        'objective',
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        '2',
        '',
        '',
        '',
        '',
        '',
        'Lihat batang tertinggi di diagram',
        'Berdasarkan diagram, batang tertinggi berada di bulan Maret.',
        'diagram,grafik,tiu',
        'https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/SimpleBarChartEn.svg/320px-SimpleBarChartEn.svg.png',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
      // Soal 5 - TWK dengan gambar di opsi (lambang/simbol)
      [
        'CPNS 2025 Paket 1',
        'TWK',
        '30',
        'Gambar di bawah ini merupakan lambang sila ke berapa dalam Pancasila?',
        'objective',
        'Sila ke-1',
        'Sila ke-2',
        'Sila ke-3',
        'Sila ke-4',
        'Sila ke-5',
        '0',
        '',
        '',
        '',
        '',
        '',
        'Bintang = sila ke-1 Ketuhanan YME',
        'Lambang bintang emas melambangkan sila pertama Pancasila yaitu Ketuhanan Yang Maha Esa.',
        'pancasila,lambang,twk',
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/Star_and_crescent.svg/240px-Star_and_crescent.svg.png',
        '',
        '',
        '',
        '',
        '',
        '',
      ],
    ];

    for (var row in contohSoal) {
      sheet.appendRow(row.map((e) => TextCellValue(e)).toList());
    }

    // Download
    final bytes = excel.encode();
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final _ = html.AnchorElement(href: url)
      ..setAttribute('download', 'template_twk_tiu.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _exportLikertTemplateToExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['questions'];

    // Header
    sheet.appendRow([
      TextCellValue('Package'),
      TextCellValue('Category'),
      TextCellValue('Difficulty'),
      TextCellValue('Question'),
      TextCellValue('Type'),
      TextCellValue('Option A'),
      TextCellValue('Option B'),
      TextCellValue('Option C'),
      TextCellValue('Option D'),
      TextCellValue('Option E'),
      TextCellValue('Correct Index'),
      TextCellValue('Score A'),
      TextCellValue('Score B'),
      TextCellValue('Score C'),
      TextCellValue('Score D'),
      TextCellValue('Score E'),
      TextCellValue('Explanation Short'),
      TextCellValue('Explanation Full'),
      TextCellValue('Tags'),
      TextCellValue('Question Image URL'),
      TextCellValue('Option A Image URL'),
      TextCellValue('Option B Image URL'),
      TextCellValue('Option C Image URL'),
      TextCellValue('Option D Image URL'),
      TextCellValue('Option E Image URL'),
    ]);

    // Contoh soal TKP (Likert)
    final contohSoal = [
      [
        'CPNS 2025 Paket 1',
        'TKP',
        '30',
        'Ketika rekan kerja Anda melakukan kesalahan yang merugikan tim, apa yang akan Anda lakukan?',
        'likert',
        'Menegur dengan keras di depan semua orang',
        'Membiarkan saja karena bukan urusan saya',
        'Melaporkan langsung ke atasan tanpa memberitahu yang bersangkutan',
        'Berbicara empat mata secara pribadi dan memberikan saran konstruktif',
        'Membantu memperbaiki kesalahan tanpa menegur',
        '',
        '1',
        '2',
        '3',
        '5',
        '4',
        'Komunikasi efektif dengan empati',
        'Pilihan D mendapat skor tertinggi karena menunjukkan pendekatan yang dewasa dan profesional dengan berbicara empat mata dan memberikan saran konstruktif. Ini mencerminkan sikap yang baik dalam hubungan kerja.',
        'tkp,kerja sama,komunikasi,integritas',
      ],
      [
        'CPNS 2025 Paket 1',
        'TKP',
        '25',
        'Anda diberi tugas mendesak yang harus selesai hari ini, namun Anda sudah memiliki jadwal padat. Apa yang Anda lakukan?',
        'likert',
        'Menolak tugas tersebut karena sudah terlalu banyak pekerjaan',
        'Menerima dan mengerjakan asal-asalan',
        'Meminta bantuan rekan kerja untuk mengerjakannya',
        'Menerima tugas, mengatur ulang prioritas, dan menyelesaikannya dengan optimal',
        'Mengerjakan tugas baru dan menunda pekerjaan lama',
        '',
        '1',
        '2',
        '3',
        '5',
        '4',
        'Manajemen waktu dan prioritas',
        'Pilihan D mendapat skor tertinggi karena menunjukkan kemampuan manajemen waktu yang baik, tanggung jawab, dan profesionalisme dengan menerima tugas sambil mengatur ulang prioritas untuk menyelesaikan semua pekerjaan dengan optimal.',
        'tkp,manajemen waktu,tanggung jawab,prioritas',
      ],
      [
        'CPNS 2025 Paket 1',
        'TKP',
        '28',
        'Anda menemukan kesalahan dalam laporan atasan yang akan dipresentasikan. Apa yang Anda lakukan?',
        'likert',
        'Diam saja karena takut disalahkan',
        'Memberitahu rekan kerja lain tentang kesalahan tersebut',
        'Langsung memperbaiki tanpa memberitahu atasan',
        'Segera memberitahu atasan secara pribadi dan sopan dengan menyertakan bukti',
        'Menunggu sampai presentasi selesai baru memberitahu',
        '',
        '1',
        '2',
        '3',
        '5',
        '4',
        'Integritas dan komunikasi proaktif',
        'Pilihan D mendapat skor tertinggi karena menunjukkan integritas, keberanian, dan profesionalisme dengan segera memberitahu atasan secara pribadi dan sopan. Ini membantu mencegah kesalahan lebih lanjut dan menunjukkan tanggung jawab.',
        'tkp,integritas,komunikasi,keberanian',
      ],
    ];

    for (var row in contohSoal) {
      sheet.appendRow(row.map((e) => TextCellValue(e)).toList());
    }

    // Download
    final bytes = excel.encode();
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final _ = html.AnchorElement(href: url)
      ..setAttribute('download', 'template_tkp.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}

class ProcessingStatus {
  final String message;
  final double? progress; // null untuk indeterminate
  final bool isError;

  ProcessingStatus({
    required this.message,
    this.progress,
    this.isError = false,
  });
}

class QuestionReviewCard extends StatefulWidget {
  final Map<String, dynamic> question;
  final Function(String url) onImageUploaded;

  const QuestionReviewCard({
    required this.question,
    required this.onImageUploaded,
  });

  @override
  State<QuestionReviewCard> createState() => _QuestionReviewCardState();
}

class _QuestionReviewCardState extends State<QuestionReviewCard> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    setState(() => _isUploading = true);

    try {
      // Logika upload ke Firebase Storage
      final file = result.files.first;
      final ref = FirebaseStorage.instance.ref().child(
        'questions/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
      );

      final uploadTask = ref.putData(file.bytes!);

      // Monitor Progress (Opsional jika ingin detail per gambar)
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      widget.onImageUploaded(url);
    } catch (e) {
      debugPrint("Upload error: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.question['imageUrl'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Soal: ${widget.question['questionText']}"),
            const SizedBox(height: 12),

            // AREA GAMBAR
            if (imageUrl != null && imageUrl.isNotEmpty)
              Stack(
                children: [
                  Image.network(imageUrl, height: 150, fit: BoxFit.cover),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => widget.onImageUploaded(''), // Hapus URL
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadImage,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo),
                label: Text(
                  _isUploading ? "Mengunggah..." : "Tambah Gambar Soal",
                ),
              ),
          ],
        ),
      ),
    );
  }
}
