// lib/users/auth/screens/login_screen.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../service/user_service.dart';
import 'email_sent_screen.dart';

// ============================================================================
// LOGIN SCREEN
// ============================================================================
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
  bool _obscurePassword = true;
  bool _showEmailSent = false;
  bool _showResendButton = false;

  String? _errorMessage;
  String? _successMessage;

  // Simpan email yang baru saja daftar untuk EmailSentScreen
  String _registeredEmail = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Main Auth Handler ──────────────────────────────────────────────────
  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
      _showResendButton = false;
    });

    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

      if (_isLogin) {
        await _handleLogin(email, password);
      } else {
        await _handleRegister(email, password);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AuthErrorMessage.get(e.code);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Terjadi kesalahan tak terduga. Periksa koneksi internet Anda.';
        _loading = false;
      });
    }
  }

  // ── Login Logic ────────────────────────────────────────────────────────
  Future<void> _handleLogin(String email, String password) async {
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (!cred.user!.emailVerified) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Email belum diverifikasi. Silakan cek inbox Anda dan klik link '
            'verifikasi yang telah kami kirim. Cek juga folder Spam/Junk.';
        _showResendButton = true;
        _loading = false;
      });
      return;
    }

    await _navigateAfterLogin(cred.user!.uid);
  }

  // ── Register Logic ─────────────────────────────────────────────────────
  Future<void> _handleRegister(String email, String password) async {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Kirim email verifikasi
    await cred.user!.sendEmailVerification();

    // Sign out — user wajib verifikasi dulu sebelum bisa masuk
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    // ✅ Set state SEKALI, atomik — tidak ada loading=false terpisah
    setState(() {
      _registeredEmail = email;
      _showEmailSent = true;
      _loading = false;
    });
  }

  // ── Back to Login dari EmailSentScreen ────────────────────────────────
  void _handleBackToLogin() {
    setState(() {
      _showEmailSent = false;
      _isLogin = true;
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _errorMessage = null;
      _successMessage = null;
      _showResendButton = false;
      _registeredEmail = '';
    });
  }

  // ── Navigation After Login ────────────────────────────────────────────
  Future<void> _navigateAfterLogin(String uid) async {
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

    if (!mounted) return;

    final isAdmin = userDoc.data()?['admin'] ?? false;
    Navigator.pushReplacementNamed(
      context,
      isAdmin ? AppRoutes.adminMain : AppRoutes.main,
    );
  }

  // ── Resend Verification Email ─────────────────────────────────────────
  Future<void> _resendVerification() async {
    try {
      final email = _registeredEmail.isNotEmpty
          ? _registeredEmail
          : _emailCtrl.text.trim();
      final password = _passwordCtrl.text;

      if (email.isEmpty || password.isEmpty) {
        if (!mounted) return;
        setState(
          () => _errorMessage =
              'Isi email dan password terlebih dahulu untuk kirim ulang.',
        );
        return;
      }

      // Login sementara untuk kirim ulang
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.sendEmailVerification();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      setState(() {
        _successMessage = 'Email verifikasi berhasil dikirim ulang!';
        _showResendButton = false;
        _errorMessage = null;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = AuthErrorMessage.get(e.code));
    } catch (e) {
      if (!mounted) return;
      setState(
        () =>
            _errorMessage = 'Gagal mengirim email verifikasi. Coba lagi nanti.',
      );
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────
  void _showForgotPasswordDialog() {
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => _ForgotPasswordDialog(ctrl: ctrl),
    ).then((_) => ctrl.dispose());
  }

  // ── Toggle ────────────────────────────────────────────────────────────
  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
      _successMessage = null;
      _showResendButton = false;
      _formKey.currentState?.reset();
    });
  }

  void _togglePasswordVisibility() =>
      setState(() => _obscurePassword = !_obscurePassword);

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // ✅ EmailSentScreen — tampil setelah register berhasil
    if (_showEmailSent) {
      return EmailSentScreen(
        email: _registeredEmail,
        onResend: _resendVerification,
        onBackToLogin: _handleBackToLogin,
        isRegistration: true,
      );
    }

    final desktop = MediaQuery.sizeOf(context).width >= 1024;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: desktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(child: _HeroPanel()),
        SizedBox(
          width: 520,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: _buildFormCard(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
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
          _buildFormCard(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Dengan melanjutkan, Anda menyetujui Syarat & Ketentuan kami.',
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return _FormCard(
      isLogin: _isLogin,
      loading: _loading,
      obscurePassword: _obscurePassword,
      errorMessage: _errorMessage,
      successMessage: _successMessage,
      showResendButton: _showResendButton,
      formKey: _formKey,
      emailCtrl: _emailCtrl,
      passwordCtrl: _passwordCtrl,
      onToggleMode: _toggleAuthMode,
      onToggleObscure: _togglePasswordVisibility,
      onSubmit: _handleAuth,
      onForgotPassword: _showForgotPasswordDialog,
      onResendVerification: _resendVerification,
    );
  }
}

// ============================================================================
// FORM CARD WIDGET
// ============================================================================
class _FormCard extends StatelessWidget {
  final bool isLogin;
  final bool loading;
  final bool obscurePassword;
  final bool showResendButton;
  final String? errorMessage;
  final String? successMessage;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onResendVerification;

  const _FormCard({
    required this.isLogin,
    required this.loading,
    required this.obscurePassword,
    required this.showResendButton,
    required this.errorMessage,
    required this.successMessage,
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.onToggleMode,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onResendVerification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            _buildModeToggle(),
            AppSpacing.vmd,
            _buildEmailField(),
            AppSpacing.vsm,
            _buildPasswordField(),
            AppSpacing.vmd,
            _buildSubmitButton(),
            if (errorMessage != null) ...[
              AppSpacing.vsm,
              _ErrorBox(message: errorMessage!),
            ],
            if (successMessage != null) ...[
              AppSpacing.vsm,
              _SuccessBox(message: successMessage!),
            ],
            if (showResendButton) ...[AppSpacing.vsm, _buildResendButton()],
            if (isLogin) ...[AppSpacing.vsm, _buildForgotPasswordButton()],
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
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
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailCtrl,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'nama@example.com',
        prefixIcon: Icon(Icons.mail_outline_rounded),
      ),
      validator: Validators.email,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordCtrl,
      obscureText: obscurePassword,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: isLogin ? 'Password' : 'Password (min. 8 karakter)',
        hintText: isLogin ? 'Masukkan password' : 'Minimal 8 karakter',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
          ),
          onPressed: onToggleObscure,
        ),
      ),
      validator: isLogin ? Validators.passwordLogin : Validators.password,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
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
    );
  }

  Widget _buildResendButton() {
    return OutlinedButton.icon(
      onPressed: onResendVerification,
      icon: const Icon(Icons.refresh_rounded, size: 16),
      label: const Text('Kirim Ulang Email Verifikasi'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.warning,
        side: const BorderSide(color: AppColors.warning),
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bMd),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onForgotPassword,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Lupa password?', style: TextStyle(fontSize: 13)),
      ),
    );
  }
}

