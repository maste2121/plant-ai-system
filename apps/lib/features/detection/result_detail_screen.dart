import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:convert'; // ✅ Added for jsonDecode
import 'package:farmer_mobile_app/shared/widgets/voice_mic_button.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ResultDetailScreen extends StatefulWidget {
  final File? image;
  final Map<dynamic, dynamic> resultData;

  const ResultDetailScreen({super.key, this.image, required this.resultData});

  @override
  State<ResultDetailScreen> createState() => _ResultDetailScreenState();
}

class _ResultDetailScreenState extends State<ResultDetailScreen> {
  final FlutterTts _tts = FlutterTts();
  String _selectedLang = 'am';
  Map<String, dynamic> _decodedRawAi = {}; // ✅ To store parsed AI JSON

  @override
  void initState() {
    super.initState();
    _parseRawAiData(); // ✅ Parse JSON first
    _loadLanguageAndSpeak();
  }

  // ✅ Step 1: Decode the 'raw_ai_result' JSON string from MySQL
  void _parseRawAiData() {
    try {
      if (widget.resultData['raw_ai_result'] != null) {
        final String rawStr = widget.resultData['raw_ai_result'].toString();
        _decodedRawAi = jsonDecode(rawStr);
      }
    } catch (e) {
      debugPrint("Error parsing raw_ai_result: $e");
    }
  }

