import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/donation_model.dart';
import '../screens/donasiku/detail_donasi_screen.dart';
import 'status_badge.dart';

class DonationCard extends StatelessWidget {
  final DonationModel donation;
  const DonationCard({required this.donation, super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('d MMM yyyy', 'id_ID');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailDonasiScreen(donation: donation),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5EE),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.favorite,
                color: Color(0xFF1D9E75),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.kampanyeJudul,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateFmt.format(donation.createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  StatusBadge(status: donation.status),
                ],
              ),
            ),

            // Nominal
            Text(
              fmt.format(donation.nominal),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF085041),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
