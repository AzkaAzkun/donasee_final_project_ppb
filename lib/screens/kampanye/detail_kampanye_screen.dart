import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donasee_final_project_ppb/services/donation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/campaign_service.dart';
import '../../services/allocation_service.dart';
import '../../models/campaign_model.dart';
import '../../models/allocation_model.dart';
import '../../models/donation_model.dart';
import 'edit_kampanye_screen.dart';
import '../donasiku/form_donasi_screen.dart';
import '../admin/detail_donasi_admin_screen.dart';
import '../kabar/form_alokasi_screen.dart';

class DetailKampanyeScreen extends StatefulWidget {
  final String campaignId;
  final bool isAdmin;
  final String? currentUserId; // UID user yang sedang login

  const DetailKampanyeScreen({
    required this.campaignId,
    this.isAdmin = false,
    this.currentUserId,
    super.key,
  });

  @override
  State<DetailKampanyeScreen> createState() => _DetailKampanyeScreenState();
}

class _DetailKampanyeScreenState extends State<DetailKampanyeScreen> {
  int _selectedTab = 0; // 0 = Deskripsi, 1 = Kabar Terbaru, 2 = Donatur, 3 = Verifikasi
  bool _isDescriptionExpanded = false;

  late final Stream<CampaignModel?> _campaignStream;
  late final Stream<List<AllocationModel>> _allocationsStream;
  late final Stream<List<DonationModel>> _donationsStream;

  String? _loadedOrganisasiId;
  Future<DocumentSnapshot>? _organisasiFuture;

