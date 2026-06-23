import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:donasee_final_project_ppb/models/user_model.dart';
import 'package:donasee_final_project_ppb/screens/donasiku/donasiku_screen.dart';
import 'package:donasee_final_project_ppb/screens/kabar/kabar_baik_screen.dart';
import 'package:donasee_final_project_ppb/screens/profil/profil_screen.dart';
import 'package:donasee_final_project_ppb/services/auth_service.dart';
import 'package:donasee_final_project_ppb/services/notification_service.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import 'jelajah_screen.dart';
import '../admin/manajemen_kampanye_screen.dart';

class MainNavigation extends StatefulWidget {
  static final GlobalKey<MainNavigationState> navigationKey = GlobalKey<MainNavigationState>();

  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _idx = 0;
  UserModel? _currentUser;
  bool _loadingUser = true;
  StreamSubscription<QuerySnapshot>? _notifSub;

  void setIndex(int index) {
    if (_cachedScreens != null && index >= 0 && index < _cachedScreens!.length) {
      setState(() {
        _idx = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  List<Widget>? _cachedScreens;

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUserModel();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _loadingUser = false;
        if (user != null) {
          final screens = user.isAdmin
              ? [
                  const ManajemenKampanyeScreen(isRootTab: true),
                  const KabarBaikScreen(),
                  ProfilScreen(user: user),
                ]
              : [
                  JelajahScreen(user: user),
                  DonasikuScreen(user: user),
                  const KabarBaikScreen(),
                  ProfilScreen(user: user),
                ];
          _cachedScreens = screens;
          if (_idx >= screens.length) {
            _idx = 0;
          }
          _startListeningNotifications(user.uid);
        }
      });
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    if (_currentUser?.isAdmin == true) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.volunteer_activism_outlined),
          activeIcon: Icon(Icons.volunteer_activism),
          label: 'Donasi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.newspaper_outlined),
          activeIcon: Icon(Icons.newspaper),
          label: 'Manajemen Kabar Baik',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_outlined),
          activeIcon: Icon(Icons.account_circle),
          label: 'Profil',
        ),
      ];
    }
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.explore_outlined),
        activeIcon: Icon(Icons.explore),
        label: 'Jelajah',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.favorite_outline),
        activeIcon: Icon(Icons.favorite),
        label: 'Donasiku',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.newspaper_outlined),
        activeIcon: Icon(Icons.newspaper),
        label: 'Kabar Baik',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.account_circle_outlined),
        activeIcon: Icon(Icons.account_circle),
        label: 'Profil',
      ),
    ];
  }

  void _startListeningNotifications(String userId) {
    _notifSub?.cancel();

    // Initialize foreground FCM listener
    NotificationService().initForegroundNotificationListener((title, body) {
      _showNotificationOverlay(title, body);
    });

    // Initialize Firestore fallback notification listener
    _notifSub = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final title = data['title'] as String? ?? 'Notifikasi';
            final body = data['body'] as String? ?? '';
            final docId = change.doc.id;

            // Mark as read immediately to avoid showing it multiple times
            FirebaseFirestore.instance
                .collection('notifications')
                .doc(docId)
                .update({'isRead': true});

            // Show overlay
            _showNotificationOverlay(title, body);
          }
        }
      }
    });
  }

  void _showNotificationOverlay(String title, String body) {
    if (!mounted) return;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _SlidingNotificationCard(
            title: title,
            body: body,
            onDismiss: () {
              overlayEntry.remove();
            },
            onTap: () {
              if (title.contains('Terverifikasi')) {
                // Ganti tab aktif di Donasiku ke 'riwayat' dan arahkan ke tab index 1 (Donasiku)
                DonasikuScreen.activeTab = 'riwayat';
                setIndex(1);
              } else if (title.contains('Kabar') || title.contains('Laporan') || title.contains('alokasi')) {
                // Arahkan ke tab index 2 (Kabar Baik)
                setIndex(2);
              }
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Auto dismiss after 5 seconds
    Timer(const Duration(seconds: 5), () {
      try {
        overlayEntry.remove();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(index: _idx, children: _cachedScreens ?? []),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        selectedItemColor: const Color(0xFF0050CB),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // wajib jika tab >= 4
        items: _navItems,
      ),
    );
  }
}

class _SlidingNotificationCard extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const _SlidingNotificationCard({
    required this.title,
    required this.body,
    required this.onDismiss,
    this.onTap,
  });

  @override
  State<_SlidingNotificationCard> createState() => _SlidingNotificationCardState();
}

class _SlidingNotificationCardState extends State<_SlidingNotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: GestureDetector(
        onTap: () async {
          if (widget.onTap != null) {
            widget.onTap!();
          }
          await _dismiss();
        },
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! < -10) {
            _dismiss();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF0050CB).withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0050CB).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0050CB).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Color(0xFF0050CB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.body,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF727687),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Color(0xFF727687)),
                onPressed: _dismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class _PlaceholderScreen extends StatelessWidget {
//   final String label;
//   final IconData icon;

//   const _PlaceholderScreen({required this.label, required this.icon});

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.read<AuthService>();
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(label),
//         backgroundColor: const Color(0xFF1D9E75),
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             tooltip: 'Logout',
//             onPressed: () async {
//               await auth.logout();
//             },
//           ),
//         ],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, size: 64, color: Colors.grey.shade300),
//             const SizedBox(height: 16),
//             Text(
//               'Halaman $label',
//               style: const TextStyle(fontSize: 18, color: Colors.grey),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Coming Sprint 2',
//               style: TextStyle(fontSize: 13, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
