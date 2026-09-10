import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Fix for Chrome
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../../shared/models/disease_model.dart';

class ResultScreen extends StatefulWidget {
  final File image;
  final DiseaseResult result; // ✅ Receive REAL data from the API call

  const ResultScreen({super.key, required this.image, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _playResultVoice();
  }

  // 🔊 UX: Automatically speak the result in Amharic/English
  Future<void> _playResultVoice() async {
    // Detect preferred language (logic can be expanded to check SharedPreferences)
    await _tts.setLanguage("am-ET");
    await _tts.speak("${widget.result.nameAm} ተገኝቷል።");
  }

  // 🎨 Helper: Change gauge color based on AI confidence
  Color _getConfidenceColor(double value) {
    if (value > 0.8) return Colors.green;
    if (value > 0.5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.result;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12), // KARE Dark Green
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Analysis Result",
          style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. DYNAMIC IMAGE (Handles Chrome and Mobile)
            _buildImageHeader(),

            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. CONFIDENCE GAUGE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "AI Confidence",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "${(res.confidence * 100).toInt()}%",
                        style: TextStyle(
                          color: _getConfidenceColor(res.confidence),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: res.confidence,
                      minHeight: 12,
                      backgroundColor: Colors.white10,
                      color: _getConfidenceColor(res.confidence),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 3. DISEASE NAMES
                  Text(
                    res.nameAm,
                    style: GoogleFonts.notoSansEthiopic(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    res.nameEn,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white54,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 4. ADVISORY CARDS (SRD 4.6 Requirements)
                  _buildAdvisoryCard(
                    "🌿 Organic Treatment / ኦርጋኒክ",
                    res.treatmentOrganic,
                    Colors.green,
                  ),
                  _buildAdvisoryCard(
                    "🧪 Chemical Treatment / ኬሚካል",
                    res.treatmentChemical,
                    Colors.orange,
                  ),
                  _buildAdvisoryCard(
                    "🛡️ Prevention / መከላከያ",
                    res.prevention,
                    Colors.blue,
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
        ],
      ),
      child:
          kIsWeb
              ? Image.network(widget.image.path, fit: BoxFit.cover)
              : Image.file(widget.image, fit: BoxFit.cover),
    );
  }

  Widget _buildAdvisoryCard(String title, String content, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              // Speaker icon for inclusive design (SRD 7)
              GestureDetector(
                onTap: () => _tts.speak(content),
                child: Icon(Icons.volume_up, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
