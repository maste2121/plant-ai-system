import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class DioClient {
  // 1. Singleton pattern: Only one instance of Dio exists in the app
  static final DioClient _instance = DioClient._internal();
  late final Dio _dio;

  factory DioClient() => _instance;

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        // 2. Updated with your REAL IP for mobile testing
        baseUrl: 'http://10.64.82.100:3000/api',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
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

          // If token exists, add it to the Header for Backend (Member 2)
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Global error handling (e.g., if token expires, go to login)
          if (e.response?.statusCode == 401) {
            print("Token expired or unauthorized");
          }
          return handler.next(e);
        },
      ),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
      ),
    );
  }

  Dio get dio => _dio;
}
