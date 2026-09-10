import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter/foundation.dart';

class DioClient {
  // 1. Singleton pattern: Only one instance of Dio exists in the app
  static final DioClient _instance = DioClient._internal();
  late final Dio _dio;

  factory DioClient() => _instance;

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        // 2. Updated with your REAL IP for mobile testing (Member 2/Backend IP)
        baseUrl: 'http://192.168.215.100:5000/api',
        connectTimeout: const Duration(
          seconds: 20,
        ), // Increased for AI processing
        receiveTimeout: const Duration(seconds: 20),
        responseType: ResponseType.json,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 3. Add Interceptors (The "Security Guard" of your requests)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Automatically get the saved token from login
          final prefs = await SharedPreferences.getInstance();
          final String? token = prefs.getString('auth_token');

          // If token exists, add it to the Header for Backend
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            if (kDebugMode) print("🟢 DIO_CLIENT: Token attached to request");
          } else {
            if (kDebugMode)
              print("🔴 DIO_CLIENT: No token found in SharedPreferences");
          }

          // Special handling for file uploads (Multipart)
          if (options.data is FormData) {
            options.headers['Content-Type'] = 'multipart/form-data';
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Global error handling: If token expires or is invalid (401)
          if (e.response?.statusCode == 401) {
            print("🚨 Unauthorized/Expired Token - Clearing session...");

            // Clear the invalid token from storage
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
            await prefs.remove('user_name');

            // Note: You can trigger a redirect to login here if using a GlobalKey for navigation
          }

          if (e.type == DioExceptionType.connectionTimeout) {
            print(
              "🕒 Connection Timeout - Check if Backend is running at 192.168.215.100",
            );
          }

          return handler.next(e);
        },
      ),
    );

    // 4. Advanced Debug Logger
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader:
            true, // Set to true to see if "Bearer" is correctly formatted
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
  }

  Dio get dio => _dio;
}
