import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/campaign_service.dart';
import '../../services/image_upload_service.dart';
import '../../models/campaign_model.dart';
import 'form_kampanye_screen.dart'; // import to reuse DashedRectPainter

class EditKampanyeScreen extends StatefulWidget {
  final CampaignModel campaign;
  const EditKampanyeScreen({required this.campaign, super.key});

  @override
  State<EditKampanyeScreen> createState() => _EditKampanyeScreenState();
}

class _EditKampanyeScreenState extends State<EditKampanyeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _deskripsiCtrl;
  final _svc = CampaignService();
  final _imgSvc = ImageUploadService();
  final _picker = ImagePicker();

  late DateTime _batasTanggal;
  File? _newImageFile;       // gambar baru yang dipilih
  Uint8List? _newImageBytes;
  String? _newImageExt;
  bool _removeImage = false; // flag hapus gambar saat ini
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _deskripsiCtrl = TextEditingController(text: widget.campaign.deskripsi);
    _batasTanggal = widget.campaign.batasTanggal;
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
              width: 40, height: 4,
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
         _newImageBytes = bytes;
         _newImageExt = ext;
         _removeImage = false;
         if (!kIsWeb) {
           _newImageFile = File(xfile.path);
         }
       });
     }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _batasTanggal.isAfter(now) ? _batasTanggal : now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0050CB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _batasTanggal = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String? newImageUrl = widget.campaign.imageUrl;

      if (_removeImage) {
        if (widget.campaign.imageUrl != null) {
          await _imgSvc.deleteByUrl(widget.campaign.imageUrl!);
        }
        newImageUrl = null;
      } else if (_newImageBytes != null) {
        if (widget.campaign.imageUrl != null) {
          await _imgSvc.deleteByUrl(widget.campaign.imageUrl!);
        }
        if (kIsWeb) {
          newImageUrl = await _imgSvc.uploadCampaignImageBytes(_newImageBytes!, _newImageExt ?? 'jpg');
        } else if (_newImageFile != null) {
          newImageUrl = await _imgSvc.uploadCampaignImage(_newImageFile!);
        }
      }

      final fields = <String, dynamic>{
        'deskripsi': _deskripsiCtrl.text.trim(),
        'batasTanggal': Timestamp.fromDate(_batasTanggal),
        'imageUrl': newImageUrl,
      };
      if (newImageUrl == null) fields.remove('imageUrl');

      await _svc.updateCampaign(widget.campaign.id, fields);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kampanye berhasil diperbarui!'),
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
            content: Text('Gagal memperbarui kampanye: $e'),
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
    _deskripsiCtrl.dispose();
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
          'Edit Kampanye',
          style: TextStyle(
            color: Color(0xFF0050CB),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Lexend',
          ),
        ),
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
                    // Preview / Picker Gambar
                    _buildImagePicker(),
                    const SizedBox(height: 24),

                    // Campaign title (read-only info card)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFC2C6D8).withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'KAMPANYE',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF727687),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.campaign.judul,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF191C1E),
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.campaign.organisasiNama,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF006B5F),
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Deskripsi
                    _label('Deskripsi'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _deskripsiCtrl,
                      maxLines: 6,
                      style: const TextStyle(fontSize: 15, fontFamily: 'Inter'),
                      decoration: _inputDec(
                        hint: 'Perbarui deskripsi kampanye...',
                        icon: Icons.description_rounded,
                        alignLabel: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Deskripsi wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Batas Tanggal
                    _label('Perpanjang Batas Tanggal'),
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
                                dateFmt.format(_batasTanggal),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'Inter',
                                  color: Color(0xFF191C1E),
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF727687)),
                          ],
                        ),
                      ),
                    ),

                    // Info perubahan tanggal
                    if (_batasTanggal != widget.campaign.batasTanggal)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDAD6).withValues(alpha: 0.2), // bg-error-container/20
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFDAD6).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFBA1A1A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Batas tanggal sebelumnya: ${dateFmt.format(widget.campaign.batasTanggal)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFBA1A1A),
                                  fontFamily: 'Inter',
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

          // Persistent Bottom Action Bar
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
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                      label: const Text(
                        'Simpan Perubahan',
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

  Widget _buildImagePicker() {
    final hasExisting = widget.campaign.imageUrl != null && !_removeImage && _newImageBytes == null;
    final hasNew = _newImageBytes != null;

    Widget content;
    if (hasNew) {
      content = Stack(fit: StackFit.expand, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.memory(_newImageBytes!, fit: BoxFit.cover),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _imgActionBtn(Icons.edit, _pickImage),
          ),
        ),
      ]);
    } else if (hasExisting) {
      content = Stack(fit: StackFit.expand, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.network(widget.campaign.imageUrl!, fit: BoxFit.cover),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _imgActionBtn(Icons.edit, _pickImage),
              const SizedBox(width: 8),
              _imgActionBtn(Icons.delete, () => setState(() => _removeImage = true), color: Colors.red),
            ]),
          ),
        ),
      ]);
    } else {
      content = CustomPaint(
        painter: DashedRectPainter(
          color: const Color(0xFF0050CB).withValues(alpha: 0.3),
          gap: 6,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF6DF5E1).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.add_photo_alternate_outlined, size: 48, color: Color(0xFF0050CB)),
            const SizedBox(height: 8),
            Text(
              _removeImage ? 'Gambar dihapus. Tap untuk tambah baru' : 'Tambah Foto (opsional)',
              style: const TextStyle(color: Color(0xFF0050CB), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ]),
        ),
      );
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        child: content,
      ),
    );
  }

  Widget _imgActionBtn(IconData icon, VoidCallback onTap, {Color color = Colors.white}) =>
      GestureDetector(
        onTap: onTap,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          child: Icon(icon, size: 16, color: color),
        ),
      );

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
