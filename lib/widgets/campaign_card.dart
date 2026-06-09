import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/campaign_model.dart';
import '../screens/kampanye/detail_kampanye_screen.dart';

class CampaignCard extends StatelessWidget {
  final CampaignModel campaign;
  final bool isAdmin;
  final String? currentUserId;
  const CampaignCard({
    required this.campaign,
    this.isAdmin = false,
    this.currentUserId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailKampanyeScreen(
            campaignId: campaign.id,
            isAdmin: isAdmin,
            currentUserId: currentUserId,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Nama organisasi
          Text(campaign.organisasiNama,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF0F6E56),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          // Judul kampanye
          Text(campaign.judul,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: campaign.progressPersen,
              backgroundColor: const Color(0xFFE1F5EE),
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFF1D9E75)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Terkumpul ${fmt.format(campaign.terkumpul)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(
                '${(campaign.progressPersen * 100).toInt()}% dari ${fmt.format(campaign.targetDana)}',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF085041),
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 8),
          // Badge sisa hari
          if (campaign.sisaHari <= 7)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFAEEDA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${campaign.sisaHari} hari lagi',
                  style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF633806),
                      fontWeight: FontWeight.w500)),
            ),
        ]),
      ),
    );
  }
}
