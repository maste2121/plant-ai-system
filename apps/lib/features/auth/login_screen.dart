import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/countries.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _tts = FlutterTts();

  bool _isLoading = false;
  String _selectedLang = 'am';
  Country _selectedCountry = countries[0];
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLang = prefs.getString('language_code') ?? 'am';
    });
    await _tts.setLanguage(_selectedLang == 'am' ? "am-ET" : "en-US");
    await _tts.setSpeechRate(0.4);
    _speak(isAm ? "እባክዎን ስልክ ቁጥርዎን ያስገቡ" : "Please enter your phone number.");
  }

  bool get isAm => _selectedLang == 'am';

  // 🔊 Audio Helper
  void _speak(String text) async {
    await _tts.speak(text);
  }

  // ✅ Professional Audio-Visual Validation
  bool _validate() {
    final val = _phoneController.text.trim();

    if (val.isEmpty) {
      _handleValidationError(
        "እባክዎን ስልክ ቁጥርዎን ያስገቡ",
        "Please enter your phone number",
      );
      return false;
    }

    if (val.length < _selectedCountry.minLength ||
        val.length > _selectedCountry.maxLength) {
      String errorAm =
          "ቁጥሩ ከ ${_selectedCountry.minLength} እስከ ${_selectedCountry.maxLength} አሃዝ መሆን አለበት";
      String errorEn =
          "Number must be between ${_selectedCountry.minLength} and ${_selectedCountry.maxLength} digits";

      _handleValidationError(errorAm, errorEn);
      return false;
    }

    setState(() => _errorText = null);
    return true;
  }

  // 🛡️ Handles Visual, Physical, and Auditory Feedback
  void _handleValidationError(String am, String en) {
    HapticFeedback.heavyImpact(); // Physical vibration for accessibility
    setState(() => _errorText = isAm ? am : en);
    _speak(isAm ? am : en);
  }

  void _handleLogin() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);
    String fullPhone = _selectedCountry.dialCode + _phoneController.text.trim();

    try {
      bool success = await AuthService().login(fullPhone);
      if (success && mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (e == "USER_NOT_FOUND") {
        _suggestRegistration();
      } else {
        _handleValidationError(
          "የስልክ ቁጥር ወይም የይለፍ ቃል ተሳስቷል",
          "Invalid credentials",
        );
      }
    }
  }

  // 💎 Professional Suggestion Logic
  void _suggestRegistration() {
    HapticFeedback.vibrate();

    // 🔊 Voice Assistant Suggestion
    _speak(
      isAm ? "መለያዎ አልተገኘም። እባክዎን ይመዝገቡ" : "Account not found. Please register.",
    );

    // 📺 Visual SnackBar with Action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFB38B4D), // KARE Gold
        duration: const Duration(seconds: 5),
        content: Text(
          isAm ? "መለያ አልተገኘም፤ ይመዝገቡ?" : "Account not found. Register now?",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        action: SnackBarAction(
          label: isAm ? "ይመዝገቡ" : "REGISTER",
          textColor: Colors.white,
          onPressed: () => context.push('/register'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12),
      body: Stack(
        children: [
          _buildDecor(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  const Icon(
                    Icons.eco_rounded,
                    color: Color(0xFF4CAF50),
                    size: 56,
                  ),
                  const SizedBox(height: 25),
                  Text(
                    isAm ? "እንኳን ደህና መጡ" : "Welcome Back",
                    style: GoogleFonts.notoSans(
                      fontSize: 34,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    isAm ? "ወደ መለያዎ ይግቡ" : "Sign in to continue",
                    style: GoogleFonts.notoSans(
                      color: Colors.white38,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 60),
                  _buildLabel(isAm ? "የስልክ ቁጥር" : "Phone Number"),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCountrySelector(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(
                              _selectedCountry.maxLength,
                            ),
                          ],
                          onChanged: (v) {
                            if (_errorText != null)
                              setState(() => _errorText = null);
                          },
                          decoration: _inputStyle(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),
                  _buildLoginBtn(),
                  const SizedBox(height: 40),
                  _buildRegisterFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildCountrySelector() {
    return GestureDetector(
      onTap: () => _showPicker(),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B3022),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Text(_selectedCountry.flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white38,
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B3022),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder:
          (context) => ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 20),
            itemCount: countries.length,
            itemBuilder:
                (context, i) => ListTile(
                  leading: Text(
                    countries[i].flag,
                    style: const TextStyle(fontSize: 26),
                  ),
                  title: Text(
                    countries[i].name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Text(
                    countries[i].dialCode,
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedCountry = countries[i];
                      _phoneController.clear();
                      _errorText = null;
                    });
                    _speak(countries[i].name);
                    Navigator.pop(context);
                  },
                ),
          ),
    );
  }

  InputDecoration _inputStyle() {
    return InputDecoration(
      hintText: "9123...",
      errorText: _errorText,
      errorMaxLines: 2,
      errorStyle: const TextStyle(
        color: Colors.redAccent,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.fromLTRB(16, 17, 10, 0),
        child: Text(
          _selectedCountry.dialCode,
          style: const TextStyle(
            color: Color(0xFF4CAF50),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      filled: true,
      fillColor: const Color(0xFF1B3022),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
      ),
      // Visual Feedback: Red border on error
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      counterText: "", // Hidden to keep it professional
    );
  }

  Widget _buildLoginBtn() {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : _handleLogin,
        child:
            _isLoading
                ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  isAm ? "ይግቡ" : "SIGN IN",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
      ),
    );
  }

  // 💎 PROFESSIONAL FOOTER DESIGN
  Widget _buildRegisterFooter() {
    return Center(
      child: InkWell(
        onTap: () => context.push('/register'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.notoSans(color: Colors.white38, fontSize: 15),
              children: [
                TextSpan(
                  text: isAm ? "መለያ የለዎትም? " : "Don't have an account? ",
                ),
                TextSpan(
                  text: isAm ? "አዲስ ይፍጠሩ" : "Register Now",
                  style: const TextStyle(
                    color: Color(0xFFB38B4D), // KARE Gold
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String t) => Padding(
    padding: const EdgeInsets.only(left: 6, bottom: 12),
    child: Text(
      t,
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _buildDecor() => Positioned(
    top: -60,
    right: -60,
    child: CircleAvatar(
      radius: 120,
      backgroundColor: const Color(0xFF4CAF50).withOpacity(0.04),
    ),
  );
}
