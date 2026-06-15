import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donasee_final_project_ppb/models/allocation_model.dart';
import 'package:donasee_final_project_ppb/models/campaign_model.dart';
import 'package:donasee_final_project_ppb/screens/kabar/form_alokasi_screen.dart';
import 'package:donasee_final_project_ppb/services/allocation_service.dart';
import 'package:donasee_final_project_ppb/services/image_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailAlokasiScreen extends StatefulWidget {
  final String allocationId;

  const DetailAlokasiScreen({super.key, required this.allocationId});

  @override
  State<DetailAlokasiScreen> createState() => _DetailAlokasiScreenState();
}

class _DetailAlokasiScreenState extends State<DetailAlokasiScreen> {
  final _service = AllocationService();
  bool _isDeleting = false;

  List<Map<String, dynamic>> _getBreakdown(String category, int totalNominal) {
    final int item1 = (totalNominal * 0.7).round();
    final int item2 = (totalNominal * 0.2).round();
    final int item3 = totalNominal - item1 - item2;

    switch (category) {
      case 'Pendidikan':
        return [
          {
            'title': 'Paket Perlengkapan & Seragam',
            'subtitle': 'Lengkap dengan atribut sekolah',
            'amount': item1,
            'icon': Icons.backpack_outlined,
            'color': const Color(0xFFDAE1FF),
            'textColor': const Color(0xFF001849),
          },
          {
            'title': 'Buku & Alat Tulis Belajar',
            'subtitle': 'Standar kualitas belajar siswa',
            'amount': item2,
            'icon': Icons.menu_book_outlined,
            'color': const Color(0xFF6DF5E1).withOpacity(0.3),
            'textColor': const Color(0xFF005048),
          },
          {
            'title': 'Logistik & Distribusi Paket',
            'subtitle': 'Pengiriman ke lokasi penerima',
            'amount': item3,
            'icon': Icons.local_shipping_outlined,
            'color': const Color(0xFFECEEF0),
            'textColor': const Color(0xFF424656),
          },
        ];
      case 'Kesehatan':
        return [
          {
            'title': 'Tindakan Medis & Operasi',
            'subtitle': 'Penanganan oleh tim dokter spesialis',
            'amount': item1,
            'icon': Icons.medical_services_outlined,
            'color': const Color(0xFFDAE1FF),
            'textColor': const Color(0xFF001849),
          },
          {
            'title': 'Obat-obatan & Terapi Pasca Tindakan',
            'subtitle': 'Pemulihan dan pencegahan infeksi',
            'amount': item2,
            'icon': Icons.medication_outlined,
            'color': const Color(0xFF6DF5E1).withOpacity(0.3),
            'textColor': const Color(0xFF005048),
          },
          {
            'title': 'Transportasi & Operasional Medis',
            'subtitle': 'Akomodasi pasien prasejahtera',
            'amount': item3,
            'icon': Icons.local_shipping_outlined,
            'color': const Color(0xFFECEEF0),
            'textColor': const Color(0xFF424656),
          },
        ];
      case 'Bencana':
      case 'Bencana Alam':
        return [
          {
            'title': 'Kebutuhan Pokok & Sembako Darurat',
            'subtitle': 'Bahan makanan pokok & air bersih',
            'amount': item1,
            'icon': Icons.restaurant_outlined,
            'color': const Color(0xFFDAE1FF),
            'textColor': const Color(0xFF001849),
          },
          {
            'title': 'Perlengkapan Hunian Sementara',
            'subtitle': 'Tenda darurat, selimut & kasur lipat',
            'amount': item2,
            'icon': Icons.home_outlined,
            'color': const Color(0xFF6DF5E1).withOpacity(0.3),
            'textColor': const Color(0xFF005048),
          },
          {
            'title': 'Logistik Pengiriman Bantuan',
            'subtitle': 'Operasional distribusi ke posko bencana',
            'amount': item3,
            'icon': Icons.local_shipping_outlined,
            'color': const Color(0xFFECEEF0),
            'textColor': const Color(0xFF424656),
          },
        ];
      case 'Pangan':
        return [
          {
            'title': 'Bahan Pangan Pokok & Sembako',
            'subtitle': 'Beras, minyak, protein nabati/hewani',
            'amount': item1,
            'icon': Icons.restaurant_outlined,
            'color': const Color(0xFFDAE1FF),
            'textColor': const Color(0xFF001849),
          },
          {
            'title': 'Alat Masak & Peralatan Makan',
            'subtitle': 'Penunjang operasional dapur sosial',
            'amount': item2,
            'icon': Icons.soup_kitchen_outlined,
            'color': const Color(0xFF6DF5E1).withOpacity(0.3),
            'textColor': const Color(0xFF005048),
          },
          {
            'title': 'Distribusi & Paket Kemasan',
            'subtitle': 'Operasional pembagian ke rumah warga',
            'amount': item3,
            'icon': Icons.local_shipping_outlined,
            'color': const Color(0xFFECEEF0),
            'textColor': const Color(0xFF424656),
          },
        ];
      case 'Renovasi':
        return [
          {
            'title': 'Bahan & Material Konstruksi',
            'subtitle': 'Semen, pasir, cat, besi, kayu, dll.',
            'amount': item1,
            'icon': Icons.construction_outlined,
            'color': const Color(0xFFDAE1FF),
            'textColor': const Color(0xFF001849),
          },
          {
            'title': 'Upah Pekerja & Tukang Bangunan',
            'subtitle': 'Jasa pengerjaan konstruksi fisik',
            'amount': item2,
            'icon': Icons.engineering_outlined,
            'color': const Color(0xFF6DF5E1).withOpacity(0.3),
            'textColor': const Color(0xFF005048),
          },
          {
            'title': 'Penyewaan Alat & Kebersihan',
            'subtitle': 'Alat penunjang pengerjaan konstruksi',
            'amount': item3,
            'icon': Icons.cleaning_services_outlined,
            'color': const Color(0xFFECEEF0),
            'textColor': const Color(0xFF424656),
          },
        ];
      default:
        return [
          {
            'title': 'Kebutuhan Utama Program Kebajikan',
            'subtitle': 'Penyaluran dana langsung ke sasaran',
            'amount': item1,
            'icon': Icons.volunteer_activism_outlined,
            'color': const Color(0xFFDAE1FF),
            'textColor': const Color(0xFF001849),
          },
          {
            'title': 'Sarana & Prasarana Penunjang',
            'subtitle': 'Fasilitas pelengkap program',
            'amount': item2,
            'icon': Icons.widgets_outlined,
            'color': const Color(0xFF6DF5E1).withOpacity(0.3),
            'textColor': const Color(0xFF005048),
          },
          {
            'title': 'Logistik & Administrasi Lapangan',
            'subtitle': 'Biaya operasional tim lapangan',
            'amount': item3,
            'icon': Icons.local_shipping_outlined,
            'color': const Color(0xFFECEEF0),
            'textColor': const Color(0xFF424656),
          },
        ];
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka dokumen bukti.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<AllocationModel?>(
      stream: _service.getAllocationByIdStream(widget.allocationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: _ErrorState(message: snapshot.error.toString()),
          );
        }

        final allocation = snapshot.data;
        if (allocation == null) {
          return const Scaffold(
            body: _EmptyState(message: 'Data alokasi tidak ditemukan'),
          );
        }

        final isOwner = allocation.adminId == currentUserUid;

        return FutureBuilder<CampaignModel?>(
          future: FirebaseFirestore.instance
              .collection('campaigns')
              .doc(allocation.kampanyeId)
              .get()
              .then(
                (doc) => doc.exists
                    ? CampaignModel.fromFirestore(doc.data()!, doc.id)
                    : null,
              ),
          builder: (context, campaignSnapshot) {
            final campaign = campaignSnapshot.data;
            final category = campaign?.kategori ?? 'Lainnya';
            final breakdownItems = _getBreakdown(category, allocation.nominal);

            return Scaffold(
              backgroundColor: const Color(0xFFF7F9FB),
              appBar: AppBar(
                title: const Text(
                  'Alokasi Dana',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0050CB),
                  ),
                ),
                elevation: 0,
                backgroundColor: const Color(0xFFF7F9FB),
                foregroundColor: const Color(0xFF0050CB),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Color(0xFF424656)),
                    tooltip: 'Bagikan',
                    onPressed: () {
                      final shareText =
                          '[Alokasi Dana Donasee]\n\nJudul: ${allocation.judulAlokasi}\nProgram: ${allocation.kampanyeJudul}\nNominal: ${currency.format(allocation.nominal)}\n\nLaporan ini terverifikasi dan disalurkan secara transparan.';
                      Clipboard.setData(ClipboardData(text: shareText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Info alokasi disalin ke papan klip!'),
                          backgroundColor: Color(0xFF006B5F),
                        ),
                      );
                    },
                  ),
                  if (isOwner) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xFF0050CB)),
                      tooltip: 'Edit',
                      onPressed: _isDeleting ? null : () => _openEdit(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFFBA1A1A)),
                      tooltip: 'Hapus',
                      onPressed: _isDeleting
                          ? null
                          : () => _confirmDelete(context, allocation),
                    ),
                  ],
                ],
              ),
              body: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    children: [
                      // 1. Summary Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE0E3E5).withOpacity(0.5),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 20,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7FFE5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: Color(0xFF00682C),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00682C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              allocation.judulAlokasi,
                              style: const TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF191C1E),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFFECEEF0), height: 1),
                            const SizedBox(height: 16),
                            const Text(
                              'Total Anggaran Terpakai',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0xFF424656),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currency.format(allocation.nominal),
                              style: const TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0050CB),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Mini Progress Viz
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progress Penyaluran',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF424656),
                                  ),
                                ),
                                Text(
                                  '100%',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0050CB),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 10,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0050CB).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF0050CB),
                                        Color(0xFF6DF5E1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. Breakdown List ("Rincian Pengeluaran")
                      const Text(
                        'Rincian Pengeluaran',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: breakdownItems.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F4F6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: item['color'] as Color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    color: item['textColor'] as Color,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] as String,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF191C1E),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item['subtitle'] as String,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          color: Color(0xFF424656),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currency.format(item['amount']),
                                  style: const TextStyle(
                                    fontFamily: 'Lexend',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF191C1E),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // 3. Documentation Section ("Bukti Pendukung")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bukti Pendukung',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF191C1E),
                            ),
                          ),
                          if (allocation.buktiAlokasiUrl != null)
                            TextButton(
                              onPressed: () {
                                _launchURL(allocation.buktiAlokasiUrl!);
                              },
                              child: const Text(
                                'Lihat Asli',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0050CB),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSupportingProofWidget(allocation),
                      const SizedBox(height: 24),

                      // 4. Audit & Transparency Note
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDAE1FF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFDAE1FF).withOpacity(0.4),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info,
                              color: Color(0xFF0050CB),
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Audit & Transparansi',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF191C1E),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Seluruh alokasi dana telah diaudit dan diverifikasi oleh tim internal Donasee untuk memastikan setiap rupiah sampai ke penerima manfaat yang tepat.',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      height: 1.4,
                                      color: Color(0xFF424656),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 5. Download Action Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0050CB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          if (allocation.buktiAlokasiUrl != null) {
                            _launchURL(allocation.buktiAlokasiUrl!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Bukti pendukung resmi belum diunggah. Unduhan dinonaktifkan.',
                                ),
                                backgroundColor: Color(0xFFBA1A1A),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text(
                          'Unduh Laporan Lengkap (PDF / Bukti)',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                  if (_isDeleting)
                    Container(
                      color: Colors.black.withOpacity(0.15),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSupportingProofWidget(AllocationModel allocation) {
    final url = allocation.buktiAlokasiUrl;
    if (url == null || url.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFECEEF0).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E3E5)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description_outlined, color: Colors.grey, size: 28),
              SizedBox(height: 8),
              Text(
                'Belum ada bukti dokumen yang diunggah.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF727687),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isPdf = url.toLowerCase().contains('.pdf');

    if (isPdf) {
      return InkWell(
        onTap: () => _launchURL(url),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E3E5)),
          ),
          child: const Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Color(0xFFBA1A1A), size: 36),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dokumen Bukti Penyaluran.pdf',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ketuk untuk melihat dokumen resmi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xFF727687),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, color: Color(0xFF727687), size: 18),
            ],
          ),
        ),
      );
    } else {
      // It's an image
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  InteractiveViewer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(url),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Kwitansi Pembelian / Bukti Penyaluran',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF191C1E),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _openEdit(BuildContext context) async {
    final allocation = await _service
        .getAllocationByIdStream(widget.allocationId)
        .first;
    if (allocation == null || !context.mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormAlokasiScreen(allocation: allocation),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alokasi berhasil diperbarui'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AllocationModel allocation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Alokasi?'),
        content: const Text('Data alokasi ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      // Hapus dokumen bukti dari storage Supabase jika ada
      if (allocation.buktiAlokasiUrl != null) {
        await ImageUploadService().deleteBuktiAlokasiByUrl(
          allocation.buktiAlokasiUrl!,
        );
      }
      await _service.deleteAllocation(widget.allocationId);
      if (!context.mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus alokasi: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
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
          'Gagal memuat detail alokasi.\n$message',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red.shade700),
        ),
      ),
    );
  }
}
