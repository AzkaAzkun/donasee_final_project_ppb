import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

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
    } catch (e) {
      if (kDebugMode) {
        print('Gagal mengirim notifikasi alokasi: $e');
      }
    }
  }

  Future<void> _sendFcmMessage({
    required String token,
    required String title,
    required String body,
  }) async {
    const serverKey = 'YOUR_FCM_SERVER_KEY';

    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode({
        'to': token,
        'notification': {'title': title, 'body': body},
        'data': {'screen': 'kabar_baik'},
      }),
    );
  }
}
