import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/donation_service.dart';
import '../../models/donation_model.dart';
import '../../widgets/donation_card.dart';

class DonasikuScreen extends StatelessWidget {
  const DonasikuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final svc = DonationService();
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<List<DonationModel>>(
        stream: svc.getDonationsByUserStream(uid),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final donations = snapshot.data ?? [];

          // Hitung total donasi berhasil
          final totalBerhasil = donations
              .where((d) => d.status == DonationStatus.berhasil)
              .fold<int>(0, (sum, d) => sum + d.nominal);

          final totalKampanye = donations
              .map((d) => d.kampanyeId)
              .toSet()
              .length;

          return CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: const Color(0xFF1D9E75),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: const Color(0xFF1D9E75),
                    padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Riwayat Donasiku',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${donations.length} total transaksi',
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

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kartu statistik
                      Row(
                        children: [
                          _statCard(
                            label: 'Total Donasi',
                            value: fmt.format(totalBerhasil),
                            icon: Icons.volunteer_activism,
                            color: const Color(0xFF1D9E75),
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            label: 'Kampanye',
                            value: '$totalKampanye kampanye',
                            icon: Icons.campaign,
                            color: const Color(0xFF534AB7),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // List donasi
                      if (donations.isEmpty)
                        _emptyState()
                      else ...[
                        const Text(
                          'TRANSAKSI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...donations.map((d) => DonationCard(donation: d)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Belum ada donasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yuk mulai berdonasi dari tab Jelajah!',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
