import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:farmer_mobile_app/shared/widgets/voice_mic_button.dart';
import '../../core/api/dio_client.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  final FlutterTts _tts = FlutterTts();
  String _selectedLang = 'am';
  String _activeCategory = 'All'; // Or 'ሁሉም' for Amharic
  List<dynamic> _allTips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadLang();
    await _fetchTipsFromDb();
  }

  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedLang = prefs.getString('language_code') ?? 'am';
    await _tts.setLanguage(_selectedLang == 'am' ? "am-ET" : "en-US");
    if (mounted) setState(() {});
  }

  Future<void> _fetchTipsFromDb() async {
    try {
      final response = await DioClient().dio.get('/users/tips');
      if (response.statusCode == 200) {
        setState(() {
          _allTips = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Tips Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // ✅ Helper to map DB string to Flutter Icon
  IconData _getIcon(String name) {
    switch (name) {
      case 'grain':
        return Icons.grain_rounded;
      case 'eco':
        return Icons.eco_rounded;
      case 'landscape':
        return Icons.landscape_rounded;
      default:
        return Icons.tips_and_updates_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAm = _selectedLang == 'am';

    // Filter logic
    final filteredTips =
        _allTips.where((tip) {
          if (_activeCategory == 'All' || _activeCategory == 'ሁሉም') return true;
          return tip['category'].toString().toLowerCase() ==
              _activeCategory.toLowerCase();
        }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(isAm ? "የእርሻ ምክሮች" : "Farming Tips"),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFB38B4D)),
              )
              : Column(
                children: [
                  _buildCategorySlider(isAm),
                  Expanded(
                    child:
                        filteredTips.isEmpty
                            ? _buildEmptyState(isAm)
                            : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: filteredTips.length,
                              itemBuilder:
                                  (context, index) =>
                                      _buildTipCard(filteredTips[index], isAm),
                            ),
                  ),
                ],
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const VoiceMicButton(),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildCategorySlider(bool isAm) {
    final cats =
        isAm
            ? ['ሁሉም', 'Maize', 'Coffee', 'Soil']
            : ['All', 'Maize', 'Coffee', 'Soil'];
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: cats.length,
        itemBuilder: (context, i) {
          bool active = _activeCategory == cats[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(cats[i]),
              selected: active,
              onSelected: (val) => setState(() => _activeCategory = cats[i]),
              selectedColor: const Color(0xFFB38B4D),
              backgroundColor: const Color(0xFF1B3022),
              labelStyle: TextStyle(
                color: active ? Colors.white : Colors.white54,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip, bool isAm) {
    Color cardColor = Color(
      int.parse(tip['color_hex'].replaceAll('#', '0xFF')),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3022),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: cardColor.withOpacity(0.2),
          child: Icon(_getIcon(tip['icon_name']), color: cardColor),
        ),
        title: Text(
          isAm ? tip['title_am'] : tip['title_en'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            isAm ? tip['description_am'] : tip['description_en'],
            style: const TextStyle(color: Colors.white60),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.volume_up, color: Color(0xFFB38B4D)),
          onPressed:
              () => _tts.speak(
                isAm ? tip['description_am'] : tip['description_en'],
              ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isAm) {
    return Center(
      child: Text(
        isAm ? "ምንም ምክሮች አልተገኙም" : "No tips found",
        style: const TextStyle(color: Colors.white24),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      color: const Color(0xFF1B3022),
      shape: const CircularNotchedRectangle(),
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
            icon: const Icon(Icons.tips_and_updates, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.grey),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}
