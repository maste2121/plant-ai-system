import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:farmer_mobile_app/shared/widgets/voice_mic_button.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FlutterTts _tts = FlutterTts();
  String _selectedLang = 'am';

  // Mock Data: Professional Alert Collection (SRD 4.10)
  final List<Map<String, dynamic>> _notifications = [
    {
      "id": "1",
      "type": "outbreak",
      "titleEn": "Outbreak Alert: Late Blight",
      "titleAm": "የበሽታ ወረርሽኝ ማስጠንቀቂያ",
      "descEn":
          "Late Blight detected 2km from your location. Check your Potato crops.",
      "descAm": "ከእርስዎ 2 ኪ.ሜ ርቀት ላይ በሽታ ተገኝቷል። ድንችዎን ይፈትሹ።",
      "time": "2 hours ago",
      "isRead": false,
    },
    {
      "id": "2",
      "type": "weather",
      "titleEn": "Heavy Rain Forecast",
      "titleAm": "ከባድ ዝናብ ይጠበቃል",
      "descEn":
          "Heavy rain expected in Addis Ababa this evening. Avoid spraying today.",
      "descAm": "ዛሬ ምሽት አዲስ አበባ ውስጥ ዝናብ ይጠበቃል። ዛሬ መድሃኒት አይርጩ።",
      "time": "5 hours ago",
      "isRead": true,
    },
    {
      "id": "3",
      "type": "farming",
      "titleEn": "Fertilizer Reminder",
      "titleAm": "የማዳበሪያ ማስታወሻ",
      "descEn": "Time to apply top-dress urea for your Maize crop.",
      "descAm": "ለበቆሎ ሰብልዎ ማዳበሪያ የሚጨምሩበት ጊዜ ደርሷል።",
      "time": "Yesterday",
      "isRead": true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selectedLang = prefs.getString('language_code') ?? 'am');
  }

  void _readNotification(String am, String en) async {
    await _tts.setLanguage(_selectedLang == 'am' ? "am-ET" : "en-US");
    await _tts.speak(_selectedLang == 'am' ? am : en);
  }

  @override
  Widget build(BuildContext context) {
    bool isAm = _selectedLang == 'am';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12), // KARE Deep Dark Green
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isAm ? "ማሳወቂያዎች" : "Notifications",
          style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed:
                () => setState(() {
                  for (var n in _notifications) {
                    n['isRead'] = true;
                  }
                }),
            child: Text(
              isAm ? "ሁሉንም አንብብ" : "Mark all read",
              style: const TextStyle(color: Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
      body:
          _notifications.isEmpty
              ? _buildEmptyState(isAm)
              : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationCard(_notifications[index], isAm);
                },
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const VoiceMicButton(),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n, bool isAm) {
    // Styling logic based on type
    IconData icon;
    Color iconColor;
    switch (n['type']) {
      case 'outbreak':
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.redAccent;
        break;
      case 'weather':
        icon = Icons.cloud_sync_rounded;
        iconColor = Colors.blueAccent;
        break;
      default:
        icon = Icons.assignment_turned_in_outlined;
        iconColor = const Color(0xFF4CAF50);
    }

    return GestureDetector(
      onTap: () => setState(() => n['isRead'] = true),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color:
              n['isRead'] ? const Color(0xFF1B3022) : const Color(0xFF233D2B),
          borderRadius: BorderRadius.circular(20),
          border:
              n['isRead']
                  ? null
                  : Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Icon
              CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.1),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 15),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          n['time'],
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 11,
                          ),
                        ),
                        if (!n['isRead'])
                          const CircleAvatar(
                            radius: 4,
                            backgroundColor: Color(0xFFB38B4D),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isAm ? n['titleAm'] : n['titleEn'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            n['isRead'] ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAm ? n['descAm'] : n['descEn'],
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // 🔊 Voice Playback Button
              IconButton(
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white30,
                  size: 20,
                ),
                onPressed: () => _readNotification(n['descAm'], n['descEn']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isAm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.white10,
          ),
          const SizedBox(height: 15),
          Text(
            isAm ? "ምንም ማሳወቂያ የለም" : "No new notifications",
            style: const TextStyle(color: Colors.white24),
          ),
        ],
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
            icon: const Icon(Icons.home_rounded, color: Colors.grey),
            onPressed: () => context.go('/home'),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.grey),
            onPressed: () => context.go('/history'),
          ),
          const SizedBox(width: 40),
          IconButton(
            icon: const Icon(
              Icons.tips_and_updates_rounded,
              color: Colors.grey,
            ),
            onPressed: () => context.go('/tips'),
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded, color: Colors.grey),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}
