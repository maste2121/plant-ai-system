import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptic Feedback
import 'package:avatar_glow/avatar_glow.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmer_mobile_app/shared/widgets/voice_assistant_overlay.dart'; // Import the overlay we created
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceMicButton extends StatefulWidget {
  const VoiceMicButton({super.key});

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton> {
  final FlutterTts _tts = FlutterTts();
  bool _isServiceReady = false;

  @override
  void initState() {
    super.initState();
    _prepareService();
  }

  Future<void> _prepareService() async {
    // Pre-warm the TTS engine for zero-lag response
    await _tts.setSpeechRate(0.4);
    setState(() => _isServiceReady = true);
  }

  // 🔊 Professional Trigger: Open the Full Conversation Modal
  void _onMicPressed() async {
    // 1. Give physical vibration feedback (Premium feel)
    HapticFeedback.mediumImpact();

    // 2. Detect current language
    final prefs = await SharedPreferences.getInstance();
    String lang = prefs.getString('language_code') ?? 'am';

    if (!mounted) return;

    // 3. Open the Intelligent Assistant Overlay
    // This allows the "Ask and Answer" flow you requested
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => VoiceAssistantOverlay(lang: lang),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isServiceReady) {
      return const SizedBox(
        width: 56,
        height: 56,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
      );
    }

    return Hero(
      tag: 'mic_btn',
      child: AvatarGlow(
        animate:
            true, // Always show a subtle pulse so farmers know it's "Alive"
        glowColor: Colors.blue,
        duration: const Duration(milliseconds: 3000),
        repeat: true,
        glowRadiusFactor: 0.5,
        child: Material(
          elevation: 12,
          shape: const CircleBorder(),
          color: Colors.transparent,
          child: Container(
            height: 70, // Slightly larger for easier farmer access
            width: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _onMicPressed,
              icon: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 35,
              ),
              tooltip: "Voice Assistant / የድምፅ እርዳታ",
            ),
          ),
        ),
      ),
    );
  }
}
