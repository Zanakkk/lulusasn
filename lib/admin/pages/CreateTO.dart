// ignore_for_file: file_names, deprecated_member_use, avoid_web_libraries_in_flutter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle, TextSpan;
import 'dart:html' as html;

import '../../app/theme.dart';
import 'manage_categories_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════
// REVISI 1: MODEL — Tambah ScoringConfig ke SubTest
// Ganti class SubTest yang lama dengan ini
// ═══════════════════════════════════════════════════════════════════════════

class ScoringConfig {
  double correctScore;
  double wrongScore;
  double emptyScore;

  ScoringConfig({
    this.correctScore = 1.0,
    this.wrongScore = -0.33,
    this.emptyScore = 0.0,
  });

  Map<String, dynamic> toMap() => {
    'correctScore': correctScore,
    'wrongScore': wrongScore,
    'emptyScore': emptyScore,
  };

  factory ScoringConfig.fromMap(Map<String, dynamic> m) => ScoringConfig(
    correctScore: (m['correctScore'] as num?)?.toDouble() ?? 1.0,
    wrongScore: (m['wrongScore'] as num?)?.toDouble() ?? -0.33,
    emptyScore: (m['emptyScore'] as num?)?.toDouble() ?? 0.0,
  );
}

class SubTest {
  String id;
  String name;
  String description;
  String category;
  String difficulty;
  int estimatedMinutes;
  String type; // 'objective' | 'likert'
  String? fileName;
  int? questionCount;
  List<Map<String, dynamic>>? questions;
  ScoringConfig scoringConfig; // ← BARU

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
    ScoringConfig? scoringConfig,
  }) : scoringConfig = scoringConfig ?? ScoringConfig();
}

class ProcessingStatus {
  final String message;
  final bool isError;
  const ProcessingStatus({required this.message, this.isError = false});
}

// ── Template Model ────────────────────────────────────────────────────────────
class _TryoutTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String tryoutTitle;
  final String tryoutDesc;
  final int price;
  final bool isActive;
  final List<_TemplateSubTest> subtests;

  const _TryoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.tryoutTitle,
    required this.tryoutDesc,
    required this.price,
    required this.isActive,
    required this.subtests,
  });
}

class _TemplateSubTest {
  final String name;
  final String description;
  final String category;
  final String type;
  final String difficulty;
  final int estimatedMinutes;
  final ScoringConfig scoringConfig;

  const _TemplateSubTest({
    required this.name,
    required this.description,
    required this.category,
    required this.type,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.scoringConfig,
  });
}

