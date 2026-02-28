// ignore_for_file: file_names, deprecated_member_use, avoid_web_libraries_in_flutter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle, TextSpan;
import 'dart:html' as html;

import '../../app/theme.dart';
import 'createTO/manage_categories_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class SubTest {
  String id;
  String name;
  String description;
  String category;
  String difficulty;
  int estimatedMinutes;
  String type;
  String? fileName;
  int? questionCount;
  List<Map<String, dynamic>>? questions;

  SubTest({
    required this.id,
    this.name = '',
    this.description = '',
    this.category = '',
    this.difficulty = 'medium',
    this.estimatedMinutes = 30,
    this.type = 'objective',
    this.fileName,
    this.questionCount,
    this.questions,
  });
}

class ProcessingStatus {
  final String message;
  final bool isError;
  const ProcessingStatus({required this.message, this.isError = false});
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class CreateTryoutScreen extends StatefulWidget {
  const CreateTryoutScreen({super.key});

  @override
  State<CreateTryoutScreen> createState() => _CreateTryoutScreenState();
}

class _CreateTryoutScreenState extends State<CreateTryoutScreen>
    with SingleTickerProviderStateMixin {
  // ── Form ──────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '0');

  // ── Tryout meta ───────────────────────────────────────────────
  bool _isActive = true;
  bool _isFlexible = true;
  DateTime? _startDate;
  DateTime? _endDate;

  // ── Exam types ────────────────────────────────────────────────
  List<ExamType> _examTypes = [];
  String? _selectedExamTypeId;
  bool _loadingExamTypes = true;

  // ── Sub-tests ─────────────────────────────────────────────────
  final List<SubTest> _subTests = [];
  int _activeTab = 0;

  // Per-subtest controllers (keyed by subtest index)
  final Map<int, TextEditingController> _nameCtrl = {};
  final Map<int, TextEditingController> _descCtrl2 = {};
  final Map<int, TextEditingController> _timeCtrl = {};

  // ── State flags ───────────────────────────────────────────────
  bool _isSaving = false;
  bool _isParsing = false;
  double _parseProgress = 0;
  String _parseMsg = '';
  String? _errorMsg;

  final ValueNotifier<ProcessingStatus?> _toast = ValueNotifier(null);

  // ── Step UI ───────────────────────────────────────────────────
  int _currentStep = 0; // 0=Info, 1=ExamType, 2=Schedule, 3=Subtests

  @override
  void initState() {
    super.initState();
    _loadExamTypes();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    for (final c in _nameCtrl.values) {
      c.dispose();
    }
    for (final c in _descCtrl2.values) {
      c.dispose();
    }
    for (final c in _timeCtrl.values) {
      c.dispose();
    }
    _toast.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // DATA
  // ─────────────────────────────────────────────────────────────

  Future<void> _loadExamTypes() async {
    if (!mounted) return;
    setState(() => _loadingExamTypes = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('exam_types')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();
      if (!mounted) return;
      setState(() {
        _examTypes = snap.docs.map((d) => ExamType.fromFirestore(d)).toList();
        _loadingExamTypes = false;
      });
      if (_subTests.isEmpty) _addSubTest();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingExamTypes = false);
      _showToast('Gagal memuat kategori: $e', isError: true);
    }
  }

  ExamType? get _selectedExamType => _selectedExamTypeId == null
      ? null
      : _examTypes.where((e) => e.id == _selectedExamTypeId).firstOrNull;

  List<String> get _availableCategories => _selectedExamType?.categories ?? [];

  // ─────────────────────────────────────────────────────────────
  // SUBTEST MANAGEMENT
  // ─────────────────────────────────────────────────────────────

  void _addSubTest() {
    final idx = _subTests.length;
    _subTests.add(
      SubTest(id: DateTime.now().millisecondsSinceEpoch.toString()),
    );
    _nameCtrl[idx] = TextEditingController();
    _descCtrl2[idx] = TextEditingController();
    _timeCtrl[idx] = TextEditingController(text: '30');
    setState(() => _activeTab = idx);
  }

  void _removeSubTest(int idx) {
    if (_subTests.length <= 1) return;
    _nameCtrl[idx]?.dispose();
    _descCtrl2[idx]?.dispose();
    _timeCtrl[idx]?.dispose();
    _nameCtrl.remove(idx);
    _descCtrl2.remove(idx);
    _timeCtrl.remove(idx);
    setState(() {
      _subTests.removeAt(idx);
      if (_activeTab >= _subTests.length) _activeTab = _subTests.length - 1;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // TOAST
  // ─────────────────────────────────────────────────────────────

  void _showToast(String msg, {bool isError = false}) {
    _toast.value = ProcessingStatus(message: msg, isError: isError);
    if (!isError) {
      Future.delayed(const Duration(seconds: 3), () => _toast.value = null);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SAVE
  // ─────────────────────────────────────────────────────────────

  Future<void> _save() async {
    // Sync controller values → model
    for (int i = 0; i < _subTests.length; i++) {
      _subTests[i].name = _nameCtrl[i]?.text.trim() ?? '';
      _subTests[i].description = _descCtrl2[i]?.text.trim() ?? '';
      _subTests[i].estimatedMinutes =
          int.tryParse(_timeCtrl[i]?.text ?? '30') ?? 30;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedExamTypeId == null) {
      setState(() => _errorMsg = 'Pilih tipe ujian terlebih dahulu.');
      return;
    }
    for (final s in _subTests) {
      if (s.name.isEmpty) {
        setState(() => _errorMsg = 'Semua subtes harus memiliki nama.');
        return;
      }
      if (s.questions == null || s.questions!.isEmpty) {
        setState(() => _errorMsg = 'Upload file Excel untuk setiap subtes.');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _errorMsg = null;
    });
    _showToast('Menyimpan Try Out...');

    try {
      final subtestsData = [
        for (int i = 0; i < _subTests.length; i++)
          {
            'order': i,
            'name': _subTests[i].name,
            'description': _subTests[i].description,
            'category': _subTests[i].category,
            'difficulty': _subTests[i].difficulty,
            'estimatedMinutes': _subTests[i].estimatedMinutes,
            'type': _subTests[i].type,
            'questionCount': _subTests[i].questionCount ?? 0,
            'isActive': true,
            'questions': _subTests[i].questions ?? [],
          },
      ];

      await FirebaseFirestore.instance.collection('tryouts').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'examTypeId': _selectedExamTypeId,
        'examTypeName': _selectedExamType?.name ?? '',
        'price': int.tryParse(_priceCtrl.text) ?? 0,
        'isActive': _isActive,
        'isFlexibleDate': _isFlexible,
        'startDate': _isFlexible ? null : Timestamp.fromDate(_startDate!),
        'endDate': _isFlexible ? null : Timestamp.fromDate(_endDate!),
        'totalEstimatedMinutes': _subTests.fold(
          0,
          (s, t) => s + t.estimatedMinutes,
        ),
        'totalQuestions': _subTests.fold(
          0,
          (s, t) => s + (t.questionCount ?? 0),
        ),
        'subTestCount': _subTests.length,
        'subtests': subtestsData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showToast('✅ Try Out berhasil disimpan!');
      _reset();
    } catch (e) {
      _showToast('❌ Gagal menyimpan: $e', isError: true);
      setState(() => _errorMsg = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _reset() {
    for (final c in _nameCtrl.values) {
      c.dispose();
    }
    for (final c in _descCtrl2.values) {
      c.dispose();
    }
    for (final c in _timeCtrl.values) {
      c.dispose();
    }
    _nameCtrl.clear();
    _descCtrl2.clear();
    _timeCtrl.clear();
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    _descCtrl.clear();
    _priceCtrl.text = '0';
    setState(() {
      _selectedExamTypeId = null;
      _isActive = true;
      _isFlexible = true;
      _startDate = null;
      _endDate = null;
      _subTests.clear();
      _errorMsg = null;
      _currentStep = 0;
      _activeTab = 0;
    });
    _addSubTest();
  }

  // ─────────────────────────────────────────────────────────────
  // EXCEL PARSE
  // ─────────────────────────────────────────────────────────────

  Future<void> _pickFile(SubTest sub) async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );
      if (!mounted || res == null || res.files.single.bytes == null) return;
      setState(() => sub.fileName = res.files.single.name);
      await _parseExcel(sub, res.files.single.bytes!);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = 'Gagal memilih file: $e');
    }
  }

  Future<void> _parseExcel(SubTest sub, List<int> bytes) async {
    setState(() {
      _isParsing = true;
      _parseProgress = 0;
      _parseMsg = 'Membaca file…';
    });
    try {
      await Future.delayed(const Duration(milliseconds: 80));
      setState(() => _parseProgress = 0.1);

      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) throw Exception('Sheet tidak ditemukan');

      final rows = sheet.rows;
      final total = rows.length;
      final questions = <Map<String, dynamic>>[];

      String cell(List row, int i) {
        if (i >= row.length) return '';
        return (row[i]?.value ?? '').toString().trim();
      }

      for (int i = 1; i < total; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((c) => c?.value == null)) continue;
        if (i % 10 == 0) {
          setState(() {
            _parseProgress = 0.15 + (i / total) * 0.8;
            _parseMsg = 'Proses baris $i / ${total - 1}';
          });
          await Future.delayed(Duration.zero);
        }

        final pkg = cell(row, 0);
        final cat = cell(row, 1);
        final diff = cell(row, 2);
        final q = cell(row, 3);
        final type = cell(row, 4);
        if (q.isEmpty) continue;

        final opts = [
          cell(row, 5),
          cell(row, 6),
          cell(row, 7),
          cell(row, 8),
          cell(row, 9),
        ].where((o) => o.isNotEmpty).toList();

        final optImgs = [
          cell(row, 20),
          cell(row, 21),
          cell(row, 22),
          cell(row, 23),
          cell(row, 24),
        ].map((e) => e.isNotEmpty ? e : null).toList();

        final qImg = cell(row, 19);
        final exShort = cell(row, 16);
        final exFull = cell(row, 17);
        final tags = cell(
          row,
          18,
        ).split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

        if (type == 'likert') {
          questions.add({
            'package': pkg,
            'category': cat,
            'difficulty': diff.isEmpty ? 'medium' : diff,
            'question': q,
            'type': 'likert',
            'options': opts,
            'scores': [
              int.tryParse(cell(row, 11)) ?? 0,
              int.tryParse(cell(row, 12)) ?? 0,
              int.tryParse(cell(row, 13)) ?? 0,
              int.tryParse(cell(row, 14)) ?? 0,
              int.tryParse(cell(row, 15)) ?? 0,
            ],
            'explanationShort': exShort,
            'explanationFull': exFull,
            'tags': tags,
            'questionImage': qImg.isNotEmpty ? qImg : null,
            'optionImages': optImgs,
          });
        } else {
          questions.add({
            'package': pkg,
            'category': cat,
            'difficulty': diff.isEmpty ? 'medium' : diff,
            'question': q,
            'type': 'objective',
            'options': opts,
            'correctIndex': int.tryParse(cell(row, 10)) ?? 0,
            'explanationShort': exShort,
            'explanationFull': exFull,
            'tags': tags,
            'questionImage': qImg.isNotEmpty ? qImg : null,
            'optionImages': optImgs,
          });
        }
      }

      if (questions.isEmpty) throw Exception('Tidak ada soal valid di file');

      setState(() {
        sub.questions = questions;
        sub.questionCount = questions.length;
        _isParsing = false;
        _parseProgress = 0;
      });
      _showToast('✅ ${questions.length} soal berhasil dibaca');
    } catch (e) {
      setState(() {
        sub.fileName = null;
        sub.questions = null;
        sub.questionCount = null;
        _isParsing = false;
        _errorMsg = 'Parse error: $e';
      });
      _showToast('❌ $e', isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // IMAGE UPLOAD
  // ─────────────────────────────────────────────────────────────

  Future<void> _uploadImage(Map<String, dynamic> question) async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res == null) return;
    _showToast('Mengunggah gambar…');
    try {
      final f = res.files.first;
      final ref = FirebaseStorage.instance.ref(
        'questions/${DateTime.now().millisecondsSinceEpoch}_${f.name}',
      );
      final snap = await ref.putData(f.bytes!);
      final url = await snap.ref.getDownloadURL();
      setState(() => question['questionImage'] = url);
      _showToast('✅ Gambar berhasil diunggah');
    } catch (e) {
      _showToast('❌ Upload gagal: $e', isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TEMPLATE DOWNLOAD
  // ─────────────────────────────────────────────────────────────

  void _downloadTemplate(bool isLikert) {
    final excel = Excel.createExcel();
    final sheet = excel['questions'];
    sheet.appendRow(
      [
        'Package',
        'Category',
        'Difficulty',
        'Question',
        'Type',
        'Option A',
        'Option B',
        'Option C',
        'Option D',
        'Option E',
        'Correct Index',
        'Score A',
        'Score B',
        'Score C',
        'Score D',
        'Score E',
        'Explanation Short',
        'Explanation Full',
        'Tags',
        'Question Image URL',
        'Opt A Img',
        'Opt B Img',
        'Opt C Img',
        'Opt D Img',
        'Opt E Img',
      ].map(TextCellValue.new).toList(),
    );

    if (!isLikert) {
      sheet.appendRow(
        [
          'CPNS 2025',
          'TWK',
          'medium',
          'Sila pertama Pancasila adalah…',
          'objective',
          'Kemanusiaan',
          'Ketuhanan Yang Maha Esa',
          'Persatuan',
          'Kerakyatan',
          'Keadilan',
          '1',
          '',
          '',
          '',
          '',
          '',
          'Ketuhanan YME',
          'Sila 1 berbunyi Ketuhanan Yang Maha Esa.',
          'pancasila',
          '',
          '',
          '',
          '',
          '',
          '',
        ].map(TextCellValue.new).toList(),
      );
    } else {
      sheet.appendRow(
        [
          'CPNS 2025',
          'TKP',
          'medium',
          'Rekan kerja melakukan kesalahan, Anda…',
          'likert',
          'Menegur keras',
          'Membiarkan',
          'Lapor atasan langsung',
          'Bicara empat mata',
          'Bantu perbaiki',
          '',
          '1',
          '2',
          '3',
          '5',
          '4',
          'Komunikasi efektif',
          'Pilih D karena empati dan profesional.',
          'tkp,komunikasi',
          '',
          '',
          '',
          '',
          '',
          '',
        ].map(TextCellValue.new).toList(),
      );
    }

    final bytes = excel.encode()!;
    final url = html.Url.createObjectUrlFromBlob(html.Blob([bytes]));
    html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        isLikert ? 'template_tkp.xlsx' : 'template_twk_tiu.xlsx',
      )
      ..click();
    html.Url.revokeObjectUrl(url);
    _showToast('✅ Template diunduh');
  }

  // ─────────────────────────────────────────────────────────────
  // DATE PICKER
  // ─────────────────────────────────────────────────────────────

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => isStart ? _startDate = d : _endDate = d);
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left sidebar steps ─────────────────────────────
              _StepSidebar(
                current: _currentStep,
                onTap: (i) => setState(() => _currentStep = i),
              ),
              // ── Main content ───────────────────────────────────
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPageHeader(),
                        const SizedBox(height: AppSpacing.lg),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(_currentStep),
                            child: _buildStep(_currentStep),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (_errorMsg != null) _buildError(),
                        const SizedBox(height: AppSpacing.md),
                        _buildFooterActions(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // ── Floating toast ────────────────────────────────────
          ValueListenableBuilder<ProcessingStatus?>(
            valueListenable: _toast,
            builder: (_, status, __) {
              if (status == null) return const SizedBox.shrink();
              return _FloatingToast(
                status: status,
                onDismiss: () => _toast.value = null,
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PAGE HEADER
  // ─────────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradient.navy,
        borderRadius: AppRadius.bLg,
        boxShadow: AppShadow.md,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: AppRadius.bMd,
            ),
            child: const Icon(
              Icons.edit_document,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buat Try Out Baru',
                  style: AppText.h1.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Isi informasi, pilih kategori, dan unggah soal Excel',
                  style: AppText.bodySm.copyWith(
                    color: AppColors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          // Template download pills
          _TemplateBtn(
            label: 'TWK/TIU',
            icon: Icons.download_rounded,
            onTap: () => _downloadTemplate(false),
          ),
          const SizedBox(width: AppSpacing.sm),
          _TemplateBtn(
            label: 'TKP',
            icon: Icons.download_rounded,
            color: AppColors.gold,
            textColor: AppColors.primary,
            onTap: () => _downloadTemplate(true),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEPS
  // ─────────────────────────────────────────────────────────────

  Widget _buildStep(int step) {
    return switch (step) {
      0 => _buildStepInfo(),
      1 => _buildStepExamType(),
      2 => _buildStepSchedule(),
      3 => _buildStepSubtests(),
      _ => const SizedBox.shrink(),
    };
  }

  // ── Step 0: Info ─────────────────────────────────────────────

  Widget _buildStepInfo() {
    return _Card(
      icon: Icons.description_rounded,
      title: 'Informasi Try Out',
      accentColor: AppColors.primary,
      child: Column(
        children: [
          _Field(
            label: 'Judul Try Out',
            hint: 'Contoh: CPNS 2025 – Paket Simulasi 1',
            controller: _titleCtrl,
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Judul wajib diisi' : null,
            prefixIcon: Icons.title_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          _Field(
            label: 'Deskripsi',
            hint: 'Jelaskan materi yang diujikan…',
            controller: _descCtrl,
            maxLines: 3,
            validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Deskripsi wajib diisi' : null,
            prefixIcon: Icons.notes_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'Harga (coin/IDR)',
                  hint: '0 = gratis',
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Wajib diisi';
                    if (int.tryParse(v!) == null) return 'Harus angka';
                    return null;
                  },
                  prefixIcon: Icons.monetization_on_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SwitchTile(
                  label: 'Status Aktif',
                  subtitle: _isActive
                      ? 'Ditampilkan ke pengguna'
                      : 'Disembunyikan',
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeColor: AppColors.success,
                  icon: Icons.visibility_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 1: Exam Type ────────────────────────────────────────

  Widget _buildStepExamType() {
    return _Card(
      icon: Icons.school_rounded,
      title: 'Tipe Ujian',
      accentColor: AppColors.gold,
      child: _loadingExamTypes
          ? const _LoadingPlaceholder(message: 'Memuat tipe ujian…')
          : _examTypes.isEmpty
          ? _EmptyState(
              icon: Icons.category_rounded,
              message: 'Belum ada tipe ujian.',
              action: TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageCategoriesScreen(),
                    ),
                  );
                  if (mounted) _loadExamTypes();
                },
                icon: const Icon(Icons.add),
                label: const Text('Tambah Tipe Ujian'),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grid pilihan tipe ujian
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _examTypes.map((e) {
                    final isSelected = e.id == _selectedExamTypeId;
                    return _ExamTypeChip(
                      examType: e,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedExamTypeId = e.id),
                    );
                  }).toList(),
                ),
                if (_selectedExamType != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.softBg(AppColors.info),
                      borderRadius: AppRadius.bMd,
                      border: Border.all(
                        color: AppColors.info.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.label_rounded,
                          color: AppColors.info,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Kategori: ${_selectedExamType!.categories.join("  ·  ")}',
                            style: AppText.label.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageCategoriesScreen(),
                        ),
                      );
                      if (mounted) _loadExamTypes();
                    },
                    icon: const Icon(Icons.settings_rounded, size: 16),
                    label: const Text('Kelola Kategori'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  // ── Step 2: Schedule ─────────────────────────────────────────

  Widget _buildStepSchedule() {
    return _Card(
      icon: Icons.calendar_month_rounded,
      title: 'Periode Pengerjaan',
      accentColor: AppColors.info,
      child: Column(
        children: [
          _SwitchTile(
            label: 'Tanggal Bebas',
            subtitle: 'Pengguna bisa mengerjakan kapan saja',
            value: _isFlexible,
            onChanged: (v) => setState(() => _isFlexible = v),
            activeColor: AppColors.success,
            icon: Icons.all_inclusive_rounded,
          ),
          if (!_isFlexible) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Mulai',
                    date: _startDate,
                    onTap: () => _pickDate(true),
                    icon: Icons.play_circle_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _DateField(
                    label: 'Selesai',
                    date: _endDate,
                    onTap: () => _pickDate(false),
                    icon: Icons.stop_circle_rounded,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Step 3: Subtests ─────────────────────────────────────────

  Widget _buildStepSubtests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtest tab bar + add button
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _subTests.length,
                  itemBuilder: (_, i) {
                    final active = i == _activeTab;
                    final name = _nameCtrl[i]?.text.trim() ?? '';
                    return _SubTestTab(
                      label: name.isEmpty ? 'Subtes ${i + 1}' : name,
                      isActive: active,
                      canDelete: _subTests.length > 1,
                      onTap: () => setState(() => _activeTab = i),
                      onDelete: () => _removeSubTest(i),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _AddSubTestBtn(onTap: _addSubTest),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Active subtest form
        if (_subTests.isNotEmpty && _activeTab < _subTests.length)
          _buildSubTestForm(_subTests[_activeTab], _activeTab),
      ],
    );
  }

  Widget _buildSubTestForm(SubTest sub, int i) {
    _nameCtrl[i] ??= TextEditingController(text: sub.name);
    _descCtrl2[i] ??= TextEditingController(text: sub.description);
    _timeCtrl[i] ??= TextEditingController(
      text: sub.estimatedMinutes.toString(),
    );

    return Column(
      children: [
        _Card(
          icon: Icons.tune_rounded,
          title: 'Detail Subtes',
          accentColor: AppColors.gold,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _Field(
                      label: 'Nama Subtes',
                      hint: 'Contoh: TWK – Pancasila',
                      controller: _nameCtrl[i]!,
                      onChanged: (v) => sub.name = v,
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Nama wajib diisi'
                          : null,
                      prefixIcon: Icons.label_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _Field(
                      label: 'Durasi (menit)',
                      hint: '30',
                      controller: _timeCtrl[i]!,
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          sub.estimatedMinutes = int.tryParse(v) ?? 30,
                      validator: (v) {
                        if (v?.trim().isEmpty ?? true) return 'Wajib diisi';
                        if (int.tryParse(v!) == null) return 'Harus angka';
                        return null;
                      },
                      prefixIcon: Icons.timer_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _Field(
                label: 'Deskripsi Subtes (opsional)',
                hint: 'Jelaskan fokus materi subtes ini…',
                controller: _descCtrl2[i]!,
                maxLines: 2,
                onChanged: (v) => sub.description = v,
                prefixIcon: Icons.notes_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _DropdownField<String>(
                      label: 'Kategori',
                      icon: Icons.category_rounded,
                      value: _availableCategories.contains(sub.category)
                          ? sub.category
                          : (_availableCategories.isNotEmpty
                                ? _availableCategories.first
                                : null),
                      items: _availableCategories,
                      itemLabel: (v) => v,
                      emptyHint: 'Pilih tipe ujian dulu',
                      onChanged: (v) => setState(() => sub.category = v ?? ''),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DropdownField<String>(
                      label: 'Tipe Soal',
                      icon: Icons.quiz_rounded,
                      value: sub.type,
                      items: const ['objective', 'likert'],
                      itemLabel: (v) => v == 'objective'
                          ? 'Objektif (A–E)'
                          : 'Likert (Skala)',
                      onChanged: (v) => setState(() => sub.type = v!),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DropdownField<String>(
                      label: 'Kesulitan',
                      icon: Icons.trending_up_rounded,
                      value: sub.difficulty,
                      items: const ['easy', 'medium', 'hard'],
                      itemLabel: (v) => switch (v) {
                        'easy' => 'Mudah',
                        'medium' => 'Menengah',
                        _ => 'Sulit',
                      },
                      onChanged: (v) => setState(() => sub.difficulty = v!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Upload area
        _Card(
          icon: Icons.upload_file_rounded,
          title: 'File Soal Excel',
          accentColor: AppColors.info,
          child: _buildUploadSection(sub),
        ),
      ],
    );
  }

  Widget _buildUploadSection(SubTest sub) {
    if (_isParsing && _subTests[_activeTab] == sub) {
      return _ParseProgress(progress: _parseProgress, message: _parseMsg);
    }

    if (sub.fileName == null) {
      return _UploadDropZone(onTap: () => _pickFile(sub));
    }

    return Column(
      children: [
        // File info bar
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.softBg(AppColors.success),
            borderRadius: AppRadius.bMd,
            border: Border.all(color: AppColors.success.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: AppRadius.bSm,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.fileName!,
                      style: AppText.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${sub.questionCount ?? 0} soal terdeteksi',
                      style: AppText.caption.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
                tooltip: 'Hapus file',
                onPressed: () => setState(() {
                  sub.fileName = null;
                  sub.questions = null;
                  sub.questionCount = null;
                }),
              ),
            ],
          ),
        ),
        // Question preview
        if (sub.questions != null && sub.questions!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _QuestionsPreview(
            questions: sub.questions!,
            onUploadImage: _uploadImage,
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.softBg(AppColors.error),
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMsg!,
              style: AppText.bodySm.copyWith(color: AppColors.error),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: AppColors.error),
            onPressed: () => setState(() => _errorMsg = null),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions() {
    final isLast = _currentStep == 3;
    return Row(
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: () => setState(() => _currentStep--),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Kembali'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
            ),
          ),
        const Spacer(),
        TextButton(
          onPressed: _reset,
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Reset'),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton.icon(
          onPressed: _isSaving
              ? null
              : () {
                  if (isLast) {
                    _save();
                  } else {
                    setState(() => _currentStep++);
                  }
                },
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : Icon(
                  isLast
                      ? Icons.cloud_upload_rounded
                      : Icons.arrow_forward_rounded,
                  size: 16,
                ),
          label: Text(
            _isSaving
                ? 'Menyimpan…'
                : isLast
                ? 'Simpan Try Out'
                : 'Lanjut',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: isLast ? AppColors.success : AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 14,
            ),
            textStyle: AppText.btnMd,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

// ── Step Sidebar ────────────────────────────────────────────────────────────

class _StepSidebar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const _StepSidebar({required this.current, required this.onTap});

  static const _steps = [
    (Icons.description_rounded, 'Info'),
    (Icons.school_rounded, 'Tipe Ujian'),
    (Icons.calendar_month_rounded, 'Jadwal'),
    (Icons.quiz_rounded, 'Subtes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(gradient: AppGradient.navy),
            child: Row(
              children: [
                const Icon(
                  Icons.layers_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Langkah',
                  style: AppText.label.copyWith(color: AppColors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...List.generate(_steps.length, (i) {
            final done = i < current;
            final active = i == current;
            final (icon, label) = _steps[i];
            return InkWell(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.softBg(AppColors.primary)
                      : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: active ? AppColors.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: done
                            ? AppColors.success
                            : active
                            ? AppColors.primary
                            : AppColors.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: done
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.white,
                              size: 14,
                            )
                          : Icon(
                              icon,
                              color: active
                                  ? AppColors.white
                                  : AppColors.textHint,
                              size: 14,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      label,
                      style: AppText.bodySm.copyWith(
                        color: active
                            ? AppColors.primary
                            : done
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: active ? FontWeight.w700 : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Card Section ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final Widget child;

  const _Card({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.bLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.softBg(accentColor),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
              ),
              border: Border(
                bottom: BorderSide(color: accentColor.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: AppText.h3.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
        ],
      ),
    );
  }
}

// ── Field ─────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          style: AppText.bodyLg,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
          ),
        ),
      ],
    );
  }
}

// ── Dropdown Field ────────────────────────────────────────────────────────────

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final String? emptyHint;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.softBg(AppColors.warning),
              borderRadius: AppRadius.bMd,
              border: Border.all(color: AppColors.warning.withOpacity(0.4)),
            ),
            child: Text(
              emptyHint ?? 'Tidak ada pilihan',
              style: AppText.bodySm.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      );
    }
    final safeValue = items.contains(value) ? value : items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<T>(
          value: safeValue,
          items: items
              .map(
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(itemLabel(i), style: AppText.bodyLg),
                ),
              )
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.expand_more_rounded, size: 20),
          decoration: InputDecoration(prefixIcon: Icon(icon, size: 18)),
        ),
      ],
    );
  }
}

// ── Switch Tile ───────────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final IconData icon;

  const _SwitchTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.activeColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: value ? AppColors.softBg(activeColor) : AppColors.surfaceAlt,
        borderRadius: AppRadius.bMd,
        border: Border.all(
          color: value ? activeColor.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: value ? activeColor : AppColors.textHint),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.label.copyWith(
                    color: value ? activeColor : AppColors.textPrimary,
                  ),
                ),
                Text(subtitle, style: AppText.caption),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ── Date Field ────────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final IconData icon;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: onTap,
          borderRadius: AppRadius.bMd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: hasDate
                  ? AppColors.softBg(AppColors.primary)
                  : AppColors.surfaceAlt,
              borderRadius: AppRadius.bMd,
              border: Border.all(
                color: hasDate
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: hasDate ? AppColors.primary : AppColors.textHint,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  hasDate
                      ? '${date!.day}/${date!.month}/${date!.year}'
                      : 'Pilih tanggal',
                  style: AppText.bodyLg.copyWith(
                    color: hasDate ? AppColors.textPrimary : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Exam Type Chip ────────────────────────────────────────────────────────────

class _ExamTypeChip extends StatelessWidget {
  final ExamType examType;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExamTypeChip({
    required this.examType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.bMd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: AppRadius.bMd,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppShadow.sm : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              examType.name,
              style: AppText.label.copyWith(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              examType.categories.take(3).join(' · '),
              style: AppText.caption.copyWith(
                color: isSelected
                    ? AppColors.white.withOpacity(0.7)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SubTest Tab ───────────────────────────────────────────────────────────────

class _SubTestTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SubTestTab({
    required this.label,
    required this.isActive,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.bMd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surface,
            borderRadius: AppRadius.bMd,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.article_rounded,
                size: 14,
                color: isActive ? AppColors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.label.copyWith(
                  color: isActive ? AppColors.white : AppColors.textPrimary,
                ),
              ),
              if (canDelete) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(99),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: isActive
                        ? AppColors.white.withOpacity(0.7)
                        : AppColors.textHint,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add SubTest Button ────────────────────────────────────────────────────────

class _AddSubTestBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddSubTestBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add_rounded, size: 16),
      label: const Text('Tambah'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: AppText.btnSm,
      ),
    );
  }
}

// ── Upload Drop Zone ─────────────────────────────────────────────────────────

class _UploadDropZone extends StatefulWidget {
  final VoidCallback onTap;
  const _UploadDropZone({required this.onTap});

  @override
  State<_UploadDropZone> createState() => _UploadDropZoneState();
}

class _UploadDropZoneState extends State<_UploadDropZone> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          color: _hovering
              ? AppColors.softBg(AppColors.primary)
              : AppColors.surfaceAlt,
          borderRadius: AppRadius.bLg,
          border: Border.all(
            color: _hovering ? AppColors.primary : AppColors.border,
            width: _hovering ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.bLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_upload_rounded,
                size: 40,
                color: _hovering ? AppColors.primary : AppColors.textHint,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Klik atau seret file Excel ke sini',
                style: AppText.bodyLg.copyWith(
                  color: _hovering
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text('Format: .xlsx  ·  .xls', style: AppText.caption),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Parse Progress ────────────────────────────────────────────────────────────

class _ParseProgress extends StatelessWidget {
  final double progress;
  final String message;

  const _ParseProgress({required this.progress, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.softBg(AppColors.info),
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppText.bodySm.copyWith(color: AppColors.info),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppText.label.copyWith(color: AppColors.info),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.bFull,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.info.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.info),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Questions Preview ────────────────────────────────────────────────────────

class _QuestionsPreview extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final Future<void> Function(Map<String, dynamic>) onUploadImage;

  const _QuestionsPreview({
    required this.questions,
    required this.onUploadImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(
            Icons.preview_rounded,
            color: AppColors.info,
            size: 20,
          ),
          title: Text('Preview Soal', style: AppText.label),
          subtitle: Text('${questions.length} soal', style: AppText.caption),
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              separatorBuilder: (_, __) => const Divider(height: AppSpacing.lg),
              itemBuilder: (_, i) => _QuestionItem(
                question: questions[i],
                number: i + 1,
                onUploadImage: onUploadImage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Question Item ────────────────────────────────────────────────────────────

class _QuestionItem extends StatelessWidget {
  final Map<String, dynamic> question;
  final int number;
  final Future<void> Function(Map<String, dynamic>) onUploadImage;

  const _QuestionItem({
    required this.question,
    required this.number,
    required this.onUploadImage,
  });

  @override
  Widget build(BuildContext context) {
    final isObj = question['type'] == 'objective';
    final opts = (question['options'] as List?)?.cast<String>() ?? [];
    final correctIdx = question['correctIndex'] as int? ?? -1;
    final scores = (question['scores'] as List?)?.cast<int>() ?? [];
    final qImg = question['questionImage'] as String?;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.bMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.bSm,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: AppText.label.copyWith(color: AppColors.white),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Pill(label: question['category'] ?? '', color: AppColors.info),
              const SizedBox(width: 4),
              _Pill(
                label: isObj ? 'Objektif' : 'Likert',
                color: isObj ? AppColors.success : AppColors.warning,
              ),
              if (question['difficulty'] != null) ...[
                const SizedBox(width: 4),
                _Pill(
                  label: question['difficulty'],
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(question['question'] ?? '', style: AppText.body),
          // Question image
          if (qImg != null && qImg.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.bMd,
                  child: Image.network(
                    qImg,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Text('❌ Gambar gagal dimuat'),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () {
                      // Using a Builder trick here since we're in a stateless widget
                      // The parent manages state via onUploadImage
                    },
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.error,
                      child: const Icon(
                        Icons.delete_rounded,
                        size: 14,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => onUploadImage(question),
              icon: const Icon(Icons.add_a_photo_rounded, size: 16),
              label: const Text('Tambah Gambar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: AppText.btnSm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          // Options
          if (opts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...List.generate(opts.length, (i) {
              final isCorrect = isObj && correctIdx == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppColors.success
                            : AppColors.surface,
                        borderRadius: AppRadius.bSm,
                        border: Border.all(
                          color: isCorrect
                              ? AppColors.success
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + i),
                          style: AppText.caption.copyWith(
                            color: isCorrect
                                ? AppColors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        opts[i],
                        style: AppText.bodySm.copyWith(
                          color: isCorrect
                              ? AppColors.success
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!isObj && i < scores.length)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softBg(AppColors.info),
                          borderRadius: AppRadius.bSm,
                        ),
                        child: Text(
                          '${scores[i]}',
                          style: AppText.caption.copyWith(
                            color: AppColors.info,
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
}

// ── Pill ──────────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

// ── Template Button ───────────────────────────────────────────────────────────

class _TemplateBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;

  const _TemplateBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = AppColors.white,
    this.textColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.bMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: AppRadius.bMd,
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: AppText.btnSm.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Floating Toast ────────────────────────────────────────────────────────────

class _FloatingToast extends StatelessWidget {
  final ProcessingStatus status;
  final VoidCallback onDismiss;

  const _FloatingToast({required this.status, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: AppSpacing.lg,
      right: AppSpacing.lg,
      child: Material(
        elevation: 8,
        borderRadius: AppRadius.bMd,
        shadowColor: Colors.black26,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 320,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: status.isError
                ? AppColors.softBg(AppColors.error)
                : AppColors.surface,
            borderRadius: AppRadius.bMd,
            border: Border.all(
              color: status.isError
                  ? AppColors.error.withOpacity(0.4)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              if (!status.isError)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                )
              else
                Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  status.message,
                  style: AppText.bodySm.copyWith(
                    color: status.isError
                        ? AppColors.error
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (status.isError)
                InkWell(
                  onTap: onDismiss,
                  borderRadius: AppRadius.bFull,
                  child: const Icon(Icons.close_rounded, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading Placeholder ───────────────────────────────────────────────────────

class _LoadingPlaceholder extends StatelessWidget {
  final String message;
  const _LoadingPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: AppText.bodySm),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _EmptyState({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppText.bodySm),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
