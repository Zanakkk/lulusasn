// lib/features/auth/screens/login_screen.dart

// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:line_icons/line_icons.dart';

import '../../../app/routes.dart';
import '../../../core/utils/validators.dart';
import '../service/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLoginMode) {
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        if (!userCredential.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          setState(() {
            _errorMessage = 'Email belum diverifikasi. Cek inbox Anda!';
            _isLoading = false;
          });
          return;
        }

        final userExists = await UserService.instance.userExists(
          userCredential.user!.uid,
        );

        if (!mounted) return;

        if (!userExists) {
          Navigator.pushReplacementNamed(context, AppRoutes.goalSetting);
        } else {
          await UserService.instance.updateLastLogin(userCredential.user!.uid);

          // ✅ Cek apakah user adalah admin
          // ✅ Query berdasarkan email
          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (querySnapshot.docs.isEmpty) {
            // User document tidak ditemukan
            setState(() {
              _errorMessage = 'Data user tidak ditemukan';
              _isLoading = false;
            });
            return;
          }

          final userData = querySnapshot.docs.first.data();
          final isAdmin = userData['admin'] ?? false;

          if (!mounted) return;

// Arahkan sesuai role
          if (isAdmin) {
            Navigator.pushReplacementNamed(context, AppRoutes.adminMain);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.main);
          }
        }
      } else {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        await userCredential.user!.sendEmailVerification();

        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Email tidak terdaftar';
          break;
        case 'wrong-password':
          message = 'Password salah';
          break;
        case 'email-already-in-use':
          message = 'Email sudah terdaftar';
          break;
        case 'weak-password':
          message = 'Password terlalu lemah (min 6 karakter)';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid';
          break;
        default:
          message = 'Error: ${e.message}';
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Email verifikasi telah dikirim ulang!'),
              backgroundColor: const Color(0xFF58CC02),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim email: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;

    if (_emailSent) {
      return _buildEmailSentScreen(isMobile);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: BoxConstraints(maxWidth: isMobile ? size.width : 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo & Title
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF58CC02), Color(0xFF58A700)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF58CC02).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LineIcons.graduationCap,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'LULUSASN',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: Color(0xFF3C3C3C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Platform Latihan Ujian Nasional',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

                // Card
                Container(
                  padding: EdgeInsets.all(isMobile ? 24 : 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE5E5E5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Mode toggle
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(child: _buildModeButton('Login', true)),
                              Expanded(
                                child: _buildModeButton('Daftar', false),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'nama@example.com',
                            prefixIcon: const Icon(LineIcons.envelope),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E5E5),
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E5E5),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1CB0F6),
                                width: 3,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFFF4B4B),
                                width: 2,
                              ),
                            ),
                          ),
                          validator:
                              Validators.email, // ← PAKAI VALIDATOR DARI CLASS
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Minimal 6 karakter',
                            prefixIcon: const Icon(LineIcons.lock),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? LineIcons.eye
                                    : LineIcons.eyeSlash,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E5E5),
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E5E5),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1CB0F6),
                                width: 3,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFFF4B4B),
                                width: 2,
                              ),
                            ),
                          ),
                          validator: Validators
                              .password, // ← PAKAI VALIDATOR DARI CLASS
                        ),
                        const SizedBox(height: 24),

                        // Submit button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF58CC02),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFE5E5E5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Color(0xFF58A700),
                                  width: 2,
                                ),
                              ),
                              shadowColor: const Color(
                                0xFF58CC02,
                              ).withOpacity(0.3),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isLoginMode ? 'Login' : 'Daftar',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),

                        // Error message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFF4B4B).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LineIcons.exclamationCircle,
                                  color: Color(0xFFFF4B4B),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFFF4B4B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Forgot password
                        const SizedBox(height: 16),
                        Opacity(
                          opacity: _isLoginMode
                              ? 1.0
                              : 0.0, // Transparan di mode Daftar
                          child: IgnorePointer(
                            ignoring:
                                !_isLoginMode, // Tidak bisa diklik di mode Daftar
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF1CB0F6),
                              ),
                              child: const Text(
                                'Lupa password?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Terms
                Text(
                  _isLoginMode
                      ? 'Dengan login, Anda menyetujui\nSyarat & Ketentuan kami'
                      : 'Dengan daftar, Anda menyetujui\nSyarat & Ketentuan kami',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String text, bool isLogin) {
    final isActive = _isLoginMode == isLogin;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: () {
          setState(() {
            _isLoginMode = isLogin;
            _errorMessage = null;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? const Color(0xFF3C3C3C)
                  : const Color(0xFF888888),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailSentScreen(bool isMobile) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: BoxConstraints(maxWidth: isMobile ? size.width : 440),
            padding: EdgeInsets.all(isMobile ? 24 : 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF58CC02).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    LineIcons.envelope,
                    size: 48,
                    color: Color(0xFF58CC02),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Cek Email Anda!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3C3C3C),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Email verifikasi telah dikirim ke:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  _emailController.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3C3C3C),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📧 Langkah Selanjutnya:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF3C3C3C),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '1. Buka inbox email Anda\n'
                        '2. Klik link verifikasi\n'
                        '3. Kembali ke halaman ini\n'
                        '4. Login dengan akun Anda',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3C3C3C),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _resendVerificationEmail,
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Kirim Ulang Email'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1CB0F6),
                      side: const BorderSide(
                        color: Color(0xFFE5E5E5),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _emailSent = false;
                      _isLoginMode = true;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1CB0F6),
                  ),
                  child: const Text(
                    'Kembali ke Login',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '💡 Tidak menerima email?\nCek folder Spam/Junk',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF1CB0F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  LineIcons.questionCircle,
                  size: 36,
                  color: Color(0xFF1CB0F6),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Lupa Password?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3C3C3C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan email Anda untuk reset password',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(LineIcons.envelope),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE5E5E5),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3C3C3C),
                          side: const BorderSide(
                            color: Color(0xFFE5E5E5),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: emailController.text.trim(),
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Email reset password telah dikirim!',
                                  ),
                                  backgroundColor: const Color(0xFF58CC02),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: const Color(0xFFFF4B4B),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF58CC02),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color(0xFF58A700),
                              width: 2,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Kirim',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
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
  }
}
