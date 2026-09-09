import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:farmer_mobile_app/core/services/assistant_logic_service.dart';
import 'package:farmer_mobile_app/core/api/dio_client.dart'; // ✅ Added to talk to Backend
import 'package:flutter/foundation.dart';

class SmartAssistantService {
  // 1. Loaded dynamically from the .env file
  static String get _apiKey => dotenv.env['GCP_API_KEY'] ?? '';

  static Future<AssistantResponse> getSmartAnswer(
    String input,
    String lang,
  ) async {
    bool isAm = lang == 'am';

    // ✅ FIRST: Try your existing local keyword logic (Fast for navigation)
    final localResponse = AssistantLogicService.getAnswer(input, lang);

    // If it's a navigation command (Scan, History, etc.), return immediately
    if (localResponse.route != null) {
      // Optional: You can also save navigation intents to DB if you want
      _saveToDatabase(input, localResponse.text);
      return localResponse;
    }

    // ✅ SECOND: Ask Gemini for general farming questions
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          maxOutputTokens: 100,
          temperature: 0.7,
        ),
      );

      final prompt = """
      You are KARE AI, a professional agricultural assistant for Ethiopian farmers.
      The user is speaking in ${isAm ? 'Amharic' : 'English'}.
      Answer the user's question about farming in a helpful and very short way (max 2 sentences).
      
      User Question: $input
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      String aiText =
          response.text ??
          (isAm
              ? "ይቅርታ፣ አሁን መልስ የለኝም።"
              : "I'm sorry, I don't have an answer right now.");

      // 🚀 THE FIX: Save the conversation to MySQL via Node.js
      _saveToDatabase(input, aiText);

      return AssistantResponse(text: aiText);
    } catch (e) {
      debugPrint("Gemini Error: $e");
      // ✅ THIRD: Fallback if AI/Internet fails
      return localResponse;
    }
  }

  // ✅ NEW: Helper function to save to DB
  static Future<void> _saveToDatabase(String query, String response) async {
    try {
      // This hits your: router.post('/assistant/save', ...)
      await DioClient().dio.post(
        '/users/assistant/save',
        data: {"query": query, "response": response},
      );
      if (kDebugMode) print("✅ Assistant history saved to DB");
    } catch (e) {
      if (kDebugMode) print("❌ Failed to save assistant history: $e");
    }
  }
}
