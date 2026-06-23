import 'package:cloud_firestore/cloud_firestore.dart';

class DonationStatus {
  static const pending = 'pending';
  static const menungguVerifikasi = 'menunggu_verifikasi';
  static const berhasil = 'berhasil';
}

class DonationModel {
  final String id;
  final String kampanyeId;
  final String kampanyeJudul;
  final String donaturId;
  final String donaturNama;
  final int nominal;
  final String metode;
  final String status;
  final String? buktiFotoUrl;
  final DateTime createdAt;
  final String? pesan; // NEW: pesan dukungan
  final bool isAnonymous; // NEW: sembunyikan nama

  DonationModel({
    required this.id,
    required this.kampanyeId,
    required this.kampanyeJudul,
    required this.donaturId,
    required this.donaturNama,
    required this.nominal,
    required this.metode,
    required this.status,
    this.buktiFotoUrl,
    required this.createdAt,
    this.pesan,
    this.isAnonymous = false,
  });

  bool get isPending => status == DonationStatus.pending;
  bool get isBerhasil => status == DonationStatus.berhasil;

  factory DonationModel.fromFirestore(Map<String, dynamic> d, String id) {
    return DonationModel(
      id: id,
      kampanyeId: _readString(d['kampanyeId']),
      kampanyeJudul: _readString(d['kampanyeJudul']),
      donaturId: _readString(d['donaturId']),
      donaturNama: _readString(d['donaturNama']),
      nominal: _readInt(d['nominal']),
      metode: _readString(d['metode']),
      status: _readString(d['status']),
      buktiFotoUrl: d['buktiFotoUrl'] as String?,
      createdAt: _readDateTime(d['createdAt']),
      pesan: d['pesan'] as String?,
      isAnonymous: d['isAnonymous'] ?? false,
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
    'donaturId': donaturId,
    'donaturNama': donaturNama,
    'nominal': nominal,
    'metode': metode,
    'status': status,
    if (buktiFotoUrl != null) 'buktiFotoUrl': buktiFotoUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    if (pesan != null) 'pesan': pesan,
    'isAnonymous': isAnonymous,
  };
}
