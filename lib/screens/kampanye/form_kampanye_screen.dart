import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/campaign_service.dart';
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

  DateTime? _batasTanggal;
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
    if (picked != null) {
      setState(() => _batasTanggal = picked);
    }
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
              // Header icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    size: 48,
                    color: Color(0xFF1D9E75),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Judul
              const Text('Judul Kampanye',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _judulCtrl,
                decoration: InputDecoration(
                  hintText: 'Contoh: Bantu Korban Banjir Bandang',
                  prefixIcon:
                      const Icon(Icons.title, color: Color(0xFF1D9E75)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF1D9E75), width: 2),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              // Deskripsi
              const Text('Deskripsi',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Jelaskan tujuan dan detail kampanye...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child:
                        Icon(Icons.description, color: Color(0xFF1D9E75)),
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

              // Target Dana
              const Text('Target Dana (Rupiah)',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _targetCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '5000000',
                  prefixIcon: const Icon(Icons.monetization_on,
                      color: Color(0xFF1D9E75)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF1D9E75), width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Target dana wajib diisi';
                  final raw = v.replaceAll('.', '').replaceAll(',', '');
                  final val = int.tryParse(raw) ?? 0;
                  if (val <= 0) return 'Target dana harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Batas Tanggal
              const Text('Batas Tanggal',
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
                    ],
                  ),
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
}
