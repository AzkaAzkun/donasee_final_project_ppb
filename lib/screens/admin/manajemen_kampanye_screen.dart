import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/campaign_model.dart';
import '../kampanye/detail_kampanye_screen.dart';
import '../kampanye/form_kampanye_screen.dart';

class ManajemenKampanyeScreen extends StatefulWidget {
  final bool isRootTab;
  const ManajemenKampanyeScreen({super.key, this.isRootTab = false});

  @override
  State<ManajemenKampanyeScreen> createState() => _ManajemenKampanyeScreenState();
}

class _ManajemenKampanyeScreenState extends State<ManajemenKampanyeScreen> {
  String _searchQuery = '';
  String _filterStatus = 'semua';
  final _searchCtrl = TextEditingController();
  late Stream<List<CampaignModel>> _campaignsStream;

  final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _campaignsStream = _streamMyCampaigns(currentUserId);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Stream<List<CampaignModel>> _streamMyCampaigns(String adminUid) {
    return FirebaseFirestore.instance
        .collection('campaigns')
        .where('organisasiId', isEqualTo: adminUid)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => CampaignModel.fromFirestore(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  String _formatShortCurrency(int amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else {
      return _fmt.format(amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FB),
        elevation: 0.5,
        scrolledUnderElevation: 0,
        leading: widget.isRootTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0050CB)),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          'Manajemen Kampanye',
          style: TextStyle(
            color: Color(0xFF0050CB),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Lexend',
          ),
        ),
      ),
      body: StreamBuilder<List<CampaignModel>>(
        stream: _campaignsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0050CB)));
          }

          final campaigns = snapshot.data ?? [];

          // Summary Stats Calculations
          int totalDonasi = 0;
          int selesaiCount = 0;
          int pendingCount = 0;
          int aktifCount = 0;

          for (final c in campaigns) {
            totalDonasi += c.terkumpul;
            if (c.status == 'selesai') {
              selesaiCount++;
            } else if (c.status == 'aktif') {
              aktifCount++;
            } else {
              pendingCount++; // status 'verifikasi' or 'pending'
            }
          }

          // Filtering by search query locally
          final queryParts = _searchQuery.toLowerCase().split(' ').where((s) => s.isNotEmpty).toList();
          final filteredCampaigns = campaigns.where((c) {
            // Apply filter status
            if (_filterStatus != 'semua' && _filterStatus != 'verifikasi') {
              if (c.status != _filterStatus) return false;
            } else if (_filterStatus == 'verifikasi') {
              if (c.status == 'aktif' || c.status == 'selesai') return false;
            }

            // Apply search query
            if (queryParts.isNotEmpty) {
              final judul = c.judul.toLowerCase();
              final kategori = c.kategori.toLowerCase();
              return queryParts.every((part) => judul.contains(part) || kategori.contains(part));
            }
            return true;
          }).toList();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Summary Metrics Section (Stacked on Mobile) ──
                      // Total Donasi Card (Full-width)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0050CB), // bg-primary
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0050CB).withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Icon(
                                Icons.volunteer_activism,
                                size: 96,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Donasi Terkumpul',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _fmt.format(totalDonasi),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Lexend',
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.trending_up, color: Colors.white, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            '+12% bln ini',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$aktifCount Kampanye Aktif',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selesai & Pending Counters Row (Side-by-side)
                      Row(
                        children: [
                          // Selesai Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F4F6), // bg-surface-container-low
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFC2C6D8).withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF00682C), size: 32),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Selesai',
                                    style: TextStyle(color: Color(0xFF424656), fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$selesaiCount',
                                    style: const TextStyle(color: Color(0xFF191C1E), fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Lexend'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Pending Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F4F6), // bg-surface-container-low
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFC2C6D8).withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.hourglass_empty_rounded, color: Color(0xFF006B5F), size: 32),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Pending',
                                    style: TextStyle(color: Color(0xFF424656), fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$pendingCount',
                                    style: const TextStyle(color: Color(0xFF191C1E), fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Lexend'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // ── Search & Header Section ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kampanye Saya',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF191C1E),
                              fontFamily: 'Lexend',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.tune_rounded, color: Color(0xFF0050CB)),
                            onPressed: _showFilterBottomSheet,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Local Instant Search Bar
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Cari kampanye...',
                          hintStyle: const TextStyle(color: Color(0xFF727687), fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF424656)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Color(0xFF727687)),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFC2C6D8)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF0050CB), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Campaign Cards List ──
                      if (filteredCampaigns.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: const [
                              Icon(Icons.campaign_outlined, size: 64, color: Color(0xFFC2C6D8)),
                              SizedBox(height: 12),
                              Text(
                                'Belum ada kampanye',
                                style: TextStyle(color: Color(0xFF727687), fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredCampaigns.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final c = filteredCampaigns[index];
                            final progress = c.progressPersen;
                            final isPending = c.status != 'aktif' && c.status != 'selesai';
                            final isSelesai = c.status == 'selesai';

                            Widget cardContent = Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left side Cover Photo
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECEEF0),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (c.imageUrl != null)
                                          isSelesai
                                              ? ColorFiltered(
                                                  colorFilter: const ColorFilter.matrix([
                                                    0.2126, 0.7152, 0.0722, 0, 0,
                                                    0.2126, 0.7152, 0.0722, 0, 0,
                                                    0.2126, 0.7152, 0.0722, 0, 0,
                                                    0,      0,      0,      1, 0,
                                                  ]),
                                                  child: Image.network(c.imageUrl!, fit: BoxFit.cover),
                                                )
                                              : Image.network(c.imageUrl!, fit: BoxFit.cover)
                                        else
                                          const Center(
                                            child: Icon(Icons.campaign_rounded, color: Color(0xFF727687), size: 36),
                                          ),
                                        if (isPending) ...[
                                          Container(color: Colors.black.withValues(alpha: 0.4)),
                                          const Center(
                                            child: Icon(Icons.pending_rounded, color: Colors.white, size: 28),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Right side Details Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header Row with Title and Badge
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              c.judul,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF191C1E),
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildStatusBadge(c.status),
                                        ],
                                      ),
                                      
                                      if (isPending) ...[
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Menunggu verifikasi admin pusat...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF727687),
                                            fontStyle: FontStyle.italic,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: const [
                                            Text(
                                              'Edit Campaign',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF727687),
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else if (isSelesai) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: const [
                                                Icon(Icons.verified_rounded, color: Color(0xFF00682C), size: 16),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Tercapai',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF00682C),
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Inter',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Text(
                                              '100%',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF00682C),
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // Green Progress Bar
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Container(
                                            height: 6,
                                            width: double.infinity,
                                            color: const Color(0xFFECEEF0),
                                            child: FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: 1.0,
                                              child: Container(color: const Color(0xFF00682C)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Donasi: ${_fmt.format(c.terkumpul)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF424656),
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => DetailKampanyeScreen(
                                                    campaignId: c.id,
                                                    isAdmin: true,
                                                    currentUserId: currentUserId,
                                                  ),
                                                ),
                                              ),
                                              child: const Text(
                                                'Lihat Laporan',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0050CB),
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        const SizedBox(height: 8),
                                        // Metrics row
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${_fmt.format(c.terkumpul)} / ${_formatShortCurrency(c.targetDana)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF424656),
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                            Text(
                                              '${(progress * 100).toInt()}%',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF006B5F),
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),

                                        // Progress Bar
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Container(
                                            height: 6,
                                            width: double.infinity,
                                            color: const Color(0xFFECEEF0),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: FractionallySizedBox(
                                                widthFactor: progress.clamp(0.0, 1.0),
                                                child: Container(
                                                  color: const Color(0xFF0050CB),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Action buttons & Days left row
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF727687)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${c.sisaHari >= 0 ? c.sisaHari : 0} hari lagi',
                                                  style: const TextStyle(fontSize: 12, color: Color(0xFF727687), fontFamily: 'Inter'),
                                                ),
                                              ],
                                            ),
                                            GestureDetector(
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => DetailKampanyeScreen(
                                                    campaignId: c.id,
                                                    isAdmin: true,
                                                    currentUserId: currentUserId,
                                                  ),
                                                ),
                                              ),
                                              child: const Text(
                                                'Kelola',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0050CB),
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            );

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFC2C6D8).withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: isSelesai
                                  ? Opacity(opacity: 0.75, child: cardContent)
                                  : cardContent,
                            );
                          },
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FormKampanyeScreen()),
        ),
        backgroundColor: const Color(0xFF0050CB),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Kampanye',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                        'Filter Kampanye',
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
                    'Status Kampanye:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Semua'),
                        selected: _filterStatus == 'semua',
                        onSelected: (val) {
                          if (val) {
                            setState(() => _filterStatus = 'semua');
                            setSheetState(() {});
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Aktif'),
                        selected: _filterStatus == 'aktif',
                        onSelected: (val) {
                          if (val) {
                            setState(() => _filterStatus = 'aktif');
                            setSheetState(() {});
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Selesai'),
                        selected: _filterStatus == 'selesai',
                        onSelected: (val) {
                          if (val) {
                            setState(() => _filterStatus = 'selesai');
                            setSheetState(() {});
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Pending'),
                        selected: _filterStatus == 'verifikasi',
                        onSelected: (val) {
                          if (val) {
                            setState(() => _filterStatus = 'verifikasi');
                            setSheetState(() {});
                          }
                        },
                      ),
                    ],
                  ),
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

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    if (status == 'aktif') {
      bg = const Color(0xFF6DF5E1).withValues(alpha: 0.2); // bg-secondary-container
      text = const Color(0xFF006F64);
      label = 'Aktif';
    } else if (status == 'selesai') {
      bg = const Color(0xFFECEEF0); // bg-surface-container-highest
      text = const Color(0xFF424656);
      label = 'Selesai';
    } else {
      bg = const Color(0xFFFFDAD6); // bg-error-container
      text = const Color(0xFFBA1A1A);
      label = 'Verifikasi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
