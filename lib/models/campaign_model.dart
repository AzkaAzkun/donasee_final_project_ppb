import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignModel {
  final String id;
  final String judul;
  final String deskripsi;
  final int targetDana;
  final int terkumpul;
  final String organisasiId;
  final String organisasiNama;
  final DateTime batasTanggal;
  final String status;
  final DateTime createdAt;
  final String? imageUrl; // opsional — URL dari Supabase Storage

  CampaignModel({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.targetDana,
    required this.terkumpul,
    required this.organisasiId,
    required this.organisasiNama,
    required this.batasTanggal,
    required this.status,
    required this.createdAt,
    this.imageUrl,
  });

  double get progressPersen =>
      targetDana == 0 ? 0.0 : (terkumpul / targetDana).clamp(0.0, 1.0);

  int get sisaHari => batasTanggal.difference(DateTime.now()).inDays;

  bool get isAktif => status == 'aktif';

  factory CampaignModel.fromFirestore(Map<String, dynamic> d, String id) {
    return CampaignModel(
      id: id,
      judul: d['judul'] ?? '',
      deskripsi: d['deskripsi'] ?? '',
      targetDana: (d['targetDana'] ?? 0) as int,
      terkumpul: (d['terkumpul'] ?? 0) as int,
      organisasiId: d['organisasiId'] ?? '',
      organisasiNama: d['organisasiNama'] ?? '',
      batasTanggal: (d['batasTanggal'] as Timestamp).toDate(),
      status: d['status'] ?? 'aktif',
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      imageUrl: d['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'judul': judul,
    'deskripsi': deskripsi,
    'targetDana': targetDana,
    'terkumpul': terkumpul,
    'organisasiId': organisasiId,
    'organisasiNama': organisasiNama,
    'batasTanggal': Timestamp.fromDate(batasTanggal),
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}
