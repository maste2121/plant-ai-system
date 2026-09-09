import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:farmer_mobile_app/shared/widgets/voice_mic_button.dart';
import 'package:intl/intl.dart';
import '../../core/api/dio_client.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FlutterTts _tts = FlutterTts();
  String _selectedLang = 'am';
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedLang = prefs.getString('language_code') ?? 'am';
    await _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await DioClient().dio.get('/users/notifications');
      if (mounted) {
        setState(() {
          _notifications = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Mark as Read logic
  Future<void> _markRead(int id) async {
    try {
      await DioClient().dio.put('/users/notifications/$id/read');
      _fetchNotifications(); // Refresh to update unread count
    } catch (e) {
      debugPrint("Read Error: $e");
    }
  }

  void _readVoice(String am, String en) async {
    await _tts.setLanguage(_selectedLang == 'am' ? "am-ET" : "en-US");
    await _tts.speak(_selectedLang == 'am' ? am : en);
  }

  @override
  Widget build(BuildContext context) {
    bool isAm = _selectedLang == 'am';

    // ✅ Calculate Unseen Number
    int unreadCount =
        _notifications
            .where((n) => n['is_read'] == 0 || n['is_read'] == false)
            .length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Text(isAm ? "ማሳወቂያዎች" : "Notifications"),
            if (unreadCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$unreadCount",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              )
              : _notifications.isEmpty
              ? _buildEmptyState(isAm)
              : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _notifications.length,
                itemBuilder:
                    (context, index) =>
                        _buildNotificationCard(_notifications[index], isAm),
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const VoiceMicButton(),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n, bool isAm) {
    // Check if seen based on is_read column
    bool isRead = n['is_read'] == 1 || n['is_read'] == true;

    IconData icon = Icons.notifications_none_rounded;
    Color color = const Color(0xFF4CAF50);
    if (n['type'] == 'outbreak') {
      icon = Icons.warning_amber_rounded;
      color = Colors.redAccent;
    }
    if (n['type'] == 'weather') {
      icon = Icons.cloud_outlined;
      color = Colors.blueAccent;
    }

    return GestureDetector(
      onTap: () => _markRead(n['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color:
              isRead
                  ? const Color(0xFF1B3022)
                  : const Color(0xFF233D2B), // Unseen is brighter
          borderRadius: BorderRadius.circular(20),
          border: isRead ? null : Border.all(color: color.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAm ? n['title_am'] : n['title_en'],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isAm
                          ? n['message_am']
                          : n['message_en'], // ✅ Updated from image
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead) // Show a small dot for unseen
                const CircleAvatar(
                  radius: 4,
                  backgroundColor: Color(0xFFB38B4D),
                ),

              IconButton(
                icon: const Icon(
                  Icons.volume_up,
                  color: Colors.white24,
                  size: 20,
                ),
                onPressed: () => _readVoice(n['message_am'], n['message_en']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isAm) {
    return Center(
      child: Text(
        isAm ? "ምንም ማሳወቂያ የለም" : "No notifications",
        style: const TextStyle(color: Colors.white24),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      color: const Color(0xFF1B3022),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.grey),
            onPressed: () => context.go('/home'),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.grey),
            onPressed: () => context.go('/history'),
          ),
          const SizedBox(width: 40),
          IconButton(
            icon: const Icon(
              Icons.tips_and_updates_outlined,
              color: Colors.grey,
            ),
            onPressed: () => context.go('/tips'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.grey),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}
