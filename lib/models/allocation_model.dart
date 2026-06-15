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
  final String? buktiAlokasiUrl; // NEW: URL bukti alokasi dana (Supabase Storage)

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
    this.buktiAlokasiUrl,
  });

  factory AllocationModel.fromFirestore(Map<String, dynamic> d, String id) {
    final data = d;
    return AllocationModel(
      id: id,
      kampanyeId: _readString(data['kampanyeId']),
      kampanyeJudul: _readString(data['kampanyeJudul']),
      judulAlokasi: _readString(data['judulAlokasi']),
      deskripsi: _readString(data['deskripsi']),
      nominal: _readInt(data['nominal']),
      adminId: _readString(data['adminId']),
      adminNama: _readString(data['adminNama']),
      createdAt: _readDateTime(data['createdAt']),
      buktiAlokasiUrl: data['buktiAlokasiUrl'] as String?,
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
    'kampanyeId': kampanyeId,
    'kampanyeJudul': kampanyeJudul,
    'judulAlokasi': judulAlokasi,
    'deskripsi': deskripsi,
    'nominal': nominal,
    'adminId': adminId,
    'adminNama': adminNama,
    'createdAt': Timestamp.fromDate(createdAt),
    if (buktiAlokasiUrl != null) 'buktiAlokasiUrl': buktiAlokasiUrl,
  };
}
