import 'package:cloud_firestore/cloud_firestore.dart';

class AllocationModel {
  final String id;
  final String kampanyeId;
  final String kampanyeJudul;
  final String judulAlokasi;
  final String deskripsi;
  final int nominal;
  final String adminId;
  final String adminNama;
  final DateTime createdAt;

  AllocationModel({
    required this.id,
    required this.kampanyeId,
    required this.kampanyeJudul,
    required this.judulAlokasi,
    required this.deskripsi,
    required this.nominal,
    required this.adminId,
    required this.adminNama,
    required this.createdAt,
  });

  factory AllocationModel.fromFirestore(Map<String, dynamic> d, String id) {
    return AllocationModel(
      id: id,
      kampanyeId: d['kampanyeId'] ?? '',
      kampanyeJudul: d['kampanyeJudul'] ?? '',
      judulAlokasi: d['judulAlokasi'] ?? '',
      deskripsi: d['deskripsi'] ?? '',
      nominal: (d['nominal'] ?? 0) as int,
      adminId: d['adminId'] ?? '',
      adminNama: d['adminNama'] ?? '',
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'kampanyeId': kampanyeId,
    'kampanyeJudul': kampanyeJudul,
    'judulAlokasi': judulAlokasi,
    'deskripsi': deskripsi,
    'nominal': nominal,
    'adminId': adminId,
    'adminNama': adminNama,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
