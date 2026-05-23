import 'package:farmer_mobile_app/shared/widgets/voice_mic_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12), // KARE Deep Dark Green
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. User Profile Header
                _buildHeader(size),

                SizedBox(height: isSmallScreen ? 20 : 30),

                // 2. Large White Scan Card
                _buildScanCard(context, size, isSmallScreen),

                SizedBox(height: isSmallScreen ? 20 : 25),

                // 3. Grid Tiles (Interactive Version)
                Row(
                  children: [
                    _buildTile(
                      en: "Scan History",
                      am: "ታሪክ",
                      icon: Icons.history,
                      color: const Color(0xFFB38B4D),
                      size: size,
                      // ✅ FIXED: Added navigation here
                      onTap: () => context.push('/history'),
                    ),
                    const SizedBox(width: 15),
                    _buildTile(
                      en: "Voice Help",
                      am: "እርዳታ",
                      icon: Icons.mic,
                      color: const Color(0xFF1B3022),
                      size: size,
                      onTap: () => print("Voice Assistant Activated"),
                    ),
                  ],
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),

      // 4. Floating Mic Button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const VoiceMicButton(),

      // 5. Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1B3022),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () => context.go('/home'),
              ),
              IconButton(
                icon: const Icon(Icons.history, color: Colors.grey),
                onPressed: () => context.push('/history'),
              ),
              const SizedBox(width: 40),
              IconButton(
                icon: const Icon(Icons.tips_and_updates, color: Colors.grey),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.person, color: Colors.grey),
                onPressed: () => context.push('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildHeader(Size size) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Dereje (ደረጀ)",
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSans(
                  fontSize: size.width > 400 ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                "Good day for planting",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.notifications_none, color: Colors.white),
      ],
    );
  }

  Widget _buildScanCard(BuildContext context, Size size, bool isSmall) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isSmall ? 30 : 50),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () => context.push('/detection'),
        child: Column(
          children: [
            Icon(
              Icons.camera_alt,
              size: size.width * 0.18,
              color: const Color(0xFF0D1B12),
            ),
            const SizedBox(height: 10),
            Text(
              "Scan Plant",
              style: GoogleFonts.notoSans(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "ተክል ምርመራ",
              style: GoogleFonts.notoSansEthiopic(
                color: Colors.black54,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: Added onTap parameter and InkWell to make the tiles clickable
  Widget _buildTile({
    required String en,
    required String am,
    required IconData icon,
    required Color color,
    required Size size,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 10),
              Text(
                en,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                am,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansEthiopic(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
