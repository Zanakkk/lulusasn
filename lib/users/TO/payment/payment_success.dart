import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lulusasn/app/routes.dart';
import 'package:lulusasn/app/theme.dart'; // sesuaikan import path

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<bool> get _isPaidStream {
    if (_uid.isEmpty) return Stream.value(false);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .snapshots()
        .map((snap) => snap.data()?['isPaid'] == true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: StreamBuilder<bool>(
          stream: _isPaidStream,
          builder: (context, snapshot) {
            final isPaid = snapshot.data ?? false;

            return Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.bLg,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadow.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Icon ────────────────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: isPaid
                        ? Container(
                            key: const ValueKey('paid'),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              size: 72,
                              color: AppColors.success,
                            ),
                          )
                        : Container(
                            key: const ValueKey('waiting'),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.hourglass_top_rounded,
                              size: 72,
                              color: AppColors.warning,
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // ── Title ────────────────────────────────────────────────
                  Text(
                    isPaid
                        ? 'Pembayaran Berhasil! 🎉'
                        : 'Menunggu Verifikasi...',
                    style: AppText.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPaid
                        ? 'Akses try out kamu sudah aktif.'
                        : 'Biasanya hanya butuh beberapa detik.',
                    style: AppText.bodySm,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // ── CTA ──────────────────────────────────────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isPaid
                        ? SizedBox(
                            key: const ValueKey('btn_paid'),
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRoutes.main,
                                    (_) => false,
                                  ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.bMd,
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Lihat Try Out Saya',
                                style: AppText.btnMd.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            key: const ValueKey('btn_waiting'),
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.gold,
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Jangan tutup halaman ini...',
                                style: AppText.caption,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
