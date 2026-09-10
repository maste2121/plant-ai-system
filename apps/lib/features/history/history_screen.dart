import 'package:farmer_mobile_app/shared/widgets/voice_mic_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../core/api/dio_client.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isListView = true;
  bool _isLoading = true;
  List<dynamic> _realHistory = [];
  int _classificationType = 0;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await DioClient().dio.get('/users/history');
      if (response.statusCode == 200) {
        setState(() {
          // ✅ FIX: Handle both raw List and Map { "data": [] } formats
          if (response.data is List) {
            _realHistory = response.data;
          } else if (response.data is Map && response.data['data'] != null) {
            _realHistory = response.data['data'];
          } else {
            _realHistory = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("History Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // ✅ Helper to safely parse dates
  DateTime _getDateTime(dynamic item) {
    try {
      String? dateStr =
          item['created_at'] ?? item['createdAt'] ?? item['scan_date'];
      if (dateStr == null) return DateTime.now();
      return DateTime.parse(dateStr).toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }

  // ✅ Helper to safely parse coordinates
  double _parseCoordinate(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    return double.tryParse(value.toString()) ?? defaultValue;
  }

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
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              )
              : Column(
                children: [
                  const SizedBox(height: 15),
                  _buildMainToggle(),
                  const SizedBox(height: 15),
                  if (isListView) _buildClassificationSelector(),
                  const SizedBox(height: 10),
                  Expanded(
                    child:
                        _realHistory.isEmpty
                            ? _buildEmptyState()
                            : (isListView
                                ? _buildClassifiedList()
                                : _buildFunctionalMap()),
                  ),
                ],
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const VoiceMicButton(),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildClassifiedList() {
    return _classificationType == 0
        ? _buildTimeGroupedList()
        : _buildProcessGroupedList();
  }

  Widget _buildTimeGroupedList() {
    final now = DateTime.now();
    final today =
        _realHistory.where((i) => _isSameDay(_getDateTime(i), now)).toList();
    final yesterday =
        _realHistory
            .where(
              (i) => _isSameDay(
                _getDateTime(i),
                now.subtract(const Duration(days: 1)),
              ),
            )
            .toList();
    final older =
        _realHistory.where((i) {
          final date = _getDateTime(i);
          return !_isSameDay(date, now) &&
              !_isSameDay(date, now.subtract(const Duration(days: 1)));
        }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (today.isNotEmpty) ...[
          _buildHeader("Today / ዛሬ"),
          ...today.map((i) => _buildHistoryCard(i)),
        ],
        if (yesterday.isNotEmpty) ...[
          _buildHeader("Yesterday / ትናንት"),
          ...yesterday.map((i) => _buildHistoryCard(i)),
        ],
        if (older.isNotEmpty) ...[
          _buildHeader("Older / ያለፉ"),
          ...older.map((i) => _buildHistoryCard(i)),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildProcessGroupedList() {
    final healthy =
        _realHistory
            .where((i) => i['status'].toString().toLowerCase() == 'healthy')
            .toList();
    final disease =
        _realHistory
            .where((i) => i['status'].toString().toLowerCase() != 'healthy')
            .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (disease.isNotEmpty) ...[
          _buildHeader("Infected / በሽታ ያለባቸው", color: Colors.redAccent),
          ...disease.map((i) => _buildHistoryCard(i)),
        ],
        if (healthy.isNotEmpty) ...[
          _buildHeader("Healthy / ጤናማ", color: Colors.green),
          ...healthy.map((i) => _buildHistoryCard(i)),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final bool isHealthy = item['status'].toString().toLowerCase() == 'healthy';
    final date = _getDateTime(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3022),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // ✅ FIX: Pass an empty File object instead of 'null' to prevent the subtype error
        onTap:
            () => context.push(
              '/result',
              extra: {'image': File(''), 'data': item},
            ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.white10,
                  child: Icon(
                    Icons.eco,
                    color: isHealthy ? Colors.green : Colors.orangeAccent,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['disease_en'] ?? "Unknown",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item['disease_am'] ?? "",
                      style: GoogleFonts.notoSansEthiopic(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      DateFormat('jm').format(date),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isHealthy ? Colors.green : Colors.redAccent,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionalMap() {
    return FlutterMap(
      options: MapOptions(
        initialCenter:
            _realHistory.isNotEmpty
                ? LatLng(
                  _parseCoordinate(_realHistory[0]['lat'], 9.03),
                  _parseCoordinate(_realHistory[0]['lng'], 38.74),
                )
                : const LatLng(9.03, 38.74),
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        MarkerLayer(
          markers:
              _realHistory.map((item) {
                return Marker(
                  point: LatLng(
                    _parseCoordinate(item['lat'], 9.03),
                    _parseCoordinate(item['lng'], 38.74),
                  ),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showMarkerDetails(item),
                    child: Icon(
                      Icons.location_on,
                      color:
                          item['status'].toString().toLowerCase() == 'healthy'
                              ? Colors.green
                              : Colors.redAccent,
                      size: 40,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  void _showMarkerDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B3022),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(25),
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
                        item['disease_en'] ?? "Unknown",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        DateFormat('yMMMd').format(_getDateTime(item)),
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  // ✅ FIX: Pass an empty File object instead of 'null'
                  onPressed:
                      () => context.push(
                        '/result',
                        extra: {'image': File(''), 'data': item},
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB38B4D),
                  ),
                  child: const Text("View"),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMainToggle() {
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

  Widget _buildClassificationSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          _smallTab("By Time", 0),
          const SizedBox(width: 10),
          _smallTab("By Result", 1),
        ],
      ),
    );
  }

  Widget _smallTab(String label, int index) {
    bool active = _classificationType == index;
    return GestureDetector(
      onTap: () => setState(() => _classificationType = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color:
              active
                  ? const Color(0xFFB38B4D).withOpacity(0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: active ? const Color(0xFFB38B4D) : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFB38B4D) : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, {Color color = Colors.white54}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_outlined, size: 80, color: Colors.white10),
          const SizedBox(height: 10),
          Text(
            "No history found",
            style: GoogleFonts.notoSans(color: Colors.white38),
          ),
          Text(
            "ምንም ታሪክ አልተገኘም",
            style: GoogleFonts.notoSansEthiopic(color: Colors.white10),
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
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 40),
          IconButton(
            icon: const Icon(
              Icons.tips_and_updates_rounded,
              color: Colors.grey,
            ),
            onPressed: () => context.push('/tips'),
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded, color: Colors.grey),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
}
