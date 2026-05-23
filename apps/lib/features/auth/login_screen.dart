import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _playInstruction();
  }

  Future<void> _playInstruction() async {
    await _tts.speak("እባክዎን ስልክ ቁጥርዎን ያስገቡ። Please enter your phone number.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B12),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const SizedBox(height: 50),
              const Icon(
                Icons.lock_outline,
                color: Color(0xFF4CAF50),
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                "Login",
                style: GoogleFonts.notoSans(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "ወደ መለያዎ ይግቡ",
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),

              const SizedBox(height: 50),

              // Phone Number Input
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF4CAF50)),
                  hintText: "09... (Phone Number)",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1B3022),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => context.go('/home'),
                  child: const Text(
                    "LOGIN / ግባ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Register Link
              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text(
                  "Don't have an account? Register here.\nመለያ የለዎትም? እዚህ ይመዝገቡ።",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB38B4D)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