// ── Built-in Templates ────────────────────────────────────────────────────────
final _builtinTemplates = [
  _TryoutTemplate(
    id: 'cpns_skd',
    name: 'CPNS SKD',
    description: 'Seleksi Kompetensi Dasar: TWK, TIU, TKP',
    icon: Icons.account_balance_rounded,
    color: AppColors.info,
    tryoutTitle: 'CPNS 2026 – Paket Simulasi 1',
    tryoutDesc:
        'Paket simulasi pertama CPNS 2026 dengan 110 soal lengkap 30 soal TWK, 35 soal TIU, dan 45 soal TKP. Dirancang sesuai standar SKD BKN dengan timer, skoring otomatis, dan pembahasan detail.',
    price: 25000,
    isActive: true,
    subtests: [
      _TemplateSubTest(
        name: 'TIU – CPNS',
        description:
            'Uji kemampuan penalaran verbal, numerik, dan logika dengan 35 soal standar BKN. Mencakup sinonim, antonim, analogi, deret angka, aritmatika, dan logika analitis — dirancang untuk mengukur kecepatan dan ketepatan berpikir.',
        category: 'TIU',
        type: 'objective',
        difficulty: 'medium',
        estimatedMinutes: 35,
        scoringConfig: ScoringConfig(
          correctScore: 5,
          wrongScore: 0,
          emptyScore: 0,
        ),
      ),
      _TemplateSubTest(
        name: 'TWK – CPNS',
        description:
            'Uji pemahaman kebangsaan dan kenegaraan Anda melalui 30 soal yang mencakup Pancasila, UUD 1945, sejarah nasional, sistem ketatanegaraan, dan wawasan nusantara sesuai kisi-kisi resmi SKD BKN.',
        category: 'TWK',
        type: 'objective',
        difficulty: 'medium',
        estimatedMinutes: 30,
        scoringConfig: ScoringConfig(
          correctScore: 5,
          wrongScore: 0,
          emptyScore: 0,
        ),
      ),
      _TemplateSubTest(
        name: 'TKP – CPNS',
        description:
            'Uji karakter dan perilaku kerja Anda sebagai calon ASN melalui 45 soal situasional. Tidak ada jawaban benar atau salah — setiap pilihan memiliki bobot nilai 1–5 yang mencerminkan tingkat profesionalisme, integritas, dan pelayanan publik Anda.',
        category: 'TKP',
        type: 'likert',
        difficulty: 'medium',
        estimatedMinutes: 45,
        scoringConfig: ScoringConfig(
          correctScore: 5,
          wrongScore: 0,
          emptyScore: 0,
        ),
      ),
    ],
  ),
  _TryoutTemplate(
    id: 'lpdp_tbs',
    name: 'LPDP TBS',
    description: 'Tes Beasiswa LPDP: Verbal, Numerik, Penalaran',
    icon: Icons.school_rounded,
    color: const Color(0xFFD4AF37),
    tryoutTitle: 'LPDP TBS – Tes Beasiswa',
    tryoutDesc:
        'Simulasi Tes Beasiswa LPDP dengan 60 soal TBS mencakup penalaran verbal, kuantitatif, dan pemecahan masalah. Total waktu 90 menit dirancang sesuai standar seleksi LPDP.',
    price: 0,
    isActive: true,
    subtests: [
      _TemplateSubTest(
        name: 'Penalaran Verbal',
        description:
            'Uji kemampuan memahami teks, sinonim/antonim, analogi, dan penarikan kesimpulan logis dari bacaan melalui 23 soal terstruktur.',
        category: 'Verbal',
        type: 'objective',
        difficulty: 'hard',
        estimatedMinutes: 30,
        scoringConfig: ScoringConfig(
          correctScore: 1,
          wrongScore: 0,
          emptyScore: 0,
        ),
      ),
      _TemplateSubTest(
        name: 'Penalaran Kuantitatif',
        description:
            'Uji kemampuan berhitung, logika numerik, dan analisis data dasar melalui 25 soal yang mengukur kecepatan dan akurasi penalaran angka.',
        category: 'Numerik',
        type: 'objective',
        difficulty: 'hard',
        estimatedMinutes: 40,
        scoringConfig: ScoringConfig(
          correctScore: 1,
          wrongScore: 0,
          emptyScore: 0,
        ),
      ),
      _TemplateSubTest(
        name: 'Pemecahan Masalah',
        description:
            'Uji kemampuan menyelesaikan situasi kompleks menggunakan logika dan strategi analitis melalui 12 soal penalaran logis dan analitis.',
        category: 'Penalaran',
        type: 'objective',
        difficulty: 'hard',
        estimatedMinutes: 20,
        scoringConfig: ScoringConfig(
          correctScore: 1,
          wrongScore: 0,
          emptyScore: 0,
        ),
      ),
    ],
  ),
  _TryoutTemplate(
    id: 'bumn_tbs',
    name: 'BUMN TBS',
    description: 'Rekrutmen BUMN: Verbal, Numerik, Kepribadian',
    icon: Icons.business_rounded,
    color: AppColors.success,
    tryoutTitle: 'BUMN TBS – Rekrutmen Bersama',
    tryoutDesc: 'Simulasi Tes Bersama BUMN sesuai standar FHCI.',
    price: 0,
    isActive: true,
    subtests: [
      _TemplateSubTest(
        name: 'Verbal',
        description: 'Sinonim, antonim, analogi',
        category: 'Verbal',
        type: 'objective',
        difficulty: 'medium',
        estimatedMinutes: 30,
        scoringConfig: ScoringConfig(
          correctScore: 1,
          wrongScore: -0.25,
          emptyScore: 0,
        ),
      ),
      _TemplateSubTest(
        name: 'Numerik',
        description: 'Aritmatika, deret, interpretasi data',
        category: 'Numerik',
        type: 'objective',
        difficulty: 'medium',
        estimatedMinutes: 30,
        scoringConfig: ScoringConfig(
          correctScore: 1,
          wrongScore: -0.25,
          emptyScore: 0,
        ),
      ),
      _TemplateSubTest(
        name: 'Kepribadian',
        description: 'Big Five Personality, situasional',
        category: 'Kepribadian',
        type: 'likert',
        difficulty: 'easy',
        estimatedMinutes: 25,
        scoringConfig: ScoringConfig(
          correctScore: 5,
          wrongScore: 1,
          emptyScore: 0,
        ),
      ),
    ],
  ),
  _TryoutTemplate(
    id: 'blank',
    name: 'Mulai dari Kosong',
    description: 'Buat Try Out dari awal tanpa template',
    icon: Icons.add_circle_outline_rounded,
    color: AppColors.textSecondary,
    tryoutTitle: '',
    tryoutDesc: '',
    price: 0,
    isActive: true,
    subtests: [],
  ),
];

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
  bool _templateChosen = false; // false = tampilkan picker template

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
  void _applyTemplate(_TryoutTemplate tpl) {
    // Reset controllers lama
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

    _titleCtrl.text = tpl.tryoutTitle;
    _descCtrl.text = tpl.tryoutDesc;
    _priceCtrl.text = tpl.price.toString();

    _subTests.clear();
    if (tpl.subtests.isEmpty) {
      _subTests.add(
        SubTest(id: DateTime.now().millisecondsSinceEpoch.toString()),
      );
      _nameCtrl[0] = TextEditingController();
      _descCtrl2[0] = TextEditingController();
      _timeCtrl[0] = TextEditingController(text: '30');
    } else {
      for (int i = 0; i < tpl.subtests.length; i++) {
        final ts = tpl.subtests[i];
        _subTests.add(
          SubTest(
            id: '${DateTime.now().millisecondsSinceEpoch}_$i',
            name: ts.name,
            description: ts.description,
            category: ts.category,
            type: ts.type,
            difficulty: ts.difficulty,
            estimatedMinutes: ts.estimatedMinutes,
            scoringConfig: ts.scoringConfig,
          ),
        );
        _nameCtrl[i] = TextEditingController(text: ts.name);
        _descCtrl2[i] = TextEditingController(text: ts.description);
        _timeCtrl[i] = TextEditingController(
          text: ts.estimatedMinutes.toString(),
        );
      }
    }

    setState(() {
      _isActive = tpl.isActive;
      _templateChosen = true;
      _activeTab = 0;
      _currentStep = 0;
      _errorMsg = null;
    });
  }

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
            'scoringConfig': _subTests[i].scoringConfig.toMap(), // ← BARU
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

        final isLikert = type == 'likert';

        if (isLikert) {
          // Validasi: likert harus punya minimal 1 skor valid
          final rawScores = [
            int.tryParse(cell(row, 11)),
            int.tryParse(cell(row, 12)),
            int.tryParse(cell(row, 13)),
            int.tryParse(cell(row, 14)),
            int.tryParse(cell(row, 15)),
          ];
          // Trim skor hanya sejumlah opsi yang ada
          final scores = rawScores
              .take(opts.length)
              .map((s) => s ?? 0)
              .toList();

          questions.add({
            'package': pkg,
            'category': cat,
            'difficulty': diff.isEmpty ? 'medium' : diff,
            'question': q,
            'type': 'likert',
            'options': opts,
            'scores': scores, // ← skor per opsi dari Excel
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
          if (!_templateChosen)
            _TemplatePicker(onSelect: _applyTemplate)
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepSidebar(
                  current: _currentStep,
                  onTap: (i) => setState(() => _currentStep = i),
                ),
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
          // ── Floating toast ─────────────────────────────────────
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
          _TemplateBtn(
            label: 'Ganti Template',
            icon: Icons.swap_horiz_rounded,
            color: AppColors.gold,
            textColor: AppColors.primary,
            onTap: () => setState(() => _templateChosen = false),
          ),
          const SizedBox(width: AppSpacing.sm),
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
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
          icon: Icons.calculate_rounded,
          title: 'Konfigurasi Penilaian',
          accentColor: AppColors.warning,
          child: _ScoringConfigPanel(
            sub: sub,
            onChanged: () => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        _Card(
          icon: Icons.upload_file_rounded,
          title: 'Upload Soal Excel',
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
          IntrinsicWidth(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Kembali'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
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

// ═══════════════════════════════════════════════════════════════════════════
// REVISI 4: Widget BARU — _ScoringConfigPanel
// Taruh di bagian bawah file, setelah widget _EmptyState
// ═══════════════════════════════════════════════════════════════════════════

class _ScoringConfigPanel extends StatefulWidget {
  final SubTest sub;
  final VoidCallback onChanged;

  const _ScoringConfigPanel({required this.sub, required this.onChanged});

  @override
  State<_ScoringConfigPanel> createState() => _ScoringConfigPanelState();
}

class _ScoringConfigPanelState extends State<_ScoringConfigPanel> {
  late final TextEditingController _correctCtrl;
  late final TextEditingController _wrongCtrl;
  late final TextEditingController _emptyCtrl;

  @override
  void initState() {
    super.initState();
    final sc = widget.sub.scoringConfig;
    _correctCtrl = TextEditingController(text: sc.correctScore.toString());
    _wrongCtrl = TextEditingController(text: sc.wrongScore.toString());
    _emptyCtrl = TextEditingController(text: sc.emptyScore.toString());
  }

  @override
  void dispose() {
    _correctCtrl.dispose();
    _wrongCtrl.dispose();
    _emptyCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    widget.sub.scoringConfig
      ..correctScore = double.tryParse(_correctCtrl.text) ?? 1.0
      ..wrongScore = double.tryParse(_wrongCtrl.text) ?? -0.33
      ..emptyScore = double.tryParse(_emptyCtrl.text) ?? 0.0;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isLikert = widget.sub.type == 'likert';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Info banner sesuai tipe ──────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isLikert
                ? AppColors.softBg(AppColors.info)
                : AppColors.softBg(AppColors.success),
            borderRadius: AppRadius.bMd,
            border: Border.all(
              color: isLikert
                  ? AppColors.info.withOpacity(0.3)
                  : AppColors.success.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isLikert ? Icons.bar_chart_rounded : Icons.rule_rounded,
                size: 16,
                color: isLikert ? AppColors.info : AppColors.success,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isLikert
                      ? 'Mode Likert: skor per opsi diambil dari kolom Score A–E di file Excel. '
                            'Tidak ada jawaban benar/salah, setiap opsi memiliki bobot masing-masing.'
                      : 'Mode Objektif: tentukan poin untuk jawaban benar, salah, dan kosong di bawah.',
                  style: AppText.caption.copyWith(
                    color: isLikert ? AppColors.info : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Scoring fields (hanya untuk objective) ───────────────
        if (!isLikert) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ScoreField(
                  label: '✅ Jawaban Benar',
                  hint: 'misal: 1',
                  controller: _correctCtrl,
                  color: AppColors.success,
                  onChanged: (_) => _sync(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ScoreField(
                  label: '❌ Jawaban Salah',
                  hint: 'misal: -0.33',
                  controller: _wrongCtrl,
                  color: AppColors.error,
                  onChanged: (_) => _sync(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ScoreField(
                  label: '⬜ Tidak Dijawab',
                  hint: 'misal: 0',
                  controller: _emptyCtrl,
                  color: AppColors.textSecondary,
                  onChanged: (_) => _sync(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Preview formula
          _ScoringPreviewBar(config: widget.sub.scoringConfig),
        ],

        // ── Likert: preview bobot skor dari soal ─────────────────
        if (isLikert && widget.sub.questions != null) ...[
          const SizedBox(height: AppSpacing.md),
          _LikertScoresSummary(questions: widget.sub.questions!),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET BARU — _ScoreField
// Input field khusus untuk nilai scoring (mendukung desimal & negatif)
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final Color color;
  final ValueChanged<String> onChanged;

  const _ScoreField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.color,
    required this.onChanged,
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
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          onChanged: onChanged,
          style: AppText.bodyLg.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hint,
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.bMd,
              borderSide: BorderSide(color: color.withOpacity(0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.bMd,
              borderSide: BorderSide(color: color, width: 2),
            ),
          ),
          validator: (v) {
            if (v?.trim().isEmpty ?? true) return 'Wajib diisi';
            if (double.tryParse(v!) == null) return 'Harus angka';
            return null;
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET BARU — _ScoringPreviewBar
// Menampilkan simulasi formula penilaian secara visual
// ─────────────────────────────────────────────────────────────────────────────

class _ScoringPreviewBar extends StatelessWidget {
  final ScoringConfig config;

  const _ScoringPreviewBar({required this.config});

  @override
  Widget build(BuildContext context) {
    final formula =
        'Nilai = (Benar × ${config.correctScore}) + (Salah × ${config.wrongScore}) + (Kosong × ${config.emptyScore})';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.functions_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              formula,
              style: AppText.caption.copyWith(
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEMPLATE PICKER
// ─────────────────────────────────────────────────────────────────────────────

class _TemplatePicker extends StatefulWidget {
  final ValueChanged<_TryoutTemplate> onSelect;
  const _TemplatePicker({required this.onSelect});

  @override
  State<_TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends State<_TemplatePicker> {
  int? _hovered;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Container(
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
                          Icons.auto_awesome_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Template Try Out',
                            style: AppText.h1.copyWith(color: AppColors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mulai cepat dengan template atau buat dari awal',
                            style: AppText.bodySm.copyWith(
                              color: AppColors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Grid template ──
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: _builtinTemplates.asMap().entries.map((entry) {
                    final i = entry.key;
                    final tpl = entry.value;
                    final isBlank = tpl.id == 'blank';
                    final hover = _hovered == i;

                    return MouseRegion(
                      onEnter: (_) => setState(() => _hovered = i),
                      onExit: (_) => setState(() => _hovered = null),
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => widget.onSelect(tpl),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 260,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: hover
                                ? AppColors.softBg(tpl.color)
                                : AppColors.surface,
                            borderRadius: AppRadius.bLg,
                            border: Border.all(
                              color: hover
                                  ? tpl.color
                                  : isBlank
                                  ? AppColors.border
                                  : tpl.color.withOpacity(0.3),
                              width: hover ? 2 : 1,
                            ),
                            boxShadow: hover ? AppShadow.md : AppShadow.sm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isBlank
                                      ? AppColors.surfaceAlt
                                      : AppColors.softBg(tpl.color),
                                  borderRadius: AppRadius.bMd,
                                  border: Border.all(
                                    color: tpl.color.withOpacity(0.3),
                                  ),
                                ),
                                child: Icon(
                                  tpl.icon,
                                  size: 24,
                                  color: tpl.color,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Name
                              Text(
                                tpl.name,
                                style: AppText.h3.copyWith(
                                  color: hover
                                      ? tpl.color
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(tpl.description, style: AppText.bodySm),

                              // Subtest chips
                              if (!isBlank && tpl.subtests.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: tpl.subtests.map((s) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.softBg(tpl.color),
                                        borderRadius: AppRadius.bFull,
                                        border: Border.all(
                                          color: tpl.color.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        s.name.split('–').first.trim(),
                                        style: AppText.caption.copyWith(
                                          color: tpl.color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '${tpl.subtests.length} subtes  ·  '
                                  '${tpl.subtests.fold(0, (s, t) => s + t.estimatedMinutes)} menit',
                                  style: AppText.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],

                              const SizedBox(height: AppSpacing.md),

                              // CTA
                              Row(
                                children: [
                                  Expanded(
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: hover
                                            ? tpl.color
                                            : AppColors.surfaceAlt,
                                        borderRadius: AppRadius.bMd,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isBlank
                                                ? Icons.add_rounded
                                                : Icons.flash_on_rounded,
                                            size: 14,
                                            color: hover
                                                ? AppColors.white
                                                : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isBlank
                                                ? 'Mulai Kosong'
                                                : 'Gunakan Template',
                                            style: AppText.btnSm.copyWith(
                                              color: hover
                                                  ? AppColors.white
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
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
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(
                    'Template hanya mengisi form — soal Excel tetap harus diupload secara manual.',
                    style: AppText.caption,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET BARU — _LikertScoresSummary
// Menampilkan ringkasan distribusi skor opsi dari soal-soal Likert
// ─────────────────────────────────────────────────────────────────────────────

class _LikertScoresSummary extends StatelessWidget {
  final List<Map<String, dynamic>> questions;

  const _LikertScoresSummary({required this.questions});

  @override
  Widget build(BuildContext context) {
    // Hitung frekuensi setiap skor (1–5) di seluruh soal
    final Map<int, int> freq = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    int totalOpts = 0;

    for (final q in questions) {
      final scores = (q['scores'] as List?)?.cast<int>() ?? [];
      for (final s in scores) {
        if (freq.containsKey(s)) freq[s] = freq[s]! + 1;
        totalOpts++;
      }
    }

    final maxScore = questions.fold<double>(0, (acc, q) {
      final scores = (q['scores'] as List?)?.cast<int>() ?? [];
      return acc +
          (scores.isEmpty ? 0 : scores.reduce((a, b) => a > b ? a : b));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribusi Bobot Opsi (${questions.length} soal)',
          style: AppText.label,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Bar chart distribusi skor
        ...freq.entries.map((e) {
          final pct = totalOpts == 0 ? 0.0 : e.value / totalOpts;
          final color = _scoreColor(e.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.softBg(color),
                    borderRadius: AppRadius.bSm,
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      '${e.key}',
                      style: AppText.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: AppRadius.bFull,
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 10,
                      backgroundColor: AppColors.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${e.value}x',
                    style: AppText.caption,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: AppSpacing.sm),
        // Total skor maksimum
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.softBg(AppColors.gold),
            borderRadius: AppRadius.bMd,
            border: Border.all(color: AppColors.gold.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 16,
                color: AppColors.gold,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Total skor maksimum (jika semua opsi terbaik): $maxScore',
                style: AppText.caption.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _scoreColor(int score) => switch (score) {
    5 => AppColors.success,
    4 => const Color(0xFF4CAF50),
    3 => AppColors.warning,
    2 => const Color(0xFFFF7043),
    _ => AppColors.error,
  };
}
