import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigasi ke AuthWrapper setelah 2,5 detik
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Stack(
        children: [
          // 1. Ambient Glow (Radial gradient effect in background)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    Color(0x0A0050CB), // #0050cb with 4% opacity
                    Color(0x00F7F9FB), // Transparent background color
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          
          // 2. Main content
          Positioned.fill(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Spacer to balance the layout
                  const SizedBox(height: 48),

                // Branding Cluster (Icon & Titles)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rotated Icon Card with soft blur background
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft glow behind logo
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0050CB).withValues(alpha: 0.04),
                          ),
                        ),
                        // Rotated logo card
                        Transform.rotate(
                          angle: 3 * math.pi / 180, // Rotate by 3 degrees
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0050CB),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0050CB).withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.volunteer_activism,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    const Text(
                      'Donasee',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0050CB),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Subtitle Tagline
                    const Text(
                      'Menghubungkan Kebaikan untuk Sesama',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF424656),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                // Bottom Loading & Version Cluster
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Loading Ring (Native CircularProgressIndicator configured to match the design)
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0050CB)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Loading Text
                      Text(
                        'MENYIAPKAN KEBAIKAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF727687).withValues(alpha: 0.8),
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 36),
                      
                      // Divider & Version
                      Container(
                        width: 96,
                        height: 1,
                        color: const Color(0xFFE0E3E5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Versi 2.4.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF727687),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  }
}
