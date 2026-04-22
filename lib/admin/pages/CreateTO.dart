// ignore_for_file: curly_braces_in_flow_control_structures, file_names, deprecated_member_use, avoid_web_libraries_in_flutter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle, TextSpan;
import 'dart:html' as html;
import 'dart:convert';

import '../../app/theme.dart';
import 'manage_categories_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
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
  String type;
  String? fileName;
  int? questionCount;
  List<Map<String, dynamic>>? questions;
  ScoringConfig scoringConfig;

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

// ── Template models ────────────────────────────────────────────────────────

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

final _builtinTemplates = [
  _TryoutTemplate(
    id: 'cpns_skd',
    name: 'CPNS SKD',
    description: 'Seleksi Kompetensi Dasar: TWK, TIU, TKP',
    icon: Icons.account_balance_rounded,
    color: AppColors.info,
    tryoutTitle: 'CPNS 2026 – Paket Simulasi 1',
    tryoutDesc:
        'Paket simulasi pertama CPNS 2026 dengan 110 soal lengkap: 30 soal TWK, 35 soal TIU, dan 45 soal TKP.',
    price: 25000,
    isActive: true,
    subtests: [
      _TemplateSubTest(
        name: 'TIU – CPNS',
        description: 'Uji kemampuan penalaran verbal, numerik, dan logika.',
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
        description: 'Uji pemahaman kebangsaan dan kenegaraan.',
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
        description: 'Uji karakter dan perilaku kerja sebagai calon ASN.',
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
    tryoutDesc: 'Simulasi Tes Beasiswa LPDP dengan 60 soal TBS.',
    price: 0,
    isActive: true,
    subtests: [
      _TemplateSubTest(
        name: 'Penalaran Verbal',
        description: 'Memahami teks, sinonim/antonim, analogi.',
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
        description: 'Berhitung, logika numerik, analisis data.',
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
        description: 'Logika dan strategi analitis.',
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

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class CreateTryoutScreen extends StatefulWidget {
  const CreateTryoutScreen({super.key});

  @override
  State<CreateTryoutScreen> createState() => _CreateTryoutScreenState();
}

class _CreateTryoutScreenState extends State<CreateTryoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '0');

  bool _isActive = true;
  bool _isFlexible = true;
  DateTime? _startDate;
  DateTime? _endDate;

  List<ExamType> _examTypes = [];
  String? _selectedExamTypeId;
  bool _loadingExamTypes = true;

  final List<SubTest> _subTests = [];
  int _activeTab = 0;

  final Map<int, TextEditingController> _nameCtrl = {};
  final Map<int, TextEditingController> _descCtrl2 = {};
  final Map<int, TextEditingController> _timeCtrl = {};

  bool _isSaving = false;
  bool _isParsing = false;
  double _parseProgress = 0;
  String _parseMsg = '';
  String? _errorMsg;

  final ValueNotifier<ProcessingStatus?> _toast = ValueNotifier(null);

  int _currentStep = 0;
  bool _templateChosen = false;

  // ── Editor state ────────────────────────────────────
  // index soal yang sedang di-edit (null = tidak ada)
  int? _editingQuestionIndex;

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
  // ✅ FIX 1 — Cell helper: buang \r penyebab _x000D_
  // ─────────────────────────────────────────────────────────────
  String _cleanStr(String raw) =>
      raw.replaceAll('\r\n', '\n').replaceAll('\r', '').trim();

  // ─────────────────────────────────────────────────────────────
  // DATA
  // ─────────────────────────────────────────────────────────────

  void _applyTemplate(_TryoutTemplate tpl) {
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
      _editingQuestionIndex = null;
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

  void _addSubTest() {
    final idx = _subTests.length;
    _subTests.add(
      SubTest(id: DateTime.now().millisecondsSinceEpoch.toString()),
    );
    _nameCtrl[idx] = TextEditingController();
    _descCtrl2[idx] = TextEditingController();
    _timeCtrl[idx] = TextEditingController(text: '30');
    setState(() {
      _activeTab = idx;
      _editingQuestionIndex = null;
    });
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
      _editingQuestionIndex = null;
    });
  }

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
        setState(
          () => _errorMsg = 'Upload file Excel/CSV untuk setiap subtes.',
        );
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
            'scoringConfig': _subTests[i].scoringConfig.toMap(),
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
      _editingQuestionIndex = null;
    });
    _addSubTest();
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ FIX 2 — File picker: support xlsx, xls, csv
  // ─────────────────────────────────────────────────────────────

  Future<void> _pickFile(SubTest sub) async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );
      if (!mounted || res == null || res.files.single.bytes == null) return;
      final f = res.files.single;
      setState(() => sub.fileName = f.name);

      final name = f.name.toLowerCase();
      if (name.endsWith('.csv')) {
        await _parseCsv(sub, f.bytes!);
      } else {
        await _parseExcel(sub, f.bytes!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = 'Gagal memilih file: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ FIX 3 — Excel parser: fix _x000D_ + numFmtId + empty rows
  // ─────────────────────────────────────────────────────────────

  Future<void> _parseExcel(SubTest sub, List<int> bytes) async {
    setState(() {
      _isParsing = true;
      _parseProgress = 0;
      _parseMsg = 'Membaca file Excel…';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 80));
      setState(() => _parseProgress = 0.1);

      Excel excel;
      try {
        excel = Excel.decodeBytes(bytes);
      } catch (e) {
        // ✅ Fix numFmtId crash
        if (e.toString().contains('numFmtId') ||
            e.toString().contains('FormatException')) {
          excel = Excel.decodeBytes(List<int>.from(bytes));
        } else {
          rethrow;
        }
      }

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];
      if (sheet == null) throw Exception('Sheet tidak ditemukan');

      final rows = sheet.rows;
      final questions = await _rowsToQuestions(rows, rows.length);

      if (questions.isEmpty) throw Exception('Tidak ada soal valid di file');

      setState(() {
        sub.questions = questions;
        sub.questionCount = questions.length;
        _isParsing = false;
        _parseProgress = 0;
        _editingQuestionIndex = null;
      });
      _showToast('✅ ${questions.length} soal berhasil dibaca dari Excel');
    } catch (e) {
      String errMsg = e.toString();
      if (errMsg.contains('numFmtId')) {
        errMsg =
            'Format Excel tidak didukung. Simpan ulang file sebagai .xlsx baru, lalu upload kembali.';
      }
      setState(() {
        sub.fileName = null;
        sub.questions = null;
        sub.questionCount = null;
        _isParsing = false;
        _errorMsg = errMsg;
      });
      _showToast('❌ $errMsg', isError: true);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ FITUR BARU — CSV parser
  // ─────────────────────────────────────────────────────────────

  Future<void> _parseCsv(SubTest sub, List<int> bytes) async {
    setState(() {
      _isParsing = true;
      _parseProgress = 0;
      _parseMsg = 'Membaca file CSV…';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 80));
      setState(() => _parseProgress = 0.1);

      // Decode bytes → string (UTF-8, fallback Latin-1)
      String content;
      try {
        content = utf8.decode(bytes);
      } catch (_) {
        content = latin1.decode(bytes);
      }

      // ✅ Fix _x000D_: normalise line endings sebelum parse
      content = content
          .replaceAll('_x000D_', '')
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n');

      setState(() => _parseProgress = 0.2);

      // Parse CSV dengan support quoted fields (termasuk newline dalam field)
      final rows = _parseCsvContent(content);

      if (rows.length < 2) throw Exception('CSV kosong atau hanya header');

      setState(() => _parseProgress = 0.3);

      // rows[0] = header, rows[1..] = data
      // Konversi ke format yang sama dengan _rowsToQuestions
      // tapi pakai List<String> bukan List<Data?>
      final questions = <Map<String, dynamic>>[];
      final total = rows.length;

      for (int i = 1; i < total; i++) {
        final row = rows[i];
        if (row.every((c) => c.trim().isEmpty)) continue;

        if (i % 20 == 0) {
          setState(() {
            _parseProgress = 0.3 + (i / total) * 0.65;
            _parseMsg = 'Proses baris $i / ${total - 1}';
          });
          await Future.delayed(Duration.zero);
        }

        // Helper ambil kolom aman
        String col(int idx) {
          if (idx >= row.length) return '';
          return _cleanStr(row[idx]);
        }

        final q = col(3);
        if (q.isEmpty) continue;

        final pkg = col(0);
        final cat = col(1);
        final diff = col(2);
        final type = col(4);

        final opts = [
          col(5),
          col(6),
          col(7),
          col(8),
          col(9),
        ].where((o) => o.isNotEmpty).toList();

        final optImgs = [
          col(20),
          col(21),
          col(22),
          col(23),
          col(24),
        ].map((e) => e.isNotEmpty ? e : null).toList();

        final qImg = col(19);
        final exShort = col(16);
        final exFull = col(17);
        final tags = col(
          18,
        ).split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

        if (type == 'likert') {
          final scores = [
            col(11),
            col(12),
            col(13),
            col(14),
            col(15),
          ].take(opts.length).map((s) => int.tryParse(s) ?? 0).toList();

          questions.add({
            'package': pkg,
            'category': cat,
            'difficulty': diff.isEmpty ? 'medium' : diff,
            'question': q,
            'type': 'likert',
            'options': opts,
            'scores': scores,
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
            'correctIndex': int.tryParse(col(10)) ?? 0,
            'explanationShort': exShort,
            'explanationFull': exFull,
            'tags': tags,
            'questionImage': qImg.isNotEmpty ? qImg : null,
            'optionImages': optImgs,
          });
        }
      }

      if (questions.isEmpty) {
        throw Exception('Tidak ada soal valid di file CSV');
      }

      setState(() {
        sub.questions = questions;
        sub.questionCount = questions.length;
        _isParsing = false;
        _parseProgress = 0;
        _editingQuestionIndex = null;
      });
      _showToast('✅ ${questions.length} soal berhasil dibaca dari CSV');
    } catch (e) {
      setState(() {
        sub.fileName = null;
        sub.questions = null;
        sub.questionCount = null;
        _isParsing = false;
        _errorMsg = e.toString();
      });
      _showToast('❌ ${e.toString()}', isError: true);
    }
  }

  /// RFC 4180-compliant CSV parser (support quoted fields dengan koma & newline)
  List<List<String>> _parseCsvContent(String content) {
    final rows = <List<String>>[];
    final lines = content.split('\n');
    List<String>? currentRow;
    String? inQuoteBuffer;

    for (final line in lines) {
      if (inQuoteBuffer != null) {
        // lanjutan field yang dikutip (ada newline di dalam field)
        inQuoteBuffer = '$inQuoteBuffer\n$line';
        // hitung jumlah tanda kutip
        final quoteCount = '"'.allMatches(inQuoteBuffer).length;
        if (quoteCount % 2 == 0) {
          // kutip sudah tertutup → selesaikan field
          final cleaned = inQuoteBuffer
              .replaceAll(RegExp(r'^"|"$'), '')
              .replaceAll('""', '"');
          currentRow!.add(cleaned);
          inQuoteBuffer = null;
          rows.add(currentRow);
          currentRow = null;
        }
        continue;
      }

      currentRow = <String>[];
      final fields = _splitCsvLine(line);
      for (int fi = 0; fi < fields.length; fi++) {
        final f = fields[fi];
        if (f.startsWith('"') &&
            !f.endsWith('"') &&
            '"'.allMatches(f).length % 2 != 0) {
          // field dikutip belum tertutup (ada newline di dalam)
          inQuoteBuffer = f;
          // sisa fields masuk ke buffer bersama
          if (fi + 1 < fields.length) {
            inQuoteBuffer =
                '$inQuoteBuffer,${fields.sublist(fi + 1).join(",")}';
          }
          break;
        }
        currentRow.add(_unquoteCsvField(f));
      }
      if (inQuoteBuffer == null && currentRow.isNotEmpty) {
        rows.add(currentRow);
        currentRow = null;
      }
    }

    return rows;
  }

  List<String> _splitCsvLine(String line) {
    final fields = <String>[];
    var i = 0;
    final buf = StringBuffer();
    var inQ = false;
    while (i < line.length) {
      final ch = line[i];
      if (ch == '"') {
        if (inQ && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i += 2;
          continue;
        }
        inQ = !inQ;
      } else if (ch == ',' && !inQ) {
        fields.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
      i++;
    }
    fields.add(buf.toString());
    return fields;
  }

  String _unquoteCsvField(String f) {
    f = f.trim();
    if (f.startsWith('"') && f.endsWith('"') && f.length >= 2) {
      f = f.substring(1, f.length - 1).replaceAll('""', '"');
    }
    return _cleanStr(f);
  }

  // Shared row→questions logic untuk Excel
  Future<List<Map<String, dynamic>>> _rowsToQuestions(
    List<List<dynamic>> rows,
    int total,
  ) async {
    final questions = <Map<String, dynamic>>[];

    // ✅ Fix _x000D_: pakai _cleanStr di semua cell
    String cell(List<dynamic> row, int i) {
      if (i >= row.length || row[i] == null) return '';
      final v = row[i]?.value;
      if (v == null) return '';
      String raw;
      if (v is TextCellValue) {
        raw = v.value.toString();
      } else if (v is IntCellValue)
        raw = v.value.toString();
      else if (v is DoubleCellValue)
        raw = v.value.toString();
      else if (v is BoolCellValue)
        raw = v.value.toString();
      else
        raw = v.toString();
      return _cleanStr(raw); // ← FIX _x000D_
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

      final q = cell(row, 3);
      if (q.isEmpty) continue;

      final pkg = cell(row, 0);
      final cat = cell(row, 1);
      final diff = cell(row, 2);
      final type = cell(row, 4);

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
        final scores = [
          cell(row, 11),
          cell(row, 12),
          cell(row, 13),
          cell(row, 14),
          cell(row, 15),
        ].take(opts.length).map((s) => int.tryParse(s) ?? 0).toList();

        questions.add({
          'package': pkg,
          'category': cat,
          'difficulty': diff.isEmpty ? 'medium' : diff,
          'question': q,
          'type': 'likert',
          'options': opts,
          'scores': scores,
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

    return questions;
  }

  // ─────────────────────────────────────────────────────────────
  // IMAGE UPLOAD
  // ─────────────────────────────────────────────────────────────

  Future<String?> _uploadImageFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (res == null) return null;
    _showToast('Mengunggah gambar…');
    try {
      final f = res.files.first;
      final ref = FirebaseStorage.instance.ref(
        'questions/${DateTime.now().millisecondsSinceEpoch}_${f.name}',
      );
      final snap = await ref.putData(f.bytes!);
      final url = await snap.ref.getDownloadURL();
      _showToast('✅ Gambar berhasil diunggah');
      return url;
    } catch (e) {
      _showToast('❌ Upload gagal: $e', isError: true);
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TEMPLATE DOWNLOAD — xlsx & csv
  // ─────────────────────────────────────────────────────────────

  void _downloadTemplate(bool isLikert, {bool asCsv = false}) {
    final headers = [
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
    ];

    final example = isLikert
        ? [
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
          ]
        : [
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
          ];

    final baseName = isLikert ? 'template_tkp' : 'template_twk_tiu';

    if (asCsv) {
      // ── Export as CSV ──────────────────────────────────────
      final sb = StringBuffer();
      sb.writeln(headers.map(_csvEscape).join(','));
      sb.writeln(example.map(_csvEscape).join(','));
      final bytes = utf8.encode(sb.toString());
      final url = html.Url.createObjectUrlFromBlob(
        html.Blob([bytes], 'text/csv'),
      );
      html.AnchorElement(href: url)
        ..setAttribute('download', '$baseName.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // ── Export as XLSX ─────────────────────────────────────
      final excel = Excel.createExcel();
      final sheet = excel['questions'];
      sheet.appendRow(headers.map(TextCellValue.new).toList());
      sheet.appendRow(example.map(TextCellValue.new).toList());
      final bytes = excel.encode()!;
      final url = html.Url.createObjectUrlFromBlob(html.Blob([bytes]));
      html.AnchorElement(href: url)
        ..setAttribute('download', '$baseName.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    }
    _showToast('✅ Template diunduh');
  }

  String _csvEscape(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

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
                  onTap: (i) => setState(() {
                    _currentStep = i;
                    _editingQuestionIndex = null;
                  }),
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
  // PAGE HEADER — tambah tombol download CSV
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
                  'Isi informasi, pilih kategori, dan unggah soal Excel/CSV',
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
          // Download dropdown: xlsx / csv
          _DownloadTemplateMenu(
            label: 'TWK/TIU',
            onXlsx: () => _downloadTemplate(false),
            onCsv: () => _downloadTemplate(false, asCsv: true),
          ),
          const SizedBox(width: AppSpacing.sm),
          _DownloadTemplateMenu(
            label: 'TKP',
            color: AppColors.gold,
            textColor: AppColors.primary,
            onXlsx: () => _downloadTemplate(true),
            onCsv: () => _downloadTemplate(true, asCsv: true),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int step) => switch (step) {
    0 => _buildStepInfo(),
    1 => _buildStepExamType(),
    2 => _buildStepSchedule(),
    3 => _buildStepSubtests(),
    _ => const SizedBox.shrink(),
  };

  // ─────────────────────────────────────────────────────────────
  // STEP 0 – Info
  // ─────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────
  // STEP 1 – Exam Type
  // ─────────────────────────────────────────────────────────────

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
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _examTypes
                      .map(
                        (e) => _ExamTypeChip(
                          examType: e,
                          isSelected: e.id == _selectedExamTypeId,
                          onTap: () =>
                              setState(() => _selectedExamTypeId = e.id),
                        ),
                      )
                      .toList(),
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
                ],
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 2 – Schedule
  // ─────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────
  // STEP 3 – Subtests
  // ─────────────────────────────────────────────────────────────

  Widget _buildStepSubtests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _subTests.length,
                  itemBuilder: (_, i) {
                    final name = _nameCtrl[i]?.text.trim() ?? '';
                    return _SubTestTab(
                      label: name.isEmpty ? 'Subtes ${i + 1}' : name,
                      isActive: i == _activeTab,
                      canDelete: _subTests.length > 1,
                      onTap: () => setState(() {
                        _activeTab = i;
                        _editingQuestionIndex = null;
                      }),
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
        // ── Detail subtes ──
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
                hint: 'Jelaskan fokus materi…',
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

        // ── Scoring config ──
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

        // ── Upload section ──
        _Card(
          icon: Icons.upload_file_rounded,
          title: 'Upload Soal (Excel / CSV)',
          accentColor: AppColors.info,
          child: _buildUploadSection(sub),
        ),

        // ── ✅ FITUR BARU: Question editor inline ──
        if (sub.questions != null && sub.questions!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _Card(
            icon: Icons.edit_note_rounded,
            title: 'Editor Soal (${sub.questions!.length} soal)',
            accentColor: AppColors.primary,
            child: _buildQuestionEditor(sub),
          ),
        ],
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
              TextButton.icon(
                onPressed: () => _pickFile(sub),
                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                label: const Text('Ganti'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.info,
                  textStyle: AppText.btnSm,
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
                  _editingQuestionIndex = null;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ FITUR BARU — Question Editor
  // ─────────────────────────────────────────────────────────────

  Widget _buildQuestionEditor(SubTest sub) {
    final questions = sub.questions!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Toolbar ──────────────────────────────────────────
        Row(
          children: [
            Text(
              'Klik soal untuk mengedit. Perubahan langsung tersimpan saat upload.',
              style: AppText.caption,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                final isLikert = sub.type == 'likert';
                setState(() {
                  questions.add({
                    'package': '',
                    'category': sub.category,
                    'difficulty': sub.difficulty,
                    'question': '',
                    'type': isLikert ? 'likert' : 'objective',
                    'options': ['', '', '', '', ''],
                    if (isLikert)
                      'scores': [1, 2, 3, 4, 5]
                    else
                      'correctIndex': 0,
                    'explanationShort': '',
                    'explanationFull': '',
                    'tags': <String>[],
                    'questionImage': null,
                    'optionImages': [null, null, null, null, null],
                  });
                  sub.questionCount = questions.length;
                  _editingQuestionIndex = questions.length - 1;
                });
              },
              icon: const Icon(Icons.add_rounded, size: 14),
              label: const Text('Tambah Soal'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: AppText.btnSm,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── List soal ─────────────────────────────────────────
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: questions.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final q = questions[i];
            final isEditing = _editingQuestionIndex == i;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isEditing
                    ? AppColors.softBg(AppColors.primary)
                    : AppColors.surfaceAlt,
                borderRadius: AppRadius.bMd,
                border: Border.all(
                  color: isEditing ? AppColors.primary : AppColors.border,
                  width: isEditing ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  // ── Row header soal ──────────────────────────
                  InkWell(
                    onTap: () => setState(
                      () => _editingQuestionIndex = isEditing ? null : i,
                    ),
                    borderRadius: isEditing
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(AppRadius.md),
                            topRight: Radius.circular(AppRadius.md),
                          )
                        : AppRadius.bMd,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          // Nomor
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isEditing
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: AppRadius.bSm,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: AppText.label.copyWith(
                                  color: isEditing
                                      ? AppColors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          // Preview teks soal
                          Expanded(
                            child: Text(
                              (q['question'] as String?)?.isEmpty ?? true
                                  ? '(soal kosong — klik untuk mengisi)'
                                  : q['question'],
                              style: AppText.bodySm.copyWith(
                                color:
                                    (q['question'] as String?)?.isEmpty ?? true
                                    ? AppColors.textHint
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          // Pills
                          _Pill(
                            label: q['type'] == 'likert' ? 'Likert' : 'Obj',
                            color: q['type'] == 'likert'
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          // Tombol hapus
                          InkWell(
                            onTap: () {
                              setState(() {
                                questions.removeAt(i);
                                sub.questionCount = questions.length;
                                if (_editingQuestionIndex == i) {
                                  _editingQuestionIndex = null;
                                } else if (_editingQuestionIndex != null &&
                                    _editingQuestionIndex! > i) {
                                  _editingQuestionIndex =
                                      _editingQuestionIndex! - 1;
                                }
                              });
                            },
                            borderRadius: AppRadius.bFull,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_rounded,
                                size: 16,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isEditing
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Form edit (expanded) ──────────────────────
                  if (isEditing)
                    _QuestionEditForm(
                      question: q,
                      questionNumber: i + 1,
                      onChanged: () => setState(() {}),
                      onUploadImage: (field) async {
                        final url = await _uploadImageFile();
                        if (url != null) setState(() => q[field] = url);
                      },
                      onUploadOptionImage: (optIdx) async {
                        final url = await _uploadImageFile();
                        if (url != null) {
                          setState(() {
                            final imgs = List<dynamic>.from(
                              q['optionImages'] as List? ?? [],
                            );
                            while (imgs.length <= optIdx) {
                              imgs.add(null);
                            }
                            imgs[optIdx] = url;
                            q['optionImages'] = imgs;
                          });
                        }
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ERROR + FOOTER
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
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
// ✅ WIDGET BARU — _QuestionEditForm
// Form lengkap edit satu soal (objective & likert)
// ═══════════════════════════════════════════════════════════════════════════

class _QuestionEditForm extends StatefulWidget {
  final Map<String, dynamic> question;
  final int questionNumber;
  final VoidCallback onChanged;
  final Future<void> Function(String field) onUploadImage;
  final Future<void> Function(int optIdx) onUploadOptionImage;

  const _QuestionEditForm({
    required this.question,
    required this.questionNumber,
    required this.onChanged,
    required this.onUploadImage,
    required this.onUploadOptionImage,
  });

  @override
  State<_QuestionEditForm> createState() => _QuestionEditFormState();
}

class _QuestionEditFormState extends State<_QuestionEditForm> {
  late final TextEditingController _qCtrl;
  late final TextEditingController _exShortCtrl;
  late final TextEditingController _exFullCtrl;
  late final TextEditingController _tagsCtrl;
  late final TextEditingController _pkgCtrl;
  late final List<TextEditingController> _optCtrl;
  late final List<TextEditingController> _scoreCtrl; // untuk likert

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

    final opts =
        (q['options'] as List?)?.cast<String>() ?? ['', '', '', '', ''];
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
    for (final c in _optCtrl) {
      c.dispose();
    }
    for (final c in _scoreCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  // ✅ Fix: nilai dari Firestore/Excel bisa berupa int atau string tak dikenal
  // → selalu fallback ke nilai valid agar DropdownButton tidak crash
  String _safeDifficulty(dynamic raw) {
    const valid = ['easy', 'medium', 'hard'];
    final s = raw?.toString() ?? '';
    return valid.contains(s) ? s : 'medium';
  }

  String _safeType(dynamic raw) {
    const valid = ['objective', 'likert'];
    final s = raw?.toString() ?? '';
    return valid.contains(s) ? s : 'objective';
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

    final opts = _optCtrl.map((c) => c.text.trim()).toList();
    q['options'] = opts;

    if (q['type'] == 'likert') {
      q['scores'] = _scoreCtrl.map((c) => int.tryParse(c.text) ?? 0).toList();
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final isLikert = q['type'] == 'likert';
    final qImg = q['questionImage'] as String?;
    final optImgs =
        (q['optionImages'] as List?)?.cast<dynamic>() ?? List.filled(5, null);
    final correctIdx = q['correctIndex'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Baris atas: Package + Difficulty + Type ──────────
          // ✅ Fix: pakai Wrap agar tidak overflow, dropdown punya ukuran cukup
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SizedBox(
                width: 180,
                child: _MiniField(
                  label: 'Package',
                  ctrl: _pkgCtrl,
                  onChanged: (_) => _sync(),
                ),
              ),
              SizedBox(
                width: 130,
                child: _MiniDropdown<String>(
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
                width: 130,
                child: _MiniDropdown<String>(
                  label: 'Tipe',
                  value: _safeType(q['type']),
                  items: const ['objective', 'likert'],
                  itemLabel: (v) => v == 'objective' ? 'Objektif' : 'Likert',
                  onChanged: (v) {
                    q['type'] = v!;
                    _sync();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Teks soal ──────────────────────────────────────────
          _MiniField(
            label: 'Teks Soal *',
            ctrl: _qCtrl,
            maxLines: 4,
            onChanged: (_) => _sync(),
            hint: 'Tulis teks soal di sini…',
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Gambar soal ────────────────────────────────────────
          _ImageFieldRow(
            label: 'Gambar Soal',
            url: qImg,
            onUpload: () => widget.onUploadImage('questionImage'),
            onRemove: () {
              setState(() => q['questionImage'] = null);
              _sync();
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Opsi jawaban ───────────────────────────────────────
          Text('Opsi Jawaban', style: AppText.label),
          const SizedBox(height: AppSpacing.xs),
          ...List.generate(5, (i) {
            final optImg = i < optImgs.length ? optImgs[i] as String? : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _OptionEditRow(
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
                onRemoveImage: () {
                  setState(() {
                    final imgs = List<dynamic>.from(
                      q['optionImages'] as List? ?? List.filled(5, null),
                    );
                    while (imgs.length <= i) {
                      imgs.add(null);
                    }
                    imgs[i] = null;
                    q['optionImages'] = imgs;
                  });
                  _sync();
                },
              ),
            );
          }),
          const SizedBox(height: AppSpacing.md),

          // ── Penjelasan ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MiniField(
                  label: 'Penjelasan Singkat',
                  ctrl: _exShortCtrl,
                  maxLines: 2,
                  onChanged: (_) => _sync(),
                  hint: 'Ringkasan pembahasan…',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MiniField(
                  label: 'Penjelasan Lengkap',
                  ctrl: _exFullCtrl,
                  maxLines: 2,
                  onChanged: (_) => _sync(),
                  hint: 'Pembahasan detail…',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Tags ───────────────────────────────────────────────
          _MiniField(
            label: 'Tags (pisah koma)',
            ctrl: _tagsCtrl,
            onChanged: (_) => _sync(),
            hint: 'pancasila, uud1945',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✅ WIDGET BARU — _OptionEditRow
// Satu baris opsi: huruf + text + score/correct + gambar opsi
// ─────────────────────────────────────────────────────────────────────────────

class _OptionEditRow extends StatelessWidget {
  final int index;
  final TextEditingController ctrl;
  final TextEditingController scoreCtrl;
  final bool isLikert;
  final bool isCorrect;
  final String? imageUrl;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSetCorrect;
  final VoidCallback onUploadImage;
  final VoidCallback onRemoveImage;

  const _OptionEditRow({
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
    final Color dotColor = isCorrect ? AppColors.success : AppColors.border;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Huruf / tombol jawaban benar ───────────────────────
        GestureDetector(
          onTap: onSetCorrect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: isCorrect ? AppColors.success : AppColors.surfaceAlt,
              borderRadius: AppRadius.bSm,
              border: Border.all(color: dotColor),
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
        const SizedBox(width: AppSpacing.sm),

        // ── Teks opsi ──────────────────────────────────────────
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
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),

        // ── Skor (Likert) ──────────────────────────────────────
        if (isLikert) ...[
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 56,
            child: TextFormField(
              controller: scoreCtrl,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              style: AppText.bodySm.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
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

        // ── Gambar opsi ────────────────────────────────────────
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.bSm,
                    child: Image.network(
                      imageUrl!,
                      width: 48,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_rounded,
                        size: 32,
                        color: AppColors.error,
                      ),
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
              ),
            ] else
              InkWell(
                onTap: onUploadImage,
                borderRadius: AppRadius.bSm,
                child: Container(
                  width: 48,
                  height: 40,
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
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✅ WIDGET BARU — _ImageFieldRow
// Upload/hapus gambar soal dengan preview
// ─────────────────────────────────────────────────────────────────────────────

class _ImageFieldRow extends StatelessWidget {
  final String label;
  final String? url;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  const _ImageFieldRow({
    required this.label,
    required this.url,
    required this.onUpload,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: AppText.label),
        const SizedBox(width: AppSpacing.sm),
        if (url != null && url!.isNotEmpty) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: AppRadius.bSm,
                child: Image.network(
                  url!,
                  height: 56,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Text('❌ Gagal', style: TextStyle(fontSize: 11)),
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
          const SizedBox(width: AppSpacing.sm),
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: AppText.btnSm,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MiniField — TextField compact untuk form editor
// ─────────────────────────────────────────────────────────────────────────────

class _MiniField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final String? hint;

  const _MiniField({
    required this.label,
    required this.ctrl,
    this.maxLines = 1,
    this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        // ✅ Fix: SizedBox.expand diganti dengan constraint eksplisit
        // isDense dihapus — penyebab assertion input_decorator:959
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          onChanged: onChanged,
          style: AppText.bodySm,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MiniDropdown
// ─────────────────────────────────────────────────────────────────────────────

class _MiniDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _MiniDropdown({
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
    return IntrinsicWidth(
      child: Column(
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXISTING REUSABLE WIDGETS (tidak berubah)
// ═══════════════════════════════════════════════════════════════════════════

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
    final has = date != null;
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
              color: has
                  ? AppColors.softBg(AppColors.primary)
                  : AppColors.surfaceAlt,
              borderRadius: AppRadius.bMd,
              border: Border.all(
                color: has
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: has ? AppColors.primary : AppColors.textHint,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  has
                      ? '${date!.day}/${date!.month}/${date!.year}'
                      : 'Pilih tanggal',
                  style: AppText.bodyLg.copyWith(
                    color: has ? AppColors.textPrimary : AppColors.textHint,
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
                'Klik atau seret file ke sini',
                style: AppText.bodyLg.copyWith(
                  color: _hovering
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text('Format: .xlsx  ·  .xls  ·  .csv', style: AppText.caption),
            ],
          ),
        ),
      ),
    );
  }
}

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

// ✅ WIDGET BARU — _DownloadTemplateMenu
// Tombol dengan dropdown pilih format XLSX atau CSV

class _DownloadTemplateMenu extends StatelessWidget {
  final String label;
  final VoidCallback onXlsx;
  final VoidCallback onCsv;
  final Color color;
  final Color textColor;

  const _DownloadTemplateMenu({
    required this.label,
    required this.onXlsx,
    required this.onCsv,
    this.color = AppColors.white,
    this.textColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'xlsx') {
          onXlsx();
        } else {
          onCsv();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'xlsx',
          child: Row(
            children: [
              const Icon(
                Icons.table_chart_rounded,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              Text('Download .xlsx', style: AppText.bodySm),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              const Icon(
                Icons.grid_on_rounded,
                size: 16,
                color: AppColors.info,
              ),
              const SizedBox(width: 8),
              Text('Download .csv', style: AppText.bodySm),
            ],
          ),
        ),
      ],
      tooltip: 'Download Template $label',
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
            Icon(Icons.download_rounded, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: AppText.btnSm.copyWith(color: color)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

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
                      ? 'Mode Likert: skor per opsi diambil dari kolom Score A–E di file. Tidak ada jawaban benar/salah.'
                      : 'Mode Objektif: tentukan poin untuk jawaban benar, salah, dan kosong.',
                  style: AppText.caption.copyWith(
                    color: isLikert ? AppColors.info : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLikert) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ScoreField(
                  label: '✅ Benar',
                  hint: '1',
                  controller: _correctCtrl,
                  color: AppColors.success,
                  onChanged: (_) => _sync(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ScoreField(
                  label: '❌ Salah',
                  hint: '-0.33',
                  controller: _wrongCtrl,
                  color: AppColors.error,
                  onChanged: (_) => _sync(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ScoreField(
                  label: '⬜ Kosong',
                  hint: '0',
                  controller: _emptyCtrl,
                  color: AppColors.textSecondary,
                  onChanged: (_) => _sync(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScoringPreviewBar(config: widget.sub.scoringConfig),
        ],
        if (isLikert && widget.sub.questions != null) ...[
          const SizedBox(height: AppSpacing.md),
          _LikertScoresSummary(questions: widget.sub.questions!),
        ],
      ],
    );
  }
}

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
            if (v?.trim().isEmpty ?? true) return 'Wajib';
            if (double.tryParse(v!) == null) return 'Angka';
            return null;
          },
        ),
      ],
    );
  }
}

class _ScoringPreviewBar extends StatelessWidget {
  final ScoringConfig config;
  const _ScoringPreviewBar({required this.config});

  @override
  Widget build(BuildContext context) {
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
              'Nilai = (Benar × ${config.correctScore}) + (Salah × ${config.wrongScore}) + (Kosong × ${config.emptyScore})',
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

class _LikertScoresSummary extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  const _LikertScoresSummary({required this.questions});

  @override
  Widget build(BuildContext context) {
    final Map<int, int> freq = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    int total = 0;
    for (final q in questions) {
      for (final s in (q['scores'] as List?)?.cast<int>() ?? []) {
        if (freq.containsKey(s)) freq[s] = freq[s]! + 1;
        total++;
      }
    }
    final maxScore = questions.fold<double>(0, (acc, q) {
      final sc = (q['scores'] as List?)?.cast<int>() ?? [];
      return acc + (sc.isEmpty ? 0 : sc.reduce((a, b) => a > b ? a : b));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribusi Bobot Opsi (${questions.length} soal)',
          style: AppText.label,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...freq.entries.map((e) {
          final pct = total == 0 ? 0.0 : e.value / total;
          final col = _col(e.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.softBg(col),
                    borderRadius: AppRadius.bSm,
                    border: Border.all(color: col.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      '${e.key}',
                      style: AppText.caption.copyWith(
                        color: col,
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
                      valueColor: AlwaysStoppedAnimation(col),
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
                'Total skor maksimum: $maxScore',
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

  Color _col(int s) => switch (s) {
    5 => AppColors.success,
    4 => const Color(0xFF4CAF50),
    3 => AppColors.warning,
    2 => const Color(0xFFFF7043),
    _ => AppColors.error,
  };
}

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
                              if (!isBlank && tpl.subtests.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: tpl.subtests
                                      .map(
                                        (s) => Container(
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
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '${tpl.subtests.length} subtes  ·  ${tpl.subtests.fold(0, (s, t) => s + t.estimatedMinutes)} menit',
                                  style: AppText.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: double.infinity,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                    'Template hanya mengisi form — soal Excel/CSV tetap harus diupload secara manual.',
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
