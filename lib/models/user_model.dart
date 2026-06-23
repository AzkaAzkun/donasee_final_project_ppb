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
    final roleVal = _readString(d['role']);
    final actualRole = roleVal.isEmpty ? 'donatur' : roleVal;
    return UserModel(
      uid: uid,
      email: _readString(d['email']),
      nama: _readString(d['nama']),
      role: actualRole,
      fcmToken: d['fcmToken'] as String?,
      createdAt: _readDateTime(d['createdAt']),
      fotoUrl: d['fotoUrl'] as String?,
      organisasiNama: d['organisasiNama'] as String?,
      organisasiAlamat: d['organisasiAlamat'] as String?,
      organisasiTelepon: d['organisasiTelepon'] as String?,
      suratResmiUrl: d['suratResmiUrl'] as String?,
      isVerified: d['isVerified'] ?? (actualRole != 'admin'),
      verifiedAt: d['verifiedAt'] != null ? _readDateTime(d['verifiedAt']) : null,
      verifiedBy: d['verifiedBy'] as String?,
    );
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString();
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