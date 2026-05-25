import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup Advanced Animations (Fade + Scale)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ), // ✅ Corrected
    );

    _controller.forward();

    // 2. Start Logic Check
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Artificial delay to show the beautiful UI (3 seconds total)
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();

    // Logic Checks
    final bool isFirstTime = prefs.getBool('is_first_time') ?? true;
    final String? lang = prefs.getString('language_code');
    final String? token = prefs.getString('auth_token');

    if (!mounted) return;

    // Decision Tree Navigation
    if (isFirstTime) {
      context.go('/onboarding');
    } else if (lang == null) {
      context.go('/language');
    } else if (token == null) {
      context.go('/login'); // Send to /login later when backend is ready
    } else {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Professional Radial Gradient for depth
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF1B3022), // Lighter center
              Color(0xFF0D1B12), // Deep forest edges
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Logo & Title
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glow Effect around Icon
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: Color(0xFF4CAF50),
                        size: 120,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "KARE",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "AI PLANT ADVISOR",
                      style: GoogleFonts.notoSans(
                        color: Colors.white54,
                        fontSize: 14,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Loading & Branding
            Positioned(
              bottom: 60,
              child: Column(
                children: [
                  const SizedBox(
                    width: 50,
                    child: LinearProgressIndicator(
                      color: Color(0xFF4CAF50),
                      backgroundColor: Colors.white10,
                      minHeight: 2,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "SMART AGRICULTURE SYSTEM",
                    style: GoogleFonts.notoSans(
                      color: Colors.white24,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
