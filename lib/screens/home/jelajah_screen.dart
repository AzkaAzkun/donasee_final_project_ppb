import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/campaign_service.dart';
import '../../models/campaign_model.dart';
import '../../models/user_model.dart';
import '../../widgets/campaign_card.dart';
import '../kampanye/form_kampanye_screen.dart';

enum _SortMode { terbaru, terdesak }

class JelajahScreen extends StatefulWidget {
  const JelajahScreen({super.key});

  @override
  State<JelajahScreen> createState() => _JelajahScreenState();
}

class _JelajahScreenState extends State<JelajahScreen> {
  final _svc = CampaignService();
  UserModel? _user;
  bool _loadingUser = true;

  _SortMode _sort = _SortMode.terbaru;
  bool _filterMilikSaya = false; // hanya relevan untuk admin

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
        _user = user;
        _loadingUser = false;
      });
    }
  }

  List<CampaignModel> _applyFiltersAndSort(List<CampaignModel> raw) {
    List<CampaignModel> list = List.from(raw);

    // Filter: admin hanya lihat kampanyenya sendiri
    if (_filterMilikSaya && (_user?.isAdmin ?? false)) {
      list = list.where((c) => c.organisasiId == _user!.uid).toList();
    }

    // Sort
    switch (_sort) {
      case _SortMode.terbaru:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _SortMode.terdesak:
        // Urutkan berdasarkan sisa hari terkecil (paling mendesak duluan)
        list.sort((a, b) => a.sisaHari.compareTo(b.sisaHari));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final isAdmin = _user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jelajah Kampanye'),
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async => await auth.logout(),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Bar Sort & Filter ──────────────────────────────────────
          _buildSortFilterBar(isAdmin),

          // ── List Kampanye ──────────────────────────────────────────
          Expanded(
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(
                            'Gagal memuat kampanye:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final campaigns =
                    _applyFiltersAndSort(snapshot.data ?? []);

                if (campaigns.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _filterMilikSaya
                              ? 'Belum ada kampanye milikmu'
                              : 'Belum ada kampanye aktif',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.grey),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FormKampanyeScreen()),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Buat Kampanye Pertama'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D9E75),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: campaigns.length,
                  itemBuilder: (_, i) => CampaignCard(
                    campaign: campaigns[i],
                    isAdmin: isAdmin,
                    currentUserId: _user?.uid,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _loadingUser
          ? null
          : isAdmin
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FormKampanyeScreen()),
                  ),
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Kampanye'),
                )
              : null,
    );
  }

  Widget _buildSortFilterBar(bool isAdmin) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // ── Sort chips ─────────────────────────────────────────────
          const Text('Urutkan:',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          _sortChip('Terbaru', _SortMode.terbaru),
          const SizedBox(width: 6),
          _sortChip('Terdesak', _SortMode.terdesak),

          // ── Filter milikku (admin only) ────────────────────────────
          if (isAdmin) ...[
            const Spacer(),
            GestureDetector(
              onTap: () =>
                  setState(() => _filterMilikSaya = !_filterMilikSaya),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _filterMilikSaya
                      ? const Color(0xFF1D9E75)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _filterMilikSaya
                        ? const Color(0xFF1D9E75)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _filterMilikSaya
                        ? Icons.person
                        : Icons.person_outline,
                    size: 14,
                    color: _filterMilikSaya
                        ? Colors.white
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Milik Saya',
                    style: TextStyle(
                      fontSize: 12,
                      color: _filterMilikSaya
                          ? Colors.white
                          : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sortChip(String label, _SortMode mode) {
    final selected = _sort == mode;
    return GestureDetector(
      onTap: () => setState(() => _sort = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1D9E75) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected ? const Color(0xFF1D9E75) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
