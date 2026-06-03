import 'package:donasee_final_project_ppb/models/allocation_model.dart';
import 'package:donasee_final_project_ppb/screens/kabar/form_alokasi_screen.dart';
import 'package:donasee_final_project_ppb/services/allocation_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailAlokasiScreen extends StatefulWidget {
  final String allocationId;

  const DetailAlokasiScreen({super.key, required this.allocationId});

  @override
  State<DetailAlokasiScreen> createState() => _DetailAlokasiScreenState();
}

class _DetailAlokasiScreenState extends State<DetailAlokasiScreen> {
  final _service = AllocationService();
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<AllocationModel?>(
      stream: _service.getAllocationByIdStream(widget.allocationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: _ErrorState(message: snapshot.error.toString()),
          );
        }

        final allocation = snapshot.data;
        if (allocation == null) {
          return const Scaffold(
            body: _EmptyState(
              message: 'Data alokasi tidak ditemukan',
            ),
          );
        }

        final isOwner = allocation.adminId == currentUserUid;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Alokasi'),
            backgroundColor: const Color(0xFF1D9E75),
            foregroundColor: Colors.white,
            actions: isOwner
                ? [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit',
                      onPressed: _isDeleting ? null : () => _openEdit(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Hapus',
                      onPressed: _isDeleting ? null : () => _confirmDelete(context),
                    ),
                  ]
                : null,
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE1F5EE)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF1D9E75,
                          ).withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          allocation.kampanyeJudul,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F6E56),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          allocation.judulAlokasi,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          label: 'Nominal',
                          value: currency.format(allocation.nominal),
                        ),
                        _InfoRow(label: 'Admin', value: allocation.adminNama),
                        _InfoRow(
                          label: 'Tanggal',
                          value: dateFormat.format(allocation.createdAt),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Deskripsi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D9E75),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          allocation.deskripsi,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.55,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isDeleting)
                Container(
                  color: Colors.black.withValues(alpha: 0.1),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEdit(BuildContext context) async {
    final allocation = await _service
        .getAllocationByIdStream(widget.allocationId)
        .first;
    if (allocation == null || !context.mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormAlokasiScreen(allocation: allocation),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alokasi berhasil diperbarui'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Alokasi?'),
        content: const Text('Data alokasi ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await _service.deleteAllocation(widget.allocationId);
      if (!context.mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus alokasi: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Gagal memuat detail alokasi.\n$message',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red.shade700),
        ),
      ),
    );
  }
}
