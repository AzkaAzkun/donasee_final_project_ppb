import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/campaign_service.dart';
import '../../services/allocation_service.dart';
import '../../models/campaign_model.dart';
import '../../models/allocation_model.dart';
import 'edit_kampanye_screen.dart';

class DetailKampanyeScreen extends StatelessWidget {
  final String campaignId;
  final bool isAdmin;
  const DetailKampanyeScreen({
    required this.campaignId,
    this.isAdmin = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      body: StreamBuilder<CampaignModel?>(
        stream: CampaignService().getCampaignByIdStream(campaignId),
        builder: (context, snapshot) {
          final campaign = snapshot.data;
          if (campaign == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return CustomScrollView(slivers: [
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
                        const Icon(Icons.campaign_rounded,
                            size: 56, color: Colors.white54),
                        const SizedBox(height: 8),
                        Text(campaign.organisasiNama,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
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
                      Text(campaign.judul,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(campaign.organisasiNama,
                          style: const TextStyle(color: Color(0xFF0F6E56))),
                      const SizedBox(height: 16),

                      // Statistik
                      Row(children: [
                        _statBox('Terkumpul', fmt.format(campaign.terkumpul)),
                        const SizedBox(width: 8),
                        _statBox('Target', fmt.format(campaign.targetDana)),
                      ]),
                      const SizedBox(height: 12),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: campaign.progressPersen,
                          backgroundColor: const Color(0xFFE1F5EE),
                          valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF1D9E75)),
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
                                  color: Color(0xFF085041), fontSize: 12)),
                          if (campaign.sisaHari >= 0)
                            Text('${campaign.sisaHari} hari lagi',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
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
                      DefaultTabController(
                        length: 2,
                        child: Column(children: [
                          const TabBar(
                            labelColor: Color(0xFF1D9E75),
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Color(0xFF1D9E75),
                            tabs: [
                              Tab(text: 'Info'),
                              Tab(text: 'Kabar Dana'),
                            ],
                          ),
                          SizedBox(
                            height: 300,
                            child: TabBarView(children: [
                              // Tab Info — deskripsi
                              SingleChildScrollView(
                                padding: const EdgeInsets.all(12),
                                child: Text(campaign.deskripsi,
                                    style: const TextStyle(
                                        fontSize: 14, height: 1.5)),
                              ),
                              // Tab Kabar — alokasi dana (integrasi Anggota 3)
                              _AllocationTab(campaignId: campaignId),
                            ]),
                          ),
                        ]),
                      ),
                    ]),
              ),
            ),
          ]);
        },
      ),
      // Tombol donasi (integrasi Anggota 2)
      bottomNavigationBar: Padding(
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
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // Navigasi ke FormDonasiScreen (Anggota 2)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur donasi akan tersedia setelah Sprint 2 A2'),
                    backgroundColor: Color(0xFF1D9E75),
                  ),
                );
              },
              child: const Text('Donasi Sekarang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
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
            child:
                const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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

// Widget tab alokasi — placeholder, nanti diintegrasi Anggota 3
class _AllocationTab extends StatelessWidget {
  final String campaignId;
  const _AllocationTab({required this.campaignId});

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return StreamBuilder<List<AllocationModel>>(
      stream: AllocationService().getAllocationsByCampaignStream(campaignId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('Belum ada laporan penggunaan dana'));
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (_, i) {
            final a = snapshot.data![i];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE1F5EE),
                child:
                    Icon(Icons.receipt_long, color: Color(0xFF1D9E75)),
              ),
              title: Text(a.judulAlokasi),
              subtitle: Text(a.deskripsi,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(fmt.format(a.nominal),
                  style: const TextStyle(
                      color: Color(0xFF1D9E75),
                      fontWeight: FontWeight.bold)),
            );
          },
        );
      },
    );
  }
}
