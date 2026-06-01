import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../home/main_navigation.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        // Masih loading status auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Sudah login
        if (snapshot.hasData) {
          final uid = snapshot.data!.uid;

          // Simpan FCM token setiap kali login
          NotificationService().initAndSaveToken(uid);

          return const MainNavigation();
        }

        // Belum login
        return const LoginScreen();
      },
    );
  }
}