// ============================================================================
// ERROR & SUCCESS BOXES
// ============================================================================
class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softBg(AppColors.error),
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 18,
            ),
          ),
          AppSpacing.hsm,
          Expanded(
            child: Text(
              message,
              style: AppText.bodySm.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBox extends StatelessWidget {
  final String message;
  const _SuccessBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softBg(AppColors.success),
        borderRadius: AppRadius.bMd,
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 18,
            ),
          ),
          AppSpacing.hsm,
          Expanded(
            child: Text(
              message,
              style: AppText.bodySm.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TOGGLE BUTTON
// ============================================================================
class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
}

// ============================================================================
// HERO PANEL (Desktop)
// ============================================================================
class _HeroPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradient.navy),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: _glowCircle(300, AppColors.gold.withOpacity(0.12)),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: _glowCircle(200, AppColors.gold.withOpacity(0.08)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _LogoMark(size: 56),
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
                  const _FeatureItem(
                    text: 'Ribuan soal latihan',
                    icon: Icons.quiz_outlined,
                  ),
                  const _FeatureItem(
                    text: 'Analisis progres real-time',
                    icon: Icons.analytics_outlined,
                  ),
                  const _FeatureItem(
                    text: 'Semua jenis ujian nasional',
                    icon: Icons.school_outlined,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );
}

class _FeatureItem extends StatelessWidget {
  final String text;
  final IconData icon;
  const _FeatureItem({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.15),
              borderRadius: AppRadius.bSm,
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: Icon(icon, color: AppColors.gold, size: 16),
          ),
          AppSpacing.hmd,
          Text(
            text,
            style: AppText.bodyLg.copyWith(
              color: AppColors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LOGO MARK
// ============================================================================
class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
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
      child: ClipRRect(
        // ← Clipping yang benar
        borderRadius: AppRadius.bMd,
        child: Image.asset('assets/Logo.png', fit: BoxFit.cover),
      ),
    );
  }
}

// ============================================================================
// FORGOT PASSWORD DIALOG
// ============================================================================
class _ForgotPasswordDialog extends StatelessWidget {
  final TextEditingController ctrl;
  const _ForgotPasswordDialog({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.bXl),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, minWidth: 300),
        child: Padding(
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
              const Text(
                'Reset Password',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
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
                textInputAction: TextInputAction.done,
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  AppSpacing.hmd,
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final email = ctrl.text.trim();
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Email tidak boleh kosong'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                            email: email,
                          );
                          if (context.mounted) Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Link reset berhasil dikirim! Cek inbox email Anda.',
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.bMd,
                              ),
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AuthErrorMessage.get(e.code)),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.bMd,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal mengirim link reset'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
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
    );
  }
}

