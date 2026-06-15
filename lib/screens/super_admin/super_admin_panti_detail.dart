import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donasee_final_project_ppb/models/user_model.dart';
import 'package:donasee_final_project_ppb/services/auth_service.dart';
import 'package:donasee_final_project_ppb/services/image_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SuperAdminPantiDetail extends StatefulWidget {
  final UserModel user;

  const SuperAdminPantiDetail({required this.user, super.key});

  @override
  State<SuperAdminPantiDetail> createState() => _SuperAdminPantiDetailState();
}

class _SuperAdminPantiDetailState extends State<SuperAdminPantiDetail> {
  Future<void> _viewPdf(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Surat resmi tidak ditemukan/URL kosong.')),
      );
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka surat resmi. URL tidak valid.')),
        );
      }
    }
  }

  Future<void> _approvePanti(BuildContext context, String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Setujui Panti?'),
        content: Text('Apakah Anda yakin menyetujui pendaftaran panti "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final currentAdminUid = AuthService().currentUser?.uid ?? '';
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': currentAdminUid,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Panti "$name" berhasil disetujui!'),
            backgroundColor: const Color(0xFF00682C),
          ),
        );
      }
    }
  }

  Future<void> _unverifyPanti(BuildContext context, String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cabut Verifikasi?'),
        content: Text('Apakah Anda yakin ingin mencabut verifikasi untuk "$name"? Institusi ini akan kehilangan akses publik.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Cabut Verifikasi'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isVerified': false,
        'verifiedAt': null,
        'verifiedBy': null,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verifikasi panti "$name" berhasil dicabut.'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    }
  }

  Future<void> _rejectPanti(BuildContext context, String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak & Hapus Panti?'),
        content: Text('Tindakan ini akan menolak pendaftaran dan menghapus dokumen panti "$name" beserta surat resminya secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tolak & Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Delete PDF from Supabase Storage
      await ImageUploadService().deleteSuratResmi(uid);

      // 2. Delete document from Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pendaftaran panti "$name" ditolak dan dihapus.'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0066FF);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: primaryColor)),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Document was deleted (e.g. rejected & deleted), return to previous screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });
          return const Scaffold(
            body: Center(child: Text('Data panti tidak ditemukan.')),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final user = UserModel.fromFirestore(data, snapshot.data!.id);

        final isVerified = user.isVerified;
        final formattedDate = DateFormat('dd MMMM yyyy').format(user.createdAt);
        final shortUid = user.uid.length > 12 
            ? 'ORP-${user.uid.substring(0, 8).toUpperCase()}-JKT' 
            : 'ORP-${user.uid.toUpperCase()}-JKT';

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FB),
          appBar: AppBar(
            leadingWidth: 56,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF424656)),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  hoverColor: const Color(0xFFECEEF0),
                ),
              ),
            ),
            title: const Text(
              'Super Admin',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
            backgroundColor: const Color(0xFFF2F4F6),
            elevation: 0.5,
            shadowColor: Colors.black.withValues(alpha: 0.1),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Status Row
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Status Badge
                        if (isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00843A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF005321)),
                                SizedBox(width: 6),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF005321),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.pending_actions_rounded, size: 16, color: Color(0xFF92400E)),
                                SizedBox(width: 6),
                                Text(
                                  'Pending Verification',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 12),
                        // ID display
                        Text(
                          'ID: $shortUid',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF727687),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.organisasiNama ?? 'Nama Panti',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191C1E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pengurus: ${user.nama}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF727687),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Verification Actions Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEEF0),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE0E3E5).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      if (!isVerified) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approvePanti(context, user.uid, user.organisasiNama ?? ''),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.check_circle_rounded, size: 20),
                            label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _rejectPanti(context, user.uid, user.organisasiNama ?? ''),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFBA1A1A),
                              side: const BorderSide(color: Color(0xFFBA1A1A)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.block_rounded, size: 20),
                            label: const Text('Reject/Revise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _unverifyPanti(context, user.uid, user.organisasiNama ?? ''),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFBA1A1A),
                              side: const BorderSide(color: Color(0xFFBA1A1A)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.warning_amber_rounded, size: 20),
                            label: const Text('Unverify Panti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bento Section 1: Informasi Dasar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE0E3E5).withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDAE1FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.info_outline_rounded, color: Color(0xFF001849), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Informasi Dasar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF191C1E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Flex layout or simple column for info fields
                      _buildInfoField('NAMA ORGANISASI', user.organisasiNama ?? '-'),
                      _buildInfoField('EMAIL', user.email),
                      _buildInfoField('TELEPON ORGANISASI', user.organisasiTelepon ?? '-'),
                      _buildInfoField('TANGGAL PENDAFTARAN', formattedDate),
                      _buildInfoField('ALAMAT LENGKAP ORGANISASI', user.organisasiAlamat ?? '-'),
                      

                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bento Section 2: Dokumen Resmi
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE0E3E5).withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6DF5E1).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.description_outlined, color: Color(0xFF006F64), size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Dokumen Resmi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF191C1E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Document PDF Card
                      if (user.suratResmiUrl != null && user.suratResmiUrl!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFC2C6D8).withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFCEBEB),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFBA1A1A), size: 24),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF727687), size: 20),
                                    onPressed: () => _viewPdf(context, user.suratResmiUrl),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Surat Resmi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF191C1E),
                                ),
                              ),
                              const Text(
                                'PDF Document',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF727687),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _viewPdf(context, user.suratResmiUrl),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF2F4F6),
                                    foregroundColor: const Color(0xFF191C1E),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('View Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCEBEB),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFBA1A1A).withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.error_outline_rounded, color: Color(0xFFBA1A1A), size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Panti asuhan ini belum mengunggah dokumen legalitas surat resmi.',
                                  style: TextStyle(
                                    color: Color(0xFFBA1A1A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF727687),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191C1E),
            ),
          ),
        ],
      ),
    );
  }
}
