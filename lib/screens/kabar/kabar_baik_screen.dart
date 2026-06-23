import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donasee_final_project_ppb/models/allocation_model.dart';
import 'package:donasee_final_project_ppb/models/campaign_model.dart';
import 'package:donasee_final_project_ppb/models/user_model.dart';
import 'package:donasee_final_project_ppb/screens/kabar/detail_alokasi_screen.dart';
import 'package:donasee_final_project_ppb/screens/kabar/form_alokasi_screen.dart';
import 'package:donasee_final_project_ppb/services/allocation_service.dart';
import 'package:donasee_final_project_ppb/services/auth_service.dart';
import 'package:donasee_final_project_ppb/screens/home/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class KabarBaikScreen extends StatefulWidget {
  const KabarBaikScreen({super.key});

  @override
  State<KabarBaikScreen> createState() => _KabarBaikScreenState();
}

class _KabarBaikScreenState extends State<KabarBaikScreen> {
  final _allocationService = AllocationService();
  UserModel? _currentUser;
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final auth = context.read<AuthService>();
    final user = await auth.getCurrentUserModel();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Stream<List<CampaignModel>> _campaignStream() {
    return FirebaseFirestore.instance.collection('campaigns').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => CampaignModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _currentUser?.isAdmin == true;
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: isAdmin
          ? AppBar(
              backgroundColor: const Color(0xFFF7F9FB),
              elevation: 0.5,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              title: const Text(
                'Manajemen Kabar Baik',
                style: TextStyle(
                  color: Color(0xFF0050CB),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'Lexend',
                ),
              ),
            )
          : null,
      floatingActionButton: FutureBuilder(
        future: context.read<AuthService>().getCurrentUserModel(),
        builder: (context, snapshot) {
          final isUserAdmin = snapshot.data?.isAdmin == true;
          if (!isUserAdmin) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            heroTag: 'kabar_baik_fab',
            backgroundColor: const Color(0xFF0050CB),
            foregroundColor: Colors.white,
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const FormAlokasiScreen()),
              );
              if (result == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alokasi berhasil disimpan'),
                    backgroundColor: Color(0xFF0050CB),
                  ),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah'),
          );
        },
      ),
      body: SafeArea(
        child: StreamBuilder<List<CampaignModel>>(
          stream: _campaignStream(),
          builder: (context, campaignSnapshot) {
            if (campaignSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (campaignSnapshot.hasError) {
              return Center(
                child: Text(
                  'Gagal memuat data kampanye.\n${campaignSnapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFBA1A1A)),
                ),
              );
            }

            final campaigns = campaignSnapshot.data ?? [];
            final campaignMap = {for (var c in campaigns) c.id: c};

            final adminUid = _currentUser?.isAdmin == true ? _currentUser?.uid : null;
            final allocationStream = adminUid != null
                ? _allocationService.getAllocationsByAdminStream(adminUid)
                : _allocationService.getAllAllocationsStream();

            return StreamBuilder<List<AllocationModel>>(
              stream: allocationStream,
              builder: (context, allocationSnapshot) {
                if (allocationSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (allocationSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Gagal memuat data alokasi.\n${allocationSnapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFBA1A1A)),
                    ),
                  );
                }

                final allocations = allocationSnapshot.data ?? [];

                // Calculate dynamic statistics
                final totalTersalurkan = allocations.fold<int>(
                  0,
                  (sum, item) => sum + item.nominal,
                );

                // Filter allocations based on the selected category chip
                final filteredAllocations = allocations.where((a) {
                  if (_selectedCategory == 'Semua') return true;
                  final campaign = campaignMap[a.kampanyeId];
                  final category = campaign?.kategori ?? 'Lainnya';
                  if (_selectedCategory == 'Bencana Alam' &&
                      category == 'Bencana') {
                    return true;
                  }
                  return category == _selectedCategory;
                }).toList();

                return CustomScrollView(
                  slivers: [
                    // 1. User Profile Greeting Top Bar
                    if (!isAdmin)
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
                                  final targetIdx = _currentUser?.isAdmin == true ? 2 : 3;
                                  context
                                      .findAncestorStateOfType<
                                        MainNavigationState
                                      >()
                                      ?.setIndex(targetIdx);
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
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          _currentUser?.nama.isNotEmpty == true
                                              ? _currentUser!.nama[0]
                                                    .toUpperCase()
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isAdmin
                                              ? 'Halo, Admin!'
                                              : 'Halo, Donatur!',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF424656),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          _currentUser?.nama ?? 'Donatur',
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
 
                    // 2. Impact Summary Header & Bento Stats Grid
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isAdmin) ...[
                              const Text(
                                'Kabar Baik',
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF191C1E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Laporan transparan alokasi dana dari para donatur yang telah disalurkan hari ini.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: Color(0xFF424656),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
 
                            // Bento Stats Grid (2-column Row)
                            Row(
                              children: [
                                // Left Box: Total Tersalurkan
                                Expanded(
                                  child: Container(
                                    height: 120,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDAE1FF),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Icon(
                                          Icons.account_balance_wallet,
                                          size: 28,
                                          color: Color(0xFF0050CB),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Tersalurkan'.toUpperCase(),
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(
                                                  0xFF001849,
                                                ).withOpacity(0.7),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                currency.format(
                                                  totalTersalurkan,
                                                ),
                                                style: const TextStyle(
                                                  fontFamily: 'Lexend',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF001849),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Right Box: Audit Status
                                Expanded(
                                  child: Container(
                                    height: 120,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE7FFE5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Icon(
                                          Icons.verified,
                                          size: 28,
                                          color: Color(0xFF00682C),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Audit Status'.toUpperCase(),
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(
                                                  0xFF002109,
                                                ).withOpacity(0.7),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Terverifikasi',
                                              style: TextStyle(
                                                fontFamily: 'Lexend',
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
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
                          ],
                        ),
                      ),
                    ),

                    // 3. Search & Filter Chips (Horizontal List)
                    SliverToBoxAdapter(
                      child: Container(
                        height: 52,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildFilterChip('Semua'),
                            _buildFilterChip('Pendidikan'),
                            _buildFilterChip('Kesehatan'),
                            _buildFilterChip('Bencana Alam'),
                            _buildFilterChip('Pangan'),
                            _buildFilterChip('Renovasi'),
                            _buildFilterChip('Lainnya'),
                          ],
                        ),
                      ),
                    ),

                    // 4. Chronological Feed List
                    filteredAllocations.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Belum ada laporan alokasi dana untuk kategori ini.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final allocation = filteredAllocations[index];
                                final campaign =
                                    campaignMap[allocation.kampanyeId];
                                final campaignCategory =
                                    campaign?.kategori ?? 'Lainnya';
                                final campaignImage = campaign?.imageUrl;

                                return _buildAllocationFeedCard(
                                  context,
                                  allocation,
                                  campaignCategory,
                                  campaignImage,
                                  currency,
                                );
                              }, childCount: filteredAllocations.length),
                            ),
                          ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0050CB) : const Color(0xFFECEEF0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label == 'Semua' ? 'Semua Alokasi' : label,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF424656),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationFeedCard(
    BuildContext context,
    AllocationModel allocation,
    String category,
    String? imageUrl,
    NumberFormat currency,
  ) {
    // Themed Category Avatar Configuration
    Color avatarBg;
    Color avatarIconColor;
    IconData avatarIcon;

    switch (category) {
      case 'Pendidikan':
        avatarBg = const Color(0xFFE1F5EE);
        avatarIconColor = const Color(0xFF006B5F);
        avatarIcon = Icons.school_outlined;
        break;
      case 'Kesehatan':
        avatarBg = const Color(0xFFFCEBEB);
        avatarIconColor = const Color(0xFFBA1A1A);
        avatarIcon = Icons.medical_services_outlined;
        break;
      case 'Bencana':
      case 'Bencana Alam':
        avatarBg = const Color(0xFFFFF3E0);
        avatarIconColor = const Color(0xFFE65100);
        avatarIcon = Icons.warning_amber_outlined;
        break;
      case 'Pangan':
        avatarBg = const Color(0xFFE1F5EE);
        avatarIconColor = const Color(0xFF006B5F);
        avatarIcon = Icons.restaurant_outlined;
        break;
      case 'Renovasi':
        avatarBg = const Color(0xFFE8FFE7);
        avatarIconColor = const Color(0xFF00843A);
        avatarIcon = Icons.home_work_outlined;
        break;
      default:
        avatarBg = const Color(0xFFECEEF0);
        avatarIconColor = const Color(0xFF424656);
        avatarIcon = Icons.volunteer_activism_outlined;
    }

    final dateText = DateFormat(
      'd Okt yyyy • HH:mm',
      'id_ID',
    ).format(allocation.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E3E5).withOpacity(0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: avatarBg,
                  child: Icon(avatarIcon, color: avatarIconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allocation.judulAlokasi,
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191C1E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dateText WIB',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xFF727687),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7FFE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 12,
                        color: Color(0xFF00682C),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Selesai',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00682C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Highlighted Nominal Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F9FB),
                borderRadius: BorderRadius.all(Radius.circular(12)),
                border: Border(
                  left: BorderSide(color: Color(0xFF0050CB), width: 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOMINAL ALOKASI',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF424656).withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currency.format(allocation.nominal),
                    style: const TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0050CB),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Description Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              allocation.deskripsi,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF424656),
              ),
            ),
          ),

          // Campaign Receipt/Activity Cover Image (if available)
          if (imageUrl != null && imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.network(
                      imageUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 160,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailAlokasiScreen(
                                  allocationId: allocation.id,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category == 'Pendidikan'
                                    ? Icons.receipt_long
                                    : Icons.image,
                                size: 14,
                                color: const Color(0xFF191C1E),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category == 'Pendidikan'
                                    ? 'Lihat Kuitansi'
                                    : 'Lihat Kegiatan',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF191C1E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Action Button: Lihat Alokasi Dana
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0050CB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailAlokasiScreen(
                      allocationId: allocation.id,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text(
                'Lihat Alokasi Dana',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
