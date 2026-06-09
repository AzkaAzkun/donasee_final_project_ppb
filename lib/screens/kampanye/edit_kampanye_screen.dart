import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/campaign_service.dart';
import '../../services/image_upload_service.dart';
import '../../models/campaign_model.dart';

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
            leading: const Icon(Icons.camera_alt, color: Color(0xFF1D9E75)),
            title: const Text('Kamera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Color(0xFF1D9E75)),
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
    if (xfile != null) {
      setState(() {
        _newImageFile = File(xfile.path);
        _removeImage = false;
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
        // Hapus gambar lama
        if (widget.campaign.imageUrl != null) {
          await _imgSvc.deleteByUrl(widget.campaign.imageUrl!);
        }
        newImageUrl = null;
      } else if (_newImageFile != null) {
        // Upload gambar baru, hapus yang lama
        if (widget.campaign.imageUrl != null) {
          await _imgSvc.deleteByUrl(widget.campaign.imageUrl!);
        }
        newImageUrl = await _imgSvc.uploadCampaignImage(_newImageFile!);
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
            backgroundColor: Color(0xFF1D9E75),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui kampanye: $e'),
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
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Kampanye'),
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
              // ── Preview / Picker Gambar ────────────────────────────
              _buildImagePicker(),
              const SizedBox(height: 24),

              // Campaign title (read-only info)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kampanye',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(widget.campaign.judul,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(widget.campaign.organisasiNama,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF0F6E56))),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Deskripsi
              const Text('Deskripsi',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Perbarui deskripsi kampanye...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.description, color: Color(0xFF1D9E75)),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF1D9E75), width: 2),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Deskripsi wajib diisi'
                    : null,
              ),
              const SizedBox(height: 20),

              // Batas Tanggal
              const Text('Perpanjang Batas Tanggal',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333))),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Color(0xFF1D9E75)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dateFmt.format(_batasTanggal),
                          style: const TextStyle(
                              fontSize: 15, color: Colors.black87),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              // Info perubahan tanggal
              if (_batasTanggal != widget.campaign.batasTanggal)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Color(0xFF633806)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tanggal sebelumnya: ${dateFmt.format(widget.campaign.batasTanggal)}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF633806)),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Submit button
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
                      : const Text('Simpan Perubahan',
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
  Widget _buildImagePicker() {
    // Prioritas tampilan: gambar baru > gambar lama > placeholder
    Widget content;
    final hasExisting =
        widget.campaign.imageUrl != null && !_removeImage && _newImageFile == null;
    final hasNew = _newImageFile != null;

    if (hasNew) {
      content = Stack(fit: StackFit.expand, children: [
        Image.file(_newImageFile!, fit: BoxFit.cover),
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
        Image.network(widget.campaign.imageUrl!, fit: BoxFit.cover),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _imgActionBtn(Icons.edit, _pickImage),
              const SizedBox(width: 6),
              _imgActionBtn(Icons.delete,
                  () => setState(() => _removeImage = true), color: Colors.red),
            ]),
          ),
        ),
      ]);
    } else {
      content = GestureDetector(
        onTap: _pickImage,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add_photo_alternate_outlined,
              size: 48, color: Color(0xFF1D9E75)),
          const SizedBox(height: 8),
          Text(
            _removeImage ? 'Gambar dihapus. Tap untuk tambah baru' : 'Tambah Foto (opsional)',
            style: const TextStyle(color: Color(0xFF1D9E75), fontSize: 13),
          ),
        ]),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: GestureDetector(
        onTap: (!hasExisting && !hasNew) ? _pickImage : null,
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE1F5EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.4),
                width: 1.5),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _imgActionBtn(IconData icon, VoidCallback onTap,
      {Color color = Colors.white}) =>
      GestureDetector(
        onTap: onTap,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          child: Icon(icon, size: 16, color: color),
        ),
      );
}
