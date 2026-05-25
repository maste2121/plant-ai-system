import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:farmer_mobile_app/shared/widgets/voice_mic_button.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  final FlutterTts _tts = FlutterTts();
  String _selectedLang = 'am';
  String _activeCategory = 'All';

  // Mock Data: Professional Agricultural Tips (SRD 3.7 Content Management)
  final List<Map<String, dynamic>> _tips = [
    {
      "category": "Soil",
      "titleEn": "Proper Fertilization",
      "titleAm": "ትክክለኛ ማዳበሪያ አጠቃቀም",
      "descEn": "Apply fertilizer 5cm away from the seed to avoid burning.",
      "descAm": "ዘሩ እንዳይቃጠል ማዳበሪያውን ከዘሩ 5 ሴ.ሜ ርቀት ላይ ያድርጉ።",
      "icon": Icons.landscape_rounded,
      "color": Colors.brown,
    },
    {
      "category": "Maize",
      "titleEn": "Maize Spacing",
      "titleAm": "የበቆሎ እርቀት",
      "descEn": "Maintain 25cm between plants for maximum sunlight.",
      "descAm": "ለበቆሎ ተክል በቂ የፀሐይ ብርሃን እንዲያገኝ 25 ሴ.ሜ እርቀት ይጠብቁ።",
      "icon": Icons.grain_rounded,
      "color": Colors.orange,
    },
    {
      "category": "Coffee",
      "titleEn": "Shade Management",
      "titleAm": "የቡና ጥላ አያያዝ",
      "descEn": "Ensure 40% shade coverage for young coffee plants.",
      "descAm": "ለወጣት የቡና ተክሎች 40% የጥላ ሽፋን መኖሩን ያረጋግጡ።",
      "icon": Icons.eco_rounded,
      "color": Colors.green,
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
    _tts.setLanguage(_selectedLang == 'am' ? "am-ET" : "en-US");
  }

  void _readTip(String am, String en) async {
    await _tts.speak(_selectedLang == 'am' ? am : en);
  }

  @override
  Widget build(BuildContext context) {
    bool isAm = _selectedLang == 'am';

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
          isAm ? "የእርሻ ምክሮች" : "Farming Tips",
          style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Horizontal Category Selector
          _buildCategorySlider(isAm),

          // 2. Tips List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _tips.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final tip = _tips[index];
                return _buildTipCard(tip, isAm);
              },
            ),
          ),
        ],
      ),

      // Professional Navigation UI
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const VoiceMicButton(),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildCategorySlider(bool isAm) {
    final cats =
        isAm ? ['ሁሉም', 'በቆሎ', 'ቡና', 'አፈር'] : ['All', 'Maize', 'Coffee', 'Soil'];
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipCard(Map<String, dynamic> tip, bool isAm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3022),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visual Icon Circle
            CircleAvatar(
              radius: 25,
              backgroundColor: tip['color'].withOpacity(0.2),
              child: Icon(tip['icon'], color: tip['color'], size: 30),
            ),
            const SizedBox(width: 15),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAm ? tip['titleAm'] : tip['titleEn'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isAm ? tip['descAm'] : tip['descEn'],
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Speaker Button (Inclusive UX)
            IconButton(
              icon: const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFFB38B4D),
              ),
              onPressed: () => _readTip(tip['descAm'], tip['descEn']),
            ),
          ],
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
              color: Colors.white,
            ),
            onPressed: () {},
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
