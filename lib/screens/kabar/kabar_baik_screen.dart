import 'package:donasee_final_project_ppb/models/allocation_model.dart';
import 'package:donasee_final_project_ppb/screens/kabar/detail_alokasi_screen.dart';
import 'package:donasee_final_project_ppb/screens/kabar/form_alokasi_screen.dart';
import 'package:donasee_final_project_ppb/services/allocation_service.dart';
import 'package:donasee_final_project_ppb/services/auth_service.dart';
import 'package:donasee_final_project_ppb/widgets/allocation_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class KabarBaikScreen extends StatelessWidget {
  const KabarBaikScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final service = AllocationService();
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kabar Baik'),
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async => auth.logout(),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder(
        future: auth.getCurrentUserModel(),
        builder: (context, snapshot) {
          final isAdmin = snapshot.data?.isAdmin == true;
          if (!isAdmin) {
            // TODO: validasi role admin lebih ketat jika alur role sudah final.
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            backgroundColor: const Color(0xFF1D9E75),
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
                    backgroundColor: Color(0xFF1D9E75),
                  ),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Tambah'),
          );
        },
      ),
      body: StreamBuilder<List<AllocationModel>>(
        stream: service.getAllAllocationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat data alokasi.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            );
          }

          final allocations = snapshot.data ?? const <AllocationModel>[];
          if (allocations.isEmpty) {
            return const Center(child: Text('Belum ada laporan alokasi dana'));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: allocations.length,
            itemBuilder: (context, index) {
              final allocation = allocations[index];
              return AllocationCard(
                allocation: allocation,
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DetailAlokasiScreen(allocationId: allocation.id),
                    ),
                  );
                  if (result == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Alokasi ${currency.format(allocation.nominal)} diperbarui',
                        ),
                        backgroundColor: const Color(0xFF1D9E75),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
