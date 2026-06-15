import 'package:donasee_final_project_ppb/screens/home/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/campaign_service.dart';
import '../../models/campaign_model.dart';
import '../../models/user_model.dart';
import '../kampanye/form_kampanye_screen.dart';
import '../kampanye/detail_kampanye_screen.dart';

enum _SortMode { terbaru, terdesak }

class JelajahScreen extends StatefulWidget {
  final UserModel? user;
  const JelajahScreen({this.user, super.key});

  @override
  State<JelajahScreen> createState() => _JelajahScreenState();
}

class _JelajahScreenState extends State<JelajahScreen> {
  final _svc = CampaignService();
  UserModel? _user;
  bool _loadingUser = true;

  _SortMode _sort = _SortMode.terbaru;
  bool _filterMilikSaya = false;
  String? _selectedCategory;
  String _searchQuery = '';

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

  List<CampaignModel> _applyFiltersAndSort(List<CampaignModel> raw) {
    List<CampaignModel> list = List.from(raw);

    if (_filterMilikSaya && (_user?.isAdmin ?? false)) {
      list = list.where((c) => c.organisasiId == _user!.uid).toList();
    }

    if (_selectedCategory != null) {
      list = list.where((c) => c.kategori == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((c) {
        return c.judul.toLowerCase().contains(query) ||
            c.organisasiNama.toLowerCase().contains(query);
      }).toList();
    }

    switch (_sort) {
      case _SortMode.terbaru:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortMode.terdesak:
        list.sort((a, b) => a.sisaHari.compareTo(b.sisaHari));
        break;
    }

    return list;
  }

  void _showSortFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isAdmin = _user?.isAdmin ?? false;
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Urutkan & Filter',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Urutkan Berdasarkan:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Terbaru'),
                        selected: _sort == _SortMode.terbaru,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _sort = _SortMode.terbaru);
                            setSheetState(() {});
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Paling Mendesak'),
                        selected: _sort == _SortMode.terdesak,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _sort = _SortMode.terdesak);
                            setSheetState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Filter Kampanye:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hanya Kampanye Milik Saya'),
                      value: _filterMilikSaya,
                      activeColor: const Color(0xFF0050CB),
                      onChanged: (val) {
                        setState(() => _filterMilikSaya = val);
                        setSheetState(() {});
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0050CB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Terapkan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToDetail(CampaignModel campaign) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailKampanyeScreen(
          campaignId: campaign.id,
          isAdmin: _user?.isAdmin ?? false,
          currentUserId: _user?.uid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _user?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: StreamBuilder<List<CampaignModel>>(
          stream: _svc.getCampaignsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Gagal memuat kampanye: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final rawCampaigns = snapshot.data ?? [];
            final processedCampaigns = _applyFiltersAndSort(rawCampaigns);
            final urgentCampaigns = rawCampaigns
                .where((c) => c.sisaHari <= 7 && c.isAktif)
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. TOP APP BAR
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          context
                              .findAncestorStateOfType<MainNavigationState>()
                              ?.setIndex(3);
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
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFF0050CB),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Belum ada notifikasi baru.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 2. MAIN SCROLLABLE AREA
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Search Section
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Cari kampanye donasi...',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Color(0xFF727687),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Kategori Section
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Kategori',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF191C1E),
                                    ),
                                  ),
                                  if (_selectedCategory != null)
                                    TextButton(
                                      onPressed: () => setState(
                                        () => _selectedCategory = null,
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Reset',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF0050CB),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 95,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    _buildCategoryItem(
                                      'Pendidikan',
                                      Icons.school_rounded,
                                      const Color(0xFF0050CB),
                                      const Color(0xFFDAE1FF),
                                    ),
                                    _buildCategoryItem(
                                      'Pangan',
                                      Icons.restaurant_rounded,
                                      const Color(0xFF006B5F),
                                      const Color(0xFFE1F5EE),
                                    ),
                                    _buildCategoryItem(
                                      'Renovasi',
                                      Icons.home_work_rounded,
                                      const Color(0xFF00843A),
                                      const Color(0xFFE8FFE7),
                                    ),
                                    _buildCategoryItem(
                                      'Kesehatan',
                                      Icons.medical_services_rounded,
                                      const Color(0xFFBA1A1A),
                                      const Color(0xFFFCEBEB),
                                    ),
                                    _buildCategoryItem(
                                      'Bencana',
                                      Icons.warning_amber_rounded,
                                      const Color(0xFFE65100),
                                      const Color(0xFFFFF3E0),
                                    ),
                                    _buildCategoryItem(
                                      'Lainnya',
                                      Icons.grid_view_rounded,
                                      const Color(0xFF424656),
                                      const Color(0xFFECEEF0),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Kampanye Mendesak (Horizontal list)
                        if (urgentCampaigns.isNotEmpty &&
                            _selectedCategory == null &&
                            _searchQuery.isEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Kampanye Mendesak',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF191C1E),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFBA1A1A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 330,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(left: 16),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: urgentCampaigns.length,
                              itemBuilder: (context, index) {
                                return _buildUrgentCampaignCard(
                                  urgentCampaigns[index],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Jelajah Kampanye (Vertical list)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Jelajah Kampanye',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF191C1E),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.tune,
                                  color: Color(0xFF424656),
                                ),
                                onPressed: _showSortFilterBottomSheet,
                              ),
                            ],
                          ),
                        ),

                        if (processedCampaigns.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.campaign_outlined,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Tidak ada kampanye aktif ditemukan.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: processedCampaigns.length,
                            itemBuilder: (context, index) {
                              return _buildExploreCampaignCard(
                                processedCampaigns[index],
                              );
                            },
                          ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _loadingUser
          ? null
          : isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'jelajah_fab',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FormKampanyeScreen()),
              ),
              backgroundColor: const Color(0xFF0050CB),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Buat Kampanye'),
            )
          : null,
    );
  }

  Widget _buildCategoryItem(String name, IconData icon, Color color, Color bg) {
    final isSelected = _selectedCategory == name;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedCategory = null;
          } else {
            _selectedCategory = name;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 80,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? color : bg,
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? Border.all(color: color, width: 2) : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: const Color(0xFF191C1E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentCampaignCard(CampaignModel campaign) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return GestureDetector(
      onTap: () => _navigateToDetail(campaign),
      child: Container(
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFC2C6D8).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: campaign.imageUrl != null
                      ? Image.network(
                          campaign.imageUrl!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _fallbackImage(height: 140),
                        )
                      : _fallbackImage(height: 140),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'MENDESAK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: Color(0xFF006B5F),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          campaign.organisasiNama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF424656),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GradientProgressBar(value: campaign.progressPersen),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fmt.format(campaign.terkumpul),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0050CB),
                        ),
                      ),
                      Text(
                        'Target: ${fmt.format(campaign.targetDana)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF727687),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFECEEF0)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sisa ${campaign.sisaHari} Hari',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF424656),
                        ),
                      ),
                      Row(
                        children: const [
                          Text(
                            'Donasi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0050CB),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Color(0xFF0050CB),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreCampaignCard(CampaignModel campaign) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return GestureDetector(
      onTap: () => _navigateToDetail(campaign),
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFC2C6D8).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: campaign.imageUrl != null
                      ? Image.network(
                          campaign.imageUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _fallbackImage(height: 160),
                        )
                      : _fallbackImage(height: 160),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(campaign.kategori),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      campaign.kategori,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.judul,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.apartment_rounded,
                        size: 16,
                        color: Color(0xFF727687),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          campaign.organisasiNama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF424656),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GradientProgressBar(value: campaign.progressPersen),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TERKUMPUL',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF727687),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fmt.format(campaign.terkumpul),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0050CB),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'SISA HARI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF727687),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${campaign.sisaHari} Hari',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF191C1E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pendidikan':
        return const Color(0xFF0050CB);
      case 'Pangan':
        return const Color(0xFF006B5F);
      case 'Renovasi':
        return const Color(0xFF00843A);
      case 'Kesehatan':
        return const Color(0xFFBA1A1A);
      case 'Bencana':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF424656);
    }
  }

  Widget _fallbackImage({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0050CB), Color(0xFF006B5F)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.campaign_rounded, size: 48, color: Colors.white54),
      ),
    );
  }
}

class GradientProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  const GradientProgressBar({required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF0050CB).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth * value;
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: width,
              height: 8,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0050CB), Color(0xFF006B5F)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        },
      ),
    );
  }
}
