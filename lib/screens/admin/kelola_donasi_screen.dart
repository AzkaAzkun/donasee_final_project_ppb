import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/donation_model.dart';
import 'detail_donasi_admin_screen.dart';

class KelolaDonasiScreen extends StatelessWidget {
  const KelolaDonasiScreen({super.key});

  Stream<List<DonationModel>> _streamMenunggu() {
    return FirebaseFirestore.instance
        .collection('donations')
        .where('status', isEqualTo: DonationStatus.menungguVerifikasi)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => DonationModel.fromFirestore(d.data(), d.id))
              .toList();
          list.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          ); // Sort in-memory
          return list;
        });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Donasi'),
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('campaigns')
            .where('organisasiId', isEqualTo: adminUid)
            .snapshots(),
        builder: (context, campaignsSnapshot) {
          if (campaignsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final myCampaignIds =
              campaignsSnapshot.data?.docs.map((doc) => doc.id).toSet() ?? {};

          return StreamBuilder<List<DonationModel>>(
            stream: _streamMenunggu(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final list =
                  snapshot.data
                      ?.where((d) => myCampaignIds.contains(d.kampanyeId))
                      .toList() ??
                  [];

              if (list.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Color(0xFF1D9E75),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Semua donasi sudah diverifikasi!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Counter badge
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      '${list.length} donasi menunggu verifikasi',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF633806),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final d = list[i];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailDonasiAdminScreen(donation: d),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade100),
                            ),
                            child: Row(
                              children: [
                                // Avatar inisial donatur
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFE1F5EE),
                                  child: Text(
                                    d.donaturNama.isNotEmpty
                                        ? d.donaturNama
                                              .substring(0, 1)
                                              .toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Color(0xFF085041),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.donaturNama,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        d.kampanyeJudul,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      fmt.format(d.nominal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1D9E75),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Badge "Ada Bukti" jika foto sudah diupload
                                    if (d.buktiFotoUrl != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE1F5EE),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Ada Bukti',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF085041),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
