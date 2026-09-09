import 'package:flutter/material.dart';
import 'package:farmer_mobile_app/core/api/dio_client.dart';
import 'package:google_fonts/google_fonts.dart';

class AssistantHistoryStories extends StatefulWidget {
  const AssistantHistoryStories({super.key});

  @override
  State<AssistantHistoryStories> createState() =>
      _AssistantHistoryStoriesState();
}

class _AssistantHistoryStoriesState extends State<AssistantHistoryStories> {
  List<dynamic> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  // ✅ Step 1: Improved Fetching with Type Checking
  Future<void> _fetchChats() async {
    try {
      final res = await DioClient().dio.get('/users/assistant/history');
      if (res.statusCode == 200) {
        setState(() {
          // Ensure we handle both raw list and wrapped object responses
          if (res.data is List) {
            _chats = res.data;
          } else if (res.data is Map && res.data['data'] != null) {
            _chats = res.data['data'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("🔴 Story Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Step 2: Show conversation in a nice dialog when clicked
  void _showChatDetail(Map<String, dynamic> chat) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1B3022),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              "Chat Detail",
              style: GoogleFonts.notoSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You asked:",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  chat['user_query'] ?? "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Divider(color: Colors.white10, height: 20),
                Text(
                  "AI Answered:",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  chat['ai_response'] ?? "",
                  style: const TextStyle(color: Color(0xFF4CAF50)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Color(0xFFB38B4D)),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFB38B4D),
          ),
        ),
      );
    }

    if (_chats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Assistant History",
                style: GoogleFonts.notoSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: _fetchChats,
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white24,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _chats.length,
            itemBuilder: (context, i) {
              final chat = _chats[i];
              return GestureDetector(
                onTap:
                    () => _showChatDetail(
                      chat,
                    ), // ✅ Click to see full conversation
                child: Container(
                  width: 75,
                  margin: const EdgeInsets.only(right: 15),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFB38B4D),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF1B3022),
                          child: const Icon(
                            Icons.chat_bubble_rounded,
                            color: Color(0xFFB38B4D),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        chat['user_query'] ?? "...",
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
