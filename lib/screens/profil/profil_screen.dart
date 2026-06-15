import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/image_upload_service.dart';
import '../auth/login_screen.dart';
import '../home/main_navigation.dart';
import 'detail_profil_screen.dart';
import '../admin/manajemen_kampanye_screen.dart';

class ProfilScreen extends StatelessWidget {
  final UserModel user;
  const ProfilScreen({required this.user, super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar Aplikasi?',
          style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.bold),
        ),
        content: const Text('Kamu akan logout dari akun ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF727687)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Keluar',
              style: TextStyle(
                color: Color(0xFFBA1A1A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService().logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  Future<void> _updateProfilePicture(BuildContext context, String uid) async {
    try {
      final picker = ImagePicker();
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF0050CB)),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontFamily: 'Inter')),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF0050CB)),
                title: const Text('Ambil Foto Baru', style: TextStyle(fontFamily: 'Inter')),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        );
      }

      final file = File(pickedFile.path);
      final photoUrl = await ImageUploadService().uploadProfilePicture(
        uid: uid,
        imageFile: file,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fotoUrl': photoUrl});

      if (context.mounted) {
        Navigator.pop(context); // pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Color(0xFF00682C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah foto profil: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        UserModel currentUser = user;
        if (snapshot.hasData && snapshot.data!.exists) {
          currentUser = UserModel.fromFirestore(snapshot.data!.data()!, user.uid);
        }

        final isAdmin = currentUser.isAdmin;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FB),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F9FB),
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Profil',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0050CB),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isAdmin) ...[
                  // ADMIN PROFILE VIEW
                  _buildAdminHeader(context, currentUser),
                  const SizedBox(height: 24),
                  _StreamAdminStat(uid: currentUser.uid),
                  const SizedBox(height: 24),
                  _buildAdminMenuList(context, currentUser),
                  const SizedBox(height: 32),
                  _buildAdminLogoutButton(context),
                ] else ...[
                  // DONATUR PROFILE VIEW
                  _buildUserHeader(context, currentUser),
                  const SizedBox(height: 24),
                  _StreamDonaturStat(uid: currentUser.uid),
                  const SizedBox(height: 24),
                  _buildUserMenuList(context, currentUser),
                  const SizedBox(height: 32),
                  _buildUserLogoutButton(context),
                ],
                const SizedBox(height: 24),
                Text(
                  isAdmin ? 'Versi App 2.4.0 (Admin Build)' : 'Versi App 2.4.0',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFFC2C6D8),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminHeader(BuildContext context, UserModel currentUser) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE0E3E5).withValues(alpha: 0.5),
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
        children: [
          // Avatar Initial Circle with Edit Button Stack
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFDAE1FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: currentUser.fotoUrl != null && currentUser.fotoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.network(
                          currentUser.fotoUrl!,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              currentUser.nama.isNotEmpty ? currentUser.nama[0].toUpperCase() : 'A',
                              style: const TextStyle(
                                color: Color(0xFF001849),
                                fontFamily: 'Lexend',
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          currentUser.nama.isNotEmpty ? currentUser.nama[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            color: Color(0xFF001849),
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.bold,
                            fontSize: 36,
                          ),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _updateProfilePicture(context, currentUser.uid),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0050CB),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currentUser.nama,
            style: const TextStyle(
              fontFamily: 'Lexend',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 6),
          if (currentUser.organisasiNama != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified, color: Color(0xFF00682C), size: 18),
                const SizedBox(width: 6),
                Text(
                  currentUser.organisasiNama!,
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF424656),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE7FFE5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, color: Color(0xFF00682C), size: 14),
                SizedBox(width: 6),
                Text(
                  'Verified Organization',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00682C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, UserModel currentUser) {
    final dateStr = DateFormat('MMM yyyy', 'id_ID').format(currentUser.createdAt);

    return Column(
      children: [
        // Avatar Initial Circle with Edit Button Stack
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFDAE1FF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: currentUser.fotoUrl != null && currentUser.fotoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.network(
                        currentUser.fotoUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            currentUser.nama.isNotEmpty ? currentUser.nama[0].toUpperCase() : 'D',
                            style: const TextStyle(
                              color: Color(0xFF001849),
                              fontFamily: 'Lexend',
                              fontWeight: FontWeight.bold,
                              fontSize: 38,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        currentUser.nama.isNotEmpty ? currentUser.nama[0].toUpperCase() : 'D',
                        style: const TextStyle(
                          color: Color(0xFF001849),
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.bold,
                          fontSize: 38,
                        ),
                      ),
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _updateProfilePicture(context, currentUser.uid),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0050CB),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          currentUser.nama,
          style: const TextStyle(
            fontFamily: 'Lexend',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF191C1E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currentUser.email,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF727687),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6DF5E1).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, color: Color(0xFF006F64), size: 14),
              const SizedBox(width: 6),
              Text(
                'Member since $dateStr',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006F64),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminMenuList(BuildContext context, UserModel currentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'MANAJEMEN ORGANISASI',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF727687),
              letterSpacing: 0.8,
            ),
          ),
        ),
        _buildAdminMenuItem(
          context: context,
          icon: Icons.corporate_fare,
          title: 'Edit Profil Organisasi',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailProfilScreen(user: currentUser),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildAdminMenuItem(
          context: context,
          icon: Icons.analytics_outlined,
          title: 'Manajemen Kampanye',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManajemenKampanyeScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdminMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE0E3E5).withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap ?? () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title akan segera hadir!')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF424656), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFC2C6D8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserMenuList(BuildContext context, UserModel currentUser) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE0E3E5).withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildUserMenuItem(
            context: context,
            icon: Icons.person_outline,
            title: 'Edit Profil',
            iconBg: const Color(0xFFDAE1FF),
            iconColor: const Color(0xFF0050CB),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailProfilScreen(user: currentUser),
                ),
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFECEEF0), indent: 72),
          _buildUserMenuItem(
            context: context,
            icon: Icons.history,
            title: 'Riwayat Donasi',
            iconBg: const Color(0xFFE1F5EE),
            iconColor: const Color(0xFF006B5F),
            onTap: () {
              MainNavigation.navigationKey.currentState?.setIndex(1);
            },
          ),
          const Divider(height: 1, color: Color(0xFFECEEF0), indent: 72),
          _buildUserMenuItem(
            context: context,
            icon: Icons.info_outline,
            title: 'Tentang Kami',
            iconBg: const Color(0xFFF2F4F6),
            iconColor: const Color(0xFF424656),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color iconBg,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$title akan segera hadir!')));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF191C1E),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFC2C6D8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFDAD6),
        foregroundColor: const Color(0xFF93000A),
        elevation: 0,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () => _logout(context),
      icon: const Icon(Icons.logout),
      label: const Text(
        'Keluar',
        style: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFBA1A1A),
        side: const BorderSide(color: Color(0xFFFFDAD6), width: 2),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () => _logout(context),
      icon: const Icon(Icons.logout),
      label: const Text(
        'Keluar',
        style: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StreamDonaturStat extends StatelessWidget {
  final String uid;
  const _StreamDonaturStat({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .where('donaturId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final successfulDonations = docs
            .where((d) => d['status'] == 'berhasil')
            .toList();
        final totalCount = successfulDonations.length;
        final totalSum = successfulDonations.fold<int>(
          0,
          (total, d) => total + (d['nominal'] as int),
        );

        String formatCompact(int nominal) {
          if (nominal >= 1000000) {
            double millions = nominal / 1000000;
            return 'Rp ${millions.toStringAsFixed(millions % 1 == 0 ? 0 : 1)}jt';
          } else if (nominal >= 1000) {
            double thousands = nominal / 1000;
            return 'Rp ${thousands.toStringAsFixed(thousands % 1 == 0 ? 0 : 1)}rb';
          }
          return 'Rp $nominal';
        }

        return Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE0E3E5).withValues(alpha: 0.5),
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
                    const Icon(
                      Icons.favorite,
                      color: Color(0xFF0050CB),
                      size: 24,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'TOTAL DONASI',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF727687),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCount',
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0050CB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE0E3E5).withValues(alpha: 0.5),
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
                    const Icon(
                      Icons.volunteer_activism,
                      color: Color(0xFF00682C),
                      size: 24,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'TERSALURKAN',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF727687),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCompact(totalSum),
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00682C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StreamAdminStat extends StatelessWidget {
  final String uid;
  const _StreamAdminStat({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaigns')
          .where('organisasiId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final activeCampaigns = docs
            .where((d) => d['status'] == 'aktif')
            .toList();
        final totalCount = activeCampaigns.length;
        final totalSum = docs.fold<int>(
          0,
          (total, d) => total + ((d['terkumpul'] ?? 0) as int),
        );

        String formatCompact(int nominal) {
          if (nominal >= 1000000) {
            double millions = nominal / 1000000;
            return 'Rp ${millions.toStringAsFixed(millions % 1 == 0 ? 0 : 1)}jt';
          } else if (nominal >= 1000) {
            double thousands = nominal / 1000;
            return 'Rp ${thousands.toStringAsFixed(thousands % 1 == 0 ? 0 : 1)}rb';
          }
          return 'Rp $nominal';
        }

        return Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE0E3E5).withValues(alpha: 0.5),
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
                    const Icon(
                      Icons.campaign,
                      color: Color(0xFF0050CB),
                      size: 24,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'KAMPANYE AKTIF',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF727687),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCount',
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0050CB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE0E3E5).withValues(alpha: 0.5),
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
                    const Icon(
                      Icons.payments,
                      color: Color(0xFF00682C),
                      size: 24,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'TOTAL DANA',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF727687),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCompact(totalSum),
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00682C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
