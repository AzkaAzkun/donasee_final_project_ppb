import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class RegisterDonaturScreen extends StatefulWidget {
  const RegisterDonaturScreen({super.key});

  @override
  State<RegisterDonaturScreen> createState() => _RegisterDonaturScreenState();
}

class _RegisterDonaturScreenState extends State<RegisterDonaturScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  String? _errorMsg;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passCtrl.text != _confirmPassCtrl.text) {
      setState(() => _errorMsg = 'Konfirmasi password tidak cocok');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final auth = context.read<AuthService>();
      await auth.registerDonatur(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        nama: _namaCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _errorMsg = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0050CB);
    const errorColor = Color(0xFFBA1A1A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Ambient Glow Top Right
          Positioned(
            right: -120,
            top: -120,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Ambient Glow Bottom Left
          Positioned(
            left: -120,
            bottom: -120,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF006B5F).withValues(alpha: 0.05),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Custom Navigation Header
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
                  child: Row(
                    children: [
                      // Circular Back Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: Color(0xFF475569),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 400),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Header Section
                                    Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                            border: Border.all(
                                              color: const Color(0xFFC2C6D8).withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.volunteer_activism,
                                            color: primaryColor,
                                            size: 40,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "Donasee",
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          "Daftar Donatur",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF424656),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          "Buat akun baru untuk mulai berbagi kebaikan",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF727687),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),

                                    Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Label Nama
                                          const Text(
                                            'Nama Lengkap',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF424656),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _namaCtrl,
                                            validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                                            decoration: _inputDecor(
                                              hint: 'Masukkan nama lengkap',
                                              prefixIcon: Icons.person_rounded,
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Label Email
                                          const Text(
                                            'Alamat Email',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF424656),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _emailCtrl,
                                            keyboardType: TextInputType.emailAddress,
                                            validator: (v) {
                                              if (v == null || v.isEmpty) return 'Email wajib diisi';
                                              if (!v.contains('@') || !v.contains('.')) return 'Format email tidak valid';
                                              return null;
                                            },
                                            decoration: _inputDecor(
                                              hint: 'contoh@email.com',
                                              prefixIcon: Icons.email_rounded,
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Label Password
                                          const Text(
                                            'Password',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF424656),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _passCtrl,
                                            obscureText: _obscurePass,
                                            validator: (v) {
                                              if (v == null || v.isEmpty) return 'Password wajib diisi';
                                              if (v.length < 6) return 'Password minimal 6 karakter';
                                              return null;
                                            },
                                            decoration: _inputDecor(
                                              hint: 'Masukkan password',
                                              prefixIcon: Icons.lock_rounded,
                                              suffix: IconButton(
                                                icon: Icon(
                                                  _obscurePass ? Icons.visibility : Icons.visibility_off,
                                                  color: const Color(0xFF727687),
                                                  size: 20,
                                                ),
                                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Label Konfirmasi Password
                                          const Text(
                                            'Ulangi Password',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF424656),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _confirmPassCtrl,
                                            obscureText: _obscureConfirmPass,
                                            validator: (v) {
                                              if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
                                              return null;
                                            },
                                            decoration: _inputDecor(
                                              hint: 'Ulangi password',
                                              prefixIcon: Icons.lock_rounded,
                                              suffix: IconButton(
                                                icon: Icon(
                                                  _obscureConfirmPass ? Icons.visibility : Icons.visibility_off,
                                                  color: const Color(0xFF727687),
                                                  size: 20,
                                                ),
                                                onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),

                                          // Error Message
                                          if (_errorMsg != null) ...[
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFCEBEB),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: errorColor.withValues(alpha: 0.15)),
                                              ),
                                              child: Text(
                                                _errorMsg!,
                                                style: const TextStyle(
                                                  color: errorColor,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                          ],

                                          // Register Button
                                          SizedBox(
                                            width: double.infinity,
                                            height: 52,
                                            child: ElevatedButton(
                                              onPressed: _loading ? null : _register,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryColor,
                                                foregroundColor: Colors.white,
                                                disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: _loading
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
                                                          'Daftar Sekarang',
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

                                    // Footer Link
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Sudah punya akun? ',
                                          style: TextStyle(
                                            color: Color(0xFF424656),
                                            fontSize: 14,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => Navigator.pop(context),
                                          child: const Text(
                                            'Masuk Sekarang',
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
                      );
                    },
                  ),
                ),
              ],
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
      fillColor: Colors.white,
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
