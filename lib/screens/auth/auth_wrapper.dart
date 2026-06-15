import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../home/main_navigation.dart';
import '../super_admin/super_admin_dashboard.dart';
import 'login_screen.dart';
import 'pending_verification_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription<User?>? _authSub;
  String? _currentUid;
  UserModel? _userModel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _authSub = auth.authStateChanges.listen((user) {
      if (user == null) {
        if (mounted) {
          setState(() {
            _currentUid = null;
            _userModel = null;
            _loading = false;
          });
        }
      } else {
        if (user.uid != _currentUid) {
          _currentUid = user.uid;
          _loadUserModel();
        }
      }
    });
  }

  Future<void> _loadUserModel() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });
    try {
      final auth = context.read<AuthService>();
      UserModel? user;
      
      // Retry up to 5 times with a 1-second delay if the user document is not yet found.
      // This prevents the race condition during registration where Firebase Auth
      // triggers authStateChanges before the Firestore set operation completes.
      for (int i = 0; i < 5; i++) {
        user = await auth.getCurrentUserModel();
        if (user != null) break;
        if (auth.currentUser == null) break; // If logged out in the meantime
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
      }
      
      if (user != null && !kIsWeb) {
        await NotificationService().saveTokenForUser(user.uid);
      }

      if (mounted) {
        setState(() {
          _userModel = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUid == null || _userModel == null) {
      if (_currentUid != null && _userModel == null) {
        // Sesi auth aktif tetapi data pengguna di database tidak ada (misal ditolak/dihapus)
        // Logout paksa untuk mereset ke LoginScreen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AuthService>().logout();
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return const LoginScreen();
    }

    final user = _userModel!;
    // Pengalihan berdasarkan Peran (Role) & Verifikasi
    if (user.role == 'super_admin') {
      return const SuperAdminDashboard();
    } else if (user.role == 'admin' && !user.isVerified) {
      return const PendingVerificationScreen();
    }

    return MainNavigation(key: MainNavigation.navigationKey);
  }
}
