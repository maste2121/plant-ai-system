import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceHelper {
  // 1. Singleton Instance
  static final VoiceHelper _instance = VoiceHelper._internal();
  factory VoiceHelper() => _instance;
  VoiceHelper._internal();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _isSttAvailable = false;

  // 2. Initialize the Voice Engine
  Future<void> init() async {
    _isSttAvailable = await _stt.initialize();

    // Default TTS Settings for clarity (Natural for Farmers)
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.4);
  }

  // 3. Dynamic Language Detection Logic (SRD Section 6.3)
  Future<String> _getLanguageTag() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString('language_code') ?? 'am';
    return code == 'am' ? "am-ET" : "en-US";
  }

  // 4. Professional SPEAK Method (Localized)
  Future<void> speak(String amharicText, String englishText) async {
    String lang = await _getLanguageTag();
    await _tts.setLanguage(lang);

    String textToSay = (lang == "am-ET") ? amharicText : englishText;
    await _tts.speak(textToSay);
  }

  // 5. Professional LISTEN Method (Localized Commands)
  Future<void> listen({
    required Function(String) onResult,
    required VoidCallback onListeningStarted,
    required VoidCallback onListeningStopped,
  }) async {
    String lang = await _getLanguageTag();

    if (_isSttAvailable) {
      onListeningStarted();
      _stt.listen(
        localeId: lang == "am-ET" ? "am_ET" : "en_US",
        onResult: (val) {
          onResult(val.recognizedWords);
          if (val.finalResult) {
            onListeningStopped();
          }
        },
      );
    } else {
      debugPrint("STT not available on this device");
    }
  }

  // 6. Stop all speech and listening
  Future<void> stopAll() async {
    await _tts.stop();
    await _stt.stop();
  }
}
