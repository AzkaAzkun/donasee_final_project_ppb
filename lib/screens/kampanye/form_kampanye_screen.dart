import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/campaign_service.dart';
import '../../services/image_upload_service.dart';
import '../../models/campaign_model.dart';

class FormKampanyeScreen extends StatefulWidget {
  const FormKampanyeScreen({super.key});

  @override
  State<FormKampanyeScreen> createState() => _FormKampanyeScreenState();
}

class _FormKampanyeScreenState extends State<FormKampanyeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _svc = CampaignService();
  final _imgSvc = ImageUploadService();
  final _picker = ImagePicker();

  DateTime? _batasTanggal;
  File? _imageFile;
  bool _loading = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1D9E75),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _batasTanggal = picked);
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          ListTile(
            leading:
                const Icon(Icons.camera_alt, color: Color(0xFF1D9E75)),
            title: const Text('Kamera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading:
                const Icon(Icons.photo_library, color: Color(0xFF1D9E75)),
            title: const Text('Galeri'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source == null) return;
    final xfile = await _picker.pickImage(
        source: source, imageQuality: 75, maxWidth: 1024);
    if (xfile != null) setState(() => _imageFile = File(xfile.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_batasTanggal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih batas tanggal kampanye'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = context.read<AuthService>();
      final user = await auth.getCurrentUserModel();
      if (user == null) return;

      // Upload gambar jika ada
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _imgSvc.uploadCampaignImage(_imageFile!);
      }

      final raw = _targetCtrl.text.replaceAll('.', '').replaceAll(',', '');
      final target = int.tryParse(raw) ?? 0;

      final campaign = CampaignModel(
        id: '',
        judul: _judulCtrl.text.trim(),
        deskripsi: _deskripsiCtrl.text.trim(),
        targetDana: target,
        terkumpul: 0,
        organisasiId: user.uid,
        organisasiNama: user.organisasiNama ?? user.nama,
        batasTanggal: _batasTanggal!,
        status: 'aktif',
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      await _svc.createCampaign(campaign);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kampanye berhasil dibuat!'),
            backgroundColor: Color(0xFF1D9E75),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat kampanye: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _deskripsiCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Kampanye Baru'),
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Picker gambar ──────────────────────────────────────
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF1D9E75).withValues(alpha: 0.4),
                        width: 1.5),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imageFile != null
                      ? Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.5),
                              child: const Icon(Icons.edit,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined,
                                size: 48, color: Color(0xFF1D9E75)),
                            const SizedBox(height: 8),
                            const Text('Tambah Foto Kampanye (opsional)',
                                style: TextStyle(
                                    color: Color(0xFF1D9E75), fontSize: 13)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Judul ──────────────────────────────────────────────
              _label('Judul Kampanye'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _judulCtrl,
                decoration: _inputDec(
                    hint: 'Contoh: Bantu Korban Banjir Bandang',
                    icon: Icons.title),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // ── Deskripsi ──────────────────────────────────────────
              _label('Deskripsi'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 4,
                decoration: _inputDec(
                    hint: 'Jelaskan tujuan dan detail kampanye...',
                    icon: Icons.description,
                    prefixPadding: const EdgeInsets.only(bottom: 60)),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Deskripsi wajib diisi'
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Target Dana ────────────────────────────────────────
              _label('Target Dana (Rupiah)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _targetCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDec(
                    hint: '5000000',
                    icon: Icons.monetization_on,
                    prefix: 'Rp '),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Target dana wajib diisi';
                  final val = int.tryParse(
                          v.replaceAll('.', '').replaceAll(',', '')) ??
                      0;
                  if (val <= 0) return 'Target dana harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Batas Tanggal ──────────────────────────────────────
              _label('Batas Tanggal'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today,
                        color: Color(0xFF1D9E75)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _batasTanggal != null
                            ? dateFmt.format(_batasTanggal!)
                            : 'Pilih batas tanggal',
                        style: TextStyle(
                          fontSize: 15,
                          color: _batasTanggal != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ]),
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Buat Kampanye',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333)));

  InputDecoration _inputDec({
    required String hint,
    required IconData icon,
    String? prefix,
    EdgeInsetsGeometry? prefixPadding,
  }) =>
      InputDecoration(
        hintText: hint,
        prefixText: prefix,
        prefixIcon: prefixPadding != null
            ? Padding(padding: prefixPadding, child: Icon(icon, color: const Color(0xFF1D9E75)))
            : Icon(icon, color: const Color(0xFF1D9E75)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2),
        ),
      );
}
