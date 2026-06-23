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
  final String kategori; // NEW: kategori kampanye (Pendidikan, Pangan, Renovasi, Kesehatan, Lainnya)

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
    this.kategori = 'Lainnya',
  });

  double get progressPersen =>
      targetDana == 0 ? 0.0 : (terkumpul / targetDana).clamp(0.0, 1.0);

  int get sisaHari => batasTanggal.difference(DateTime.now()).inDays;

  bool get isAktif => status == 'aktif';

  factory CampaignModel.fromFirestore(Map<String, dynamic> d, String id) {
    return CampaignModel(
      id: id,
      judul: _readString(d['judul']),
      deskripsi: _readString(d['deskripsi']),
      targetDana: _readInt(d['targetDana']),
      terkumpul: _readInt(d['terkumpul']),
      organisasiId: _readString(d['organisasiId']),
      organisasiNama: _readString(d['organisasiNama']),
      batasTanggal: _readDateTime(d['batasTanggal']),
      status: _readString(d['status']),
      createdAt: _readDateTime(d['createdAt']),
      imageUrl: d['imageUrl'] as String?,
      kategori: _readString(d['kategori']),
    );
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed ?? DateTime.now();
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
    'kategori': kategori,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}
