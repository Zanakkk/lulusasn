// ignore_for_file: avoid_print, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lulusasn/core/constants/colors.dart';
import 'package:lulusasn/core/constants/text_styles.dart';
import 'package:lulusasn/core/constants/spacing.dart';
import 'package:lulusasn/core/widgets/brutalist_button.dart';
import '../../../core/services/firebase_service.dart';

class SeedData {
  static final _firestore = FirebaseService.instance.firestore;

  /// Seed semua data dengan struktur OPTIMAL
  static Future<void> seedAll() async {
    print('🌱 Starting OPTIMIZED data seeding...');

    try {
      await seedExamPackagesWithQuestions();
      print('✅ Seeding completed successfully!');
    } catch (e) {
      print('❌ Seeding failed: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // EXAM PACKAGES WITH EMBEDDED QUESTIONS
  // ==========================================================================

  static Future<void> seedExamPackagesWithQuestions() async {
    print('📦 Seeding exam packages with embedded questions...');

    final packages = [
      // TWK - Easy (10 questions)
      {
        'title': 'TWK Dasar - Pancasila',
        'description': 'Latihan soal Pancasila sebagai dasar negara',
        'category': 'TWK',
        'difficulty': 'easy',
        'questionCount': 10,
        'estimatedMinutes': 15,
        'energyCost': 1,
        'isPremium': false,
        'isActive': true,
        'order': 1,
        'questions': _getTWKEasyQuestions(),
        'createdAt': Timestamp.now(), // ✅ Atau pakai ini
      },

      // TWK - Medium (15 questions)
      {
        'title': 'TWK Menengah - UUD 1945',
        'description': 'Paham konstitusi dan amandemen UUD 1945',
        'category': 'TWK',
        'difficulty': 'medium',
        'questionCount': 15,
        'estimatedMinutes': 20,
        'energyCost': 1,
        'isPremium': false,
        'isActive': true,
        'order': 2,
        'questions': _getTWKMediumQuestions(),
        'createdAt': Timestamp.now(),
      },

      // TWK - Hard (20 questions)
      {
        'title': 'TWK Lanjut - Sistem Pemerintahan',
        'description': 'Menguji pemahaman sistem pemerintahan Indonesia',
        'category': 'TWK',
        'difficulty': 'hard',
        'questionCount': 20,
        'estimatedMinutes': 30,
        'energyCost': 1,
        'isPremium': true,
        'isActive': true,
        'order': 3,
        'questions': _getTWKHardQuestions(),
        'createdAt': Timestamp.now(),
      },

      // TIU - Easy (10 questions)
      {
        'title': 'TIU Dasar - Logika Sederhana',
        'description': 'Latihan logika dan penalaran dasar',
        'category': 'TIU',
        'difficulty': 'easy',
        'questionCount': 10,
        'estimatedMinutes': 15,
        'energyCost': 1,
        'isPremium': false,
        'isActive': true,
        'order': 4,
        'questions': _getTIUEasyQuestions(),
        'createdAt': Timestamp.now(),
      },

      // TIU - Medium (15 questions)
      {
        'title': 'TIU Menengah - Numerik',
        'description': 'Soal deret angka dan operasi hitung',
        'category': 'TIU',
        'difficulty': 'medium',
        'questionCount': 15,
        'estimatedMinutes': 20,
        'energyCost': 1,
        'isPremium': false,
        'isActive': true,
        'order': 5,
        'questions': _getTIUMediumQuestions(),
        'createdAt': Timestamp.now(),
      },

      // TIU - Hard (20 questions)
      {
        'title': 'TIU Lanjut - Analitik',
        'description': 'Soal analisis data dan problem solving',
        'category': 'TIU',
        'difficulty': 'hard',
        'questionCount': 20,
        'estimatedMinutes': 30,
        'energyCost': 1,
        'isPremium': true,
        'isActive': true,
        'order': 6,
        'questions': _getTIUHardQuestions(),
        'createdAt': Timestamp.now(),
      },

      // TKP - Easy (10 questions)
      {
        'title': 'TKP Dasar - Integritas',
        'description': 'Menilai integritas dan kejujuran',
        'category': 'TKP',
        'difficulty': 'easy',
        'questionCount': 10,
        'estimatedMinutes': 15,
        'energyCost': 1,
        'isPremium': false,
        'isActive': true,
        'order': 7,
        'questions': _getTKPEasyQuestions(),
        'createdAt': Timestamp.now(),
      },

      // TKP - Medium (15 questions)
      {
        'title': 'TKP Menengah - Kerja Sama',
        'description': 'Menguji kemampuan bekerja dalam tim',
        'category': 'TKP',
        'difficulty': 'medium',
        'questionCount': 15,
        'estimatedMinutes': 20,
        'energyCost': 1,
        'isPremium': false,
        'isActive': true,
        'order': 8,
        'questions': _getTKPMediumQuestions(),
        'createdAt': Timestamp.now(),
      },

      // TKP - Hard (20 questions)
      {
        'title': 'TKP Lanjut - Pelayanan Publik',
        'description': 'Orientasi pelayanan masyarakat',
        'category': 'TKP',
        'difficulty': 'hard',
        'questionCount': 20,
        'estimatedMinutes': 30,
        'energyCost': 1,
        'isPremium': true,
        'isActive': true,
        'order': 9,
        'questions': _getTKPHardQuestions(),
        'createdAt': Timestamp.now(),
      },
    ];

    final batch = _firestore.batch();
    final collection = _firestore.collection('exam_packages');

    for (var package in packages) {
      final docRef = collection.doc();
      batch.set(docRef, package);
    }

    await batch.commit();
    print('✅ ${packages.length} exam packages seeded with embedded questions');
  }

  // ==========================================================================
  // QUESTION GENERATORS (COMPACT FORMAT)
  // ==========================================================================

  // ==========================================================================
  // QUESTION GENERATORS - SESUAI QuestionModel
  // ==========================================================================

  static List<Map<String, dynamic>> _getTWKEasyQuestions() {
    return [
      {
        'question': 'Sila pertama Pancasila adalah...',
        'type': 'objective',
        'options': [
          'Kemanusiaan yang adil dan beradab',
          'Ketuhanan Yang Maha Esa',
          'Persatuan Indonesia',
          'Kerakyatan yang dipimpin oleh hikmat kebijaksanaan',
          'Keadilan sosial bagi seluruh rakyat Indonesia',
        ],
        'correctAnswer': 1,
        'explanationShort': 'Sila pertama adalah "Ketuhanan Yang Maha Esa".',
        'explanationFull':
            'Sila pertama adalah "Ketuhanan Yang Maha Esa" yang mengandung makna bahwa negara Indonesia berdasarkan kepercayaan terhadap Tuhan Yang Maha Esa.',
        'category': 'TWK',
        'subcategory': 'TWK_Pancasila',
        'tags': ['pancasila', 'dasar-negara'],
        'difficulty': 20,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Lambang sila kedua Pancasila adalah...',
        'type': 'objective',
        'options': [
          'Bintang',
          'Rantai',
          'Pohon Beringin',
          'Kepala Banteng',
          'Padi dan Kapas',
        ],
        'correctAnswer': 1,
        'explanationShort': 'Rantai melambangkan sila kedua.',
        'explanationFull':
            'Rantai melambangkan sila kedua "Kemanusiaan yang adil dan beradab", menggambarkan keterkaitan antara manusia.',
        'category': 'TWK',
        'subcategory': 'TWK_Pancasila',
        'tags': ['pancasila', 'lambang-negara'],
        'difficulty': 25,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Pancasila sebagai dasar negara tercantum dalam...',
        'type': 'objective',
        'options': [
          'Pembukaan UUD 1945 alinea keempat',
          'Pasal 1 UUD 1945',
          'Pasal 33 UUD 1945',
          'Batang Tubuh UUD 1945',
          'Penjelasan UUD 1945',
        ],
        'correctAnswer': 0,
        'explanationShort':
            'Tercantum dalam Pembukaan UUD 1945 alinea keempat.',
        'explanationFull':
            'Pancasila sebagai dasar negara secara resmi tercantum dalam Pembukaan UUD 1945 alinea keempat.',
        'category': 'TWK',
        'subcategory': 'TWK_Pancasila',
        'tags': ['pancasila', 'uud-1945'],
        'difficulty': 30,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Nilai-nilai Pancasila bersumber dari...',
        'type': 'objective',
        'options': [
          'Budaya Barat',
          'Kepribadian dan pandangan hidup bangsa Indonesia',
          'Ajaran agama tertentu',
          'Ideologi negara lain',
          'Undang-undang',
        ],
        'correctAnswer': 1,
        'explanationShort': 'Bersumber dari kepribadian bangsa Indonesia.',
        'explanationFull':
            'Pancasila digali dari nilai-nilai luhur yang sudah ada dalam kepribadian dan pandangan hidup bangsa Indonesia sejak dahulu.',
        'category': 'TWK',
        'subcategory': 'TWK_Pancasila',
        'tags': ['pancasila', 'nilai-luhur'],
        'difficulty': 28,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question':
            'Yang termasuk implementasi sila ketiga dalam kehidupan berbangsa adalah...',
        'type': 'objective',
        'options': [
          'Menghormati perbedaan agama',
          'Gotong royong membangun negara',
          'Mengutamakan kepentingan umum',
          'Semua jawaban benar',
          'Tidak ada jawaban yang benar',
        ],
        'correctAnswer': 1,
        'explanationShort': 'Gotong royong membangun negara.',
        'explanationFull':
            'Sila ketiga "Persatuan Indonesia" diimplementasikan melalui gotong royong dan semangat kebersamaan dalam membangun negara.',
        'category': 'TWK',
        'subcategory': 'TWK_Pancasila',
        'tags': ['pancasila', 'persatuan'],
        'difficulty': 35,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Lambang Garuda Pancasila diresmikan pada tahun...',
        'type': 'objective',
        'options': ['1945', '1949', '1950', '1951', '1952'],
        'correctAnswer': 2,
        'explanationShort': 'Diresmikan tahun 1950.',
        'explanationFull':
            'Garuda Pancasila diresmikan pada tanggal 11 Februari 1950.',
        'category': 'TWK',
        'subcategory': 'TWK_Pancasila',
        'tags': ['pancasila', 'garuda', 'sejarah'],
        'difficulty': 32,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Jumlah bulu pada ekor Garuda Pancasila adalah...',
        'type': 'objective',
        'options': ['17', '19', '45', '8', '5'],
        'correctAnswer': 1,
        'explanationShort': 'Bulu ekor berjumlah 19.',
        'explanationFull':
            'Bulu ekor Garuda berjumlah 19, melambangkan tanggal 19 pada proklamasi kemerdekaan.',
        'category': 'TWK',
        'subcategory': 'TWK_Pancasila',
        'tags': ['pancasila', 'garuda', 'lambang'],
        'difficulty': 38,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Pancasila pertama kali diperkenalkan oleh...',
        'type': 'objective',
        'options': [
          'Soekarno',
          'Mohammad Hatta',
          'Soepomo',
          'Muhammad Yamin',
          'Ahmad Soebardjo',
        ],
        'correctAnswer': 0,
        'explanationShort': 'Diperkenalkan oleh Ir. Soekarno.',
        'explanationFull':
            'Ir. Soekarno pertama kali memperkenalkan Pancasila dalam sidang BPUPKI tanggal 1 Juni 1945.',
        'category': 'TWK',
        'subcategory': 'TWK_Pancasila',
        'tags': ['pancasila', 'sejarah', 'soekarno'],
        'difficulty': 22,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Hari lahir Pancasila diperingati setiap tanggal...',
        'type': 'objective',
        'options': [
          '17 Agustus',
          '18 Agustus',
          '1 Juni',
          '22 Juni',
          '1 Oktober',
        ],
        'correctAnswer': 2,
        'explanationShort': 'Diperingati setiap 1 Juni.',
        'explanationFull':
            'Hari lahir Pancasila diperingati setiap 1 Juni, sesuai pidato Soekarno di BPUPKI.',
        'category': 'TWK',
        'subcategory': 'TWK_Pancasila',
        'tags': ['pancasila', 'hari-bersejarah'],
        'difficulty': 18,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Makna sila kelima Pancasila adalah...',
        'type': 'objective',
        'options': [
          'Kesetaraan di mata hukum',
          'Kesejahteraan yang merata bagi seluruh rakyat',
          'Persatuan bangsa',
          'Demokrasi',
          'Ketuhanan',
        ],
        'correctAnswer': 1,
        'explanationShort': 'Kesejahteraan yang merata.',
        'explanationFull':
            'Sila kelima "Keadilan sosial bagi seluruh rakyat Indonesia" bermakna kesejahteraan yang merata.',
        'category': 'TWK',
        'subcategory': 'TWK_Pancasila',
        'tags': ['pancasila', 'keadilan-sosial'],
        'difficulty': 26,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
    ];
  }

  static List<Map<String, dynamic>> _getTWKMediumQuestions() {
    return [
      {
        'question': 'UUD 1945 disahkan pada tanggal...',
        'type': 'objective',
        'options': [
          '17 Agustus 1945',
          '18 Agustus 1945',
          '19 Agustus 1945',
          '20 Agustus 1945',
          '1 Juni 1945',
        ],
        'correctAnswer': 1,
        'explanationShort': 'Disahkan 18 Agustus 1945.',
        'explanationFull':
            'UUD 1945 disahkan oleh PPKI pada tanggal 18 Agustus 1945, sehari setelah proklamasi kemerdekaan.',
        'category': 'TWK',
        'subcategory': 'TWK_UUD1945',
        'tags': ['uud-1945', 'sejarah'],
        'difficulty': 40,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question':
            'Kedaulatan berada di tangan rakyat tercantum dalam pasal...',
        'type': 'objective',
        'options': [
          'Pasal 1 ayat 1',
          'Pasal 1 ayat 2',
          'Pasal 2 ayat 1',
          'Pasal 3 ayat 1',
          'Pasal 4 ayat 1',
        ],
        'correctAnswer': 1,
        'explanationShort': 'Tercantum dalam Pasal 1 ayat 2.',
        'explanationFull':
            'Pasal 1 ayat 2 UUD 1945 menyatakan "Kedaulatan berada di tangan rakyat dan dilaksanakan menurut Undang-Undang Dasar".',
        'category': 'TWK',
        'subcategory': 'TWK_UUD1945',
        'tags': ['uud-1945', 'kedaulatan'],
        'difficulty': 45,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Amandemen UUD 1945 dilakukan sebanyak...',
        'type': 'objective',
        'options': ['2 kali', '3 kali', '4 kali', '5 kali', '6 kali'],
        'correctAnswer': 2,
        'explanationShort': 'Diamandemen 4 kali.',
        'explanationFull':
            'UUD 1945 telah diamandemen sebanyak 4 kali: tahun 1999, 2000, 2001, dan 2002.',
        'category': 'TWK',
        'subcategory': 'TWK_UUD1945',
        'tags': ['uud-1945', 'amandemen'],
        'difficulty': 48,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question':
            'Lembaga negara yang berwenang mengubah dan menetapkan UUD adalah...',
        'type': 'objective',
        'options': ['DPR', 'MPR', 'Presiden', 'MA', 'MK'],
        'correctAnswer': 1,
        'explanationShort': 'MPR berwenang mengubah UUD.',
        'explanationFull':
            'Sesuai Pasal 3 ayat 1 UUD 1945, MPR berwenang mengubah dan menetapkan Undang-Undang Dasar.',
        'category': 'TWK',
        'subcategory': 'TWK_UUD1945',
        'tags': ['uud-1945', 'mpr', 'lembaga-negara'],
        'difficulty': 42,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Hak asasi manusia diatur dalam UUD 1945 pada pasal...',
        'type': 'objective',
        'options': [
          'Pasal 27-34',
          'Pasal 28A-28J',
          'Pasal 1-7',
          'Pasal 18-18B',
          'Pasal 23-24',
        ],
        'correctAnswer': 1,
        'explanationShort': 'Diatur dalam Pasal 28A-28J.',
        'explanationFull':
            'Hak Asasi Manusia diatur secara lengkap dalam Pasal 28A sampai dengan 28J UUD 1945 hasil amandemen kedua tahun 2000.',
        'category': 'TWK',
        'subcategory': 'TWK_UUD1945',
        'tags': ['uud-1945', 'ham'],
        'difficulty': 52,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question':
            'Presiden dan Wakil Presiden dipilih dalam satu pasangan secara...',
        'type': 'objective',
        'options': [
          'Langsung oleh rakyat',
          'Oleh MPR',
          'Oleh DPR',
          'Oleh DPD',
          'Oleh MA',
        ],
        'correctAnswer': 0,
        'explanationShort': 'Dipilih langsung oleh rakyat.',
        'explanationFull':
            'Sesuai Pasal 6A ayat 1 UUD 1945, Presiden dan Wakil Presiden dipilih dalam satu pasangan secara langsung oleh rakyat.',
        'category': 'TWK',
        'subcategory': 'TWK_UUD1945',
        'tags': ['uud-1945', 'pemilu', 'presiden'],
        'difficulty': 38,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Masa jabatan Presiden dan Wakil Presiden adalah...',
        'type': 'objective',
        'options': ['3 tahun', '4 tahun', '5 tahun', '6 tahun', '7 tahun'],
        'correctAnswer': 2,
        'explanationShort': 'Masa jabatan 5 tahun.',
        'explanationFull':
            'Berdasarkan Pasal 7 UUD 1945, Presiden dan Wakil Presiden memegang jabatan selama 5 tahun.',
        'category': 'TWK',
        'subcategory': 'TWK_UUD1945',
        'tags': ['uud-1945', 'presiden'],
        'difficulty': 35,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'DPR memiliki fungsi legislasi, anggaran, dan...',
        'type': 'objective',
        'options': [
          'Yudikatif',
          'Eksekutif',
          'Pengawasan',
          'Konsultatif',
          'Administratif',
        ],
        'correctAnswer': 2,
        'explanationShort': 'Fungsi ketiga adalah pengawasan.',
        'explanationFull':
            'Sesuai Pasal 20A ayat 1, DPR memiliki tiga fungsi: legislasi, anggaran, dan pengawasan.',
        'category': 'TWK',
        'subcategory': 'TWK_UUD1945',
        'tags': ['uud-1945', 'dpr', 'lembaga-negara'],
        'difficulty': 44,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Kekuasaan kehakiman dilakukan oleh...',
        'type': 'objective',
        'options': ['MA saja', 'MK saja', 'MA dan MK', 'Presiden', 'DPR'],
        'correctAnswer': 2,
        'explanationShort': 'Dilakukan oleh MA dan MK.',
        'explanationFull':
            'Pasal 24 ayat 2 UUD 1945 menyatakan kekuasaan kehakiman dilakukan oleh sebuah Mahkamah Agung dan Mahkamah Konstitusi.',
        'category': 'TWK',
        'subcategory': 'TWK_UUD1945',
        'tags': ['uud-1945', 'yudikatif', 'ma', 'mk'],
        'difficulty': 50,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Bentuk negara Indonesia menurut UUD 1945 adalah...',
        'type': 'objective',
        'options': ['Serikat', 'Kesatuan', 'Federal', 'Konfederasi', 'Monarki'],
        'correctAnswer': 1,
        'explanationShort': 'Bentuk negara kesatuan.',
        'explanationFull':
            'Pasal 1 ayat 1 UUD 1945 menyatakan "Negara Indonesia ialah Negara Kesatuan yang berbentuk Republik".',
        'category': 'TWK',
        'subcategory': 'TWK_UUD1945',
        'tags': ['uud-1945', 'bentuk-negara'],
        'difficulty': 32,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Perubahan pertama UUD 1945 dilakukan pada tahun...',
        'type': 'objective',
        'options': ['1998', '1999', '2000', '2001', '2002'],
        'correctAnswer': 1,
        'explanationShort': 'Amandemen pertama tahun 1999.',
        'explanationFull':
            'Amandemen pertama UUD 1945 dilakukan pada tahun 1999 dalam Sidang Umum MPR.',
        'category': 'TWK',
        'subcategory': 'TWK_UUD1945',
        'tags': ['uud-1945', 'amandemen', 'reformasi'],
        'difficulty': 46,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question':
            'Yang bukan termasuk lembaga tinggi negara menurut UUD 1945 adalah...',
        'type': 'objective',
        'options': ['MPR', 'DPR', 'Presiden', 'BPK', 'KPK'],
        'correctAnswer': 4,
        'explanationShort': 'KPK bukan lembaga tinggi negara dalam UUD.',
        'explanationFull':
            'KPK adalah lembaga negara independen tapi bukan lembaga tinggi negara yang disebutkan dalam UUD 1945.',
        'category': 'TWK',
        'subcategory': 'TWK_UUD1945',
        'tags': ['uud-1945', 'lembaga-negara'],
        'difficulty': 55,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Pembukaan UUD 1945 terdiri dari... alinea',
        'type': 'objective',
        'options': ['2', '3', '4', '5', '6'],
        'correctAnswer': 2,
        'explanationShort': 'Terdiri dari 4 alinea.',
        'explanationFull':
            'Pembukaan UUD 1945 terdiri dari 4 alinea yang memuat cita-cita dan tujuan negara.',
        'category': 'TWK',
        'subcategory': 'TWK_UUD1945',
        'tags': ['uud-1945', 'pembukaan'],
        'difficulty': 36,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'BPK bertugas untuk...',
        'type': 'objective',
        'options': [
          'Membuat undang-undang',
          'Memeriksa pengelolaan dan tanggung jawab keuangan negara',
          'Memilih presiden',
          'Mengadili perkara',
          'Memberi grasi',
        ],
        'correctAnswer': 1,
        'explanationShort': 'BPK memeriksa keuangan negara.',
        'explanationFull':
            'Sesuai Pasal 23E UUD 1945, BPK bertugas memeriksa pengelolaan dan tanggung jawab keuangan negara.',
        'category': 'TWK',
        'subcategory': 'TWK_UUD1945',
        'tags': ['uud-1945', 'bpk', 'keuangan-negara'],
        'difficulty': 48,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Mahkamah Konstitusi berwenang mengadili pada tingkat...',
        'type': 'objective',
        'options': [
          'Pertama dan terakhir',
          'Pertama saja',
          'Banding',
          'Kasasi',
          'Peninjauan kembali',
        ],
        'correctAnswer': 0,
        'explanationShort': 'Mengadili tingkat pertama dan terakhir.',
        'explanationFull':
            'Pasal 24C ayat 1 menyatakan MK berwenang mengadili pada tingkat pertama dan terakhir yang putusannya bersifat final.',
        'category': 'TWK',
        'subcategory': 'TWK_UUD1945',
        'tags': ['uud-1945', 'mk', 'yudikatif'],
        'difficulty': 53,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
    ];
  }

  static List<Map<String, dynamic>> _getTWKHardQuestions() {
    return List.generate(
      20,
      (i) => {
        'question':
            'Soal TWK Lanjutan ${i + 1}: Sistem pemerintahan Indonesia menganut prinsip...',
        'type': 'objective',
        'options': [
          'Pilihan A',
          'Pilihan B',
          'Pilihan C',
          'Pilihan D',
          'Pilihan E',
        ],
        'correctAnswer': i % 5,
        'explanationShort': 'Penjelasan singkat soal ${i + 1}.',
        'explanationFull':
            'Penjelasan lengkap untuk soal TWK hard nomor ${i + 1} tentang sistem pemerintahan.',
        'category': 'TWK',
        'subcategory': 'TWK_Sistem',
        'tags': ['sistem-pemerintahan', 'advanced'],
        'difficulty': 60 + (i % 20),
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
    );
  }

  static List<Map<String, dynamic>> _getTIUEasyQuestions() {
    return [
      {
        'question': 'Lengkapi pola: A, C, F, J, ...',
        'type': 'objective',
        'options': ['M', 'N', 'O', 'P', 'Q'],
        'correctAnswer': 2,
        'explanationShort': 'Polanya +2, +3, +4, +5.',
        'explanationFull': 'Pola: +2, +3, +4, +5. A+2=C, C+3=F, F+4=J, J+5=O.',
        'category': 'TIU',
        'subcategory': 'TIU_Logika',
        'tags': ['pola-huruf', 'logika'],
        'difficulty': 30,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Analog: BUKU : PENULIS = LUKISAN : ...',
        'type': 'objective',
        'options': ['Kanvas', 'Pelukis', 'Cat', 'Museum', 'Galeri'],
        'correctAnswer': 1,
        'explanationShort': 'Hubungan karya dengan pembuatnya.',
        'explanationFull':
            'Hubungan: hasil karya dan pembuatnya. Buku dibuat oleh penulis, lukisan dibuat oleh pelukis.',
        'category': 'TIU',
        'subcategory': 'TIU_Logika',
        'tags': ['analogi', 'logika'],
        'difficulty': 28,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Lengkapi deret: 2, 4, 8, 16, ...',
        'type': 'objective',
        'options': ['24', '28', '30', '32', '36'],
        'correctAnswer': 3,
        'explanationShort': 'Setiap angka dikali 2.',
        'explanationFull':
            'Pola: setiap angka dikalikan 2. 2×2=4, 4×2=8, 8×2=16, 16×2=32.',
        'category': 'TIU',
        'subcategory': 'TIU_Numerik',
        'tags': ['deret-angka', 'numerik'],
        'difficulty': 25,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': '25% dari 80 adalah...',
        'type': 'objective',
        'options': ['15', '18', '20', '22', '25'],
        'correctAnswer': 2,
        'explanationShort': '25% × 80 = 20.',
        'explanationFull': '25% × 80 = 0.25 × 80 = 20.',
        'category': 'TIU',
        'subcategory': 'TIU_Numerik',
        'tags': ['persentase', 'aritmatika'],
        'difficulty': 22,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Rata-rata dari 8, 12, 15, 20, dan 25 adalah...',
        'type': 'objective',
        'options': ['14', '15', '16', '17', '18'],
        'correctAnswer': 2,
        'explanationShort': 'Rata-rata = 80÷5 = 16.',
        'explanationFull':
            'Jumlah semua angka: 8+12+15+20+25 = 80. Rata-rata: 80÷5 = 16.',
        'category': 'TIU',
        'subcategory': 'TIU_Numerik',
        'tags': ['rata-rata', 'statistik'],
        'difficulty': 26,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question':
            'Pilih kata yang berbeda: Apel, Jeruk, Tomat, Mangga, Pisang',
        'type': 'objective',
        'options': ['Apel', 'Jeruk', 'Tomat', 'Mangga', 'Pisang'],
        'correctAnswer': 2,
        'explanationShort': 'Tomat adalah sayuran.',
        'explanationFull':
            'Apel, jeruk, mangga, dan pisang adalah buah-buahan. Tomat dikategorikan sebagai sayuran.',
        'category': 'TIU',
        'subcategory': 'TIU_Logika',
        'tags': ['klasifikasi', 'logika'],
        'difficulty': 24,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Sinonim kata "AKURAT" adalah...',
        'type': 'objective',
        'options': ['Salah', 'Tepat', 'Cepat', 'Lambat', 'Besar'],
        'correctAnswer': 1,
        'explanationShort': 'Sinonim akurat adalah tepat.',
        'explanationFull': 'Akurat berarti tepat, cermat, atau teliti.',
        'category': 'TIU',
        'subcategory': 'TIU_Verbal',
        'tags': ['sinonim', 'verbal'],
        'difficulty': 20,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Antonim kata "PROGRESIF" adalah...',
        'type': 'objective',
        'options': ['Maju', 'Mundur', 'Cepat', 'Lambat', 'Statis'],
        'correctAnswer': 4,
        'explanationShort': 'Antonim progresif adalah statis.',
        'explanationFull':
            'Progresif berarti berkembang/maju, antonimnya adalah statis/tetap.',
        'category': 'TIU',
        'subcategory': 'TIU_Verbal',
        'tags': ['antonim', 'verbal'],
        'difficulty': 32,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': '3 + 5 × 2 = ...',
        'type': 'objective',
        'options': ['10', '11', '13', '16', '18'],
        'correctAnswer': 2,
        'explanationShort': 'Perkalian dulu: 5×2=10, lalu 3+10=13.',
        'explanationFull':
            'Perkalian lebih dulu: 5 × 2 = 10, kemudian 3 + 10 = 13.',
        'category': 'TIU',
        'subcategory': 'TIU_Numerik',
        'tags': ['operasi-hitung', 'aritmatika'],
        'difficulty': 28,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Jika A > B dan B > C, maka...',
        'type': 'objective',
        'options': [
          'A = C',
          'A < C',
          'A > C',
          'A ≤ C',
          'Tidak dapat disimpulkan',
        ],
        'correctAnswer': 2,
        'explanationShort': 'A pasti lebih besar dari C.',
        'explanationFull':
            'Jika A lebih besar dari B dan B lebih besar dari C, maka A pasti lebih besar dari C.',
        'category': 'TIU',
        'subcategory': 'TIU_Logika',
        'tags': ['logika', 'perbandingan'],
        'difficulty': 26,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
    ];
  }

  static List<Map<String, dynamic>> _getTIUMediumQuestions() {
    return List.generate(
      15,
      (i) => {
        'question':
            'Soal TIU Menengah ${i + 1}: Deret angka 5, 10, 20, 40, ...',
        'type': 'objective',
        'options': ['60', '70', '80', '90', '100'],
        'correctAnswer': i % 5,
        'explanationShort': 'Penjelasan singkat soal ${i + 1}.',
        'explanationFull':
            'Penjelasan lengkap untuk soal TIU medium nomor ${i + 1} tentang analitik.',
        'category': 'TIU',
        'subcategory': 'TIU_Analitik',
        'tags': ['numerik', 'medium'],
        'difficulty': 40 + (i % 15),
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
    );
  }

  static List<Map<String, dynamic>> _getTIUHardQuestions() {
    return List.generate(
      20,
      (i) => {
        'question': 'Soal TIU Lanjutan ${i + 1}: Analisis data kompleks...',
        'type': 'objective',
        'options': [
          'Pilihan A',
          'Pilihan B',
          'Pilihan C',
          'Pilihan D',
          'Pilihan E',
        ],
        'correctAnswer': i % 5,
        'explanationShort': 'Penjelasan singkat soal ${i + 1}.',
        'explanationFull':
            'Penjelasan lengkap untuk soal TIU hard nomor ${i + 1} tentang problem solving.',
        'category': 'TIU',
        'subcategory': 'TIU_Analitik',
        'tags': ['analitik', 'advanced'],
        'difficulty': 60 + (i % 20),
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
    );
  }

  static List<Map<String, dynamic>> _getTKPEasyQuestions() {
    return [
      {
        'question':
            'Saya menemukan dompet berisi uang Rp 500.000 di kantor. Saya akan...',
        'type': 'likert',
        'options': [
          'Mengambil uang dan membuang dompetnya',
          'Mengambil sebagian uang saja',
          'Menyimpannya untuk diri sendiri',
          'Menanyakan kepada rekan kerja dan mencari pemiliknya',
          'Langsung menyerahkan ke keamanan/HRD',
        ],
        'correctAnswer': 4,
        'optionScores': [1, 2, 3, 4, 5], // 🆕 TAMBAH INI
        'explanationShort': 'Langsung serahkan ke pihak berwenang.',
        'explanationFull':
            'Integritas ditunjukkan dengan segera menyerahkan barang temuan kepada pihak yang berwenang tanpa mengambil apapun.',
        'category': 'TKP',
        'subcategory': 'TKP_Integritas',
        'tags': ['integritas', 'kejujuran'],
        'difficulty': 25,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Dalam tim kerja, saya lebih suka...',
        'type': 'likert',
        'options': [
          'Bekerja sendiri tanpa campur tangan orang lain',
          'Mengerjakan bagian saya saja',
          'Berkontribusi sesuai kemampuan dalam tim',
          'Membantu rekan yang kesulitan',
          'Memimpin tim dan mengkoordinasi semua orang',
        ],
        'correctAnswer': 4, // Index opsi terbaik (skor tertinggi)
        'optionScores': [1, 2, 3, 4, 5], // 🆕 TAMBAH INI
        'explanationShort': 'Memimpin dan koordinasi menunjukkan leadership.',
        'explanationFull':
            'Kerja sama terbaik ditunjukkan dengan kemampuan memimpin dan mengkoordinasi tim sambil membantu semua anggota.',
        'category': 'TKP',
        'subcategory': 'TKP_KerjaSama',
        'tags': ['kerja-sama', 'teamwork'],
        'difficulty': 28,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question':
            'Saya diminta lembur saat ada rencana keluarga. Saya akan...',
        'type': 'likert',
        'options': [
          'Menolak karena sudah ada janji',
          'Minta izin untuk tidak lembur',
          'Mencoba mengatur ulang jadwal keluarga',
          'Lembur dan menjelaskan situasi kepada keluarga',
          'Lembur tanpa berpikir panjang', // Ini sebenarnya kurang tepat
        ],
        'correctAnswer': 3,
        'optionScores': [
          1,
          2,
          3,
          5,
          4,
        ], // 🆕 Skor disesuaikan (opsi 3 = skor tertinggi)
        'explanationShort':
            'Prioritaskan tanggung jawab dengan komunikasi baik.',
        'explanationFull':
            'Komitmen kerja tinggi ditunjukkan dengan lembur sambil menjelaskan situasi kepada keluarga, menunjukkan keseimbangan profesional dan personal.',
        'category': 'TKP',
        'subcategory': 'TKP_Komitmen',
        'tags': ['komitmen', 'tanggung-jawab'],
        'difficulty': 32,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Jika ada masalah di kantor, saya cenderung...',
        'type': 'likert',
        'options': [
          'Menunggu atasan menyelesaikannya',
          'Membicarakan dengan rekan kerja',
          'Mencari solusi sendiri',
          'Mengusulkan solusi kepada atasan',
          'Proaktif mencari solusi dan berdiskusi dengan tim',
        ],
        'correctAnswer': 4,
        'optionScores': [1, 2, 3, 4, 5], // 🆕 TAMBAH INI
        'explanationShort': 'Proaktif mencari solusi bersama tim.',
        'explanationFull':
            'Inisiatif terbaik adalah proaktif mencari solusi sambil melibatkan tim untuk mendapat masukan.',
        'category': 'TKP',
        'subcategory': 'TKP_Inisiatif',
        'tags': ['inisiatif', 'problem-solving'],
        'difficulty': 30,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Ketika mendapat tugas baru yang sulit, saya akan...',
        'type': 'likert',
        'options': [
          'Menolak karena tidak yakin bisa',
          'Menerima dengan ragu-ragu',
          'Menerima dan mencoba semaksimal mungkin',
          'Menerima dan meminta bimbingan',
          'Antusias menerima sebagai kesempatan belajar',
        ],
        'correctAnswer': 4,
        'optionScores': [1, 2, 3, 4, 5], // 🆕 TAMBAH INI
        'explanationShort': 'Antusias sebagai kesempatan belajar.',
        'explanationFull':
            'Sikap positif terhadap tantangan menunjukkan motivasi tinggi untuk berkembang.',
        'category': 'TKP',
        'subcategory': 'TKP_Motivasi',
        'tags': ['motivasi', 'learning'],
        'difficulty': 26,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Saya lebih suka bekerja pada situasi yang...',
        'type': 'likert',
        'options': [
          'Rutin dan pasti',
          'Agak bervariasi',
          'Kadang menantang',
          'Sering berubah',
          'Selalu dinamis dan menantang',
        ],
        'correctAnswer': 4,
        'optionScores': [1, 2, 3, 4, 5], // 🆕 TAMBAH INI
        'explanationShort': 'Suka situasi dinamis dan menantang.',
        'explanationFull':
            'Adaptabilitas tinggi ditunjukkan dengan menyukai lingkungan dinamis dan penuh tantangan.',
        'category': 'TKP',
        'subcategory': 'TKP_Adaptasi',
        'tags': ['adaptasi', 'fleksibilitas'],
        'difficulty': 34,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question':
            'Ketika rekan kerja mengkritik hasil kerja saya, saya akan...',
        'type': 'likert',
        'options': [
          'Tersinggung dan membela diri',
          'Diam saja',
          'Mendengarkan tapi tidak setuju',
          'Mendengarkan dan mempertimbangkan',
          'Berterima kasih dan memperbaiki',
        ],
        'correctAnswer': 4,
        'optionScores': [1, 2, 3, 4, 5], // 🆕 TAMBAH INI
        'explanationShort': 'Berterima kasih dan memperbaiki.',
        'explanationFull':
            'Sikap terbuka terhadap kritik menunjukkan kematangan dan keinginan untuk berkembang.',
        'category': 'TKP',
        'subcategory': 'TKP_Sikap',
        'tags': ['sikap', 'feedback'],
        'difficulty': 29,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Dalam mengambil keputusan penting, saya cenderung...',
        'type': 'likert',
        'options': [
          'Mengikuti kata hati',
          'Meminta pendapat orang lain',
          'Menganalisis pro dan kontra',
          'Mempertimbangkan berbagai aspek',
          'Menganalisis data dan berkonsultasi dengan ahli',
        ],
        'correctAnswer': 4,
        'optionScores': [1, 2, 3, 4, 5], // 🆕 TAMBAH INI
        'explanationShort': 'Analisis data dan konsultasi ahli.',
        'explanationFull':
            'Pengambilan keputusan terbaik melibatkan analisis data dan konsultasi dengan pihak yang berkompeten.',
        'category': 'TKP',
        'subcategory': 'TKP_Analitik',
        'tags': ['analitik', 'decision-making'],
        'difficulty': 36,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Prioritas utama saya dalam bekerja adalah...',
        'type': 'likert',
        'options': [
          'Menyelesaikan tugas tepat waktu',
          'Hasil yang berkualitas',
          'Kepuasan atasan',
          'Kualitas dan ketepatan waktu',
          'Memberikan hasil terbaik yang berdampak positif',
        ],
        'correctAnswer': 4,
        'optionScores': [
          3,
          3,
          2,
          4,
          5,
        ], // 🆕 Skor disesuaikan (beberapa opsi sama nilainya)
        'explanationShort': 'Hasil terbaik yang berdampak positif.',
        'explanationFull':
            'Orientasi hasil terbaik adalah menghasilkan kualitas tinggi yang memberikan dampak positif.',
        'category': 'TKP',
        'subcategory': 'TKP_Orientasi',
        'tags': ['orientasi-hasil', 'kualitas'],
        'difficulty': 27,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
      {
        'question': 'Saat menghadapi deadline ketat, saya akan...',
        'type': 'likert',
        'options': [
          'Panik dan stres',
          'Bekerja keras tapi cemas',
          'Tetap tenang dan fokus',
          'Memprioritaskan tugas penting',
          'Tetap tenang, fokus, dan mengatur strategi penyelesaian',
        ],
        'correctAnswer': 4,
        'optionScores': [1, 2, 4, 4, 5], // 🆕 Skor disesuaikan
        'explanationShort': 'Tenang dan atur strategi.',
        'explanationFull':
            'Manajemen stres yang baik adalah tetap tenang sambil mengatur strategi penyelesaian yang efektif.',
        'category': 'TKP',
        'subcategory': 'TKP_Stres',
        'tags': ['manajemen-stres', 'deadline'],
        'difficulty': 31,
        'isActive': true,
        'createdAt': Timestamp.now(),
      },
    ];
  }

  static List<Map<String, dynamic>> _getTKPMediumQuestions() {
    return List.generate(15, (i) {
      // 🆕 Generate skor bervariasi untuk setiap soal
      final scores = [1, 2, 3, 4, 5];

      return {
        'question':
            'Soal TKP Menengah ${i + 1}: Dalam situasi konflik tim, saya akan...',
        'type': 'likert',
        'options': [
          'Menghindari konflik',
          'Memihak satu pihak',
          'Mencari jalan tengah',
          'Mediasi dengan objektif',
          'Fasilitasi diskusi konstruktif untuk solusi bersama',
        ],
        'correctAnswer': 4, // Selalu opsi terakhir = skor tertinggi
        'optionScores': scores, // 🆕 TAMBAH INI
        'explanationShort': 'Penjelasan singkat soal ${i + 1}.',
        'explanationFull':
            'Penjelasan lengkap untuk soal TKP medium nomor ${i + 1} tentang pelayanan.',
        'category': 'TKP',
        'subcategory': 'TKP_Pelayanan',
        'tags': ['kerja-sama', 'medium'],
        'difficulty': 40 + (i % 15),
        'isActive': true,
        'createdAt': Timestamp.now(),
      };
    });
  }

  static List<Map<String, dynamic>> _getTKPHardQuestions() {
    return List.generate(20, (i) {
      // 🆕 Generate skor dengan variasi (tidak selalu 1-5 linear)
      final scores = i % 3 == 0
          ? [1, 2, 3, 4, 5] // Soal normal
          : i % 3 == 1
          ? [1, 1, 3, 4, 5] // Opsi 0 dan 1 sama-sama rendah
          : [1, 2, 4, 4, 5]; // Opsi 2 dan 3 sama-sama sedang

      return {
        'question':
            'Soal TKP Lanjutan ${i + 1}: Menghadapi dilema etika dalam pelayanan publik...',
        'type': 'likert',
        'options': [
          'Mengikuti prosedur standar',
          'Meminta arahan atasan',
          'Mempertimbangkan berbagai aspek',
          'Konsultasi dengan tim dan stakeholder',
          'Analisis mendalam dan putuskan sesuai nilai integritas',
        ],
        'correctAnswer': 4, // Selalu opsi terakhir
        'optionScores': scores, // 🆕 TAMBAH INI
        'explanationShort': 'Penjelasan singkat soal ${i + 1}.',
        'explanationFull':
            'Penjelasan lengkap untuk soal TKP hard nomor ${i + 1} tentang orientasi pelayanan publik.',
        'category': 'TKP',
        'subcategory': 'TKP_Pelayanan',
        'tags': ['pelayanan-publik', 'advanced'],
        'difficulty': 60 + (i % 20),
        'isActive': true,
        'createdAt': Timestamp.now(),
      };
    });
  }
}

class SeedDataScreen extends StatefulWidget {
  const SeedDataScreen({super.key});

  @override
  State<SeedDataScreen> createState() => _SeedDataScreenState();
}

class _SeedDataScreenState extends State<SeedDataScreen> {
  bool _isSeeding = false;
  String _status = 'Belum mulai';
  bool _isDone = false;

  Future<void> _startSeeding() async {
    setState(() {
      _isSeeding = true;
      _status = 'Memulai seeding...';
      _isDone = false;
    });

    try {
      setState(() => _status = 'Seeding exam packages dengan pertanyaan...');
      await SeedData.seedExamPackagesWithQuestions(); // ✅ Method yang benar

      setState(() {
        _status = 'Seeding selesai! ✅';
        _isDone = true;
      });
    } catch (e) {
      print(e);
      setState(() {
        _status = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }

  Future<void> updateExistingLikertQuestions() async {
    final db = FirebaseFirestore.instance;
    final packagesRef = db.collection('exam_packages');

    final snapshot = await packagesRef.get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final questions = List<Map<String, dynamic>>.from(
        data['questions'] ?? [],
      );

      bool needsUpdate = false;
      final updatedQuestions = questions.map((q) {
        if (q['type'] == 'likert' && q['optionScores'] == null) {
          needsUpdate = true;
          return {
            ...q,
            'optionScores': [1, 2, 3, 4, 5], // Default scores
          };
        }
        return q;
      }).toList();

      if (needsUpdate) {
        await doc.reference.update({'questions': updatedQuestions});
        print('✅ Updated ${doc.id}');
      }
    }

    print('🎉 All done!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Seed Data', style: AppTextStyles.appBarTitle),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SeedDataScreen()),
                );
              },
              child: Text('push data'),
            ),
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.warning, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: AppColors.warning),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'PERHATIAN: Ini akan menambahkan data dummy ke Firestore!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.xl),

            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border, width: 3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status:', style: AppTextStyles.headingSmall),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    _status,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: _isDone
                          ? AppColors.success
                          : _isSeeding
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (_isSeeding) ...[
                    SizedBox(height: AppSpacing.md),
                    LinearProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ],
                ],
              ),
            ),

            Spacer(),
            DuolingoButton.secondary(
              text: _isSeeding ? 'PROCESSING...' : 'MULAI UPDATE SEEDING',
              onPressed: _isSeeding ? null : updateExistingLikertQuestions,
            ),

            DuolingoButton.primary(
              text: _isSeeding ? 'PROCESSING...' : 'MULAI SEEDING',
              onPressed: _isSeeding ? null : _startSeeding,
            ),
          ],
        ),
      ),
    );
  }
}
