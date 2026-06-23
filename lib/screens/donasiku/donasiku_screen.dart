import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/donation_service.dart';
import '../../services/auth_service.dart';
import '../../models/donation_model.dart';
import '../../models/user_model.dart';
import '../home/main_navigation.dart';
import 'detail_donasi_screen.dart';

class DonasikuScreen extends StatefulWidget {
  final UserModel? user;
  const DonasikuScreen({this.user, super.key});

  static String activeTab = 'aktif';

  @override
  State<DonasikuScreen> createState() => _DonasikuScreenState();
}

class _DonasikuScreenState extends State<DonasikuScreen> {
  final _svc = DonationService();
  UserModel? _user;
  bool _loadingUser = true;
  
  String get _activeTab => DonasikuScreen.activeTab;
  set _activeTab(String val) {
    DonasikuScreen.activeTab = val;
  }

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _user = widget.user;
      _loadingUser = false;
    } else {
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    final auth = context.read<AuthService>();
    final user = await auth.getCurrentUserModel();
    if (mounted) {
      setState(() {
        _user = user;
        _loadingUser = false;
      });
    }
  }

  final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dateFmt = DateFormat('d MMMM yyyy, HH:mm', 'id_ID');

  String _formatCompact(int nominal) {
    if (nominal >= 1000000) {
      double millions = nominal / 1000000;
      return 'Rp ${millions.toStringAsFixed(millions % 1 == 0 ? 0 : 1)}jt';
    } else if (nominal >= 1000) {
      double thousands = nominal / 1000;
      return 'Rp ${thousands.toStringAsFixed(thousands % 1 == 0 ? 0 : 1)}rb';
    }
    return 'Rp $nominal';
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isAdmin = _user?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: StreamBuilder<List<DonationModel>>(
          stream: _svc.getDonationsByUserStream(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final donations = snapshot.data ?? [];

            // Hitung metrik bento
            final successfulDonations = donations
                .where((d) => d.status == DonationStatus.berhasil)
                .toList();
            final totalDonasiCount = successfulDonations.length;
            final totalDanaTersalurkan = successfulDonations.fold<int>(
              0,
              (sum, d) => sum + d.nominal,
            );

            // Partisi data client-side
            // Aktif: pending (menunggu transfer) & menunggu verifikasi (sedang diproses)
            final aktifDonations = donations
                .where((d) =>
                    d.status == DonationStatus.pending ||
                    d.status == DonationStatus.menungguVerifikasi)
                .toList();

            // Riwayat: berhasil (donasi sukses selesai dilakukan)
            final riwayatDonations = donations
                .where((d) => d.status == DonationStatus.berhasil)
                .toList();

            final currentList = _activeTab == 'aktif' ? aktifDonations : riwayatDonations;

            return CustomScrollView(
              slivers: [
                // 1. TOP APP BAR
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            context.findAncestorStateOfType<MainNavigationState>()?.setIndex(3);
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDAE1FF),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _user?.nama.isNotEmpty == true
                                        ? _user!.nama[0].toUpperCase()
                                        : 'D',
                                    style: const TextStyle(
                                      color: Color(0xFF001849),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAdmin ? 'Halo, Admin!' : 'Halo, Donatur!',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF424656),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _user?.nama ?? 'Donatur',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF191C1E),
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
                ),
                // Sticky Sub-Header with Tabs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Donasiku',
                          style: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildTabButton('aktif', 'Aktif', aktifDonations.length),
                            const SizedBox(width: 24),
                            _buildTabButton('riwayat', 'Riwayat', riwayatDonations.length),
                          ],
                        ),
                        const Divider(color: Color(0xFFC2C6D8), height: 1, thickness: 1),
                      ],
                    ),
                  ),
                ),

                // Content List
                if (currentList.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildDonationCard(currentList[index]);
                        },
                        childCount: currentList.length,
                      ),
                    ),
                  ),

                // Featured Impact Bento Grid (Only when view is not empty or at bottom of scroll)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 40),
                    child: _buildBentoGrid(totalDonasiCount, totalDanaTersalurkan),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabButton(String tabKey, String label, int count) {
    final isSelected = _activeTab == tabKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tabKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(
                  bottom: BorderSide(
                    color: Color(0xFF0050CB),
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF0050CB) : const Color(0xFF424656),
          ),
        ),
      ),
    );
  }

  Widget _buildDonationCard(DonationModel d) {
    final isBerhasil = d.status == DonationStatus.berhasil;
    final isWaiting = d.status == DonationStatus.menungguVerifikasi;

    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    IconData badgeIcon;
    Widget actionButton;

    if (isBerhasil) {
      badgeBg = const Color(0xFFE7FFE5);
      badgeText = const Color(0xFF00682C);
      badgeLabel = 'Berhasil';
      badgeIcon = Icons.check_circle;
      actionButton = TextButton(
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailDonasiScreen(donation: d)),
          );
        },
        child: const Text(
          'Lihat Kabar',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0050CB),
          ),
        ),
      );
    } else if (isWaiting) {
      badgeBg = const Color(0xFFDAE1FF);
      badgeText = const Color(0xFF0050CB);
      badgeLabel = 'Menunggu Verifikasi';
      badgeIcon = Icons.update;
      actionButton = TextButton(
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailDonasiScreen(donation: d)),
          );
        },
        child: const Text(
          'Detail',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0050CB),
          ),
        ),
      );
    } else {
      // Pending
      badgeBg = const Color(0xFFFCEBEB);
      badgeText = const Color(0xFFBA1A1A);
      badgeLabel = 'Pending';
      badgeIcon = Icons.error_outline;
      actionButton = TextButton(
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailDonasiScreen(donation: d)),
          );
        },
        child: const Text(
          'Coba Lagi',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0050CB),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailDonasiScreen(donation: d)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E3E5).withValues(alpha: 0.5)),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.kampanyeJudul,
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191C1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateFmt.format(d.createdAt),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF424656),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 12, color: badgeText),
                      const SizedBox(width: 4),
                      Text(
                        badgeLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Donasi',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF424656),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fmt.format(d.nominal),
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isBerhasil || isWaiting ? const Color(0xFF0050CB) : const Color(0xFF424656),
                      ),
                    ),
                  ],
                ),
                actionButton,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoGrid(int count, int totalSum) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDAE1FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.volunteer_activism, size: 28, color: Color(0xFF0050CB)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count',
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF001849),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Total Donasi',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF001849),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE7FFE5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.emoji_events, size: 28, color: Color(0xFF00682C)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatCompact(totalSum),
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002109),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tersalurkan',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF002109),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0050CB).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_outline, size: 48, color: Color(0xFF0050CB)),
            ),
            const SizedBox(height: 16),
            Text(
              _activeTab == 'aktif' ? 'Tidak ada donasi aktif' : 'Belum ada riwayat donasi',
              style: const TextStyle(
                fontFamily: 'Lexend',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _activeTab == 'aktif'
                  ? 'Yuk mulai berdonasi dan sebarkan kebaikan hari ini!'
                  : 'Transaksi donasi Anda yang telah lampau akan tercatat di sini.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF727687),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
