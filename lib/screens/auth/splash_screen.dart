import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();

    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    await authProvider.loadCurrentUser();
    if (!mounted) return;

    if (authProvider.currentUser == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    switch (authProvider.currentUser!.role) {
      case UserRole.doctor:
        Navigator.of(context).pushReplacementNamed('/doctor/home');
        break;
      case UserRole.nurse:
        Navigator.of(context).pushReplacementNamed('/nurse/home');
        break;
      case UserRole.admin:
        Navigator.of(context).pushReplacementNamed('/admin/home');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_box_outlined,
                    size: 64,
                    color: Colors.white,
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.8, 0.8)),
                  const SizedBox(height: 20),
                  Text(
                    'Wardly',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Ward, connected',
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate(
                            onPlay: (c) => c.repeat(reverse: true),
                          )
                          .fadeIn(
                            delay: (i * 200).ms,
                            duration: 600.ms,
                          )
                          .then()
                          .fadeOut(duration: 600.ms),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
