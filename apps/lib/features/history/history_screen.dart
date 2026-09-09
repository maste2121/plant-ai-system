import 'package:farmer_mobile_app/shared/widgets/voice_mic_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
// ✅ New Imports for Map functionality
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isListView = true;

  // Mock Data (Updated with Coordinates for the Map)
  final List<Map<String, dynamic>> scanHistory = [
    {
      "date": "2024-05-15",
      "disease": "Late Blight",
      "amharic": "የቆየ ግርሻ",
      "status": "Disease",
      "crop": "Potato",
      "imagePath": "",
      "lat": 9.0300, "lng": 38.7400, // Addis Ababa area
    },
    {
      "date": "2024-05-12",
      "disease": "Healthy",
      "amharic": "ጤናማ",
      "status": "Healthy",
      "crop": "Tomato",
      "imagePath": "",
      "lat": 9.0500,
      "lng": 38.7600,
    },
    {
      "date": "2024-05-10",
      "disease": "Bacterial Wilt",
      "amharic": "ባክቴሪያል ቫይረስ",
      "status": "Disease",
      "crop": "Maize",
      "imagePath": "",
      "lat": 9.0100,
      "lng": 38.7200,
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
            // ✅ Replaced placeholder with functional Map View
            child: isListView ? _buildHistoryList() : _buildFunctionalMap(),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const VoiceMicButton(),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ✅ New Functional Map View Method
  Widget _buildFunctionalMap() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(9.0300, 38.7400), // Default to Ethiopia area
          initialZoom: 11.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.farmer_mobile_app.app',
          ),
          MarkerLayer(
            markers:
                scanHistory.map((item) {
                  return Marker(
                    point: LatLng(item['lat'], item['lng']),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _showMarkerDetails(item),
                      child: Icon(
                        Icons.location_on,
                        color:
                            item['status'] == 'Healthy'
                                ? Colors.green
                                : Colors.red,
                        size: 40,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // ✅ Helper to show details when clicking a map marker
  void _showMarkerDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B3022),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.eco, color: Colors.green, size: 40),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['disease'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item['date'],
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/result', extra: File("")),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB38B4D),
                  ),
                  child: const Text("Details"),
                ),
              ],
            ),
          ),
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
            borderRadius: BorderRadius.circular(20),
            onTap: () {
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
              // ✅ Enabled Tips Page Navigation
              onPressed: () => context.push('/tips'),
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
