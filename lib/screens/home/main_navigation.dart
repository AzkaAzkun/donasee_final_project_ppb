import 'package:donasee_final_project_ppb/models/user_model.dart';
import 'package:donasee_final_project_ppb/screens/donasiku/donasiku_screen.dart';
import 'package:donasee_final_project_ppb/screens/kabar/kabar_baik_screen.dart';
import 'package:donasee_final_project_ppb/screens/profil/profil_screen.dart';
import 'package:donasee_final_project_ppb/services/auth_service.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import 'jelajah_screen.dart';
import '../admin/kelola_donasi_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _idx = 0;
  UserModel? _currentUser;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUserModel();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _loadingUser = false;
      });
    }
  }

  List<Widget> get _screens {
    if (_currentUser!.isAdmin) {
      return [
        const JelajahScreen(),
        const KelolaDonasiScreen(), // ← admin dapat ini
        const KabarBaikScreen(),
        ProfilScreen(user: _currentUser!),
      ];
    }
    return [
      const JelajahScreen(),
      const DonasikuScreen(), // ← donatur dapat ini
      const KabarBaikScreen(),
      ProfilScreen(user: _currentUser!),
    ];
  }

  List<BottomNavigationBarItem> get _navItems {
    if (_currentUser?.isAdmin == true) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          activeIcon: Icon(Icons.explore),
          label: 'Jelajah',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.task_alt_outlined),
          activeIcon: Icon(Icons.task_alt),
          label: 'Verifikasi', // label beda untuk admin
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

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        selectedItemColor: const Color(0xFF1D9E75),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // wajib jika tab >= 4
        items: _navItems,
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
