import 'package:farmer_mobile_app/shared/widgets/voice_mic_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:io'; // Needed for File handling

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isListView = true;

  // Mock Data
  final List<Map<String, dynamic>> scanHistory = [
    {
      "date": "2024-05-15",
      "disease": "Late Blight",
      "amharic": "የቆየ ግርሻ",
      "status": "Disease",
      "crop": "Potato",
      // For history, we use a placeholder or a saved path
      "imagePath": "",
    },
    {
      "date": "2024-05-12",
      "disease": "Healthy",
      "amharic": "ጤናማ",
      "status": "Healthy",
      "crop": "Tomato",
      "imagePath": "",
    },
    {
      "date": "2024-05-10",
      "disease": "Bacterial Wilt",
      "amharic": "ባክቴሪያል ቫይረስ",
      "status": "Disease",
      "crop": "Maize",
      "imagePath": "",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          children: [
            Text(
              "Scan History",
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "የታሪክ መዝገብ",
              style: GoogleFonts.notoSansEthiopic(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildViewToggle(),
          const SizedBox(height: 20),
          Expanded(
            child: isListView ? _buildHistoryList() : _buildMapPlaceholder(),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const VoiceMicButton(),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(4),
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFF1B3022),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isListView = true),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isListView ? const Color(0xFFB38B4D) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.format_list_bulleted_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isListView = false),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      !isListView
                          ? const Color(0xFFB38B4D)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(Icons.map_outlined, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: scanHistory.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final item = scanHistory[index];
        final bool isHealthy = item['status'] == 'Healthy';

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF1B3022),
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            // ✅ Added InkWell to handle clicks
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // ✅ Navigate to the Treatment/Advisory Screen
              // For History, we pass a dummy File object or the real one if it exists
              context.push('/result', extra: File(item['imagePath'] ?? ""));
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: 75,
                      height: 75,
                      color: Colors.white10,
                      child: const Icon(
                        Icons.eco,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['date'],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          item['disease'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          item['amharic'],
                          style: GoogleFonts.notoSansEthiopic(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Navigation Arrow to indicate it's clickable
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white24,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isHealthy
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isHealthy ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Text(
                      isHealthy ? "Healthy" : "Disease",
                      style: TextStyle(
                        color: isHealthy ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapPlaceholder() {
    return const Center(
      child: Text("Map View coming soon", style: TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      color: const Color(0xFF1B3022),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.grey),
              onPressed: () => context.go('/home'),
            ),
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              onPressed: () {},
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: const Icon(Icons.tips_and_updates, color: Colors.grey),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.grey),
              onPressed: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}
