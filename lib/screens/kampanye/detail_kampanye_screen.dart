import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donasee_final_project_ppb/services/donation_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/campaign_service.dart';
import '../../services/allocation_service.dart';
import '../../models/campaign_model.dart';
import '../../models/allocation_model.dart';
import 'edit_kampanye_screen.dart';
import '../donasiku/form_donasi_screen.dart';

class DetailKampanyeScreen extends StatelessWidget {
  final String campaignId;
  final bool isAdmin;
  final String? currentUserId; // UID user yang sedang login
  const DetailKampanyeScreen({
    required this.campaignId,
    this.isAdmin = false,
    this.currentUserId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return Scaffold(
      body: StreamBuilder<CampaignModel?>(
        stream: CampaignService().getCampaignByIdStream(campaignId),
        builder: (context, snapshot) {
          final campaign = snapshot.data;
          if (campaign == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return CustomScrollView(
            slivers: [
              // App bar dengan tombol admin
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: const Color(0xFF1D9E75),
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    campaign.judul,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1D9E75), Color(0xFF085041)],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.campaign_rounded,
                            size: 56,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            campaign.organisasiNama,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: isAdmin
                    ? [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit Kampanye',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditKampanyeScreen(campaign: campaign),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Hapus Kampanye',
                          onPressed: () => _confirmDelete(context, campaign),
                        ),
                      ]
                    : null,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul & organisasi
                      Text(
                        campaign.judul,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        campaign.organisasiNama,
                        style: const TextStyle(color: Color(0xFF0F6E56)),
                      ),
                      const SizedBox(height: 16),

                      // Statistik
                      Row(
                        children: [
                          _statBox('Terkumpul', fmt.format(campaign.terkumpul)),
                          const SizedBox(width: 8),
                          _statBox('Target', fmt.format(campaign.targetDana)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: campaign.progressPersen,
                          backgroundColor: const Color(0xFFE1F5EE),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF1D9E75),
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(campaign.progressPersen * 100).toInt()}% tercapai',
                            style: const TextStyle(
                              color: Color(0xFF085041),
                              fontSize: 12,
                            ),
                          ),
                          if (campaign.sisaHari >= 0)
                            Text(
                              '${campaign.sisaHari} hari lagi',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: campaign.isAktif
                              ? const Color(0xFFE1F5EE)
                              : const Color(0xFFFCE4EC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          campaign.isAktif ? '● Aktif' : '● Selesai',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: campaign.isAktif
                                ? const Color(0xFF1D9E75)
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tab: Info | Kabar Penggunaan Dana
                      // Tab Verifikasi hanya untuk admin pemilik kampanye ini
                      Builder(builder: (context) {
                        final isOwner = isAdmin &&
                            currentUserId != null &&
                            campaign.organisasiId == currentUserId;
                        return DefaultTabController(
                          length: isOwner ? 3 : 2,
                          child: Column(
                            children: [
                              TabBar(
                                labelColor: const Color(0xFF1D9E75),
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: const Color(0xFF1D9E75),
                                tabs: [
                                  const Tab(text: 'Info'),
                                  const Tab(text: 'Kabar Dana'),
                                  if (isOwner) const Tab(text: 'Verifikasi'),
                                ],
                              ),
                              SizedBox(
                                height: 300,
                                child: TabBarView(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(campaign.deskripsi),
                                    ),
                                    _AllocationTab(campaignId: campaignId),
                                    if (isOwner)
                                      _VerifikasiTab(campaignId: campaignId),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // Tombol donasi — hanya untuk donatur, bukan admin
      bottomNavigationBar: isAdmin
          ? const SizedBox.shrink()
          : Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<CampaignModel?>(
          stream: CampaignService().getCampaignByIdStream(campaignId),
          builder: (context, snapshot) {
            final campaign = snapshot.data;
            if (campaign == null || !campaign.isAktif) return const SizedBox();
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FormDonasiScreen(campaign: campaign),
                  ),
                );
              },
              child: const Text(
                'Donasi Sekarang',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EFE8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CampaignModel c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Kampanye?'),
          ],
        ),
        content: Text(
          'Kampanye "${c.judul}" akan dihapus permanen.\n\nTindakan ini tidak bisa dibatalkan.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await CampaignService().deleteCampaign(c.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _AllocationTab extends StatelessWidget {
  final String campaignId;
  const _AllocationTab({required this.campaignId});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return StreamBuilder<List<AllocationModel>>(
      stream: AllocationService().getAllocationsByCampaignStream(campaignId),
      builder: (context, snapshot) {
        // Loading state — jangan langsung show empty
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Error state — tampilkan pesan error, bukan data kosong
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Gagal memuat data: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Belum ada laporan penggunaan dana'));
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (_, i) {
            final a = snapshot.data![i];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE1F5EE),
                child: Icon(Icons.receipt_long, color: Color(0xFF1D9E75)),
              ),
              title: Text(a.judulAlokasi),
              subtitle: Text(
                a.deskripsi,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                fmt.format(a.nominal),
                style: const TextStyle(
                  color: Color(0xFF1D9E75),
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _VerifikasiTab extends StatelessWidget {
  final String campaignId;
  const _VerifikasiTab({required this.campaignId});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Query tanpa orderBy untuk menghindari composite index
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .where('kampanyeId', isEqualTo: campaignId)
          .where('status', isEqualTo: 'menunggu_verifikasi')
          .snapshots(),
      builder: (context, snapshot) {
        // Loading state — jangan langsung show empty
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Gagal memuat data: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Tidak ada donasi menunggu verifikasi'),
          );
        }
        // Sort client-side by createdAt descending
        final docs = [...snapshot.data!.docs];
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'];
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'];
          if (aTime == null || bTime == null) return 0;
          return (bTime as Timestamp).compareTo(aTime as Timestamp);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final donationId = docs[i].id;
            final nominal = (data['nominal'] ?? 0) as int;
            final kampanyeId = data['kampanyeId'] as String;

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFAEEDA),
                child: Icon(Icons.pending_outlined, color: Color(0xFF633806)),
              ),
              title: Text(
                data['donaturNama'] ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                fmt.format(nominal),
                style: const TextStyle(color: Color(0xFF1D9E75)),
              ),
              trailing: ElevatedButton(
                onPressed: () async {
                  await DonationService().konfirmasiDonasi(
                    donationId,
                    kampanyeId,
                    nominal,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Donasi dikonfirmasi!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('Konfirmasi'),
              ),
            );
          },
        );
      },
    );
  }
}
