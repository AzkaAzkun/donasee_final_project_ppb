import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

class NotificationService {
  final _db = FirebaseFirestore.instance;
  final _fcm = FirebaseMessaging.instance;
  static const _serverKey = 'YOUR_FCM_SERVER_KEY';

  static bool get hasServerKey => _serverKey != 'YOUR_FCM_SERVER_KEY';
  // If you deploy the Cloud Function, set this URL to the function endpoint.
  // Example: https://us-central1-YOUR_PROJECT.cloudfunctions.net/sendAllocationNotifications
  static const functionsUrl = 'YOUR_CLOUD_FUNCTION_URL';

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
    // Prefer calling a deployed Cloud Function (secure) if URL provided.
    if (functionsUrl != 'YOUR_CLOUD_FUNCTION_URL') {
      try {
        final resp = await http.post(
          Uri.parse(functionsUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'kampanyeId': kampanyeId,
            'kampanyeJudul': kampanyeJudul,
          }),
        );
        if (kDebugMode) {
          print('Cloud Function response: ${resp.statusCode} ${resp.body}');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          print('Gagal memanggil Cloud Function: $e');
        }
        // Fall through to server-key based sending if configured
      }
    }

    // If no Cloud Function configured, fall back to server key (if set).
    if (_serverKey == 'YOUR_FCM_SERVER_KEY') {
      if (kDebugMode) {
        print('FCM server key not set — not sending real notifications.');
      }
      return;
    }

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
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$_serverKey',
      },
      body: jsonEncode({
        'to': token,
        'notification': {'title': title, 'body': body},
        'data': {'screen': 'kabar_baik'},
      }),
    );
  }
}
