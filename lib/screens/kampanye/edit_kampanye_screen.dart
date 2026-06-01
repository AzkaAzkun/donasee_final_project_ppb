import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/campaign_service.dart';
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

  late DateTime _batasTanggal;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _deskripsiCtrl = TextEditingController(text: widget.campaign.deskripsi);
    _batasTanggal = widget.campaign.batasTanggal;
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
      await _svc.updateCampaign(widget.campaign.id, {
        'deskripsi': _deskripsiCtrl.text.trim(),
        'batasTanggal': Timestamp.fromDate(_batasTanggal),
      });

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
}
