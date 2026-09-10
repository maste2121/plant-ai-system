import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/countries.dart';
import 'auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tts = FlutterTts();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;
  String _selectedLang = 'am';
  Country _selectedCountry = countries[0]; // Default to Ethiopia

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 🌍 Load settings and trigger Voice Greeting
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLang = prefs.getString('language_code') ?? 'am';
    });
    await _tts.setLanguage(_selectedLang == 'am' ? "am-ET" : "en-US");
    await _tts.setSpeechRate(0.4);
    _speak(
      isAm
          ? "አዲስ መለያ ይፍጠሩ። እባክዎን መረጃዎን ያስገቡ"
          : "Create a new account. Please enter your details.",
    );
  }

  bool get isAm => _selectedLang == 'am';

  void _speak(String text) async {
    await _tts.speak(text);
  }

  // 🛡️ Handles Visual, Physical (Vibration), and Auditory Feedback
  void _handleError(String am, String en) {
    HapticFeedback.heavyImpact(); // Vibrate phone for accessibility
    _speak(isAm ? am : en);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAm ? am : en,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // 🚀 MAIN REGISTRATION LOGIC
  Future<void> _handleRegister() async {
    // 1. Check basic form validation
    if (!_formKey.currentState!.validate()) {
      _handleError(
        "እባክዎን መረጃዎን በትክክል ያስገቡ",
        "Please fill in all fields correctly.",
      );
      return;
    }

    // 2. Check phone length based on selected country
    if (_phoneController.text.length < _selectedCountry.minLength) {
      _handleError(
        "ያስገቡት ስልክ ቁጥር አጭር ነው",
        "The phone number is too short for ${_selectedCountry.name}.",
      );
      return;
    }

    setState(() => _isLoading = true);

    // 3. Prepare Phone with Dial Code (e.g. +251911...)
    String fullPhone = _selectedCountry.dialCode + _phoneController.text.trim();

    // 4. CALL BACKEND: Wait for the Database to confirm the save
    // Passing language code so backend saves 'Amharic' or 'English' ENUM
    bool success = await AuthService().register(
      _nameController.text.trim(),
      fullPhone,
      _locationController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (success) {
        // ✅ SUCCESS: Data is in MySQL
        _speak(
          isAm
              ? "መለያዎ ተፈጥሯል። እንኳን ደህና መጡ"
              : "Account created. Welcome to KARE.",
        );

        // Navigate and clear the navigation stack
        context.go('/home');
      } else {
        // ❌ FAILURE: Backend error (e.g. phone already exists) or Network Timeout
        _handleError(
          "ምዝገባው አልተሳካም። ስልኩ ቀድሞ ተመዝግቧል ወይም ኢንተርኔት የለም",
          "Registration failed. Number might be taken or server is down.",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12), // KARE Deep Dark Green
      body: Stack(
        children: [
          _buildDecor(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isAm ? "አዲስ መለያ ይፍጠሩ" : "Create Account",
                      style: GoogleFonts.notoSans(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isAm
                          ? "የእርሻ ረዳትዎን ለመጠቀም ይመዝገቡ"
                          : "Join KARE to get smart agricultural advice",
                      style: GoogleFonts.notoSans(
                        color: Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- FULL NAME ---
                    _buildLabel(isAm ? "ሙሉ ስም" : "Full Name"),
                    _buildTextField(
                      _nameController,
                      Icons.person_outline,
                      isAm ? "ደረጀ አበበ" : "e.g. John Doe",
                    ),

                    const SizedBox(height: 20),

                    // --- PHONE NUMBER ---
                    _buildLabel(isAm ? "ስልክ ቁጥር" : "Phone Number"),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCountrySelector(),
                        const SizedBox(width: 10),
                        Expanded(child: _buildPhoneField()),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // --- LOCATION ---
                    _buildLabel(isAm ? "ክልል/ከተማ" : "Region/City"),
                    _buildTextField(
                      _locationController,
                      Icons.location_on_outlined,
                      isAm ? "አዲስ አበባ" : "e.g. Addis Ababa",
                    ),

                    const SizedBox(height: 50),

                    // --- SUBMIT BUTTON ---
                    _buildRegisterButton(),

                    const SizedBox(height: 30),

                    // --- FOOTER ---
                    _buildFooter(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENT METHODS ---

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _buildTextField(
    TextEditingController controller,
    IconData icon,
    String hint,
  ) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      validator:
          (v) => v!.isEmpty ? (isAm ? "ይህ ቦታ ባዶ መሆን የለበትም" : "Required") : null,
      decoration: _inputDecoration(icon, hint),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(_selectedCountry.maxLength),
      ],
      decoration: _inputDecoration(null, "911...").copyWith(
        prefixIcon: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 8, 0),
          child: Text(
            _selectedCountry.dialCode,
            style: const TextStyle(
              color: Color(0xFF4CAF50),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    return GestureDetector(
      onTap: _showCountryPicker,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B3022),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Text(_selectedCountry.flag, style: const TextStyle(fontSize: 24)),
            const Icon(Icons.arrow_drop_down, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B3022),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: countries.length,
              itemBuilder:
                  (context, i) => ListTile(
                    leading: Text(
                      countries[i].flag,
                      style: const TextStyle(fontSize: 26),
                    ),
                    title: Text(
                      countries[i].name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCountry = countries[i];
                        _phoneController.clear();
                      });
                      Navigator.pop(context);
                    },
                  ),
            ),
          ),
    );
  }

  InputDecoration _inputDecoration(IconData? icon, String hint) {
    return InputDecoration(
      hintText: hint,
      prefixIcon:
          icon != null
              ? Icon(icon, color: const Color(0xFF4CAF50), size: 22)
              : null,
      hintStyle: const TextStyle(color: Colors.white10),
      filled: true,
      fillColor: const Color(0xFF1B3022),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB38B4D).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB38B4D), // KARE Gold
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : _handleRegister,
        child:
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                  isAm ? "ይመዝገቡ" : "GET STARTED",
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

  Widget _buildFooter() {
    return Center(
      child: InkWell(
        onTap: () => context.pop(),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.notoSans(color: Colors.white38, fontSize: 15),
            children: [
              TextSpan(
                text: isAm ? "ቀድሞ መለያ አለዎት? " : "Already have an account? ",
              ),
              TextSpan(
                text: isAm ? "ይግቡ" : "Sign In",
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecor() => Positioned(
    top: -50,
    right: -50,
    child: CircleAvatar(
      radius: 120,
      backgroundColor: const Color(0xFF4CAF50).withOpacity(0.03),
    ),
  );
}