// ============================================================================
// AUTH ERROR MESSAGE HELPER
// ============================================================================
abstract class AuthErrorMessage {
  AuthErrorMessage._();

  static String get(String code) {
    return switch (code) {
      'invalid-email' =>
        'Format email tidak valid. Contoh yang benar: nama@email.com',
      'network-request-failed' =>
        'Tidak dapat terhubung ke server.\nPeriksa koneksi internet Anda dan coba lagi.',
      'too-many-requests' =>
        'Terlalu banyak percobaan gagal dalam waktu singkat.\n'
            'Mohon tunggu beberapa menit, atau gunakan fitur "Lupa password".',
      'operation-not-allowed' =>
        'Metode login ini tidak diaktifkan. Hubungi administrator aplikasi.',
      'user-disabled' =>
        'Akun ini telah dinonaktifkan.\nHubungi tim dukungan kami untuk informasi lebih lanjut.',
      'user-not-found' =>
        'Email tidak terdaftar.\nPeriksa kembali email Anda atau daftar akun baru.',
      'wrong-password' =>
        'Password salah. Silakan coba lagi.\nGunakan "Lupa password?" jika tidak ingat password.',
      'invalid-credential' =>
        'Email atau password tidak sesuai.\nPeriksa kembali atau gunakan "Lupa password?"',
      'invalid-login-credentials' =>
        'Email atau password salah.\nPastikan Anda menggunakan kredensial yang benar.',
      'user-mismatch' =>
        'Data pengguna tidak cocok. Silakan login ulang dari awal.',
      'account-exists-with-different-credential' =>
        'Akun sudah ada dengan metode login berbeda. Gunakan metode yang saat pendaftaran.',
      'email-already-in-use' =>
        'Email ini sudah terdaftar.\nSilakan login, atau gunakan "Lupa password?" jika lupa password.',
      'weak-password' =>
        'Password terlalu lemah.\nGunakan minimal 8 karakter dengan kombinasi huruf besar, huruf kecil, angka, dan simbol.',
      'requires-recent-login' =>
        'Sesi Anda telah kedaluwarsa.\nSilakan login ulang untuk melanjutkan.',
      _ =>
        'Terjadi kesalahan (Kode: $code).\nSilakan coba lagi atau hubungi dukungan jika masalah berlanjut.',
    };
  }
}
