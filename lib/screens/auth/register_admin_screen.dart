import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/auth_service.dart';

class RegisterAdminScreen extends StatefulWidget {
  const RegisterAdminScreen({super.key});

  @override
  State<RegisterAdminScreen> createState() => _RegisterAdminScreenState();
}

class _RegisterAdminScreenState extends State<RegisterAdminScreen> {
  final _formKey = GlobalKey<FormState>();

  // Section 1: Akun
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _namaAdminCtrl = TextEditingController();

  // Section 2: Organisasi
  final _orgNamaCtrl = TextEditingController();
  final _orgAlamatCtrl = TextEditingController();
  final _orgTelpCtrl = TextEditingController();

  // Section 3: Dokumen
  PlatformFile? _pickedFile;
  Uint8List? _pdfBytes;
  File? _pdfFile;

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  String? _errorMsg;

  Future<void> _pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
          if (kIsWeb) {
            _pdfBytes = _pickedFile!.bytes;
          } else {
            if (_pickedFile!.path != null) {
              _pdfFile = File(_pickedFile!.path!);
              _pdfBytes = _pdfFile!.readAsBytesSync();
            } else {
              _pdfBytes = _pickedFile!.bytes;
            }
          }
          _errorMsg = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih file: $e')),
        );
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passCtrl.text != _confirmPassCtrl.text) {
      setState(() => _errorMsg = 'Konfirmasi password tidak cocok');
      return;
    }

    if (_pdfBytes == null) {
      setState(() => _errorMsg = 'Surat Resmi dalam format PDF wajib diunggah');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final auth = context.read<AuthService>();
      await auth.registerAdminPanti(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        namaAdmin: _namaAdminCtrl.text.trim(),
        organisasiNama: _orgNamaCtrl.text.trim(),
        organisasiAlamat: _orgAlamatCtrl.text.trim(),
        organisasiTelepon: _orgTelpCtrl.text.trim(),
        suratResmiBytes: _pdfBytes,
        suratResmiFile: _pdfFile,
      );
      if (mounted) {
        // Kembali ke wrapper untuk memicu loading dan pending screen
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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _namaAdminCtrl.dispose();
    _orgNamaCtrl.dispose();
    _orgAlamatCtrl.dispose();
    _orgTelpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0050CB); // Blue theme for admin
    const errorColor = Color(0xFFBA1A1A);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
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
                            color: Colors.black.withOpacity(0.05),
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
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 440),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: Form(
                            key: _formKey,
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
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.volunteer_activism,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Donasee",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Pendaftaran Panti Asuhan",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF191C1E),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      "Isi informasi akun dan panti asuhan Anda secara lengkap",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF727687),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),

                                // SECTION 1: Detail Akun
                                _buildSectionHeader("Detail Akun"),
                                const SizedBox(height: 16),

                                _buildLabel("Nama Lengkap Admin"),
                                TextFormField(
                                  controller: _namaAdminCtrl,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Nama admin wajib diisi' : null,
                                  decoration: _inputDecor(hint: 'Masukkan nama lengkap Anda', icon: Icons.person_outline_rounded),
                                ),
                                const SizedBox(height: 16),

                                _buildLabel("Alamat Email"),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Email wajib diisi';
                                    if (!v.contains('@') || !v.contains('.')) return 'Format email tidak valid';
                                    return null;
                                  },
                                  decoration: _inputDecor(hint: 'contoh@email.com', icon: Icons.mail_outline_rounded),
                                ),
                                const SizedBox(height: 16),

                                _buildLabel("Password"),
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
                                    icon: Icons.lock_outline_rounded,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: const Color(0xFF727687),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                _buildLabel("Konfirmasi Password"),
                                TextFormField(
                                  controller: _confirmPassCtrl,
                                  obscureText: _obscureConfirmPass,
                                  validator: (v) => v == null || v.isEmpty ? 'Konfirmasi password wajib diisi' : null,
                                  decoration: _inputDecor(
                                    hint: 'Ulangi password',
                                    icon: Icons.lock_outline_rounded,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: const Color(0xFF727687),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // SECTION 2: Detail Panti Asuhan
                                _buildSectionHeader("Detail Panti Asuhan"),
                                const SizedBox(height: 16),

                                _buildLabel("Nama Panti Asuhan"),
                                TextFormField(
                                  controller: _orgNamaCtrl,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Nama organisasi wajib diisi' : null,
                                  decoration: _inputDecor(hint: 'Masukkan nama resmi panti asuhan', icon: Icons.corporate_fare_rounded),
                                ),
                                const SizedBox(height: 16),

                                _buildLabel("Alamat Lengkap Panti"),
                                TextFormField(
                                  controller: _orgAlamatCtrl,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Alamat panti wajib diisi' : null,
                                  maxLines: 2,
                                  decoration: _inputDecor(hint: 'Jalan, RT/RW, Kelurahan, Kecamatan, Kota/Kabupaten', icon: Icons.location_on_outlined),
                                ),
                                const SizedBox(height: 16),

                                _buildLabel("Nomor Telepon Panti"),
                                TextFormField(
                                  controller: _orgTelpCtrl,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Nomor telepon wajib diisi' : null,
                                  decoration: _inputDecor(hint: 'Contoh: 081234567890 atau (021) 123456', icon: Icons.phone_outlined),
                                ),
                                const SizedBox(height: 32),

                                // SECTION 3: Dokumen Legalitas
                                _buildSectionHeader("Dokumen Legalitas"),
                                const SizedBox(height: 16),

                                // PDF picker card
                                GestureDetector(
                                  onTap: _pickPDF,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _pickedFile != null ? const Color(0xFF0050CB) : const Color(0xFFC2C6D8),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          _pickedFile != null ? Icons.picture_as_pdf_rounded : Icons.cloud_upload_outlined,
                                          size: 48,
                                          color: _pickedFile != null ? const Color(0xFF0050CB) : const Color(0xFF727687),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _pickedFile != null ? _pickedFile!.name : "Unggah Surat Resmi Panti Asuhan (PDF)",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _pickedFile != null ? const Color(0xFF0050CB) : const Color(0xFF191C1E),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _pickedFile != null
                                              ? "${(_pickedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB"
                                              : "Klik untuk memilih berkas resmi PDF",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF727687),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Information Box
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFFE082)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Icon(Icons.info_outline_rounded, color: Color(0xFFFFB300), size: 20),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          "Surat resmi legalitas diperlukan untuk proses verifikasi. Akun Anda baru dapat digunakan setelah disetujui oleh Super Admin Donasee.",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF5D4037),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

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
                                      style: const TextStyle(
                                        color: errorColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Register CTA Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: primaryColor.withOpacity(0.6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
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
                                                'Daftar Panti Asuhan',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.chevron_right_rounded, size: 20),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 32),
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF0050CB),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF191C1E),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF191C1E)),
      ),
    );
  }

  InputDecoration _inputDecor({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF727687), fontSize: 14, fontWeight: FontWeight.w400),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF727687)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC2C6D8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC2C6D8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0050CB), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 2),
      ),
    );
  }
}
