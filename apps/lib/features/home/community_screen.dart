// lib/features/community/presentation/community_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer_mobile_app/core/api/dio_client.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _isLoading = true;
  bool _isAm = false;
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadLanguageAndData();
  }

  Future<void> _loadLanguageAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language_code') ?? 'am';
    setState(() => _isAm = lang == 'am');

    try {
      final response = await DioClient().dio.get('/community/posts');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> raw =
            response.data is List ? response.data : response.data['data'] ?? [];
        setState(() {
          _posts =
              raw
                  .map(
                    (p) => {
                      'id': p['id']?.toString() ?? '',
                      'author': p['author_name'] ?? 'Farmer',
                      'content': p['content'] ?? '',
                      'likes': p['likes_count'] ?? 0,
                      'comments': p['comments_count'] ?? 0,
                    },
                  )
                  .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Community Fetch Error: $e");
      // Fallback local data if backend is offline
      setState(() {
        _posts = [
          {
            'id': '1',
            'author': _isAm ? 'አቶ በቀለ' : 'Ato Bekele',
            'content':
                _isAm
                    ? 'የስንዴ ቢጫ ዝገትን ለመከላከል የትኛውን መድሃኒት ብጠቀም ይሻላል?'
                    : 'Which pesticide works best for Wheat Yellow Rust?',
            'likes': 14,
            'comments': 5,
          },
          {
            'id': '2',
            'author': _isAm ? 'ወይዘሮ እመቤት' : 'W/ro Emebet',
            'content':
                _isAm
                    ? 'የቲማቲም ተክሌ ቅጠሎች እየወፈሩ ነው። መፍትሄ ያላችሁ?'
                    : 'My tomato leaves are yellowing. Any tips?',
            'likes': 8,
            'comments': 3,
          },
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B3022),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isAm ? "የአርሶ አደሮች ማህበረሰብ" : "Farmer Community",
          style: GoogleFonts.notoSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6A1B9A)),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return Card(
                      color: const Color(0xFF1B3022),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFF6A1B9A),
                                  child: Icon(
                                    Icons.groups,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  post['author'],
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              post['content'],
                              style: GoogleFonts.notoSans(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.thumb_up_alt_outlined,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${post['likes']}",
                                  style: const TextStyle(color: Colors.white54),
                                ),
                                const SizedBox(width: 20),
                                const Icon(
                                  Icons.comment_outlined,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${post['comments']}",
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
