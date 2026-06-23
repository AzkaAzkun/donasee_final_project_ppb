import 'package:donasee_final_project_ppb/screens/auth/register_choose_screen.dart';
import 'package:donasee_final_project_ppb/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  bool _obscure = true;
  String? _errorMsg;

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final auth = context.read<AuthService>();
      await auth.login(
        email: email,
        password: _passwordController.text,
      );
    } catch (e) {
      setState(() {
        _errorMsg = _parseError(e.toString());
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(String raw) {
    String cleaned = raw;
    if (cleaned.startsWith('Exception: ')) {
      cleaned = cleaned.replaceFirst('Exception: ', '');
    }
    if (cleaned.contains('email-already-in-use')) {
      return 'Email sudah terdaftar. Gunakan fitur “Lupa Password” jika ingin reset.';
    }
    if (cleaned.contains('user-not-found') ||
        cleaned.contains('invalid-credential') ||
        cleaned.contains('wrong-password') ||
        cleaned.contains('invalid-email')) {
      return 'Email atau password yang Anda masukkan salah.';
    }
    if (cleaned.contains('too-many-requests')) {
      return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
    }
    if (cleaned.contains('network-request-failed')) {
      return 'Koneksi internet bermasalah. Silakan periksa jaringan Anda.';
    }
    return cleaned.isNotEmpty ? cleaned : 'Gagal masuk, silakan coba lagi.';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0050CB);
    final errorColor = const Color(0xFFBA1A1A);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Stack(
        children: [
          // 1. Ambient Background Gradients
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF7F9FB),
                    Color(0xFFF7F9FB),
                  ],
                ),
              ),
            ),
          ),
          // Radial glow at top left (Blue)
          Positioned(
            left: -100,
            top: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Radial glow at top right (Teal)
          Positioned(
            right: -100,
            top: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4AE176).withValues(alpha: 0.04),
              ),
            ),
          ),

          // 2. Main content area
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header Logo & Text
                      Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.volunteer_activism,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Selamat Datang di Donasee",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF191C1E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Masuk untuk melanjutkan aksi kebaikanmu',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF424656),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Login Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label Email
                            const Text(
                              'Alamat Email',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF191C1E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Field Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              validator: (s) {
                                if (s == null || s.trim().isEmpty) {
                                  return "Email wajib diisi";
                                }
                                if (!s.contains('@') || !s.contains('.')) {
                                  return "Format email tidak valid";
                                }
                                return null;
                              },
                              decoration: _inputDecor(
                                hint: 'contoh@email.com',
                                prefixIcon: Icons.mail_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Label Password with Lupa Password
                            const Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF191C1E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Field Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              validator: (s) {
                                if (s == null || s.trim().isEmpty) {
                                  return "Password wajib diisi";
                                }
                                if (s.length < 6) {
                                  return "Password minimal 6 karakter";
                                }
                                return null;
                              },
                              decoration: _inputDecor(
                                hint: 'Masukkan password',
                                prefixIcon: Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: const Color(0xFF727687),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Error Box
                            if (_errorMsg != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCEBEB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: errorColor.withOpacity(0.15)),
                                ),
                                child: Text(
                                  _errorMsg!,
                                  style: TextStyle(
                                    color: errorColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: primaryColor.withOpacity(0.6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Text(
                                            'Masuk',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward, size: 18),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const SizedBox(height: 24),

                      // Footer Signup Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              color: Color(0xFF424656),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterChooseScreen(),
                              ),
                            ),
                            child: Text(
                              'Daftar Akun Baru',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecor({required String hint, required IconData prefixIcon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF727687), fontSize: 14, fontWeight: FontWeight.w400),
      prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF727687)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF2F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFC2C6D8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFC2C6D8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0050CB), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 2),
      ),
    );
  }
}
