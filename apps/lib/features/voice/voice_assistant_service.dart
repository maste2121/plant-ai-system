import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

class VoiceAssistantService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeechAvailable = false;

  // Initialize both STT and TTS
  Future<void> initVoice() async {
    _isSpeechAvailable = await _speechToText.initialize();
    await _flutterTts.setLanguage("am-ET"); // Set TTS to Amharic
    await _flutterTts.setSpeechRate(0.4); // Slower for better understanding
  }

  // Speak a message in Amharic
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  // Start listening for Amharic commands
  void startListening(BuildContext context, Function(String) onResult) async {
    if (_isSpeechAvailable) {
      await _speechToText.listen(
        onResult: (result) {
          String command = result.recognizedWords.toLowerCase();
          _processCommand(context, command);
          onResult(command);
        },
        localeId: "am_ET", // Set Listening to Amharic (Ethiopia)
      );
    }
  }

  void stopListening() async {
    await _speechToText.stop();
  }

  // --- SRD Section 4.9: Command Processing ---
  void _processCommand(BuildContext context, String command) {
    if (command.contains("መርምር") || command.contains("scan")) {
      speak("ምርመራ እየጀመርኩ ነው።"); // "Starting scan"
      context.go('/home'); // Link to your camera/scan page here
    } else if (command.contains("ታሪክ") || command.contains("history")) {
      speak("የቀድሞ ምርመራዎች ውጤት እዚህ አለ።"); // "Here is your history"
      // context.go('/history');
    } else if (command.contains("ጤና") || command.contains("help")) {
      speak("እንዴት ልረዳዎት እችላለሁ?"); // "How can I help you?"
    }
  }
}
