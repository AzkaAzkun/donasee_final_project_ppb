import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donasee_final_project_ppb/models/user_model.dart';
import 'package:donasee_final_project_ppb/services/image_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import 'super_admin_verification_list.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _currentTab = 0;

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar Aplikasi?'),
        content: const Text('Anda akan keluar dari akun Super Admin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0050CB); // #0050cb (Compassion Blue)

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        titleSpacing: 24,
        title: Row(
          children: const [
            Icon(
              Icons.admin_panel_settings_rounded,
              color: primaryColor,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Super Admin',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF2F4F6),
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded, color: primaryColor, size: 18),
              label: const Text(
                'Logout',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _currentTab == 0 
          ? const SuperAdminVerificationList() 
          : _ProfileTab(onLogout: () => _logout(context)),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFECEEF0), // bg-surface-container
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), // rounded-t-xl
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), // shadow-[0_-4px_20px_rgba(0,0,0,0.04)]
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                index: 0,
                icon: Icons.list_alt_rounded,
                label: 'Manajemen Panti',
              ),
              _buildBottomNavItem(
                index: 1,
                icon: Icons.account_circle_rounded,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isActive = _currentTab == index;
    if (isActive) {
      return GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6DF5E1), // bg-secondary-container
            borderRadius: BorderRadius.circular(9999), // rounded-full
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(0xFF006F64), // text-on-secondary-container
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF006F64), // text-on-secondary-container
                  fontSize: 12,
                  fontWeight: FontWeight.w600, // font-label-md
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.all(8),
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(0xFF424656), // text-on-surface-variant
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF424656), // text-on-surface-variant
                  fontSize: 12,
                  fontWeight: FontWeight.w600, // font-label-md
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: PROFIL SUPER ADMIN
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatefulWidget {
  final VoidCallback onLogout;
  const _ProfileTab({required this.onLogout});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  Future<Map<String, dynamic>>? _profileDataFuture;

  @override
  void initState() {
    super.initState();
    _profileDataFuture = _loadProfileData();
  }

  Future<Map<String, dynamic>> _loadProfileData() async {
    final results = await Future.wait([
      AuthService().getCurrentUserModel(),
      FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .where('isVerified', isEqualTo: true)
          .count()
          .get(),
      FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .count()
          .get(),
    ]);
    return {
      'user': results[0] as UserModel?,
      'verifiedCount': (results[1] as AggregateQuerySnapshot).count ?? 0,
      'totalCount': (results[2] as AggregateQuerySnapshot).count ?? 0,
    };
  }

  Future<void> _editAvatar(UserModel user) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF0050CB)),
      ),
    );

    try {
      final file = File(pickedFile.path);
      final url = await ImageUploadService().uploadProfilePicture(
        uid: user.uid,
        imageFile: file,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fotoUrl': url});

      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Color(0xFF00682C),
          ),
        );
        setState(() {
          _profileDataFuture = _loadProfileData();
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah foto profil: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0050CB)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat profil: ${snapshot.error}'));
        }

        final data = snapshot.data!;
        final user = data['user'] as UserModel?;
        final verifiedCount = data['verifiedCount'] as int? ?? 0;
        final totalCount = data['totalCount'] as int? ?? 0;

        if (user == null) {
          return const Center(child: Text('Data profil tidak ditemukan.'));
        }

        final activeSince = DateFormat('yyyy').format(user.createdAt);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bento Profile Hero Card
              Container(
                padding: const EdgeInsets.all(32), // p-stack-lg
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24), // rounded-3xl
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04), // shadow-[0_4px_20px_rgba(0,0,0,0.04)]
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4), // ring-4
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF0066FF), // ring-primary-container
                          ),
                          child: CircleAvatar(
                            radius: 64, // 128px diameter on mobile
                            backgroundColor: const Color(0xFFF2F4F6),
                            backgroundImage: user.fotoUrl != null && user.fotoUrl!.isNotEmpty
                                ? NetworkImage(user.fotoUrl!)
                                : null,
                            child: user.fotoUrl == null || user.fotoUrl!.isEmpty
                                ? const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    color: Color(0xFF0050CB),
                                    size: 64,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _editAvatar(user),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0050CB), // bg-primary
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      user.nama.isNotEmpty ? user.nama : 'Super Admin',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24, // font-headline-lg
                        fontWeight: FontWeight.w600, // font-semibold
                        color: Color(0xFF191C1E), // text-on-surface
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6DF5E1), // bg-secondary-container
                        borderRadius: BorderRadius.circular(20), // rounded-full
                      ),
                      child: const Text(
                        'Super Admin Level 3',
                        style: TextStyle(
                          fontSize: 12, // font-label-sm
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF006F64), // text-on-secondary-container
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.only(top: 24),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Color(0xFFE0E3E5), // border-surface-variant
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.mail_outline_rounded, color: Color(0xFF424656), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  user.email,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF424656), // text-on-surface-variant
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded, color: Color(0xFF424656), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Terverifikasi sejak $activeSince',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF424656), // text-on-surface-variant
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Activity Cards Grid (Col-2 / Col-1 Layout)
              Row(
                children: [
                  Expanded(
                    child: _buildActivityCard(
                      icon: Icons.task_alt_rounded,
                      bgColor: const Color(0xFF0066FF), // bg-primary-container
                      valueColor: const Color(0xFFF8F7FF), // text-on-primary-container
                      labelColor: const Color(0xFFF8F7FF).withValues(alpha: 0.8),
                      iconColor: const Color(0xFFF8F7FF),
                      value: '$verifiedCount',
                      label: 'Verifikasi Selesai',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActivityCard(
                      icon: Icons.group_rounded,
                      bgColor: const Color(0xFF00843A), // bg-tertiary-container
                      valueColor: const Color(0xFFE7FFE5), // text-on-tertiary-container
                      labelColor: const Color(0xFFE7FFE5).withValues(alpha: 0.8),
                      iconColor: const Color(0xFFE7FFE5),
                      value: '$totalCount',
                      label: 'Panti Terdaftar',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildActivityCard(
                icon: Icons.schedule_rounded,
                bgColor: Colors.white,
                borderColor: const Color(0xFFE0E3E5), // border-surface-variant
                valueColor: const Color(0xFF191C1E), // text-on-surface
                labelColor: const Color(0xFF424656), // text-on-surface-variant
                iconColor: const Color(0xFF0050CB), // text-primary
                value: '12h',
                label: 'Rata-rata Respon',
              ),
              const SizedBox(height: 24),

              // Log out button card
              InkWell(
                onTap: widget.onLogout,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24), // rounded-3xl
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04), // shadow-[0_4px_20px_rgba(0,0,0,0.04)]
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDAD6).withValues(alpha: 0.2), // bg-error-container/20
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFBA1A1A), // text-error
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Keluar Sesi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFBA1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Keluar dari akun Super Admin',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFFBA1A1A).withValues(alpha: 0.7), // text-error/70
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFFBA1A1A), // text-error
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required Color bgColor,
    required Color valueColor,
    required Color labelColor,
    Color? iconColor,
    Color? borderColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 128, // matches h-32
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16), // rounded-2xl
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor ?? valueColor, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24, // font-display-lg
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12, // font-label-sm
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
