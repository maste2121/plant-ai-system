import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _service = WeatherService();
  final FlutterTts _tts = FlutterTts();

  Map<String, dynamic>? _weather;
  bool _isLoading = true;
  String _selectedLang = 'am'; // Defaults to Amharic

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 🔄 Initialize Language and Weather together
  Future<void> _initializeData() async {
    await _loadUserLanguage();
    await _initWeather();
  }

  // 💾 Get language selected by user during onboarding/settings
  Future<void> _loadUserLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLang = prefs.getString('language_code') ?? 'am';
    });
  }

  // 📍 Detect Location & Fetch Data
  Future<void> _initWeather() async {
    try {
      // Automatically detect current GPS coordinates
      final pos = await _service.getCurrentLocation();

      // Fetch weather from API (or service) based on coordinates
      final data = await _service.getWeatherData(pos.latitude, pos.longitude);

      if (mounted) {
        setState(() {
          _weather = data;
          _isLoading = false;
        });
        _speakAdvisory();
      }
    } catch (e) {
      debugPrint("Weather/Location Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔊 Conditional Speaker based on Language Code
  void _speakAdvisory() async {
    if (_weather == null) return;

    bool isAm = _selectedLang == 'am';
    await _tts.setLanguage(isAm ? "am-ET" : "en-US");
    await _tts.setSpeechRate(0.4); // Natural speed for agricultural advice

    String city = _weather!['city'];
    String temp = "${_weather!['temp']}";
    String advisory = isAm ? _weather!['advisoryAm'] : _weather!['advisoryEn'];

    String speechText =
        isAm
            ? "$city ውስጥ አሁን $temp ዲግሪ ነው። $advisory"
            : "In $city, it is currently $temp degrees. $advisory";

    await _tts.speak(speechText);
  }

  @override
  Widget build(BuildContext context) {
    bool isAm = _selectedLang == 'am';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12), // KARE Dark Green
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isAm ? "የአየር ሁኔታ መረጃ" : "Agricultural Weather",
          style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              setState(() => _isLoading = true);
              _initWeather();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF4CAF50)),
                    const SizedBox(height: 20),
                    Text(
                      isAm ? "ቦታዎን በመፈለግ ላይ..." : "Detecting location...",
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              )
              : _weather == null
              ? _buildErrorState(isAm)
              : SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    // 1. MAIN TEMPERATURE CARD (Gradient Hero)
                    _buildMainWeatherCard(),

                    const SizedBox(height: 25),

                    // 2. SMART ADVISORY BOX (SRD 4.8)
                    _buildAdvisoryBox(isAm),

                    const SizedBox(height: 25),

                    // 3. STATS GRID (Humidity & Wind)
                    Row(
                      children: [
                        _buildStatTile(
                          isAm ? "እርጥበት" : "Humidity",
                          "${_weather!['humidity']}%",
                          Icons.water_drop,
                          Colors.blue,
                        ),
                        const SizedBox(width: 15),
                        _buildStatTile(
                          isAm ? "ንፋስ" : "Wind",
                          "${_weather!['wind']} km/h",
                          Icons.air,
                          Colors.teal,
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // 4. RAIN ALERT BANNER
                    _buildAlertBanner(isAm),
                  ],
                ),
              ),
    );
  }

  Widget _buildMainWeatherCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B3022), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 16),
              const SizedBox(width: 5),
              Text(
                _weather!['city'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Icon(Icons.wb_cloudy_rounded, size: 100, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            "${_weather!['temp']}°C",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _weather!['condition'],
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 20,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisoryBox(bool isAm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFB38B4D).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB38B4D), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.psychology_outlined,
            color: Color(0xFFB38B4D),
            size: 45,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAm ? "የባለሙያ ምክር" : "Farmer's Advice",
                  style: const TextStyle(
                    color: Color(0xFFB38B4D),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isAm ? _weather!['advisoryAm'] : _weather!['advisoryEn'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _speakAdvisory,
            icon: const Icon(Icons.volume_up, color: Color(0xFFB38B4D)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1B3022),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner(bool isAm) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.redAccent, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAm ? "ማስጠንቀቂያ" : "Weather Alert",
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _weather!['alert'],
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isAm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 80,
              color: Colors.white24,
            ),
            const SizedBox(height: 20),
            Text(
              isAm ? "የአካባቢ መረጃ ማግኘት አልተቻለም" : "Could not detect location",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _initWeather,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: Text(isAm ? "እንደገና ይሞክሩ" : "Try Again"),
            ),
          ],
        ),
      ),
    );
  }
}
