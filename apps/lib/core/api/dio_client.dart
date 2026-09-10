import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  // Singleton pattern: Only one instance of Dio exists in the app
  static final DioClient _instance = DioClient._internal();
  late final Dio _dio;

  factory DioClient() => _instance;

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        // Production backend on Render
        baseUrl: 'https://plant-ai-system.onrender.com/api',

        // Render may need time to wake up
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),

        responseType: ResponseType.json,

        // Allow 401 status handling gracefully if needed without crash cascades
        validateStatus: (status) {
          return status != null && status < 500;
        },

        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Use QueuedInterceptorsWrapper to prevent async token race conditions on parallel requests
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          // Automatically get the saved token from login
          final prefs = await SharedPreferences.getInstance();
          final String? token =
              prefs.getString('auth_token') ?? prefs.getString('token');

          // If token exists, add it to the Header for Backend
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';

            if (kDebugMode) {
              print(
                "🟢 DIO_CLIENT: Token attached to request -> ${options.path}",
              );
            }
          } else {
            if (kDebugMode) {
              print(
                "🔴 DIO_CLIENT: No token found in SharedPreferences for ${options.path}",
              );
            }
          }

          // Special handling for file uploads
          if (options.data is FormData) {
            options.headers['Content-Type'] = 'multipart/form-data';
          }

          return handler.next(options);
        },

        onError: (DioException e, handler) async {
          // Global error handling: If token expires or is invalid (401)
          if (e.response?.statusCode == 401) {
            if (kDebugMode) {
              print("🚨 Unauthorized/Expired Token - Clearing session...");
            }

            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
            await prefs.remove('token');
            await prefs.remove('user_name');
          }

          // Connection timeout
          if (e.type == DioExceptionType.connectionTimeout) {
            print("🕒 Connection Timeout");
            print("🌐 Backend: ${e.requestOptions.baseUrl}");
            print("🔗 URL: ${e.requestOptions.uri}");
          }

          // Receive timeout
          if (e.type == DioExceptionType.receiveTimeout) {
            print("🕒 Server Response Timeout");
            print("🌐 Backend: ${e.requestOptions.baseUrl}");
            print("🔗 URL: ${e.requestOptions.uri}");
          }

          return handler.next(e);
        },
      ),
    );

    // Advanced Debug Logger
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
  }

  Dio get dio => _dio;
}
