import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfilScreen extends StatelessWidget {
  final UserModel user;
  const ProfilScreen({required this.user, super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar Aplikasi?'),
        content: const Text('Kamu akan logout dari akun ini.'),
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
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header avatar ─────────────────────────────────
            Container(
              width: double.infinity,
              color: const Color(0xFF1D9E75),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      user.nama.isNotEmpty
                          ? user.nama.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.nama,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Badge role
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      isAdmin ? 'Admin Panti' : 'Donatur',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Info akun ─────────────────────────────────────
            _sectionCard(
              title: 'Informasi Akun',
              children: [
                _infoTile(Icons.person_outline, 'Nama Lengkap', user.nama),
                _infoTile(Icons.email_outlined, 'Email', user.email),
                if (isAdmin && user.organisasiNama != null)
                  _infoTile(
                    Icons.home_outlined,
                    'Nama Panti',
                    user.organisasiNama!,
                  ),
                _infoTile(
                  Icons.shield_outlined,
                  'Role',
                  isAdmin ? 'Admin / Panti Asuhan' : 'Donatur',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Ringkasan aktivitas — berbeda per role ─────────
            if (!isAdmin)
              _sectionCard(
                title: 'Aktivitas Donasi',
                children: [_StreamDonaturStat(uid: user.uid)],
              ),

            if (isAdmin)
              _sectionCard(
                title: 'Ringkasan Admin',
                children: [_StreamAdminStat()],
              ),

            const SizedBox(height: 12),

            // ── Tombol logout ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF085041),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1D9E75)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreamDonaturStat extends StatelessWidget {
  final String uid;
  const _StreamDonaturStat({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .where('donaturId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        final total = docs.length;
        final berhasil = docs.where((d) => d['status'] == 'berhasil').length;
        final pending = docs
            .where(
              (d) =>
                  d['status'] == 'pending' ||
                  d['status'] == 'menunggu_verifikasi',
            )
            .length;
        final totalNominal = docs
            .where((d) => d['status'] == 'berhasil')
            .fold<int>(0, (sum, d) => sum + (d['nominal'] as int));

        final fmt = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );

        return Column(
          children: [
            Row(
              children: [
                _statBox(
                  'Total Donasi',
                  '$total kali',
                  const Color(0xFFE1F5EE),
                  const Color(0xFF085041),
                ),
                const SizedBox(width: 8),
                _statBox(
                  'Berhasil',
                  '$berhasil kali',
                  const Color(0xFFE1F5EE),
                  const Color(0xFF1D9E75),
                ),
                const SizedBox(width: 8),
                _statBox(
                  'Proses',
                  '$pending kali',
                  const Color(0xFFFAEEDA),
                  const Color(0xFF633806),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Dana Tersalurkan',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmt.format(totalNominal),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D9E75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statBox(String label, String value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget stat admin (stream Firestore) ───────────────────
class _StreamAdminStat extends StatelessWidget {
  const _StreamAdminStat();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .where('status', isEqualTo: 'menunggu_verifikasi')
          .snapshots(),
      builder: (context, snapshotPending) {
        return StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('campaigns')
              .where('status', isEqualTo: 'aktif')
              .snapshots(),
          builder: (context, snapshotCampaign) {
            final menugggu = snapshotPending.data?.docs.length ?? 0;
            final aktif = snapshotCampaign.data?.docs.length ?? 0;

            return Row(
              children: [
                _statBox(
                  'Donasi Menunggu',
                  '$menugggu',
                  const Color(0xFFFAEEDA),
                  const Color(0xFF633806),
                ),
                const SizedBox(width: 8),
                _statBox(
                  'Kampanye Aktif',
                  '$aktif',
                  const Color(0xFFE1F5EE),
                  const Color(0xFF1D9E75),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statBox(String label, String value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
