import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Top-level function untuk handle background/terminated messages.
/// HARUS top-level (bukan method di dalam class).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase sudah di-init otomatis oleh plugin saat background handler dipanggil.
  if (kDebugMode) {
    print('========== FCM BACKGROUND MESSAGE ==========');
    print('Message ID  : ${message.messageId}');
    print('Title       : ${message.notification?.title}');
    print('Body        : ${message.notification?.body}');
    print('Data        : ${message.data}');
    print('=============================================');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _fcm = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;

  /// Inisialisasi lengkap FCM — panggil sekali di main().
  Future<void> initialize() async {
    // 1. Request permission (penting untuk Android 13+ / iOS)
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('========== FCM PERMISSION ==========');
      print('Status: ${settings.authorizationStatus}');
      print('====================================');
    }

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (kDebugMode) {
        print('⚠️ Notification permission ditolak oleh user.');
      }
      return;
    }

    // 2. Ambil FCM Token
    final token = await _fcm.getToken();
    if (kDebugMode) {
      print('========================================');
      print('🔑 FCM DEVICE TOKEN:');
      print(token);
      print('========================================');
      print('📋 Copy token di atas untuk testing via backend.');
    }

    // 3. Atur agar notifikasi tampil saat app di foreground (Android)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Listen foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Listen saat user tap notifikasi (app di background → opened)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 6. Cek apakah app dibuka dari terminated state via notifikasi
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // 7. Listen token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('🔄 FCM Token refreshed: $newToken');
      }
    });
  }

  /// Simpan FCM token ke Firestore untuk user yang login.
  Future<void> saveTokenForUser(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).update({'fcmToken': token});
        if (kDebugMode) {
          print('✅ FCM Token disimpan ke Firestore untuk user: $uid');
        }
      }

      // Listen token refresh dan update Firestore
      _fcm.onTokenRefresh.listen((newToken) async {
        await _db.collection('users').doc(uid).update({'fcmToken': newToken});
        if (kDebugMode) {
          print('🔄 FCM Token updated di Firestore untuk user: $uid');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Gagal menyimpan FCM Token: $e');
      }
    }
  }

  /// Handle foreground message — print info ke console.
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('========== FCM FOREGROUND MESSAGE ==========');
      print('Message ID  : ${message.messageId}');
      print('Title       : ${message.notification?.title}');
      print('Body        : ${message.notification?.body}');
      print('Data        : ${message.data}');
      print('=============================================');
    }

    // Notifikasi akan otomatis tampil sebagai heads-up notification
    // karena setForegroundNotificationPresentationOptions sudah di-set.
    // Jika perlu custom UI (in-app banner), tambahkan logic di sini.
  }

  /// Handle saat user tap notifikasi — navigasi ke screen tertentu.
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('========== NOTIFICATION TAPPED ==========');
      print('Data: ${message.data}');
      print('==========================================');
    }

    // TODO: Implementasi navigasi berdasarkan data payload.
    // Contoh: if (message.data['screen'] == 'kabar_baik') { ... }
  }

  /// Kirim notifikasi alokasi ke semua donatur kampanye.
  ///
  /// CATATAN: Fungsi ini hanya mengumpulkan token dari Firestore.
  /// Pengiriman FCM seharusnya dilakukan dari backend (Cloud Functions
  /// atau server Node.js), BUKAN dari client Flutter.
  /// Lihat `fcm-backend/send-notification.js` untuk contoh pengiriman.
  Future<void> kirimNotifikasiAlokasi({
    required String kampanyeId,
    required String kampanyeJudul,
  }) async {
    try {
      final donations = await _db
          .collection('donations')
          .where('kampanyeId', isEqualTo: kampanyeId)
          .where('status', isEqualTo: 'berhasil')
          .get();

      final donaturIds = donations.docs
          .map((doc) => doc.data()['donaturId'] as String?)
          .whereType<String>()
          .toSet();

      // Kumpulkan token-token untuk dikirim dari backend
      final tokens = <String>[];
      for (final uid in donaturIds) {
        final userDoc = await _db.collection('users').doc(uid).get();
        final token = userDoc.data()?['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      if (kDebugMode) {
        print('📢 Notifikasi alokasi untuk kampanye "$kampanyeJudul"');
        print('   Jumlah donatur: ${donaturIds.length}');
        print('   Token tersedia: ${tokens.length}');
        print('   ⚠️ Pengiriman FCM harus dari backend, bukan client.');
      }

      // TODO: Kirim token-token ini ke backend API kamu untuk dikirim via
      // Firebase Admin SDK. Contoh: POST ke endpoint backend kamu dengan
      // payload { tokens, title, body }.
      //
      // Untuk sementara, kamu bisa manual copy token dan kirim via:
      //   cd fcm-backend && node send-notification.js

    } catch (e) {
      if (kDebugMode) {
        print('❌ Gagal memproses notifikasi alokasi: $e');
      }
    }
  }
}
