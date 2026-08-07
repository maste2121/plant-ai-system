import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/dio_client.dart';

class AuthService {
  final Dio _dio = DioClient().dio;

  // ✅ FIXED LOGIN: Adjusted path and keys
  Future<bool> login(String fullPhone) async {
    try {
      final response = await _dio.post(
        '/users/login', // Matches your userRoutes.js
        data: {
          'phone': fullPhone,
          'password': 'password123', // Use the default password for now
        },
      );

      if (response.statusCode == 200) {
        return await _handleAuthSuccess(response.data);
      }
      return false;
    } on DioException catch (e) {
      _logDioError(e, "Login");
      return false;
    }
  }

  // ✅ FIXED REGISTRATION: Corrected "name" to "full_name" to match Sequelize
  Future<bool> register(String name, String phone, String location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String langCode = prefs.getString('language_code') ?? 'am';

      final response = await _dio.post(
        '/users/register', // Matches your userRoutes.js
        data: {
          'full_name': name, // ✅ FIXED: was 'name'
          'phone': phone, // ✅ Matches model
          'location': location, // ✅ Matches model
          'language_pref':
              langCode == 'am' ? 'Amharic' : 'English', // ✅ Matches ENUM
          'password': 'password123', // Default for simplified farmer auth
          'email':
              '$phone@kare.com', // Placeholder email since model requires it
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return await _handleAuthSuccess(response.data);
      }
      return false;
    } on DioException catch (e) {
      _logDioError(e, "Registration");
      return false;
    }
  }

  // 💾 Professional Helper to save session
  Future<bool> _handleAuthSuccess(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    final String token = data['token'];
    final String fullName = data['user']['full_name'] ?? "";
    final String langPref = data['user']['language_pref'] ?? "Amharic";

    // Default professional name logic
    final String displayName =
        fullName.isNotEmpty
            ? fullName
            : (langPref == 'Amharic' ? "አርሶ አደር" : "Farmer");

    await prefs.setString('auth_token', token);
    await prefs.setString('user_name', displayName);

    debugPrint("Session Saved: $displayName");
    return true;
  }

  void _logDioError(DioException e, String type) {
    debugPrint("🔴 $type Error: ${e.response?.data['message'] ?? e.message}");
    debugPrint("Status Code: ${e.response?.statusCode}");
    debugPrint("Backend Data: ${e.response?.data}");
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    debugPrint("User logged out.");
  }
}
