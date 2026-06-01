import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donasee_final_project_ppb/models/allocation_model.dart';
import 'package:donasee_final_project_ppb/models/campaign_model.dart';
import 'package:donasee_final_project_ppb/services/allocation_service.dart';
import 'package:donasee_final_project_ppb/services/auth_service.dart';
import 'package:donasee_final_project_ppb/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class FormAlokasiScreen extends StatefulWidget {
  final AllocationModel? allocation;

  const FormAlokasiScreen({super.key, this.allocation});

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
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Alokasi' : 'Tambah Alokasi'),
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<CampaignModel>>(
        stream: _campaignStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString());
          }

          final campaigns = _effectiveCampaigns(snapshot.data ?? const []);

          return AbsorbPointer(
            absorbing: _isSubmitting,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCampaignField(campaigns),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _judulCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Judul Alokasi',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Judul tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deskripsiCtrl,
                    minLines: 4,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Deskripsi tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nominalCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Nominal',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Nominal harus angka dan lebih dari 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D9E75),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : () => _submit(context),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            )
                          : Text(
                              isEdit ? 'Simpan Perubahan' : 'Simpan Alokasi',
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

  Stream<List<CampaignModel>> _campaignStream() {
    return FirebaseFirestore.instance
        .collection('campaigns')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CampaignModel.fromFirestore(doc.data(), doc.id))
              .toList(),
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
      decoration: const InputDecoration(
        labelText: 'Pilih Kampanye',
        border: OutlineInputBorder(),
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
      final isEdit = widget.allocation != null;
      if (isEdit) {
        await _service.updateAllocation(widget.allocation!.id, {
          'judulAlokasi': _judulCtrl.text.trim(),
          'deskripsi': _deskripsiCtrl.text.trim(),
          'nominal': nominal,
          'kampanyeId': campaignId,
          'kampanyeJudul': campaignTitle,
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
        );
        await _service.createAllocation(allocation);
        await NotificationService().kirimNotifikasiAlokasi(
          kampanyeId: campaignId,
          kampanyeJudul: campaignTitle,
        );

        // Inform user about notification sending state (simulation vs real)
        if (mounted) {
          final sent = NotificationService.hasServerKey;
          messenger.showSnackBar(
            SnackBar(
              content: Text(sent
                  ? 'Notifikasi dikirim ke donatur.'
                  : 'Notifikasi disimulasikan (server key belum diatur).'),
              backgroundColor: const Color(0xFF1D9E75),
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
