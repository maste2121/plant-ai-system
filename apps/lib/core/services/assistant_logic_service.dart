class AssistantResponse {
  final String text;
  final String? route; // The path the app should navigate to

  AssistantResponse({required this.text, this.route});
}

class AssistantLogicService {
  static AssistantResponse getAnswer(String input, String lang) {
    String query = input.toLowerCase();
    bool isAm = lang == 'am';

    // --- 1. NAVIGATION INTENTS (SRD 4.9) ---

    // Intent: SCAN
    if (_matches(query, [
      "scan",
      "camera",
      "capture",
      "መርምር",
      "ምርመራ",
      "ፎቶ",
      "ያዝ",
    ])) {
      return AssistantResponse(
        text:
            isAm
                ? "ካሜራውን እየከፈትኩ ነው። ተክልዎን ያሳዩኝ።"
                : "Opening camera. Please show me the plant leaf.",
        route: '/detection',
      );
    }

    // Intent: HISTORY
    if (_matches(query, [
      "history",
      "past",
      "records",
      "ታሪክ",
      "ያለፉት",
      "መዝገብ",
    ])) {
      return AssistantResponse(
        text:
            isAm
                ? "ያለፉትን የምርመራ ውጤቶች እያወጣሁ ነው።"
                : "Fetching your past scan records.",
        route: '/history',
      );
    }

    // Intent: WEATHER
    if (_matches(query, [
      "weather",
      "rain",
      "forecast",
      "አየር ሁኔታ",
      "ዝናብ",
      "ንፋስ",
    ])) {
      return AssistantResponse(
        text:
            isAm
                ? "ዛሬ ያለውን የአየር ሁኔታ እና ምክር ላሳይዎት።"
                : "Showing today's weather and farming advice.",
        route: '/weather',
      );
    }

    // Intent: PROFILE / SETTINGS
    if (_matches(query, [
      "profile",
      "settings",
      "account",
      "መገለጫ",
      "ቅንብር",
      "እኔ",
    ])) {
      return AssistantResponse(
        text:
            isAm
                ? "የእርስዎን መገለጫ እና መረጃ እዚህ ያገኛሉ።"
                : "Here is your profile and account settings.",
        route: '/profile',
      );
    }

    // --- 2. CROP ADVISORY INTENTS (SRD 4.6 / 4.8) ---

    // Crop: TEFF (ጤፍ)
    if (_matches(query, ["teff", "ጤፍ"])) {
      return AssistantResponse(
        text:
            isAm
                ? "ጤፍ ለመዝራት ምርጥ ጊዜ ከሰኔ እስከ ሐምሌ አጋማሽ ነው። ማዳበሪያ በወቅቱ መጠቀምዎን አይርሱ።"
                : "The best time to sow Teff is between June and mid-July. Ensure timely fertilizer application.",
      );
    }

    // Crop: COFFEE (ቡና)
    if (_matches(query, ["coffee", "ቡና"])) {
      return AssistantResponse(
        text:
            isAm
                ? "ለቡና ተክልዎ የዛፍ ጥላ ማዘጋጀት እና የደረቁ ቅጠሎችን ማስወገድ ለምርቱ ይረዳል።"
                : "Providing shade trees and removing dry leaves helps your coffee productivity.",
      );
    }

    // Crop: MAIZE / CORN (በቆሎ)
    if (_matches(query, ["maize", "corn", "በቆሎ"])) {
      return AssistantResponse(
        text:
            isAm
                ? "በቆሎ በሚተክሉበት ጊዜ በመካከላቸው በቂ ርቀት መኖሩን ያረጋግጡ።"
                : "Ensure proper spacing between plants when growing maize for better yield.",
      );
    }

    // Intent: GREETING / HELP
    if (_matches(query, ["hello", "hi", "help", "ጤና ይስጥልኝ", "እርዳታ", "ሰላም"])) {
      return AssistantResponse(
        text:
            isAm
                ? "ሰላም! እኔ የእርሻ ረዳትዎ ነኝ። ተክል ለመመርመር 'መርምር' ይበሉኝ።"
                : "Hello! I am your farming assistant. Say 'Scan' to check a plant for diseases.",
      );
    }

    // --- 3. FALLBACK ---
    return AssistantResponse(
      text:
          isAm
              ? "ይቅርታ አልገባኝም። ስለ ሰብልዎ፣ ስለ አየር ሁኔታ ወይም ስለ ምርመራ መጠየቅ ይችላሉ።"
              : "I'm sorry, I didn't catch that. You can ask about your crops, weather, or scans.",
    );
  }

  // Helper to match multiple keywords (Member 4/Voice QA focus)
  static bool _matches(String input, List<String> keywords) {
    for (var word in keywords) {
      if (input.contains(word)) return true;
    }
    return false;
  }
}
