import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../services/image_upload_service.dart';

class DetailProfilScreen extends StatefulWidget {
  final UserModel user;
  const DetailProfilScreen({required this.user, super.key});

  @override
  State<DetailProfilScreen> createState() => _DetailProfilScreenState();
}

class _DetailProfilScreenState extends State<DetailProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _orgNamaController;
  late final TextEditingController _orgAlamatController;
  late final TextEditingController _orgTeleponController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.user.nama);
    _orgNamaController = TextEditingController(
      text: widget.user.organisasiNama ?? '',
    );
    _orgAlamatController = TextEditingController(
      text: widget.user.organisasiAlamat ?? '',
    );
    _orgTeleponController = TextEditingController(
      text: widget.user.organisasiTelepon ?? '',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _orgNamaController.dispose();
    _orgAlamatController.dispose();
    _orgTeleponController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final updates = {
        'nama': _namaController.text.trim(),
        if (widget.user.isAdmin) ...{
          'organisasiNama': _orgNamaController.text.trim(),
          'organisasiAlamat': _orgAlamatController.text.trim(),
          'organisasiTelepon': _orgTeleponController.text.trim(),
        },
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: Color(0xFF00682C),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka tautan dokumen.'),
            backgroundColor: Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _updateProfilePicture(BuildContext context, String uid) async {
    try {
      final picker = ImagePicker();
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF0050CB),
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(fontFamily: 'Inter'),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0050CB)),
                title: const Text(
                  'Ambil Foto Baru',
                  style: TextStyle(fontFamily: 'Inter'),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        );
      }

      final file = File(pickedFile.path);
      final photoUrl = await ImageUploadService().uploadProfilePicture(
        uid: uid,
        imageFile: file,
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fotoUrl': photoUrl,
      });

      if (context.mounted) {
        Navigator.pop(context); // pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Color(0xFF00682C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah foto profil: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        UserModel currentUser = widget.user;
        if (snapshot.hasData && snapshot.data!.exists) {
          currentUser = UserModel.fromFirestore(
            snapshot.data!.data()!,
            widget.user.uid,
          );
        }

        final dateStr = DateFormat(
          'dd MMMM yyyy',
          'id_ID',
        ).format(currentUser.createdAt);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FB),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F9FB),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF191C1E)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Profil',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191C1E),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE0E3E5).withValues(alpha: 0.5),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDAE1FF),
                                shape: BoxShape.circle,
                              ),
                              child:
                                  currentUser.fotoUrl != null &&
                                      currentUser.fotoUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: Image.network(
                                        currentUser.fotoUrl!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Center(
                                                  child: Text(
                                                    currentUser.nama.isNotEmpty
                                                        ? currentUser.nama[0]
                                                              .toUpperCase()
                                                        : 'U',
                                                    style: const TextStyle(
                                                      color: Color(0xFF001849),
                                                      fontFamily: 'Lexend',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 32,
                                                    ),
                                                  ),
                                                ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        currentUser.nama.isNotEmpty
                                            ? currentUser.nama[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Color(0xFF001849),
                                          fontFamily: 'Lexend',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 32,
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _updateProfilePicture(
                                  context,
                                  currentUser.uid,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0050CB),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentUser.nama,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentUser.isAdmin
                              ? 'Admin Panti Asuhan'
                              : 'Donatur Dermawan',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFF006B5F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SECTION: DETAIL DATA
                  const Text(
                    'INFORMASI PENGGUNA',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF727687),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE0E3E5).withValues(alpha: 0.5),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildReadOnlyField(
                          icon: Icons.email_outlined,
                          label: 'Alamat Email',
                          value: currentUser.email,
                        ),
                        const Divider(height: 24, color: Color(0xFFECEEF0)),

                        _buildReadOnlyField(
                          icon: Icons.calendar_month_outlined,
                          label: 'Bergabung Sejak',
                          value: dateStr,
                        ),
                        const Divider(height: 24, color: Color(0xFFECEEF0)),
                        _buildInputField(
                          controller: _namaController,
                          icon: Icons.person_outline,
                          label: 'Nama Lengkap',
                          hint: 'Masukkan nama lengkap',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nama tidak boleh kosong'
                              : null,
                        ),

                        if (widget.user.isAdmin) ...[
                          const Divider(height: 24, color: Color(0xFFECEEF0)),
                          // EDITABLE: NAMA ORGANISASI
                          _buildInputField(
                            controller: _orgNamaController,
                            icon: Icons.corporate_fare_outlined,
                            label: 'Nama Panti / Organisasi',
                            hint: 'Masukkan nama panti asuhan',
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Nama organisasi tidak boleh kosong'
                                : null,
                          ),
                          const Divider(height: 24, color: Color(0xFFECEEF0)),
                          // EDITABLE: ALAMAT ORGANISASI
                          _buildInputField(
                            controller: _orgAlamatController,
                            icon: Icons.place_outlined,
                            label: 'Alamat Organisasi',
                            hint: 'Masukkan alamat organisasi lengkap',
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Alamat tidak boleh kosong'
                                : null,
                          ),
                          const Divider(height: 24, color: Color(0xFFECEEF0)),
                          // EDITABLE: TELEPON ORGANISASI
                          _buildInputField(
                            controller: _orgTeleponController,
                            icon: Icons.phone_outlined,
                            label: 'Nomor Telepon Organisasi',
                            hint: 'Masukkan nomor telepon panti',
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Nomor telepon tidak boleh kosong'
                                : null,
                          ),
                          if (widget.user.suratResmiUrl != null) ...[
                            const Divider(height: 24, color: Color(0xFFECEEF0)),
                            const Text(
                              'Dokumen Verifikasi',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0xFF727687),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _launchUrl(widget.user.suratResmiUrl!),
                              icon: const Icon(
                                Icons.description,
                                color: Color(0xFF0050CB),
                              ),
                              label: const Text(
                                'Lihat Surat Resmi Resmi',
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0050CB),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFDAE1FF),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // SAVE BUTTON
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0050CB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadOnlyField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF727687), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF727687),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF191C1E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Color(0xFF727687),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: Color(0xFF191C1E),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFC2C6D8)),
            prefixIcon: Icon(icon, color: const Color(0xFF0050CB), size: 20),
            filled: true,
            fillColor: const Color(0xFFF7F9FB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E3E5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF0050CB),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFBA1A1A),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
