import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donasee_final_project_ppb/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'image_upload_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Exception _parseAuthException(FirebaseAuthException e) {
    if (e.code == 'weak-password') {
      return Exception('Password terlalu lemah. Gunakan minimal 6 karakter.');
    } else if (e.code == 'email-already-in-use') {
      return Exception('Email ini sudah terdaftar. Silakan gunakan email lain.');
    } else if (e.code == 'invalid-email') {
      return Exception('Format email tidak valid.');
    }
    return Exception(e.message ?? 'Terjadi kesalahan autentikasi.');
  }

  Future<UserModel> registerDonatur({
    required String email,
    required String password,
    required String nama,
  }) async {
    User? firebaseUser;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebaseUser = cred.user;

      final user = UserModel(
        uid: firebaseUser!.uid,
        email: email,
        nama: nama,
        role: 'donatur',
        createdAt: DateTime.now(),
        isVerified: true,
      );

      await _db.collection('users').doc(user.uid).set(user.toFirestore());
      return user;
    } on FirebaseAuthException catch (e) {
      if (firebaseUser != null) {
        try {
          await firebaseUser.delete();
        } catch (_) {}
      }
      throw _parseAuthException(e);
    } catch (e) {
      if (firebaseUser != null) {
        try {
          await firebaseUser.delete();
        } catch (_) {}
      }
      throw Exception('Gagal mendaftar Donatur: ${e.toString()}');
    }
  }

  Future<UserModel> registerAdminPanti({
    required String email,
    required String password,
    required String namaAdmin,
    required String organisasiNama,
    required String organisasiAlamat,
    required String organisasiTelepon,
    Uint8List? suratResmiBytes,
    File? suratResmiFile,
  }) async {
    User? firebaseUser;
    try {
      // 1. Create user in Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebaseUser = cred.user;
      final uid = firebaseUser!.uid;

      // 2. Upload official PDF to Supabase and get signed URL
      final pdfUrl = await ImageUploadService().uploadSuratResmi(
        uid: uid,
        bytes: suratResmiBytes,
        file: suratResmiFile,
      );

      // 3. Save user info to Firestore
      final user = UserModel(
        uid: uid,
        email: email,
        nama: namaAdmin,
        role: 'admin',
        createdAt: DateTime.now(),
        organisasiNama: organisasiNama,
        organisasiAlamat: organisasiAlamat,
        organisasiTelepon: organisasiTelepon,
        suratResmiUrl: pdfUrl,
        isVerified: false,
      );

      await _db.collection('users').doc(uid).set(user.toFirestore());
      return user;
    } on FirebaseAuthException catch (e) {
      if (firebaseUser != null) {
        try {
          await firebaseUser.delete();
        } catch (_) {}
      }
      throw _parseAuthException(e);
    } catch (e) {
      if (firebaseUser != null) {
        try {
          await firebaseUser.delete();
        } catch (_) {}
      }
      throw Exception('Gagal mendaftar Admin Panti: ${e.toString()}');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred = await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCred.user;
      if (firebaseUser == null) return;

      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (!doc.exists) {
        final user = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          nama: firebaseUser.displayName ?? 'Donatur Donasee',
          role: 'donatur',
          createdAt: DateTime.now(),
          isVerified: true,
        );
        await _db.collection('users').doc(firebaseUser.uid).set(user.toFirestore());
      }
    } catch (e) {
      throw Exception('Gagal masuk dengan Google: ${e.toString()}');
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String nama,
    required String role,
    String? organisasiNama,
  }) async {
    User? firebaseUser;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebaseUser = cred.user;

      final user = UserModel(
        uid: firebaseUser!.uid,
        email: email,
        nama: nama,
        role: role,
        organisasiNama: organisasiNama,
        createdAt: DateTime.now(),
        isVerified: role != 'admin', // admin harus menunggu persetujuan super admin
      );

      await _db.collection('users').doc(user.uid).set(user.toFirestore());
      return user;
    } on FirebaseAuthException catch (e) {
      if (firebaseUser != null) {
        try {
          await firebaseUser.delete();
        } catch (_) {}
      }
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
      if (firebaseUser != null) {
        try {
          await firebaseUser.delete();
        } catch (_) {}
      }
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
