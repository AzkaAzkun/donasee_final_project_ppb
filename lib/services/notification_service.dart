import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;
  final _fcm = FirebaseMessaging.instance;

  Future<void> initAndSaveToken(String uid) async {
    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);

      final token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).update({'fcmToken': token});
      }

      _fcm.onTokenRefresh.listen((token) async {
        await _db.collection('users').doc(uid).update({'fcmToken': token});
      });
    } catch (e) {
      if (kDebugMode) {
        print('Gagal menyimpan FCM Token: $e');
      }
    }
  }
}
