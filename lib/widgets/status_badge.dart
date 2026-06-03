import 'package:flutter/material.dart';
import '../models/donation_model.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case DonationStatus.pending:
        bgColor = const Color(0xFFFAEEDA);
        textColor = const Color(0xFF633806);
        label = 'Pending';
        icon = Icons.hourglass_empty;
        break;
      case DonationStatus.menungguVerifikasi:
        bgColor = const Color(0xFFE6F1FB);
        textColor = const Color(0xFF0C447C);
        label = 'Menunggu Verifikasi';
        icon = Icons.upload_file;
        break;
      case DonationStatus.berhasil:
        bgColor = const Color(0xFFE1F5EE);
        textColor = const Color(0xFF085041);
        label = 'Berhasil';
        icon = Icons.check_circle_outline;
        break;
      default:
        bgColor = const Color(0xFFF1EFE8);
        textColor = const Color(0xFF444441);
        label = status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
