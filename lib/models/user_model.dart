import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String nama;
  final String role; // 'donatur' | 'admin' | 'super_admin'
  final String? fcmToken;
  final DateTime createdAt;
  final String? fotoUrl;

  // Field khusus Admin Panti (null jika donatur/super_admin)
  final String? organisasiNama;
  final String? organisasiAlamat;
  final String? organisasiTelepon;
  final String? suratResmiUrl;
  final bool isVerified;
  final DateTime? verifiedAt;
  final String? verifiedBy;

  UserModel({
    required this.uid,
    required this.email,
    required this.nama,
    required this.role,
    this.fcmToken,
    required this.createdAt,
    this.fotoUrl,
    this.organisasiNama,
    this.organisasiAlamat,
    this.organisasiTelepon,
    this.suratResmiUrl,
    required this.isVerified,
    this.verifiedAt,
    this.verifiedBy,
  });

  bool get isAdmin => role == 'admin';
  bool get isSuperAdmin => role == 'super_admin';

  factory UserModel.fromFirestore(Map<String, dynamic> d, String uid) {
    final roleVal = d['role'] ?? 'donatur';
    return UserModel(
      uid: uid,
      email: d['email'] ?? '',
      nama: d['nama'] ?? '',
      role: roleVal,
      fcmToken: d['fcmToken'],
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      fotoUrl: d['fotoUrl'],
      organisasiNama: d['organisasiNama'],
      organisasiAlamat: d['organisasiAlamat'],
      organisasiTelepon: d['organisasiTelepon'],
      suratResmiUrl: d['suratResmiUrl'],
      isVerified: d['isVerified'] ?? (roleVal != 'admin'),
      verifiedAt: d['verifiedAt'] != null ? (d['verifiedAt'] as Timestamp).toDate() : null,
      verifiedBy: d['verifiedBy'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'nama': nama,
    'role': role,
    if (fcmToken != null) 'fcmToken': fcmToken,
    'createdAt': Timestamp.fromDate(createdAt),
    if (fotoUrl != null) 'fotoUrl': fotoUrl,
    if (organisasiNama != null) 'organisasiNama': organisasiNama,
    if (organisasiAlamat != null) 'organisasiAlamat': organisasiAlamat,
    if (organisasiTelepon != null) 'organisasiTelepon': organisasiTelepon,
    if (suratResmiUrl != null) 'suratResmiUrl': suratResmiUrl,
    'isVerified': isVerified,
    if (verifiedAt != null) 'verifiedAt': Timestamp.fromDate(verifiedAt!),
    if (verifiedBy != null) 'verifiedBy': verifiedBy,
  };
}