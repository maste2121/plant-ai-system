import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Simulate a server login
  Future<bool> login(String phone) async {
    await Future.delayed(
      const Duration(seconds: 2),
    ); // Simulate network latency
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', 'KARE_SECURE_TOKEN_XYZ');
    await prefs.setString('user_phone', phone);
    return true;
  }

  // Register a new farmer
  Future<bool> register(String name, String phone, String location) async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('auth_token', 'KARE_SECURE_TOKEN_XYZ');
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
