import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart' as auth;

/// Top-level function untuk handle background/terminated messages.
/// HARUS top-level (bukan method di dalam class).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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

  // Plugin untuk notifikasi lokal (foreground)
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'DonaSee Notifikasi',
    description: 'Notifikasi donasi dan alokasi dana DonaSee',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Inisialisasi lengkap FCM — panggil sekali di main().
  Future<void> initialize() async {
    // 1. Setup flutter_local_notifications
    await _initLocalNotifications();

    // 2. Request permission (penting untuk Android 13+ / iOS)
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

    // 3. Ambil FCM Token
    String? token;
    try {
      token = await _fcm.getToken();
      if (kDebugMode) {
        print('========================================');
        print('🔑 FCM DEVICE TOKEN:');
        print(token);
        print('========================================');
        print('📋 Copy token di atas untuk testing via backend.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Gagal mendapatkan FCM Token (FCM tidak tersedia): $e');
        print('   App tetap berjalan tanpa push notification token.');
      }
    }

    // 4. Agar notifikasi tampil saat app di foreground (Android)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. Listen foreground messages — tampilkan sebagai local notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Listen saat user tap notifikasi (app di background → opened)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 7. Cek apakah app dibuka dari terminated state via notifikasi
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // 8. Listen token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('🔄 FCM Token refreshed: $newToken');
      }
    });
  }

  /// Setup flutter_local_notifications
  Future<void> _initLocalNotifications() async {
    // Buat channel di Android
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);

    // Inisialisasi plugin
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (kDebugMode) {
          print('🔔 Local notification tapped: ${details.payload}');
        }
      },
    );
  }

  /// Handle foreground message — tampilkan sebagai local notification
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('========== FCM FOREGROUND MESSAGE ==========');
      print('Message ID  : ${message.messageId}');
      print('Title       : ${message.notification?.title}');
      print('Body        : ${message.notification?.body}');
      print('Data        : ${message.data}');
      print('=============================================');
    }

    final notification = message.notification;
    if (notification == null) return;

    // Tampilkan sebagai notifikasi sistem meski app sedang terbuka
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Handle saat user tap notifikasi — navigasi ke screen tertentu.
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('========== NOTIFICATION TAPPED ==========');
      print('Data: ${message.data}');
      print('==========================================');
    }
    // TODO: Implementasi navigasi berdasarkan data payload.
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

  /// Alias agar tetap sesuai penamaan di dokumen proyek.
  Future<void> initAndSaveToken(String uid) async {
    await saveTokenForUser(uid);
  }

  /// Kirim notifikasi alokasi ke semua donatur kampanye.
  Future<void> kirimNotifikasiAlokasi({
    required String kampanyeId,
    required String kampanyeJudul,
  }) async {
    try {
      // Query semua donasi berhasil untuk kampanye ini
      final donations = await _db
          .collection('donations')
          .where('kampanyeId', isEqualTo: kampanyeId)
          .where('status', isEqualTo: 'berhasil')
          .get();

      // Kumpulkan unique donatur IDs
      final donaturIds = donations.docs
          .map((doc) => doc.data()['donaturId'] as String?)
          .whereType<String>()
          .toSet();

      // Kirim notifikasi ke setiap donatur
      for (final uid in donaturIds) {
        final userDoc = await _db.collection('users').doc(uid).get();
        final token = userDoc.data()?['fcmToken'] as String?;
        if (token == null || token.isEmpty) continue;

        await _sendFcmMessage(
          token: token,
          title: 'Kabar Donasi Anda! 🎉',
          body: 'Dana di "$kampanyeJudul" telah dialokasikan. Cek laporannya!',
        );
      }

      if (kDebugMode) {
        print('📢 Notifikasi alokasi terkirim ke ${donaturIds.length} donatur pada kampanye "$kampanyeJudul".');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Gagal memproses notifikasi alokasi: $e');
      }
    }
  }

  Future<String> _getAccessToken() async {
    final jsonString = await rootBundle.loadString('assets/serviceAccountKey.json');
    final accountCredentials = auth.ServiceAccountCredentials.fromJson(jsonString);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await auth.clientViaServiceAccount(accountCredentials, scopes);
    final token = client.credentials.accessToken.data;
    client.close();
    return token;
  }

  Future<void> _sendFcmMessage({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      final String accessToken = await _getAccessToken();
      final jsonString = await rootBundle.loadString('assets/serviceAccountKey.json');
      final Map<String, dynamic> serviceAccount = jsonDecode(jsonString);
      final String projectId = serviceAccount['project_id'];

      final String endpoint = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final Map<String, dynamic> message = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'high_importance_channel',
              'default_sound': true,
            },
          },
          'data': {
            'screen': 'kabar_baik',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        }
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (kDebugMode) {
        if (response.statusCode == 200) {
          print('✅ Berhasil mengirim notifikasi via HTTP v1 API');
        } else {
          print('❌ Gagal mengirim notifikasi: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Exception saat mengirim notifikasi: $e');
      }
    }
  }
}
