import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/dio_client.dart';

class AuthService {
  // Uses the Singleton instance to ensure Port 3000 and IP are consistent
  final Dio _dio = DioClient().dio;

  // ✅ REAL LOGIN: Connection to Node.js /users/login
  Future<bool> login(String fullPhone) async {
    try {
      final response = await _dio.post(
        '/users/login',
        data: {
          'phone': fullPhone,
          'password': 'password123', // Matches the hashed password in your DB
        },
      );

      if (response.statusCode == 200) {
        return await _handleAuthSuccess(response.data);
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Return a specific string so the UI knows to suggest registration
        return Future.error("USER_NOT_FOUND");
      }
      _logDioError(e, "Login");
      return false;
    }
  }

  // ✅ REAL REGISTRATION: Connection to Node.js /users/register
  Future<bool> register(String name, String phone, String location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String langCode = prefs.getString('language_code') ?? 'am';

      // Mapping keys to match server/models/User.js exactly
      final response = await _dio.post(
        '/users/register',
        data: {
          'full_name': name,
          'phone': phone,
          'location': location,
          'language_pref': langCode == 'am' ? 'Amharic' : 'English',
          'password': 'password123',
          'email':
              '$phone@kare.com', // Placeholder to satisfy unique email constraint
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

  // 💾 Saves User Session & Handles Professional Default Naming
  Future<bool> _handleAuthSuccess(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Extracting from backend response (assuming { token: "", user: {...} })
      final String token = data['token'] ?? "";
      final userData = data['user'] ?? {};
      final String fullName = userData['full_name'] ?? "";
      final String langPref = userData['language_pref'] ?? "Amharic";

      // 🏆 SRD Requirement: Professional naming if name is missing
      final String displayName =
          fullName.isNotEmpty
              ? fullName
              : (langPref == 'Amharic' ? "አርሶ አደር" : "Farmer");

      await prefs.setString('auth_token', token);
      await prefs.setString('user_name', displayName);
      await prefs.setString('user_phone', userData['phone'] ?? "");

      debugPrint("✅ Session Established: $displayName");
      return true;
    } catch (e) {
      debugPrint("❌ Error Parsing Auth Success Data: $e");
      return false;
    }
  }

  // 🔍 Professional Terminal Debugger
  void _logDioError(DioException e, String type) {
    debugPrint("------------------------------------------");
    debugPrint("🔴 $type API ERROR");
    if (e.type == DioExceptionType.connectionTimeout) {
      debugPrint(
        "ERROR: Connection Timeout! Is the server at 10.64.82.100 running?",
      );
    } else if (e.response != null) {
      debugPrint("STATUS: ${e.response?.statusCode}");
      debugPrint(
        "BACKEND MSG: ${e.response?.data['message'] ?? e.response?.data}",
      );
    } else {
      debugPrint("MSG: ${e.message}");
    }
    debugPrint("------------------------------------------");
  }

  // ✅ Secure Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    debugPrint("🚪 User logged out successfully.");
  }
}
