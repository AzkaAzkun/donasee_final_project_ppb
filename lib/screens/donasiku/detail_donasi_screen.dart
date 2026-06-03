import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';
import '../../widgets/status_badge.dart';

class DetailDonasiScreen extends StatefulWidget {
  final DonationModel donation;
  const DetailDonasiScreen({required this.donation, super.key});

  @override
  State<DetailDonasiScreen> createState() => _DetailDonasiScreenState();
}

class _DetailDonasiScreenState extends State<DetailDonasiScreen> {
  final _svc = DonationService();
  bool _uploading = false;
  bool _canceling = false;

  final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dateFmt = DateFormat('d MMMM yyyy, HH:mm', 'id_ID');

  Future<void> _uploadBukti() async {
    setState(() => _uploading = true);
    try {
      final berhasil = await _svc.uploadBuktiFoto(widget.donation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              berhasil
                  ? 'Bukti transfer berhasil diupload!'
                  : 'Upload dibatalkan',
            ),
            backgroundColor: berhasil ? const Color(0xFF1D9E75) : Colors.grey,
          ),
        );
        if (berhasil) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _batalkan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Donasi?'),
        content: const Text('Transaksi ini akan dihapus permanen. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Ya, Batalkan',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _canceling = true);
    try {
      await _svc.batalkanDonasi(widget.donation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donasi berhasil dibatalkan'),
            backgroundColor: Colors.grey,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal batalkan: $e')));
      }
    } finally {
      if (mounted) setState(() => _canceling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.donation;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Detail Donasi'),
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  StatusBadge(status: d.status),
                  const SizedBox(height: 16),
                  Text(
                    _fmt.format(d.nominal),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF085041),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d.kampanyeJudul,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detail transaksi
            _infoCard('Detail Transaksi', [
              _InfoRow(label: 'Tanggal', value: _dateFmt.format(d.createdAt)),
              _InfoRow(label: 'Metode', value: 'Transfer Bank Manual'),
              _InfoRow(label: 'Donatur', value: d.donaturNama),
              _InfoRow(label: 'Kampanye', value: d.kampanyeJudul),
              _InfoRow(label: 'ID', value: d.id, isSmall: true),
            ]),
            const SizedBox(height: 16),

            // Info rekening (jika pending atau menunggu verifikasi)
            if (d.status == DonationStatus.pending ||
                d.status == DonationStatus.menungguVerifikasi)
              _infoCard('Rekening Tujuan Transfer', [
                const _InfoRow(label: 'Bank', value: 'BCA'),
                const _InfoRow(label: 'No. Rek', value: '1234567890'),
                const _InfoRow(label: 'a.n.', value: 'Yayasan Donasi'),
              ]),

            // Bukti foto (jika sudah diupload)
            if (d.buktiFotoUrl != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bukti Transfer',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        d.buktiFotoUrl!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            height: 220,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (_, __, ___) => const SizedBox(
                          height: 80,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Tombol aksi
            if (d.status == DonationStatus.pending) ...[
              // Upload bukti
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _uploading ? null : _uploadBukti,
                  icon: _uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(
                    _uploading ? 'Mengupload...' : 'Upload Bukti Transfer',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Batalkan donasi
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _canceling ? null : _batalkan,
                  icon: _canceling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: const Text(
                    'Batalkan Donasi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],

            // Info status menunggu verifikasi
            if (d.status == DonationStatus.menungguVerifikasi)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF0C447C),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bukti transfer sedang diverifikasi oleh admin. Mohon tunggu.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0C447C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isSmall;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmall ? 11 : 13,
                fontWeight: FontWeight.w500,
                color: isSmall ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
