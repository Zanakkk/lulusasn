// lib/users/auth/screens/email_sent_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class EmailSentScreen extends StatelessWidget {
  final String email;
  final VoidCallback onResend;
  final VoidCallback onBackToLogin;
  final bool isRegistration;

  const EmailSentScreen({
    super.key,
    required this.email,
    required this.onResend,
    required this.onBackToLogin,
    this.isRegistration = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.bXl,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadow.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.softBg(AppColors.success),
                      borderRadius: AppRadius.bFull,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: AppColors.success,
                      size: 40,
                    ),
                  ),
                  AppSpacing.vlg,

                  // Title
                  Text(
                    isRegistration
                        ? 'Verifikasi Email Wajib'
                        : 'Email Verifikasi Dikirim',
                    style: AppText.h1,
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.vsm,

                  // Subtitle
                  Text(
                    isRegistration
                        ? 'Akun berhasil dibuat! Untuk melanjutkan, Anda\nWAJIB verifikasi email terlebih dahulu:'
                        : 'Link verifikasi dikirim ke:',
                    style: AppText.bodySm,
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.vxs,

                  // Email display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: AppRadius.bMd,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      email,
                      style: AppText.bodyLg.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  AppSpacing.vlg,

                  // Steps card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.softBg(AppColors.primary),
                          AppColors.softBg(AppColors.gold),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppRadius.bMd,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            AppSpacing.hsm,
                            Text(
                              'Langkah selanjutnya:',
                              style: AppText.label.copyWith(
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.vsm,
                        _StepItem(
                          number: 1,
                          text: 'Buka inbox email Anda',
                          icon: Icons.inbox_outlined,
                        ),
                        _StepItem(
                          number: 2,
                          text: 'Cek folder Spam/Junk jika tidak ada',
                          icon: Icons.warning_amber_outlined,
                        ),
                        _StepItem(
                          number: 3,
                          text: 'Klik link verifikasi dalam email',
                          icon: Icons.link_outlined,
                        ),
                        if (isRegistration)
                          _StepItem(
                            number: 4,
                            text: 'Kembali ke sini dan login untuk melanjutkan',
                            icon: Icons.login_rounded,
                          ),
                      ],
                    ),
                  ),
                  AppSpacing.vlg,

                  // Resend button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: onResend,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Kirim Ulang Email Verifikasi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.bMd,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.vsm,

                  // Back to login button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onBackToLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.bMd,
                        ),
                      ),
                      child: Text(
                        isRegistration
                            ? '← Kembali ke Login untuk Verifikasi'
                            : 'Kembali ke Login',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.vmd,

                  // Spam folder reminder
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softBg(AppColors.warning),
                      borderRadius: AppRadius.bSm,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.report_outlined,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        AppSpacing.hsm,
                        Expanded(
                          child: Text(
                            'Tidak menerima email? Cek folder Spam/Junk atau promosi, atau klik "Kirim Ulang" untuk mengirim ulang.',
                            style: AppText.caption.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STEP ITEM WIDGET
// ============================================================================
class _StepItem extends StatelessWidget {
  final int number;
  final String text;
  final IconData icon;

  const _StepItem({
    required this.number,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.bFull,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          AppSpacing.hsm,
          Icon(icon, size: 16, color: AppColors.textSecondary),
          AppSpacing.hsm,
          Expanded(child: Text(text, style: AppText.body)),
        ],
      ),
    );
  }
}
