import 'package:farmer_mobile_app/shared/widgets/assistant_history_stories.dart';
import 'package:farmer_mobile_app/shared/widgets/voice_assistant_overlay.dart';
import 'package:farmer_mobile_app/shared/widgets/voice_mic_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For language detection
import 'package:flutter_tts/flutter_tts.dart'; // For the voice speaker
import 'package:farmer_mobile_app/core/api/dio_client.dart'; // ✅ Added for real notification fetching

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterTts _tts = FlutterTts();
  String _selectedLang = 'am'; // Default
  String _userName = ""; // Authenticated user name
  int _unreadCount = 0; // ✅ For notification badge

  @override
  void initState() {
    super.initState();
    _initAppVoice();
    _fetchUnreadNotifications(); // ✅ Fetch real notification count
  }

  // ✅ Fetching real count from your notifications table
  Future<void> _fetchUnreadNotifications() async {
    try {
      final response = await DioClient().dio.get('/users/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> notes = response.data;
        setState(() {
          _unreadCount =
              notes
                  .where((n) => n['is_read'] == 0 || n['is_read'] == false)
                  .length;
        });
      }
    } catch (e) {
      debugPrint("Notification Count Error: $e");
    }
  }

  // 🔊 Global Voice Greeting based on authenticated user and selected language
  Future<void> _initAppVoice() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _selectedLang = prefs.getString('language_code') ?? 'am';
      bool isAm = _selectedLang == 'am';

      // ✅ Fetching authenticated user or defaulting to professional terms
      _userName = prefs.getString('user_name') ?? (isAm ? "አርሶ አደር" : "Farmer");
    });

    // Configure TTS
    await _tts.setLanguage(_selectedLang == 'am' ? "am-ET" : "en-US");
    await _tts.setSpeechRate(0.4); // Natural speed for farmers

    // Automated Greeting using Professional dynamic name
    String greeting =
        _selectedLang == 'am'
            ? "እንኳን ደህና መጡ $_userName። ዛሬ ተክልዎን መርምረዋል?"
            : "Welcome back $_userName. Have you scanned your plants today?";

    await _tts.speak(greeting);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.height < 700;
    bool isAm = _selectedLang == 'am';

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
                _buildHeader(size, isAm),

                const SizedBox(height: 25),

                // 2. PRIMARY ACTION: Large White Scan Card (Centered focus)
                _buildScanCard(context, size, isSmallScreen, isAm),

                const SizedBox(height: 25),

                // 3. ACTION GRID: History and Voice Help
                Row(
                  children: [
                    _buildTile(
                      en: "Scan History",
                      am: "የምርመራ ታሪክ",
                      icon: Icons.history_rounded,
                      color: const Color(0xFFB38B4D), // Gold/Brown Accent
                      size: size,
                      onTap: () {
                        _tts.speak(isAm ? "ታሪክን በመመልከት ላይ" : "Opening History");
                        context.push('/history');
                      },
                    ),
                    const SizedBox(width: 15),
                    _buildTile(
                      en: "Voice Help",
                      am: "የድምፅ እርዳታ",
                      icon: Icons.graphic_eq_rounded,
                      color: const Color(0xFF1B3022),
                      size: size,
                      onTap: () async {
                        // 1. Speak initial prompt
                        await _tts.speak(
                          isAm ? "እንዴት ልረዳዎት እችላለሁ?" : "How can I help you?",
                        );

                        // 2. Show the professional AI Overlay
                        if (context.mounted) {
                          final command = await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder:
                                (context) =>
                                    VoiceAssistantOverlay(lang: _selectedLang),
                          );

                          // 3. Handle Navigation commands from the voice result
                          if (command != null) {
                            if (command.contains("scan") ||
                                command.contains("መርምር")) {
                              context.push('/detection');
                            } else if (command.contains("history") ||
                                command.contains("ታሪክ")) {
                              context.push('/history');
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // 4. INFORMATION: Weather Card
                _buildWeatherCard(context, size, isAm),

                const SizedBox(height: 20),

                // 🎤 NEW: Assistant History Stories
                const AssistantHistoryStories(),

                const SizedBox(height: 20),
                // 5. QUICK ACTIONS: Set at the bottom of the weather card
                _buildQuickActions(isAm),

                const SizedBox(height: 120), // Bottom padding for FAB
              ],
            ),
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const VoiceMicButton(),

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
                icon: const Icon(Icons.home_rounded, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.grey),
                onPressed: () => context.push('/history'),
              ),
              const SizedBox(width: 40),
              IconButton(
                icon: const Icon(
                  Icons.tips_and_updates_rounded,
                  color: Colors.grey,
                ),
                onPressed:
                    () => context.go(
                      '/tips',
                    ), // ✅ Now links to your new professional Tips screen
              ),
              IconButton(
                icon: const Icon(Icons.person_rounded, color: Colors.grey),
                onPressed: () => context.push('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildHeader(Size size, bool isAm) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
          child: const CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFF1B3022),
            child: Icon(Icons.person, color: Colors.white70, size: 30),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName,
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                isAm ? "ለተክል ተስማሚ ቀን ነው" : "Good day for your crops",
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // ✅ Notification Icon with Number Badge
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.white,
                size: 26,
              ),
              onPressed: () => context.push('/notifications'),
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildScanCard(
    BuildContext context,
    Size size,
    bool isSmall,
    bool isAm,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isSmall ? 35 : 50),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(35),
        onTap: () {
          _tts.speak(isAm ? "ካሜራውን ይክፈቱ" : "Opening Camera");
          context.push('/detection');
        },
        child: Column(
          children: [
            const Icon(
              Icons.camera_enhance_rounded,
              size: 80,
              color: Color(0xFF0D1B12),
            ),
            const SizedBox(height: 15),
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
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context, Size size, bool isAm) {
    return InkWell(
      onTap: () => context.push('/weather'),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF1B3022),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.wb_cloudy_rounded,
              color: Colors.blueAccent,
              size: 40,
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "24°C - Addis Ababa",
                  style: GoogleFonts.notoSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isAm ? "ደመናማ የአየር ሁኔታ" : "Cloudy Weather Today",
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ New Quick Action section at the bottom of weather card
  Widget _buildQuickActions(bool isAm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSmallAction(
          icon: Icons.storefront_rounded,
          label: isAm ? "ገበያ" : "Market",
          color: const Color(0xFF2E7D32),
          onTap: () => context.push('/market'),
        ),
        _buildSmallAction(
          icon: Icons.psychology_rounded,
          label: isAm ? "ባለሙያ" : "Expert",
          color: const Color(0xFF1565C0),
          onTap: () => context.push('/expert'),
        ),
        _buildSmallAction(
          icon: Icons.groups_rounded,
          label: isAm ? "ማህበረሰብ" : "Community",
          color: const Color(0xFF6A1B9A),
          onTap: () => context.push('/community'),
        ),
      ],
    );
  }

  Widget _buildSmallAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B3022),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

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
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 35),
              const SizedBox(height: 12),
              Text(
                en,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                am,
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
