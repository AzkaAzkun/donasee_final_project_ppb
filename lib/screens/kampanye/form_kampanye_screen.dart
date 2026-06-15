import 'dart:io';
import 'package:flutter/foundation.dart';
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
  Uint8List? _imageBytes;
  String? _imageExt;
  bool _loading = false;
  bool _agreed = false;
  String _selectedKategori = 'Pendidikan';
  final List<String> _kategoriList = ['Pendidikan', 'Pangan', 'Renovasi', 'Kesehatan', 'Bencana', 'Lainnya'];

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
              primary: Color(0xFF0050CB), // #0050cb (Compassion Blue)
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
            leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0050CB)),
            title: const Text('Kamera', style: TextStyle(fontFamily: 'Inter')),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF0050CB)),
            title: const Text('Galeri', style: TextStyle(fontFamily: 'Inter')),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (source == null) return;
    final xfile = await _picker.pickImage(
        source: source, imageQuality: 75, maxWidth: 1024);
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      String ext = 'jpg';
      if (xfile.name.contains('.')) {
        ext = xfile.name.split('.').last.toLowerCase();
      }
      setState(() {
        _imageBytes = bytes;
        _imageExt = ext;
        if (!kIsWeb) {
          _imageFile = File(xfile.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_batasTanggal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih batas tanggal kampanye'),
          backgroundColor: Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui pernyataan tanggung jawab dana'),
          backgroundColor: Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = context.read<AuthService>();
      final user = await auth.getCurrentUserModel();
      if (user == null) return;

      String? imageUrl;
      if (_imageBytes != null) {
        if (kIsWeb) {
          imageUrl = await _imgSvc.uploadCampaignImageBytes(_imageBytes!, _imageExt ?? 'jpg');
        } else if (_imageFile != null) {
          imageUrl = await _imgSvc.uploadCampaignImage(_imageFile!);
        }
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
        kategori: _selectedKategori,
      );

      await _svc.createCampaign(campaign);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kampanye berhasil dibuat!'),
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
            content: Text('Gagal membuat kampanye: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
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
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FB),
        elevation: 0.5,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0050CB)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buat Kampanye Baru',
          style: TextStyle(
            color: Color(0xFF0050CB),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Lexend',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF424656)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Image Picker Container ────────────────────────
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: _imageBytes != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.memory(
                                      _imageBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                                        child: const Icon(Icons.edit, size: 18, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : CustomPaint(
                                painter: DashedRectPainter(
                                  color: const Color(0xFF0050CB).withValues(alpha: 0.3),
                                  gap: 6,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6DF5E1).withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.add_photo_alternate_rounded,
                                        size: 48,
                                        color: Color(0xFF0050CB),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Tambah Foto Kampanye (opsional)',
                                        style: TextStyle(
                                          color: Color(0xFF0050CB),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Format: JPG, PNG, WEBP (Maks. 5MB)',
                                        style: TextStyle(
                                          color: Color(0xFF727687),
                                          fontSize: 11,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Judul ──────────────────────────────────────────
                    _label('Judul Kampanye'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _judulCtrl,
                      style: const TextStyle(fontSize: 15, fontFamily: 'Inter'),
                      decoration: _inputDec(
                        hint: 'Contoh: Bantu Korban Banjir Bandang',
                        icon: Icons.title_rounded,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
                    ),
                    const SizedBox(height: 20),

                    // ── Kategori & Target Row ──────────────────────────
                    _label('Kategori Kampanye'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedKategori,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF191C1E), fontFamily: 'Inter'),
                      items: _kategoriList
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedKategori = val);
                      },
                      decoration: _inputDec(
                        hint: 'Pilih kategori',
                        icon: Icons.category_rounded,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _label('Target Dana (Rupiah)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _targetCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 15, fontFamily: 'Inter'),
                      decoration: _inputDec(
                        hint: '5000000',
                        icon: Icons.payments_rounded,
                        prefix: 'Rp ',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Target dana wajib diisi';
                        final val = int.tryParse(v) ?? 0;
                        if (val <= 0) return 'Target dana harus lebih dari 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Deskripsi ──────────────────────────────────────
                    _label('Deskripsi'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _deskripsiCtrl,
                      maxLines: 6,
                      style: const TextStyle(fontSize: 15, fontFamily: 'Inter'),
                      decoration: _inputDec(
                        hint: 'Jelaskan tujuan dan detail kampanye secara rinci...',
                        icon: Icons.description_rounded,
                        alignLabel: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Deskripsi wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // ── Batas Tanggal ──────────────────────────────────
                    _label('Batas Tanggal'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFC2C6D8)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: Color(0xFF424656), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _batasTanggal != null
                                    ? dateFmt.format(_batasTanggal!)
                                    : 'Pilih batas tanggal',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'Inter',
                                  color: _batasTanggal != null
                                      ? const Color(0xFF191C1E)
                                      : const Color(0xFF727687),
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF727687)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Agreement Checkbox ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F6), // bg-surface-container-low
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC2C6D8).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreed,
                            activeColor: const Color(0xFF0050CB),
                            onChanged: (val) {
                              if (val != null) setState(() => _agreed = val);
                            },
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Saya menyatakan bahwa data kampanye ini adalah benar dan saya bertanggung jawab penuh atas penggunaan dana yang terkumpul.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF424656), // text-on-surface-variant
                                fontFamily: 'Inter',
                                height: 1.5,
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

          // ── Persistent Bottom Action Bar ────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFC2C6D8).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0050CB)))
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0050CB), // bg-primary
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999), // rounded-full
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                      label: const Text(
                        'Terbitkan Kampanye',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF191C1E),
            fontFamily: 'Inter',
          ),
        ),
      );

  InputDecoration _inputDec({
    required String hint,
    required IconData icon,
    String? prefix,
    bool alignLabel = false,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF727687), fontSize: 15),
        prefixText: prefix,
        prefixStyle: const TextStyle(color: Color(0xFF191C1E), fontSize: 15, fontWeight: FontWeight.bold),
        prefixIcon: Padding(
          padding: alignLabel ? const EdgeInsets.only(bottom: 110) : EdgeInsets.zero,
          child: Icon(icon, color: const Color(0xFF424656), size: 20),
        ),
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFC2C6D8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0050CB), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 2),
        ),
      );
}

// Custom Painter for Dashed Rounded Rectangle
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(24),
      ));

    final dashWidth = gap;
    final dashSpace = gap;
    double distance = 0.0;

    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final len = dashWidth;
        if (distance + len > pathMetric.length) {
          canvas.drawPath(
            pathMetric.extractPath(distance, pathMetric.length),
            paint,
          );
        } else {
          canvas.drawPath(
            pathMetric.extractPath(distance, distance + len),
            paint,
          );
        }
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
