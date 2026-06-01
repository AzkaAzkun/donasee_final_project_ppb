import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donasee_final_project_ppb/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel> register({
    required String email,
    required String password,
    required String nama,
    required String role,
    String? organisasiNama,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        uid: cred.user!.uid,
        email: email,
        nama: nama,
        role: role,
        organisasiNama: organisasiNama,
        createdAt: DateTime.now(),
      );

      await _db.collection('users').doc(user.uid).set(user.toFirestore());

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Password terlalu lemah. Gunakan minimal 6 karakter.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception(
          'Email ini sudah terdaftar. Silakan gunakan email lain.',
        );
      } else if (e.code == 'invalid-email') {
        throw Exception('Format email tidak valid.');
      }
      throw Exception(e.message ?? 'Terjadi kesalahan saat mendaftar.');
    } catch (e) {
      throw Exception('Gagal mendaftar: ${e.toString()}');
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw Exception('Email atau password yang kamu masukkan salah.');
      } else if (e.code == 'user-disabled') {
        throw Exception('Akun ini telah dinonaktifkan.');
      }
      throw Exception(e.message ?? 'Terjadi kesalahan saat login.');
    } catch (e) {
      throw Exception('Gagal login: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Gagal logout: ${e.toString()}');
    }
  }

  Future<UserModel?> getCurrentUserModel() async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return null;

      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc.data()!, uid);
    } catch (e) {
      throw Exception('Gagal mengambil data pengguna: ${e.toString()}');
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return;

      await _db.collection('users').doc(uid).update({'fcmToken': token});
    } catch (e) {
      if (kDebugMode) {
        print('Gagal memperbarui FCM Token: $e');
      }
    }
  }
}
