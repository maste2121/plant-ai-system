import 'package:farmer_mobile_app/core/services/assistant_logic_service.dart';
import 'package:farmer_mobile_app/core/services/ai_assistant_service.dart'; // ✅ Added for Real AI
import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class VoiceAssistantOverlay extends StatefulWidget {
  final String lang;
  const VoiceAssistantOverlay({super.key, required this.lang});

  @override
  State<VoiceAssistantOverlay> createState() => _VoiceAssistantOverlayState();
}

class _VoiceAssistantOverlayState extends State<VoiceAssistantOverlay> {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isThinking = false; // ✅ Added to show AI processing state
  String _userSpeech = "";
  String _aiResponse = "";
  bool _sttInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAssistant();
  }

  // 🔊 Initialize Voice Engines
  Future<void> _initAssistant() async {
    _sttInitialized = await _stt.initialize(
      onError: (val) => debugPrint("STT Error: $val"),
      onStatus: (val) => debugPrint("STT Status: $val"),
    );

    await _tts.setLanguage(widget.lang == 'am' ? "am-ET" : "en-US");
    await _tts.setSpeechRate(0.4);

    if (_sttInitialized) {
      _listen();
    }
  }

  // 👂 Trigger Microphone
  void _listen() async {
    if (!_sttInitialized) return;

    setState(() {
      _isListening = true;
      _isThinking = false;
      _userSpeech = "";
      _aiResponse = "";
    });

    await _stt.listen(
      localeId: widget.lang == 'am' ? "am_ET" : "en_US",
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      onResult: (val) {
        setState(() => _userSpeech = val.recognizedWords);
        if (val.finalResult) {
          _processCommand(val.recognizedWords);
        }
      },
    );
  }

  // 🧠 Automatic Processing & Navigation (Updated for Real AI)
  void _processCommand(String text) async {
    setState(() {
      _isListening = false;
      _isThinking = true; // ✅ Show loading while calling Gemini API
    });

    // 1. Call the Smart service (Tries local keywords first, then Gemini)
    // Assumes you created the SmartAssistantService in the previous step
    final response = await SmartAssistantService.getSmartAnswer(
      text,
      widget.lang,
    );

    if (!mounted) return;

    setState(() {
      _aiResponse = response.text;
      _isThinking = false;
    });

    // 2. AI Speaks the result
    await _tts.speak(response.text);

    // 3. AUTOMATIC NAVIGATION
    if (response.route != null) {
      await Future.delayed(const Duration(milliseconds: 1800));

      if (mounted) {
        Navigator.pop(context);
        context.push(response.route!);
      }
    }
  }

  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isAm = widget.lang == 'am';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B12),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            _isListening
                ? (isAm ? "እየሰማሁ ነው..." : "Listening...")
                : _isThinking
                ? (isAm ? "እያሰብኩ ነው..." : "Thinking...") // ✅ Thinking state
                : (isAm ? "ረዳት" : "AI Assistant"),
            style: const TextStyle(
              color: Color(0xFF4CAF50),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // User's Recognized Text
          Text(
            _userSpeech.isEmpty
                ? (isAm ? "እንዴት ልርዳዎት?" : "Ask me anything...")
                : '"$_userSpeech"',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          // AI Response Text or Loading Indicator
          if (_isThinking)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Colors.blue),
            )
          else if (_aiResponse.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _aiResponse,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blue.shade300,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),

          const SizedBox(height: 40),

          // Main Interactive Button
          AvatarGlow(
            animate: _isListening,
            glowColor: Colors.blue,
            duration: const Duration(milliseconds: 2000),
            child: Material(
              elevation: 8.0,
              shape: const CircleBorder(),
              child: CircleAvatar(
                backgroundColor:
                    _isThinking
                        ? Colors.grey
                        : Colors.blue, // Disable if thinking
                radius: 40,
                child: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 35,
                  ),
                  onPressed: (_isListening || _isThinking) ? null : _listen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