  Future<void> _loadLanguageAndSpeak() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLang = prefs.getString('language_code') ?? 'am';
    });
    _initVoiceAndSpeak();
  }

  // ✅ Step 2: Localized List Picker (Checks Raw AI first, then DB)
  List<String> _getLocalizedList(String type) {
    bool isAm = _selectedLang == 'am';
    String dbKey = type == 'prevention' ? 'prevention_tips' : 'treatment_$type';

    // 1. Try fetching from the parsed AI JSON (contains detailed tips)
    if (_decodedRawAi.containsKey('treatments')) {
      var treatments = _decodedRawAi['treatments'];
      if (treatments != null && treatments[type] != null) {
        return _cleanLocalizedText(treatments[type].toString(), isAm);
      }
    }

    // 2. Fallback to DB "Disease" include columns
    if (widget.resultData['Disease'] != null) {
      var dbVal = widget.resultData['Disease'][dbKey];
      if (dbVal != null) return _cleanLocalizedText(dbVal.toString(), isAm);
    }

    return [];
  }

  // ✅ Step 3: Helper to separate "Amharic (English)" strings
  List<String> _cleanLocalizedText(String input, bool isAm) {
    if (input.isEmpty || input.toLowerCase() == "null") return [];

    String text = input;
    // If string is in format "Amharic (English)", split it based on language
    if (input.contains('(') && input.contains(')')) {
      final parts = input.split('(');
      text = isAm ? parts[0].trim() : parts[1].replaceAll(')', '').trim();
    }

    // Split into bullet points by dots or newlines
    return text
        .split(RegExp(r'[.\n•]'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  Future<void> _initVoiceAndSpeak() async {
    bool isAm = _selectedLang == 'am';
    await _tts.setLanguage(isAm ? "am-ET" : "en-US");
    await _tts.setSpeechRate(0.4);

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      widget.resultData,
    );
    String disease =
        isAm
            ? (data['disease_am'] ?? data['disease_en'] ?? "ያልታወቀ")
            : (data['disease_en'] ?? "Unknown");

    var confValue = data['confidence'] ?? data['confidence_level'];
    double rawConf = double.tryParse(confValue?.toString() ?? "0") ?? 0.0;
    int confidence = (rawConf > 1.0 ? rawConf : rawConf * 100).toInt();

    String speechText =
        isAm
            ? "$disease ተገኝቷል። እርግጠኛነቱ $confidence ፐርሰንት ነው።"
            : "Detected $disease. Confidence is $confidence percent.";

    await _tts.speak(speechText);
  }

  @override
  Widget build(BuildContext context) {
    bool isAm = _selectedLang == 'am';
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      widget.resultData,
    );
    final bool hasDbInfo =
        data.containsKey('Disease') && data['Disease'] != null;
    final Map<String, dynamic> dbDisease =
        hasDbInfo ? Map<String, dynamic>.from(data['Disease']) : {};

    final String displayDiseaseName =
        isAm
            ? (data['disease_am'] ??
                dbDisease['disease_am'] ??
                data['disease_en'] ??
                "ያልታወቀ")
            : (data['disease_en'] ?? dbDisease['disease_name'] ?? "Unknown");

    final String displayCropName =
        data['Crop'] != null
            ? data['Crop']['crop_name']
            : (isAm ? "ያልታወቀ ተክል" : "Unknown Crop");

    var confValue = data['confidence'] ?? data['confidence_level'];
    double confidence = double.tryParse(confValue?.toString() ?? "0") ?? 0.0;
    if (confidence > 1.0) confidence /= 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed:
              () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          isAm ? "ዝርዝር መረጃ" : "Scan Details",
          style: GoogleFonts.notoSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildImageHeader(isAm),
            _buildDetectionHeader(
              displayDiseaseName,
              displayCropName,
              confidence,
              isAm,
            ),
            const SizedBox(height: 20),

            // 📋 LOCALIZED SYMPTOMS & DESCRIPTION (From DB)
            if (hasDbInfo) ...[
              _buildInfoCard(
                title: isAm ? "ምልክቶች" : "Symptoms",
                content:
                    dbDisease['symptoms'] ?? (isAm ? "መረጃ የለም" : "No data"),
                icon: Icons.assignment_late_outlined,
                color: Colors.blueGrey,
              ),
              _buildInfoCard(
                title: isAm ? "ስለ በሽታው" : "About Disease",
                content:
                    dbDisease['description'] ?? (isAm ? "መረጃ የለም" : "No data"),
                icon: Icons.info_outline,
                color: Colors.indigo,
              ),
            ],

            // 💊 TREATMENT TIPS (Powered by Raw AI Result Parsing)
            _buildTreatmentCard(
              title: isAm ? "የኦርጋኒክ ሕክምና" : "Organic Treatment",
              steps: _getLocalizedList('organic'),
              color: const Color(0xFF2E7D32),
              icon: Icons.eco_outlined,
            ),

            _buildTreatmentCard(
              title: isAm ? "የኬሚካል ሕክምና" : "Chemical Treatment",
              steps: _getLocalizedList('chemical'),
              color: const Color(0xFF8B2635),
              icon: Icons.science_outlined,
            ),

            _buildTreatmentCard(
              title: isAm ? "የመከላከያ ምክሮች" : "Prevention Tips",
              steps: _getLocalizedList('prevention'),
              color: const Color(0xFFB38B4D),
              icon: Icons.shield_outlined,
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const VoiceMicButton(),
      bottomNavigationBar: _buildMiniBottomBar(context, isAm),
    );
  }

  // ✅ Image Header with Broken Path Handling
  Widget _buildImageHeader(bool isAm) {
    bool hasImage = widget.image != null && widget.image!.path.isNotEmpty;
    return Container(
      height: 240,
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child:
            hasImage
                ? Image.file(
                  widget.image!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _brokenUI(isAm),
                )
                : _brokenUI(isAm),
      ),
    );
  }

  Widget _brokenUI(bool isAm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white24,
            size: 60,
          ),
          Text(
            isAm ? "ምስሉ አልተገኘም" : "Image not found",
            style: const TextStyle(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionHeader(
    String disease,
    String crop,
    double conf,
    bool isAm,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3022),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Text(
            crop.toUpperCase(),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
          Text(
            disease,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${isAm ? "እርግጠኛነት" : "Confidence"}: ${(conf * 100).toInt()}%",
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    if (content == "N/A" || content == "መረጃ የለም")
      return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.withOpacity(0.7), size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard({
    required String title,
    required List<String> steps,
    required Color color,
    required IconData icon,
  }) {
    if (steps.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 25),
            ...steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "• ",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBottomBar(BuildContext context, bool isAm) {
    return BottomAppBar(
      color: const Color(0xFF1B3022),
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton.icon(
            onPressed: () => context.push('/history'),
            icon: const Icon(Icons.history_rounded, color: Colors.white70),
            label: Text(
              isAm ? "ታሪክ" : "History",
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const VerticalDivider(
            color: Colors.white10,
            width: 1,
            indent: 15,
            endIndent: 15,
          ),
          TextButton.icon(
            onPressed: _initVoiceAndSpeak,
            icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF4CAF50)),
            label: Text(
              isAm ? "ድምፅ" : "Listen",
              style: const TextStyle(color: Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    );
  }
}
