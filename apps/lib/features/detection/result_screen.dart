import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

class ResultScreen extends StatefulWidget {
  /// Optional local file (from a fresh scan). Empty file for history loads.
  final File? image;

  /// The raw scan/result map from the API. Contains:
  /// - Disease  (nested, when backend matched the disease)
  /// - raw_ai_result (JSON string as fallback)
  /// - image_url, confidence_level, status
  final Map<String, dynamic> data;

  const ResultScreen({super.key, this.image, required this.data});

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

  // ---------- DATA EXTRACTION ----------

  /// Merge nested Disease + flat fields + parsed raw_ai_result into one map.
  Map<String, dynamic> get _resolved {
    final merged = <String, dynamic>{};

    // 1. Start with flat fields on the scan
    merged.addAll(widget.data);

    // 2. Overlay raw_ai_result JSON if it's a string
    final raw = widget.data['raw_ai_result'];
    if (raw is String && raw.trim().startsWith('{')) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map) {
          for (final e in parsed.entries) {
            merged.putIfAbsent(e.key.toString(), () => e.value);
          }
        }
      } catch (_) {}
    }

    // 3. Overlay nested Disease object (highest priority — full DB data)
    final disease = widget.data['Disease'];
    if (disease is Map) {
      for (final e in disease.entries) {
        merged[e.key.toString()] = e.value;
      }
    }

    return merged;
  }

  String _pick(List<String> keys, {String fallback = ''}) {
    final d = _resolved;
    for (final k in keys) {
      final v = d[k];
      if (v != null &&
          v.toString().trim().isNotEmpty &&
          v.toString() != 'null') {
        return v.toString();
      }
    }
    return fallback;
  }

  double get _confidence {
    final raw = _resolved['confidence_level'] ?? _resolved['confidence'] ?? 0;
    final n = double.tryParse(raw.toString()) ?? 0;
    return n > 1 ? n / 100 : n; // normalize to 0–1
  }

  bool get _isHealthy =>
      _pick(['status']).toLowerCase() == 'healthy' ||
      _pick([
        'disease_en',
        'result',
        'disease_name',
      ]).toLowerCase().contains('healthy');

  // ---------- VOICE ----------
  Future<void> _playResultVoice() async {
    try {
      await _tts.setLanguage('am-ET');
      final am = _pick(['display_name_am', 'disease_am']);
      if (am.isNotEmpty) await _tts.speak('$am ተገኝቷል።');
    } catch (_) {
      /* TTS unavailable on web */
    }
  }

  Color _getConfidenceColor(double value) {
    if (value > 0.8) return Colors.green;
    if (value > 0.5) return Colors.orange;
    return Colors.red;
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    final nameEn = _pick([
      'display_name_en',
      'disease_name',
      'disease_en',
      'result',
    ], fallback: 'Unknown');
    final nameAm = _pick([
      'display_name_am',
      'disease_am',
      'disease_name_am',
    ], fallback: nameEn);
    final crop = _pick(['crop_name', 'Crop']);

    final organicEn = _pick(['treatment_organic_en', 'treatment_organic']);
    final organicAm = _pick(['treatment_organic_am']);
    final chemicalEn = _pick(['treatment_chemical_en', 'treatment_chemical']);
    final chemicalAm = _pick(['treatment_chemical_am']);
    final preventionEn = _pick([
      'prevention_tips_en',
      'prevention_tips',
      'prevention',
    ]);
    final preventionAm = _pick(['prevention_tips_am']);

    final confidence = _confidence;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Analysis Result',
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
            _buildImageHeader(),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Confidence gauge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'AI Confidence',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '${(confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _getConfidenceColor(confidence),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: confidence,
                      minHeight: 12,
                      backgroundColor: Colors.white10,
                      color: _getConfidenceColor(confidence),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Disease names
                  Text(
                    nameAm,
                    style: GoogleFonts.notoSansEthiopic(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    nameEn,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white54,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (crop.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.eco,
                          color: Colors.greenAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          crop,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 30),

                  // Advisory cards — only show if content exists
                  if (organicEn.isNotEmpty || organicAm.isNotEmpty)
                    _buildAdvisoryCard(
                      '🌿 Organic Treatment / ኦርጋኒክ',
                      organicEn,
                      organicAm,
                      Colors.green,
                    ),
                  if (chemicalEn.isNotEmpty || chemicalAm.isNotEmpty)
                    _buildAdvisoryCard(
                      '🧪 Chemical Treatment / ኬሚካል',
                      chemicalEn,
                      chemicalAm,
                      Colors.orange,
                    ),
                  if (preventionEn.isNotEmpty || preventionAm.isNotEmpty)
                    _buildAdvisoryCard(
                      '🛡️ Prevention / መከላከያ',
                      preventionEn,
                      preventionAm,
                      Colors.blue,
                    ),

                  // Fallback when nothing found
                  if (organicEn.isEmpty &&
                      chemicalEn.isEmpty &&
                      preventionEn.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.white38,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Detailed treatment information is not yet available for this disease.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSans(color: Colors.white54),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ለዚህ በሽታ ዝርዝር የህክምና መረጃ አልተገኘም።',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSansEthiopic(
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
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

  // ---------- IMAGE HEADER ----------
  Widget _buildImageHeader() {
    Widget child;

    // 1. Network URL (history loaded from backend with Cloudinary)
    final url = widget.data['image_url']?.toString();
    if (url != null && url.startsWith('http')) {
      child = Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder:
            (c, w, p) =>
                p == null
                    ? w
                    : const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, __, ___) => _imageFallback(),
      );
    }
    // 2. Local file from a fresh scan
    else if (widget.image != null &&
        widget.image!.path.isNotEmpty &&
        (kIsWeb || widget.image!.existsSync())) {
      child =
          kIsWeb
              ? Image.network(
                widget.image!.path,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imageFallback(),
              )
              : Image.file(
                widget.image!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imageFallback(),
              );
    }
    // 3. Placeholder
    else {
      child = _imageFallback();
    }

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
        ],
      ),
      child: child,
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFF1B3022),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            size: 60,
            color: Colors.white24,
          ),
          const SizedBox(height: 8),
          Text(
            'No image available',
            style: GoogleFonts.notoSans(color: Colors.white38, fontSize: 12),
          ),
          Text(
            'ምስል አልተገኘም',
            style: GoogleFonts.notoSansEthiopic(
              color: Colors.white24,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- ADVISORY CARD ----------
  Widget _buildAdvisoryCard(
    String title,
    String contentEn,
    String contentAm,
    Color color,
  ) {
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
              GestureDetector(
                onTap:
                    () => _tts.speak(
                      contentEn.isNotEmpty ? contentEn : contentAm,
                    ),
                child: Icon(Icons.volume_up, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (contentEn.isNotEmpty)
            Text(
              contentEn,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          if (contentAm.isNotEmpty) ...[
            if (contentEn.isNotEmpty) const SizedBox(height: 10),
            Text(
              contentAm,
              style: GoogleFonts.notoSansEthiopic(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
