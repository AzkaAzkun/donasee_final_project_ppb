import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/donation_model.dart';
import '../../services/donation_service.dart';

class DetailDonasiAdminScreen extends StatefulWidget {
  final DonationModel donation;
  const DetailDonasiAdminScreen({required this.donation, super.key});

  @override
  State<DetailDonasiAdminScreen> createState() =>
      _DetailDonasiAdminScreenState();
}

class _DetailDonasiAdminScreenState extends State<DetailDonasiAdminScreen> {
  bool _loading = false;

  Future<void> _konfirmasi() async {
    setState(() => _loading = true);
    await DonationService().konfirmasiDonasi(
      widget.donation.id,
      widget.donation.kampanyeId,
      widget.donation.nominal,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donasi berhasil dikonfirmasi!'),
          backgroundColor: Color(0xFF0050CB),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _tolak() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tolak Donasi?'),
        content: const Text(
          'Donasi ini akan dikembalikan ke status pending. '
          'Donatur bisa upload ulang bukti transfer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Tolak', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(widget.donation.id)
          .update({'status': DonationStatus.pending, 'buktiFotoUrl': null});
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final d = widget.donation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Donasi'),
        backgroundColor: const Color(0xFF0050CB),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info donatur ──────────────────────────────────
            _sectionTitle('Informasi Donatur'),
            _infoRow('Nama', d.donaturNama),
            _infoRow('Kampanye', d.kampanyeJudul),
            _infoRow('Nominal', fmt.format(d.nominal)),
            _infoRow('Metode', 'Transfer Bank Manual'),
            _infoRow(
              'Tanggal',
              DateFormat('d MMM yyyy, HH:mm').format(d.createdAt),
            ),
            const SizedBox(height: 24),

            // ── Foto bukti transfer ───────────────────────────
            _sectionTitle('Bukti Transfer'),
            const SizedBox(height: 8),
            if (d.buktiFotoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  d.buktiFotoUrl!,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 120,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Text(
                    'Belum ada foto bukti',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // ── Tombol aksi ───────────────────────────────────
            if (!_loading) ...[
              ElevatedButton.icon(
                onPressed: d.buktiFotoUrl != null ? _konfirmasi : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Konfirmasi Donasi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0050CB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _tolak,
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: const Text(
                  'Tolak & Kembalikan ke Pending',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ] else
              const Center(child: CircularProgressIndicator()),

            // Hint jika foto belum ada
            if (d.buktiFotoUrl == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '* Tombol konfirmasi aktif setelah donatur upload bukti transfer.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0050CB),
      ),
    ),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
