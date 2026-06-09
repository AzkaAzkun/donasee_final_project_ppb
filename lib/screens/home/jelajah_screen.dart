import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/campaign_service.dart';
import '../../models/campaign_model.dart';
import '../../models/user_model.dart';
import '../../widgets/campaign_card.dart';
import '../kampanye/form_kampanye_screen.dart';

class JelajahScreen extends StatefulWidget {
  const JelajahScreen({super.key});

  @override
  State<JelajahScreen> createState() => _JelajahScreenState();
}

class _JelajahScreenState extends State<JelajahScreen> {
  final _svc = CampaignService();
  UserModel? _user;
  bool _loadingUser = true;

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
            onPressed: () async {
              await auth.logout();
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<List<CampaignModel>>(
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
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Belum ada kampanye aktif',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
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

          final campaigns = snapshot.data!;
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
      // FAB untuk admin buat kampanye baru
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
}
