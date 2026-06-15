import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:donasee_final_project_ppb/models/allocation_model.dart';
import 'package:donasee_final_project_ppb/models/campaign_model.dart';
import 'package:donasee_final_project_ppb/services/allocation_service.dart';
import 'package:donasee_final_project_ppb/services/auth_service.dart';
import 'package:donasee_final_project_ppb/services/image_upload_service.dart';
import 'package:donasee_final_project_ppb/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../kampanye/form_kampanye_screen.dart';

class FormAlokasiScreen extends StatefulWidget {
  final AllocationModel? allocation;
  final String? preSelectedCampaignId;

  const FormAlokasiScreen({super.key, this.allocation, this.preSelectedCampaignId});

  @override
  State<FormAlokasiScreen> createState() => _FormAlokasiScreenState();
}

class _FormAlokasiScreenState extends State<FormAlokasiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _nominalCtrl = TextEditingController();
  final _service = AllocationService();

  String? _selectedCampaignId;
  String? _selectedCampaignTitle;
  bool _isSubmitting = false;

  // File Upload State
  File? _pickedFile;
  Uint8List? _pickedFileBytes;
  String? _pickedFileName;
  String? _pickedFileExt;
  String? _buktiUrl;
  bool _removeOldBukti = false;

  @override
  void initState() {
    super.initState();
    final allocation = widget.allocation;
    if (allocation != null) {
      _judulCtrl.text = allocation.judulAlokasi;
      _deskripsiCtrl.text = allocation.deskripsi;
      _nominalCtrl.text = allocation.nominal.toString();
      _selectedCampaignId = allocation.kampanyeId;
      _selectedCampaignTitle = allocation.kampanyeJudul;
      _buktiUrl = allocation.buktiAlokasiUrl;
    } else if (widget.preSelectedCampaignId != null) {
      _selectedCampaignId = widget.preSelectedCampaignId;
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _deskripsiCtrl.dispose();
    _nominalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.allocation != null;

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
        title: Text(
          isEdit ? 'Edit Alokasi' : 'Tambah Alokasi',
          style: const TextStyle(
            color: Color(0xFF0050CB),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Lexend',
          ),
        ),
      ),
      body: StreamBuilder<List<CampaignModel>>(
        stream: _campaignStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0050CB)));
          }

          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString());
          }

          final campaigns = _effectiveCampaigns(snapshot.data ?? const []);
          if (_selectedCampaignId != null && _selectedCampaignTitle == null && campaigns.isNotEmpty) {
            final matches = campaigns.where((c) => c.id == _selectedCampaignId).toList();
            if (matches.isNotEmpty) {
              _selectedCampaignTitle = matches.first.judul;
            }
          }

          return AbsorbPointer(
            absorbing: _isSubmitting,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Kampanye Terkait ──
                          _label('Kampanye Terkait'),
                          const SizedBox(height: 8),
                          _buildCampaignField(campaigns),
                          const SizedBox(height: 20),

                          // ── Judul Alokasi ──
                          _label('Judul Alokasi'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _judulCtrl,
                            textInputAction: TextInputAction.next,
                            style: const TextStyle(fontSize: 15, fontFamily: 'Inter'),
                            decoration: _inputDec(
                              hint: 'Contoh: Pembelian Sembako Bulan Juni',
                              icon: Icons.title_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Judul tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // ── Nominal Alokasi ──
                          _label('Nominal Alokasi (Rupiah)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nominalCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(fontSize: 15, fontFamily: 'Inter'),
                            decoration: _inputDec(
                              hint: 'Contoh: 1500000',
                              icon: Icons.payments_rounded,
                              prefix: 'Rp ',
                            ),
                            validator: (value) {
                              final parsed = int.tryParse(value ?? '');
                              if (parsed == null || parsed <= 0) {
                                return 'Nominal harus angka dan lebih dari 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // ── Deskripsi Alokasi ──
                          _label('Deskripsi'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _deskripsiCtrl,
                            minLines: 4,
                            maxLines: 6,
                            style: const TextStyle(fontSize: 15, fontFamily: 'Inter'),
                            decoration: _inputDec(
                              hint: 'Jelaskan secara rinci penggunaan dana alokasi ini...',
                              icon: Icons.description_rounded,
                              alignLabel: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Deskripsi tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // ── Bukti Upload ──
                          _buildBuktiUploadField(),
                        ],
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
                      child: SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : () => _submit(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0050CB), // bg-primary
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            elevation: 2,
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle_rounded, size: 20),
                          label: Text(
                            _isSubmitting
                                ? 'Memproses...'
                                : (isEdit ? 'Simpan Perubahan' : 'Simpan Alokasi'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBuktiUploadField() {
    final hasPicked = _pickedFile != null || _pickedFileBytes != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Bukti Alokasi (PDF atau Gambar)'),
        const SizedBox(height: 8),
        if (hasPicked)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC2C6D8).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(
                  (_pickedFileName ?? '').toLowerCase().endsWith('.pdf')
                      ? Icons.picture_as_pdf_rounded
                      : Icons.image_rounded,
                  color: const Color(0xFF0050CB),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _pickedFileName ?? 'Bukti Alokasi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFBA1A1A)),
                  onPressed: () {
                    setState(() {
                      _pickedFile = null;
                      _pickedFileBytes = null;
                      _pickedFileName = null;
                      _pickedFileExt = null;
                    });
                  },
                ),
              ],
            ),
          )
        else if (_buktiUrl != null && !_removeOldBukti)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC2C6D8).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(
                  _buktiUrl!.toLowerCase().contains('.pdf')
                      ? Icons.picture_as_pdf_rounded
                      : Icons.image_rounded,
                  color: const Color(0xFF0050CB),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Bukti terunggah',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFBA1A1A)),
                  onPressed: () {
                    setState(() {
                      _removeOldBukti = true;
                    });
                  },
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: _pickFile,
            child: CustomPaint(
              painter: DashedRectPainter(
                color: const Color(0xFF0050CB).withValues(alpha: 0.3),
                gap: 6,
              ),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF6DF5E1).withValues(alpha: 0.05), // bg-secondary-container/5
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.upload_file_rounded, color: Color(0xFF0050CB), size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Pilih PDF atau Gambar Bukti Alokasi',
                        style: TextStyle(color: Color(0xFF0050CB), fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Format: PDF, JPG, PNG (Maks. 5MB)',
                        style: TextStyle(color: Color(0xFF727687), fontSize: 11, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
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

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null) {
        final fileSingle = result.files.single;
        final bytes = fileSingle.bytes;
        final path = fileSingle.path;
        final name = fileSingle.name;
        
        String ext = 'jpg';
        if (name.contains('.')) {
          ext = name.split('.').last.toLowerCase();
        }

        setState(() {
          _pickedFileName = name;
          _pickedFileExt = ext;
          _removeOldBukti = false;
          
          if (kIsWeb) {
            _pickedFileBytes = bytes;
            _pickedFile = null;
          } else {
            if (bytes != null) {
              _pickedFileBytes = bytes;
            }
            if (path != null) {
              _pickedFile = File(path);
            }
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih file: $e')),
      );
    }
  }

  Stream<List<CampaignModel>> _campaignStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('campaigns')
        .where('organisasiId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) {
            final list = snapshot.docs
                .map((doc) => CampaignModel.fromFirestore(doc.data(), doc.id))
                .toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          },
        );
  }

  List<CampaignModel> _effectiveCampaigns(List<CampaignModel> campaigns) {
    final selectedId = _selectedCampaignId;
    if (selectedId == null) return campaigns;
    final hasSelected = campaigns.any((campaign) => campaign.id == selectedId);
    if (hasSelected) return campaigns;
    final fallbackTitle = _selectedCampaignTitle ?? 'Kampanye terpilih';
    return [
      CampaignModel(
        id: selectedId,
        judul: fallbackTitle,
        deskripsi: '',
        targetDana: 0,
        terkumpul: 0,
        organisasiId: '',
        organisasiNama: '',
        batasTanggal: DateTime.now(),
        status: 'aktif',
        createdAt: DateTime.now(),
      ),
      ...campaigns,
    ];
  }

  Widget _buildCampaignField(List<CampaignModel> campaigns) {
    final items = campaigns
        .map(
          (campaign) => DropdownMenuItem<String>(
            value: campaign.id,
            child: Text(
              campaign.organisasiNama.isEmpty
                  ? campaign.judul
                  : '${campaign.judul} - ${campaign.organisasiNama}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList();

    return DropdownButtonFormField<String>(
      initialValue: _selectedCampaignId,
      items: items,
      isExpanded: true,
      style: const TextStyle(fontSize: 15, color: Color(0xFF191C1E), fontFamily: 'Inter'),
      decoration: _inputDec(
        hint: 'Pilih kampanye',
        icon: Icons.campaign_rounded,
      ),
      hint: const Text('Pilih kampanye'),
      onChanged: (value) {
        final selected = campaigns
            .where((campaign) => campaign.id == value)
            .toList();
        setState(() {
          _selectedCampaignId = value;
          _selectedCampaignTitle = selected.isEmpty
              ? null
              : selected.first.judul;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Kampanye harus dipilih';
        }
        return null;
      },
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final auth = context.read<AuthService>();
    final currentUser = await auth.getCurrentUserModel();
    if (currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Data admin tidak ditemukan'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
      return;
    }

    final campaignId = _selectedCampaignId;
    final campaignTitle = _selectedCampaignTitle;
    if (campaignId == null || campaignTitle == null || campaignTitle.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Kampanye belum dipilih'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
      return;
    }

    final nominal = int.tryParse(_nominalCtrl.text) ?? 0;
    if (nominal <= 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Nominal harus lebih dari 0'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? finalBuktiUrl = _buktiUrl;

      // Hapus bukti lama jika dihapus/diganti
      if (_removeOldBukti && _buktiUrl != null) {
        await ImageUploadService().deleteBuktiAlokasiByUrl(_buktiUrl!);
        finalBuktiUrl = null;
      }

      // Upload bukti baru jika dipilih
      if (_pickedFileBytes != null) {
        if (_buktiUrl != null) {
          await ImageUploadService().deleteBuktiAlokasiByUrl(_buktiUrl!);
        }
        finalBuktiUrl = await ImageUploadService().uploadBuktiAlokasiBytes(
          _pickedFileBytes!,
          _pickedFileExt ?? 'jpg',
        );
      } else if (_pickedFile != null) {
        if (_buktiUrl != null) {
          await ImageUploadService().deleteBuktiAlokasiByUrl(_buktiUrl!);
        }
        finalBuktiUrl = await ImageUploadService().uploadBuktiAlokasi(_pickedFile!);
      }

      final isEdit = widget.allocation != null;
      if (isEdit) {
        await _service.updateAllocation(widget.allocation!.id, {
          'judulAlokasi': _judulCtrl.text.trim(),
          'deskripsi': _deskripsiCtrl.text.trim(),
          'nominal': nominal,
          'kampanyeId': campaignId,
          'kampanyeJudul': campaignTitle,
          'buktiAlokasiUrl': finalBuktiUrl,
        });
      } else {
        final allocation = AllocationModel(
          id: '',
          kampanyeId: campaignId,
          kampanyeJudul: campaignTitle,
          judulAlokasi: _judulCtrl.text.trim(),
          deskripsi: _deskripsiCtrl.text.trim(),
          nominal: nominal,
          adminId: currentUser.uid,
          adminNama: currentUser.nama,
          createdAt: DateTime.now(),
          buktiAlokasiUrl: finalBuktiUrl,
        );
        await _service.createAllocation(allocation);
        await NotificationService().kirimNotifikasiAlokasi(
          kampanyeId: campaignId,
          kampanyeJudul: campaignTitle,
        );

        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Notifikasi diproses — penerimaan bergantung pada konfigurasi server FCM.',
              ),
              backgroundColor: Color(0xFF1D9E75),
            ),
          );
        }
      }

      if (!mounted) return;
      navigator.pop(true);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan alokasi: $e'),
            backgroundColor: const Color(0xFF1D9E75),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Gagal memuat data kampanye.\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
