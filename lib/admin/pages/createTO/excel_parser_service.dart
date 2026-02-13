import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'dart:io';

/// Service untuk parsing Excel menjadi data soal
class ExcelParserService {
  /// Parse Excel Soal Objektif (TWK/TIU)
  static Future<List<Map<String, dynamic>>> parseObjectiveExcel(
    File file,
  ) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    final questions = <Map<String, dynamic>>[];

    // Ambil sheet pertama
    final sheet = excel.tables.values.first;

    // Mulai dari baris 15 (index 14) - skip panduan
    for (int row = 14; row < sheet.maxRows; row++) {
      // Skip baris header dan contoh
      if (row == 14 || row == 15 || row == 16) continue;

      // Baca data dari setiap kolom
      final _ = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value
          ?.toString();
      final question = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value
          ?.toString();
      final optionA = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value
          ?.toString();
      final optionB = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value
          ?.toString();
      final optionC = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value
          ?.toString();
      final optionD = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value
          ?.toString();
      final optionE = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value
          ?.toString();
      final correctAnswer = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
          .value
          ?.toString()
          .toUpperCase();
      final explanationShort = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
          .value
          ?.toString();
      final explanationFull = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row))
          .value
          ?.toString();
      final category = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row))
          .value
          ?.toString()
          .toUpperCase();
      final subcategory = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row))
          .value
          ?.toString();
      final difficultyStr = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row))
          .value
          ?.toString();

      // Skip jika baris kosong
      if (question == null || question.isEmpty) continue;

      // Validasi data
      if (optionA == null ||
          optionB == null ||
          optionC == null ||
          optionD == null ||
          optionE == null) {
        throw Exception('Baris $row: Semua opsi (A-E) harus diisi!');
      }

      if (correctAnswer == null ||
          !['A', 'B', 'C', 'D', 'E'].contains(correctAnswer)) {
        throw Exception('Baris $row: Jawaban benar harus A/B/C/D/E!');
      }

      if (category == null || !['TWK', 'TIU', 'TKP'].contains(category)) {
        throw Exception('Baris $row: Kategori harus TWK/TIU/TKP!');
      }

      // Convert jawaban benar dari huruf ke index
      int correctIndex = correctAnswer.codeUnitAt(0) - 'A'.codeUnitAt(0);

      // Parse difficulty
      int difficulty = 50; // default
      try {
        difficulty = int.parse(difficultyStr ?? '50');
        if (difficulty < 1 || difficulty > 100) difficulty = 50;
      } catch (e) {
        difficulty = 50;
      }

      // Buat map question
      questions.add({
        'question': question,
        'type': 'objective',
        'options': [optionA, optionB, optionC, optionD, optionE],
        'correctAnswer': correctIndex,
        'explanationShort': explanationShort ?? '',
        'explanationFull': explanationFull ?? '',
        'category': category,
        'subcategory': subcategory ?? '',
        'tags': [category.toLowerCase(), subcategory?.toLowerCase() ?? ''],
        'difficulty': difficulty,
        'isActive': true,
        'createdAt': Timestamp.now(),
      });
    }

    if (questions.isEmpty) {
      throw Exception(
        'Tidak ada soal yang valid ditemukan! Pastikan data dimulai dari baris 17.',
      );
    }

    return questions;
  }

  /// Parse Excel Soal TKP (Likert)
  static Future<List<Map<String, dynamic>>> parseLikertExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    final questions = <Map<String, dynamic>>[];

    // Ambil sheet pertama
    final sheet = excel.tables.values.first;

    // Mulai dari baris 20 (index 19) - skip panduan
    for (int row = 19; row < sheet.maxRows; row++) {
      // Skip baris header dan contoh
      if (row == 18 || row == 19) continue;

      // Baca data
      final _ = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value
          ?.toString();
      final question = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value
          ?.toString();
      final optionA = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value
          ?.toString();
      final optionB = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value
          ?.toString();
      final optionC = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value
          ?.toString();
      final optionD = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value
          ?.toString();
      final optionE = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value
          ?.toString();
      final scoreAStr = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
          .value
          ?.toString();
      final scoreBStr = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row))
          .value
          ?.toString();
      final scoreCStr = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row))
          .value
          ?.toString();
      final scoreDStr = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row))
          .value
          ?.toString();
      final scoreEStr = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row))
          .value
          ?.toString();
      final explanationShort = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row))
          .value
          ?.toString();
      final explanationFull = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: row))
          .value
          ?.toString();
      final subcategory = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: row))
          .value
          ?.toString();
      final difficultyStr = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: row))
          .value
          ?.toString();

      // Skip jika baris kosong
      if (question == null || question.isEmpty) continue;

      // Validasi opsi
      if (optionA == null ||
          optionB == null ||
          optionC == null ||
          optionD == null ||
          optionE == null) {
        throw Exception('Baris $row: Semua opsi (A-E) harus diisi!');
      }

      // Parse scores
      int scoreA, scoreB, scoreC, scoreD, scoreE;
      try {
        scoreA = int.parse(scoreAStr ?? '1');
        scoreB = int.parse(scoreBStr ?? '1');
        scoreC = int.parse(scoreCStr ?? '1');
        scoreD = int.parse(scoreDStr ?? '1');
        scoreE = int.parse(scoreEStr ?? '1');

        // Validasi skor 1-5
        if (scoreA < 1 ||
            scoreA > 5 ||
            scoreB < 1 ||
            scoreB > 5 ||
            scoreC < 1 ||
            scoreC > 5 ||
            scoreD < 1 ||
            scoreD > 5 ||
            scoreE < 1 ||
            scoreE > 5) {
          throw Exception('Baris $row: Skor harus antara 1-5!');
        }
      } catch (e) {
        throw Exception('Baris $row: Skor harus berupa angka 1-5!');
      }

      // Cari jawaban terbaik (skor tertinggi)
      final scores = [scoreA, scoreB, scoreC, scoreD, scoreE];
      final maxScore = scores.reduce((a, b) => a > b ? a : b);
      final correctIndex = scores.indexOf(maxScore);

      // Parse difficulty
      int difficulty = 50;
      try {
        difficulty = int.parse(difficultyStr ?? '50');
        if (difficulty < 1 || difficulty > 100) difficulty = 50;
      } catch (e) {
        difficulty = 50;
      }

      // Buat map question
      questions.add({
        'question': question,
        'type': 'likert',
        'options': [optionA, optionB, optionC, optionD, optionE],
        'correctAnswer': correctIndex,
        'optionScores': scores,
        'explanationShort': explanationShort ?? '',
        'explanationFull': explanationFull ?? '',
        'category': 'TKP',
        'subcategory': subcategory ?? 'TKP_Umum',
        'tags': ['tkp', subcategory?.toLowerCase() ?? 'umum'],
        'difficulty': difficulty,
        'isActive': true,
        'createdAt': Timestamp.now(),
      });
    }

    if (questions.isEmpty) {
      throw Exception(
        'Tidak ada soal yang valid ditemukan! Pastikan data dimulai dari baris 21.',
      );
    }

    return questions;
  }
}
