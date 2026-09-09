import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterTts _tts = FlutterTts();

  // Settings States
  bool _outbreakAlerts = true;
  bool _weatherAlerts = true;
  bool _autoPlayVoice = true;
  double _speechRate = 0.4; // Default slow for clarity
  String _lang = 'am';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 💾 Load all saved preferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('language_code') ?? 'am';
      _outbreakAlerts = prefs.getBool('outbreak_alerts') ?? true;
      _weatherAlerts = prefs.getBool('weather_alerts') ?? true;
      _autoPlayVoice = prefs.getBool('auto_play_voice') ?? true;
      _speechRate = prefs.getDouble('speech_rate') ?? 0.4;
    });
  }

  // 🌍 Change Language & Save
  Future<void> _changeLang(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    setState(() => _lang = code);
    await _tts.setLanguage(code == 'am' ? "am-ET" : "en-US");
    _speak(code == 'am' ? "ቋንቋ ወደ አማርኛ ተቀይሯል" : "Language changed to English");
  }

  // 🔊 Generic Voice Feedback
  Future<void> _speak(String text) async {
    await _tts.setSpeechRate(_speechRate);
    await _tts.speak(text);
  }

  // 💾 Save Generic Boolean
  Future<void> _toggleSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    bool isAm = _lang == 'am';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isAm ? "ቅንብሮች" : "App Settings",
          style: GoogleFonts.notoSans(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // --- SECTION: LANGUAGE ---
          _buildSectionHeader(isAm ? "ቋንቋ" : "App Language"),
          _buildLanguageSelector(),

          const SizedBox(height: 25),

          // --- SECTION: NOTIFICATIONS (SRD 4.10) ---
          _buildSectionHeader(isAm ? "ማሳወቂያዎች" : "Notification Alerts"),
          _buildCard([
            _buildSwitchTile(
              title: isAm ? "የበሽታ ወረርሽኝ ማንቂያ" : "Disease Outbreaks",
              sub:
                  isAm
                      ? "በአቅራቢያዎ ስላሉ በሽታዎች መረጃ"
                      : "Nearby disease detection alerts",
              val: _outbreakAlerts,
              onChanged: (v) {
                setState(() => _outbreakAlerts = v);
                _toggleSetting('outbreak_alerts', v);
                _speak(
                  v
                      ? (isAm ? "በርቷል" : "Enabled")
                      : (isAm ? "ጠፍቷል" : "Disabled"),
                );
              },
            ),
            const Divider(color: Colors.white10, indent: 15, endIndent: 15),
            _buildSwitchTile(
              title: isAm ? "የአየር ሁኔታ ማስጠንቀቂያ" : "Weather Advisories",
              sub: isAm ? "ለእርሻ የሚሆን የአየር ሁኔታ" : "Farming weather updates",
              val: _weatherAlerts,
              onChanged: (v) {
                setState(() => _weatherAlerts = v);
                _toggleSetting('weather_alerts', v);
                _speak(isAm ? "የአየር ሁኔታ ማሳወቂያ ተቀይሯል" : "Weather alert changed");
              },
            ),
          ]),

          const SizedBox(height: 25),

          // --- SECTION: VOICE ASSISTANT (SRD 6.0) ---
          _buildSectionHeader(isAm ? "የድምፅ ረዳት" : "Voice Assistant"),
          _buildCard([
            _buildSwitchTile(
              title: isAm ? "የድምፅ ንባብ" : "Auto-Read Advisory",
              sub:
                  isAm
                      ? "ውጤቶችን በድምፅ እንዲያነብ"
                      : "Automatically read treatment steps",
              val: _autoPlayVoice,
              onChanged: (v) {
                setState(() => _autoPlayVoice = v);
                _toggleSetting('auto_play_voice', v);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAm ? "የንባብ ፍጥነት" : "Speaking Speed",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Slider(
                    value: _speechRate,
                    min: 0.1,
                    max: 0.8,
                    activeColor: const Color(0xFF4CAF50),
                    inactiveColor: Colors.white10,
                    onChanged: (v) {
                      setState(() => _speechRate = v);
                      _tts.setSpeechRate(v);
                    },
                    onChangeEnd: (v) {
                      _speak(isAm ? "ይህ ፍጥነት እንዴት ነው?" : "How is this speed?");
                      final Future<void> _ = SharedPreferences.getInstance()
                          .then((p) => p.setDouble('speech_rate', v));
                    },
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 25),

          // --- SECTION: DATA & SUPPORT ---
          _buildSectionHeader(isAm ? "መረጃ እና እርዳታ" : "Data & Support"),
          _buildCard([
            _buildActionTile(
              icon: Icons.delete_sweep_outlined,
              title: isAm ? "ታሪክን አጽዳ" : "Clear Scan History",
              color: Colors.redAccent,
              onTap: () => _showDeleteDialog(context, isAm),
            ),
            const Divider(color: Colors.white10, indent: 15, endIndent: 15),
            _buildActionTile(
              icon: Icons.info_outline,
              title: isAm ? "ስለ መተግበሪያው" : "About KARE AI",
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 40),
          Center(
            child: Text(
              "Version 1.0.0 (Beta)",
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- UI COMPONENT HELPERS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF4CAF50),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B3022),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildLanguageSelector() {
    return Row(
      children: [
        _langBtn("አማርኛ", "am"),
        const SizedBox(width: 12),
        _langBtn("English", "en"),
      ],
    );
  }

  Widget _langBtn(String label, String code) {
    bool sel = _lang == code;
    return Expanded(
      child: InkWell(
        onTap: () => _changeLang(code),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFB38B4D) : const Color(0xFF1B3022),
            borderRadius: BorderRadius.circular(15),
            border: sel ? Border.all(color: Colors.white30) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String sub,
    required bool val,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      value: val,
      onChanged: onChanged,
      activeColor: const Color(0xFF4CAF50),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        sub,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.white70,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontSize: 15)),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.white10,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  void _showDeleteDialog(BuildContext context, bool isAm) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1B3022),
            title: Text(
              isAm ? "እርግጠኛ ነዎት?" : "Are you sure?",
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              isAm
                  ? "ሁሉም የምርመራ ታሪክ በቋሚነት ይጠፋል።"
                  : "All scan history will be deleted permanently.",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isAm ? "ተመለስ" : "Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  isAm ? "አጥፋ" : "Delete",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
  }
}
