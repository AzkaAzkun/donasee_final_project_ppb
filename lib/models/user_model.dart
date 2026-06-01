import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String  uid;
  final String  email;
  final String  nama;
  final String  role; // 'donatur' | 'admin'
  final String? fcmToken;
  final String? organisasiNama;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.nama,
    required this.role,
    this.fcmToken,
    this.organisasiNama,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromFirestore(Map<String, dynamic> d, String uid) {
    return UserModel(
      uid: uid,
      email: d['email'] ?? '',
      nama: d['nama'] ?? '',
      role: d['role'] ?? 'donatur',
      fcmToken: d['fcmToken'],
      organisasiNama: d['organisasiNama'],
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'nama': nama,
    'role': role,
    if (fcmToken != null) 'fcmToken': fcmToken,
    if (organisasiNama != null) 'organisasiNama': organisasiNama,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}