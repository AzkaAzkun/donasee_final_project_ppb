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
      kampanyeId: d['kampanyeId'] ?? '',
      kampanyeJudul: d['kampanyeJudul'] ?? '',
      donaturId: d['donaturId'] ?? '',
      donaturNama: d['donaturNama'] ?? '',
      nominal: (d['nominal'] ?? 0) as int,
      metode: d['metode'] ?? 'transfer_bank_manual',
      status: d['status'] ?? DonationStatus.pending,
      buktiFotoUrl: d['buktiFotoUrl'],
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      pesan: d['pesan'] as String?,
      isAnonymous: d['isAnonymous'] ?? false,
    );
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
