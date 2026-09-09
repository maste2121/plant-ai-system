import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:farmer_mobile_app/shared/widgets/voice_mic_button.dart';
import '../auth/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FlutterTts _tts = FlutterTts();
  String _currentLang = 'am';
  String _userName = "Dereje Abebe";

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLang = prefs.getString('language_code') ?? 'am';
      _userName = prefs.getString('user_name') ?? "Dereje (ደረጀ)";
    });
    _speakIntro();
  }

  Future<void> _speakIntro() async {
    await _tts.setLanguage(_currentLang == 'am' ? "am-ET" : "en-US");
    await _tts.speak(
      _currentLang == 'am'
          ? "ወደ መገለጫዎ እንኳን ደህና መጡ።"
          : "Welcome to your profile.",
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAm = _currentLang == 'am';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          isAm ? "የእኔ መገለጫ" : "My Profile",
          style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeader(isAm),
            const SizedBox(height: 40),

            // --- SRD 4.7: User Scan History Quick Access ---
            _buildMenuTile(
              icon: Icons.history_rounded,
              title: isAm ? "የምርመራ ታሪክ" : "My Scan History",
              subtitle:
                  isAm ? "ያለፉ ምርመራዎችን ይመልከቱ" : "View your previous results",
              color: const Color(0xFFB38B4D), // Gold highlight
              onTap: () {
                _tts.speak(isAm ? "ታሪክን በመመልከት ላይ" : "Viewing history");
                context.push('/history');
              },
            ),

            const SizedBox(height: 15),

            // --- SRD 4.11: App Settings Link ---
            _buildMenuTile(
              icon: Icons.settings_suggest_rounded,
              title: isAm ? "ቅንብሮች" : "App Settings",
              subtitle: isAm ? "ቋንቋ እና ማሳወቂያዎች" : "Language & Notifications",
              color: const Color(0xFF1B3022),
              onTap: () {
                _tts.speak(isAm ? "ቅንብሮች" : "Settings");
                context.push('/settings');
              },
            ),

            const SizedBox(height: 30),

            // --- SRD 4.11: My Crops Personalization ---
            _buildSectionHeader(isAm ? "የእኔ ሰብሎች" : "My Crops"),
            const SizedBox(height: 15),
            _buildCropGrid(isAm),

            const SizedBox(height: 50),
            _buildLogoutButton(isAm),
            const SizedBox(height: 120),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const VoiceMicButton(),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // --- COMPONENT WIDGETS ---

  Widget _buildHeader(bool isAm) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 55,
          backgroundColor: Color(0xFF4CAF50),
          child: CircleAvatar(
            radius: 52,
            backgroundImage: NetworkImage("https://via.placeholder.com/150"),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          _userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isAm ? "አማርኛ ተጠቃሚ" : "English User",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF4CAF50),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropGrid(bool isAm) {
    // Shared list of crops from your SRD/UI
    final crops = [
      {'n': 'Coffee', 'a': 'ቡና', 'i': Icons.eco},
      {'n': 'Teff', 'a': 'ጤፍ', 'i': Icons.grass},
      {'n': 'Maize', 'a': 'በቆሎ', 'i': Icons.grain},
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: crops.map((c) => _buildCropIcon(c, isAm)).toList(),
    );
  }

  Widget _buildCropIcon(Map<String, dynamic> crop, bool isAm) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3022),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(crop['i'], color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            isAm ? crop['a'] : crop['n'],
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(bool isAm) {
    return TextButton.icon(
      onPressed: () async {
        await AuthService().logout();
        context.go('/login');
      },
      icon: const Icon(Icons.logout, color: Colors.redAccent),
      label: Text(
        isAm ? "ውጣ" : "Logout",
        style: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      color: const Color(0xFF1B3022),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.grey),
            onPressed: () => context.go('/home'),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.grey),
            onPressed: () => context.go('/history'),
          ),
          const SizedBox(width: 40),
          IconButton(
            icon: const Icon(Icons.tips_and_updates, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
