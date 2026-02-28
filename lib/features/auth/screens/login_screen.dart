// lib/features/auth/screens/login_screen.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/utils/validators.dart';
import '../service/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _isLogin = true;
  bool _obscure = true;
  bool _emailSent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── auth logic (unchanged) ─────────────────────────────────────────
  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

      if (_isLogin) {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (!cred.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          return _setError('Email belum diverifikasi. Cek inbox Anda!');
        }

        final uid = cred.user!.uid;
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (!mounted) return;
        if (!userDoc.exists) {
          Navigator.pushReplacementNamed(context, AppRoutes.goalSetting);
          return;
        }

        await UserService.instance.updateLastLogin(uid);
        final isAdmin = userDoc.data()?['admin'] ?? false;
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          isAdmin ? AppRoutes.adminMain : AppRoutes.main,
        );
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await cred.user!.sendEmailVerification();
        setState(() => _emailSent = true);
      }
    } on FirebaseAuthException catch (e) {
      _setError(switch (e.code) {
        'user-not-found' => 'Email tidak terdaftar',
        'wrong-password' => 'Password salah',
        'email-already-in-use' => 'Email sudah terdaftar',
        'weak-password' => 'Password terlalu lemah (min 6 karakter)',
        'invalid-email' => 'Format email tidak valid',
        _ => 'Error: ${e.message}',
      });
    } catch (e) {
      _setError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setError(String msg) {
    if (mounted) setState(() => _error = msg);
  }

  Future<void> _resendVerification() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) _showSnack('Email verifikasi dikirim ulang!', success: true);
    } catch (e) {
      if (mounted) _showSnack('Gagal: ${e.toString()}');
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppText.body.copyWith(color: AppColors.white),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_emailSent) {
      return _EmailSentScreen(
        email: _emailCtrl.text,
        onResend: _resendVerification,
        onBack: () => setState(() {
          _emailSent = false;
          _isLogin = true;
        }),
      );
    }

    final w = MediaQuery.sizeOf(context).width;
    final desktop = w >= 1024;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: desktop ? _desktopLayout() : _mobileLayout(),
    );
  }

  // ── DESKTOP: split screen ──────────────────────────────────────────
  Widget _desktopLayout() => Row(
    children: [
      // Left — dark hero panel
      Expanded(
        child: Container(
          decoration: const BoxDecoration(gradient: AppGradient.navy),
          child: Stack(
            children: [
              // Gold glow
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LogoMark(size: 56),
                      const SizedBox(height: 32),
                      Text(
                        'LULUZZZ',
                        style: AppText.display.copyWith(
                          color: AppColors.white,
                          fontSize: 40,
                          letterSpacing: 2,
                        ),
                      ),
                      AppSpacing.vsm,
                      Text(
                        'Platform Latihan Ujian Nasional',
                        style: AppText.bodyLg.copyWith(
                          color: AppColors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Feature bullets
                      ...[
                        ('Ribuan soal latihan', Icons.quiz_outlined),
                        (
                          'Analisis progres real-time',
                          Icons.analytics_outlined,
                        ),
                        ('Semua jenis ujian nasional', Icons.school_outlined),
                      ].map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.15),
                                  borderRadius: AppRadius.bSm,
                                  border: Border.all(
                                    color: AppColors.gold.withOpacity(0.3),
                                  ),
                                ),
                                child: Icon(
                                  f.$2,
                                  color: AppColors.gold,
                                  size: 16,
                                ),
                              ),
                              AppSpacing.hmd,
                              Text(
                                f.$1,
                                style: AppText.bodyLg.copyWith(
                                  color: AppColors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Right — form panel
      SizedBox(
        width: 480,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(48),
            child: _FormCard(
              isLogin: _isLogin,
              loading: _loading,
              obscure: _obscure,
              error: _error,
              formKey: _formKey,
              emailCtrl: _emailCtrl,
              passwordCtrl: _passwordCtrl,
              onToggleMode: () => setState(() {
                _isLogin = !_isLogin;
                _error = null;
              }),
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSubmit: _handleAuth,
              onForgot: _showForgotDialog,
            ),
          ),
        ),
      ),
    ],
  );

  // ── MOBILE: centered card ──────────────────────────────────────────
  Widget _mobileLayout() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 60),
        _LogoMark(size: 48),
        AppSpacing.vmd,
        Text('LULUZZZ', style: AppText.display.copyWith(letterSpacing: 1)),
        AppSpacing.vxs,
        Text(
          'Platform Latihan Ujian Nasional',
          style: AppText.bodySm,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _FormCard(
          isLogin: _isLogin,
          loading: _loading,
          obscure: _obscure,
          error: _error,
          formKey: _formKey,
          emailCtrl: _emailCtrl,
          passwordCtrl: _passwordCtrl,
          onToggleMode: () => setState(() {
            _isLogin = !_isLogin;
            _error = null;
          }),
          onToggleObscure: () => setState(() => _obscure = !_obscure),
          onSubmit: _handleAuth,
          onForgot: _showForgotDialog,
        ),
        const SizedBox(height: 24),
        Text(
          'Dengan melanjutkan, Anda menyetujui Syarat & Ketentuan kami.',
          textAlign: TextAlign.center,
          style: AppText.caption,
        ),
      ],
    ),
  );

  // ── forgot password dialog ─────────────────────────────────────────
  void _showForgotDialog() {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bXl),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, minWidth: 300),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.softBg(AppColors.primary),
                    borderRadius: AppRadius.bMd,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                AppSpacing.vmd,
                Text('Reset Password', style: AppText.h2),
                AppSpacing.vxs,
                Text(
                  'Masukkan email untuk menerima link reset',
                  style: AppText.bodySm,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.vmd,
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
                AppSpacing.vmd,
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal'),
                      ),
                    ),
                    AppSpacing.hmd,
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: ctrl.text.trim(),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            _showSnack('Link reset dikirim!', success: true);
                          } catch (e) {
                            _showSnack('Error: $e');
                          }
                        },
                        child: const Text('Kirim'),
                      ),
                    ),
                  ],
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
// FORM CARD  (shared mobile & desktop)
// ─────────────────────────────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  final bool isLogin, loading, obscure;
  final String? error;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passwordCtrl;
  final VoidCallback onToggleMode, onToggleObscure, onSubmit, onForgot;

  const _FormCard({
    required this.isLogin,
    required this.loading,
    required this.obscure,
    required this.error,
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.onToggleMode,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.bXl,
      border: Border.all(color: AppColors.border),
      boxShadow: AppShadow.md,
    ),
    child: Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Mode toggle ──
          Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.bMd,
            ),
            child: Row(
              children: [
                _ToggleBtn('Masuk', isLogin, onToggleMode),
                _ToggleBtn('Daftar', !isLogin, onToggleMode),
              ],
            ),
          ),

          AppSpacing.vmd,

          // ── Email ──
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'nama@example.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: Validators.email,
          ),

          AppSpacing.vsm,

          // ── Password ──
          TextFormField(
            controller: passwordCtrl,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Minimal 6 karakter',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              ),
            ),
            validator: Validators.password,
          ),

          AppSpacing.vmd,

          // ── Submit ──
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.surfaceAlt,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.white,
                      ),
                    )
                  : Text(isLogin ? 'Masuk' : 'Buat Akun', style: AppText.btnLg),
            ),
          ),

          // ── Error ──
          if (error != null) ...[
            AppSpacing.vsm,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.softBg(AppColors.error),
                borderRadius: AppRadius.bMd,
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                  AppSpacing.hsm,
                  Expanded(
                    child: Text(
                      error!,
                      style: AppText.bodySm.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Forgot password ──
          AppSpacing.vsm,
          Visibility(
            visible: isLogin,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgot,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Lupa password?', style: AppText.bodySm),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: double.infinity,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.bSm,
          boxShadow: active ? AppShadow.sm : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppText.label.copyWith(
            color: active ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGO MARK
// ─────────────────────────────────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: AppGradient.navy,
      borderRadius: AppRadius.bMd,
      border: Border.all(color: AppColors.gold, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Center(
      child: Text(
        'L',
        style: AppText.h1.copyWith(
          color: AppColors.gold,
          fontSize: size * 0.45,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMAIL SENT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _EmailSentScreen extends StatelessWidget {
  final String email;
  final VoidCallback onResend, onBack;
  const _EmailSentScreen({
    required this.email,
    required this.onResend,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
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
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.softBg(AppColors.success),
                    borderRadius: AppRadius.bLg,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.success,
                    size: 32,
                  ),
                ),
                AppSpacing.vmd,
                Text('Cek Email Anda!', style: AppText.h1),
                AppSpacing.vsm,
                Text(
                  'Verifikasi dikirim ke:',
                  style: AppText.bodySm,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.vxs,
                Text(
                  email,
                  style: AppText.bodyLg.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.vmd,

                // Steps box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.softBg(AppColors.gold),
                    borderRadius: AppRadius.bMd,
                    border: Border.all(color: AppColors.gold.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Langkah selanjutnya:',
                        style: AppText.label.copyWith(color: AppColors.primary),
                      ),
                      AppSpacing.vsm,
                      ...[
                        'Buka inbox email Anda',
                        'Klik link verifikasi',
                        'Kembali & login',
                      ].asMap().entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: AppRadius.bFull,
                                ),
                                child: Center(
                                  child: Text(
                                    '${e.key + 1}',
                                    style: AppText.caption.copyWith(
                                      color: AppColors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                              AppSpacing.hsm,
                              Text(e.value, style: AppText.body),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vmd,

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onResend,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Kirim Ulang Email'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.bMd,
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                AppSpacing.vsm,
                TextButton(
                  onPressed: onBack,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: Text('← Kembali ke Login', style: AppText.label),
                ),
                AppSpacing.vsm,
                Text(
                  'Tidak menerima email? Cek folder Spam/Junk',
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
