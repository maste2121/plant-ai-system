import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // This is a placeholder for Member 2's Backend API
  Future<bool> login(String phone) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network

    // Save fake token for now so Splash Screen works
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', 'fake_token_123');

    return true;
  }
}
