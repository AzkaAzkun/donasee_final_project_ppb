import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:permission_handler/permission_handler.dart';
import 'fcm_credentials.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;
  final _fcm = FirebaseMessaging.instance;

  Future<void> _saveNotificationToFirestore({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (_) {}
  }

  void initForegroundNotificationListener(Function(String title, String body) onShowNotification) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        onShowNotification(notification.title ?? '', notification.body ?? '');
      }
    });
  }

  Future<void> kirimNotifikasiVerifikasi({
    required String donaturId,
    required String kampanyeJudul,
    required int nominal,
  }) async {
    try {
      final fmt = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );

      final title = 'Donasi Terverifikasi! 🌟';
      final body = 'Donasi Anda sebesar ${fmt.format(nominal)} untuk "$kampanyeJudul" telah berhasil diverifikasi. Terima kasih!';

      // Save to Firestore for fallback/in-app listener
      await _saveNotificationToFirestore(
        userId: donaturId,
        title: title,
        body: body,
      );

      final userDoc = await _db.collection('users').doc(donaturId).get();
      final token = userDoc.data()?['fcmToken'] as String?;
      if (token == null || token.isEmpty) {
        return;
      }

      await _sendFcmMessage(
        token: token,
        title: title,
        body: body,
      );
    } catch (_) {}
  }

  Future<void> initAndSaveToken(String uid) async {
    try {
      // Request native notification permission on Android 13+
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }

      await _fcm.requestPermission(alert: true, badge: true, sound: true);

      final token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).update({'fcmToken': token});
      }

      _fcm.onTokenRefresh.listen((token) async {
        await _db.collection('users').doc(uid).update({'fcmToken': token});
      });
    } catch (_) {}
  }

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

      final title = 'Kabar Donasi Anda! 🎉';
      final body = 'Dana di "$kampanyeJudul" telah dialokasikan. Cek laporannya!';

      for (final uid in donaturIds) {
        // Save to Firestore first
        await _saveNotificationToFirestore(
          userId: uid,
          title: title,
          body: body,
        );

        final userDoc = await _db.collection('users').doc(uid).get();
        final token = userDoc.data()?['fcmToken'] as String?;
        if (token == null || token.isEmpty) {
          continue;
        }

        await _sendFcmMessage(
          token: token,
          title: title,
          body: body,
        );
      }
    } catch (_) {}
  }

  Future<void> _sendFcmMessage({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      final credentials = auth.ServiceAccountCredentials.fromJson(fcmServiceAccountCredentials);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      
      final client = await auth.clientViaServiceAccount(credentials, scopes);

      final projectId = fcmServiceAccountCredentials['project_id'] ?? 'final-project-ppb-35cb4';
      final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      await client.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'donasi_channel',
                'notification_priority': 'PRIORITY_HIGH',
                'sound': 'default',
                'default_sound': true,
                'default_vibrate_timings': true,
              },
            },
            'data': {
              'screen': 'kabar_baik',
            },
          },
        }),
      );

      client.close();
    } catch (_) {}
  }
}