  final fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) {
      return 'Baru saja';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    }
  }

  @override
  void initState() {
    super.initState();
    _campaignStream = CampaignService().getCampaignByIdStream(widget.campaignId);
    _allocationsStream = AllocationService().getAllocationsByCampaignStream(widget.campaignId);
    _donationsStream = DonationService().getDonationsByCampaignStream(widget.campaignId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CampaignModel?>(
      stream: _campaignStream,
      builder: (context, campaignSnapshot) {
        if (campaignSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7F9FB),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final campaign = campaignSnapshot.data;
        if (campaign == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7F9FB),
            body: Center(
              child: Text(
                'Kampanye tidak ditemukan',
                style: TextStyle(fontFamily: 'Lexend'),
              ),
            ),
          );
        }

        final isOwner = widget.isAdmin &&
            widget.currentUserId != null &&
            campaign.organisasiId == widget.currentUserId;

        if (_loadedOrganisasiId != campaign.organisasiId) {
          _loadedOrganisasiId = campaign.organisasiId;
          _organisasiFuture = FirebaseFirestore.instance
              .collection('users')
              .doc(campaign.organisasiId)
              .get();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: _organisasiFuture,
          builder: (context, userSnapshot) {
            String locationText = 'Bandung, Jawa Barat';
            String? phoneText;

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final data = userSnapshot.data!.data() as Map<String, dynamic>?;
              if (data != null) {
                locationText = data['organisasiAlamat'] ?? 'Bandung, Jawa Barat';
                phoneText = data['organisasiTelepon'];
              }
            }

            return StreamBuilder<List<AllocationModel>>(
              stream: _allocationsStream,
              builder: (context, allocationsSnapshot) {
                final allocations = allocationsSnapshot.data ?? [];

                return StreamBuilder<List<DonationModel>>(
                  stream: _donationsStream,
                  builder: (context, donationsSnapshot) {
                    final donations = donationsSnapshot.data ?? [];
                    final successfulDonations = donations
                        .where((d) => d.status == DonationStatus.berhasil)
                        .toList();
                    final pendingDonations = donations
                        .where((d) => d.status == DonationStatus.menungguVerifikasi)
                        .toList();

                    return Scaffold(
                      backgroundColor: const Color(0xFFF7F9FB),
                      appBar: AppBar(
                        backgroundColor: const Color(0xFFF7F9FB),
                        elevation: 0.5,
                        scrolledUnderElevation: 0,
                        leading: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF0050CB),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        title: const Text(
                          'Detail Kampanye',
                          style: TextStyle(
                            color: Color(0xFF191C1E),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            fontFamily: 'Lexend',
                          ),
                        ),
                        actions: widget.isAdmin
                            ? [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Color(0xFF0050CB),
                                  ),
                                  tooltip: 'Edit Kampanye',
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditKampanyeScreen(campaign: campaign),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFBA1A1A),
                                  ),
                                  tooltip: 'Hapus Kampanye',
                                  onPressed: () =>
                                      _confirmDelete(context, campaign),
                                ),
                              ]
                            : [
                                IconButton(
                                  icon: const Icon(
                                    Icons.share_outlined,
                                    color: Color(0xFF0050CB),
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: 'https://donasee.org/campaign/${campaign.id}'));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Tautan kampanye berhasil disalin!',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.favorite_border_outlined,
                                    color: Color(0xFF0050CB),
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Ditambahkan ke favorit!',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                      ),
                      body: SafeArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: isOwner
                              ? _buildAdminDetailContent(
                                  context,
                                  campaign,
                                  allocations,
                                  successfulDonations,
                                  pendingDonations,
                                  locationText,
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Hero Cover
                                    _buildHeroCover(campaign),
                                    const SizedBox(height: 16),

                                    // Title and Creator
                                    _buildHeaderContent(campaign, locationText),
                                    const SizedBox(height: 20),

                                    // Progress Bento Card
                                    _buildProgressBentoCard(
                                      campaign,
                                      successfulDonations.length,
                                    ),
                                    const SizedBox(height: 24),

                                    // Tabs Navigation
                                    _buildTabsNavigation(
                                      isOwner,
                                      allocations.length,
                                      successfulDonations.length,
                                      pendingDonations.length,
                                    ),
                                    const SizedBox(height: 20),

                                    // Tab Content
                                    _buildSelectedTabContent(
                                      campaign,
                                      allocations,
                                      successfulDonations,
                                      pendingDonations,
                                    ),
                                    const SizedBox(height: 80),
                                  ],
                                ),
                        ),
                      ),
                      bottomNavigationBar: widget.isAdmin
                          ? const SizedBox.shrink()
                          : (!campaign.isAktif)
                              ? _buildCampaignFinishedBar(context)
                              : _buildFloatingBottomBar(
                                  context,
                                  campaign,
                                  locationText,
                                  phoneText,
                                ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeroCover(CampaignModel campaign) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE0E3E5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (campaign.imageUrl != null)
                Image.network(
                  campaign.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _gradientFallback(),
                )
              else
                _gradientFallback(),

              // Bottom Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // Badges Overlay
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006B5F),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Terverifikasi',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0050CB),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        campaign.kategori,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0050CB), Color(0xFF006B5F)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.campaign_rounded,
          size: 64,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildHeaderContent(CampaignModel campaign, String location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          campaign.judul,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF191C1E),
            fontFamily: 'Lexend',
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDAE1FF), Color(0xFF6DF5E1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.volunteer_activism_outlined,
                  color: Color(0xFF0050CB),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.organisasiNama,
                    style: const TextStyle(
                      color: Color(0xFF191C1E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Color(0xFF727687),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF727687),
                            fontSize: 12,
                            fontFamily: 'Inter',
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
      ],
    );
  }

  Widget _buildProgressBentoCard(CampaignModel campaign, int donorCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE0E3E5).withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Terkumpul',
                    style: TextStyle(
                      color: Color(0xFF727687),
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmt.format(campaign.terkumpul),
                    style: const TextStyle(
                      color: Color(0xFF0050CB),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lexend',
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Target: ${fmt.format(campaign.targetDana)}',
                    style: const TextStyle(
                      color: Color(0xFF727687),
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(campaign.progressPersen * 100).toInt()}%',
                    style: const TextStyle(
                      color: Color(0xFF006B5F),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lexend',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Gradient Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 12,
              width: double.infinity,
              color: const Color(0xFF0050CB).withValues(alpha: 0.1),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: campaign.progressPersen,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0050CB), Color(0xFF006B5F)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bottom Bento Metrics Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.group,
                          color: Color(0xFF0050CB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DONATUR',
                              style: TextStyle(
                                color: Color(0xFF727687),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$donorCount',
                              style: const TextStyle(
                                color: Color(0xFF191C1E),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lexend',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.schedule,
                          color: Color(0xFF0050CB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SISA HARI',
                              style: TextStyle(
                                color: Color(0xFF727687),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${campaign.sisaHari >= 0 ? campaign.sisaHari : 0} Hari',
                              style: const TextStyle(
                                color: Color(0xFF191C1E),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lexend',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabsNavigation(
    bool isOwner,
    int updateCount,
    int donorCount,
    int pendingCount,
  ) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFC2C6D8),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabButton(0, 'Deskripsi'),
            const SizedBox(width: 24),
            _buildTabButton(1, 'Kabar Terbaru ($updateCount)'),
            const SizedBox(width: 24),
            _buildTabButton(2, 'Donatur ($donorCount)'),
            if (isOwner) ...[
              const SizedBox(width: 24),
              _buildTabButton(3, 'Verifikasi ($pendingCount)'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String text) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(
                  bottom: BorderSide(
                    color: Color(0xFF0050CB),
                    width: 2.5,
                  ),
                )
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0050CB) : const Color(0xFF727687),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
            fontFamily: 'Lexend',
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(
    CampaignModel campaign,
    List<AllocationModel> allocations,
    List<DonationModel> successfulDonations,
    List<DonationModel> pendingDonations,
  ) {
    switch (_selectedTab) {
      case 0:
        return _buildDeskripsiTab(campaign);
      case 1:
        return _buildKabarTab(allocations);
      case 2:
        return _buildDonaturTab(successfulDonations);
      case 3:
        return _buildVerifikasiTab(pendingDonations, campaign.id);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDeskripsiTab(CampaignModel campaign) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail Kampanye',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF191C1E),
            fontFamily: 'Lexend',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          campaign.deskripsi,
          maxLines: _isDescriptionExpanded ? null : 4,
          overflow:
              _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF424656),
            fontFamily: 'Inter',
            height: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            setState(() {
              _isDescriptionExpanded = !_isDescriptionExpanded;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isDescriptionExpanded ? 'Tutup' : 'Baca Selengkapnya',
                style: const TextStyle(
                  color: Color(0xFF0050CB),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Icon(
                _isDescriptionExpanded ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFF0050CB),
                size: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE7FFE5).withValues(alpha: 0.4),
            border: const Border(
              left: BorderSide(color: Color(0xFF00682C), width: 4),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: const Text(
            '"Sedekah itu menghapus dosa sebagaimana air memadamkan api." — HR. Tirmidzi',
            style: TextStyle(
              color: Color(0xFF005321),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKabarTab(List<AllocationModel> allocations) {
    if (allocations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: const Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Color(0xFFC2C6D8),
            ),
            SizedBox(height: 12),
            Text(
              'Belum ada laporan penggunaan dana',
              style: TextStyle(
                color: Color(0xFF727687),
                fontSize: 13,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allocations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final alloc = allocations[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE0E3E5).withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF0050CB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7FFE5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Penyaluran Dana',
                            style: TextStyle(
                              color: Color(0xFF00682C),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _formatRelativeDate(alloc.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF727687),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alloc.judulAlokasi,
                      style: const TextStyle(
                        color: Color(0xFF191C1E),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Lexend',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alloc.deskripsi,
                      style: const TextStyle(
                        color: Color(0xFF727687),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fmt.format(alloc.nominal),
                      style: const TextStyle(
                        color: Color(0xFF006B5F),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Lexend',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDonaturTab(List<DonationModel> successfulDonations) {
    if (successfulDonations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: const Column(
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 48,
              color: Color(0xFFC2C6D8),
            ),
            SizedBox(height: 12),
            Text(
              'Belum ada donatur. Jadilah yang pertama!',
              style: TextStyle(
                color: Color(0xFF727687),
                fontSize: 13,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: successfulDonations.length,
          separatorBuilder: (context, index) =>
              const Divider(color: Color(0xFFECEEF0), height: 1),
          itemBuilder: (context, index) {
            final donation = successfulDonations[index];
            final nameParts = donation.donaturNama.trim().split(' ');
            final initial = nameParts.isNotEmpty && nameParts[0].isNotEmpty
                ? nameParts[0][0].toUpperCase()
                : '?';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFDAE1FF),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Color(0xFF0050CB),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donation.donaturNama,
                          style: const TextStyle(
                            color: Color(0xFF191C1E),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatRelativeDate(donation.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF727687),
                            fontSize: 11,
                          ),
                        ),
                        if (donation.pesan != null && donation.pesan!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '"${donation.pesan}"',
                            style: const TextStyle(
                              color: Color(0xFF727687),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '+ ${fmt.format(donation.nominal)}',
                    style: const TextStyle(
                      color: Color(0xFF006B5F),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Lexend',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              '"Semoga menjadi amal jariyah untuk para donatur semua. Amin."',
              style: TextStyle(
                color: Color(0xFF727687),
                fontStyle: FontStyle.italic,
                fontSize: 12,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifikasiTab(List<DonationModel> pendingDonations, String campaignId) {
    if (pendingDonations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: const Column(
          children: [
            Icon(
              Icons.pending_actions_outlined,
              size: 48,
              color: Color(0xFFC2C6D8),
            ),
            SizedBox(height: 12),
            Text(
              'Tidak ada donasi menunggu verifikasi',
              style: TextStyle(
                color: Color(0xFF727687),
                fontSize: 13,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pendingDonations.length,
      separatorBuilder: (context, index) =>
          const Divider(color: Color(0xFFECEEF0), height: 1),
      itemBuilder: (context, index) {
        final donation = pendingDonations[index];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFFCE4EC),
                child: Icon(
                  Icons.pending_outlined,
                  color: Color(0xFFBA1A1A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.donaturNama,
                      style: const TextStyle(
                        color: Color(0xFF191C1E),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fmt.format(donation.nominal),
                      style: const TextStyle(
                        color: Color(0xFF0050CB),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await DonationService().konfirmasiDonasi(
                      donation.id,
                      campaignId,
                      donation.nominal,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Donasi berhasil dikonfirmasi!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal konfirmasi: $e')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006B5F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Konfirmasi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCampaignFinishedBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Kampanye telah selesai / tidak aktif',
            style: TextStyle(
              color: Color(0xFF727687),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBottomBar(
    BuildContext context,
    CampaignModel campaign,
    String locationText,
    String? phoneText,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0050CB),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FormDonasiScreen(campaign: campaign),
                  ),
                );
              },
              icon: const Icon(Icons.volunteer_activism, size: 20),
              label: const Text(
                'Donasi Sekarang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lexend',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () =>
                _showContactBottomSheet(context, campaign, locationText, phoneText),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE6E8EA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF0050CB),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactBottomSheet(
    BuildContext context,
    CampaignModel campaign,
    String locationText,
    String? phoneText,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hubungi Pengelola',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lexend',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDAE1FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Color(0xFF0050CB),
                  ),
                ),
                title: Text(
                  campaign.organisasiNama,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(locationText),
              ),
              if (phoneText != null && phoneText.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE7FFE5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_outlined,
                      color: Color(0xFF00682C),
                    ),
                  ),
                  title: const Text(
                    'Telepon / WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(phoneText),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: phoneText));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Nomor telepon disalin ke papan klip!',
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0050CB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, CampaignModel c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Kampanye?'),
          ],
        ),
        content: Text(
          'Kampanye "${c.judul}" akan dihapus permanen.\n\nTindakan ini tidak bisa dibatalkan.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await CampaignService().deleteCampaign(c.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  Widget _buildAdminDetailContent(
    BuildContext context,
    CampaignModel campaign,
    List<AllocationModel> allocations,
    List<DonationModel> successfulDonations,
    List<DonationModel> pendingDonations,
    String locationText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Hero Cover with Status Badge Overlay
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE0E3E5),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (campaign.imageUrl != null)
                    Image.network(campaign.imageUrl!, fit: BoxFit.cover)
                  else
                    _gradientFallback(),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _buildAdminStatusBadge(campaign.status),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          campaign.judul,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF191C1E),
            fontFamily: 'Lexend',
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),

        // Progress Bento Card
        _buildProgressBentoCard(campaign, successfulDonations.length),
        const SizedBox(height: 24),

        // Management Actions (Edit Kampanye, Update Kabar)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditKampanyeScreen(campaign: campaign),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0050CB),
                  side: const BorderSide(color: Color(0xFF0050CB), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit Kampanye', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FormAlokasiScreen(preSelectedCampaignId: campaign.id),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0050CB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.campaign_rounded, size: 18),
                label: const Text('Update Kabar', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Description Section
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF0050CB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Deskripsi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191C1E),
                fontFamily: 'Lexend',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          campaign.deskripsi,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF424656),
            fontFamily: 'Inter',
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),

        // Transparency / Fund Allocation Card
        InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              builder: (_) => Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transparansi Dana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Lexend')),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildKabarTab(allocations),
                    ),
                  ],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFECEEF0).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC2C6D8).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6DF5E1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF006F64), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Transparansi Dana',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF191C1E)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Rincian rencana alokasi dana kampanye',
                        style: TextStyle(fontSize: 12, color: Color(0xFF727687)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF727687), size: 24),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Payment Verification Section
        if (pendingDonations.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Verifikasi Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191C1E),
                  fontFamily: 'Lexend',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pendingDonations.length} Perlu Verifikasi',
                  style: const TextStyle(
                    color: Color(0xFFBA1A1A),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingDonations.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final d = pendingDonations[index];
              final dateStr = _formatRelativeDate(d.createdAt);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC2C6D8).withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFDAE1FF),
                          radius: 20,
                          child: Text(
                            d.donaturNama.isNotEmpty ? d.donaturNama[0].toUpperCase() : '?',
                            style: const TextStyle(color: Color(0xFF0050CB), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.donaturNama,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF191C1E)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateStr,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF727687)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              fmt.format(d.nominal),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF006B5F)),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Menunggu Verifikasi',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailDonasiAdminScreen(donation: d),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDAE1FF),
                          foregroundColor: const Color(0xFF001849),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.receipt_long_rounded, size: 16),
                        label: const Text('Lihat Bukti', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],

        // Donatur Terbaru Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Donatur Terbaru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF191C1E),
                fontFamily: 'Lexend',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6DF5E1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${successfulDonations.length} Total',
                style: const TextStyle(
                  color: Color(0xFF006F64),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (successfulDonations.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Belum ada donatur.', style: TextStyle(color: Color(0xFF727687), fontSize: 14)),
            ),
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: successfulDonations.length > 3 ? 3 : successfulDonations.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final d = successfulDonations[index];
              final dateStr = _formatRelativeDate(d.createdAt);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC2C6D8).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFDAE1FF),
                      radius: 20,
                      child: Text(
                        d.donaturNama.isNotEmpty ? d.donaturNama[0].toUpperCase() : '?',
                        style: const TextStyle(color: Color(0xFF0050CB), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.donaturNama,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF191C1E)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF727687)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      fmt.format(d.nominal),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF006B5F)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (_) => Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Semua Donatur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Lexend')),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildDonaturTab(successfulDonations),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Text(
                'Lihat Semua Donatur',
                style: TextStyle(color: Color(0xFF0050CB), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdminStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    if (status == 'aktif') {
      bg = const Color(0xFF6DF5E1);
      text = const Color(0xFF006F64);
      label = 'Aktif';
    } else if (status == 'selesai') {
      bg = const Color(0xFFECEEF0);
      text = const Color(0xFF424656);
      label = 'Selesai';
    } else {
      bg = const Color(0xFFFFDAD6);
      text = const Color(0xFFBA1A1A);
      label = 'Verifikasi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'aktif' ? Icons.check_circle_rounded : status == 'selesai' ? Icons.verified_rounded : Icons.pending_rounded,
            color: text,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
