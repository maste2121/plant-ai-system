import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';

class DetectionService {
  final _dio = DioClient().dio;

  Future<Map<String, dynamic>?> getPrediction(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;

      // ✅ Key 'image' matches Multer upload.single('image')
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      // ✅ Endpoint matches the userRoutes/diseaseRoutes setup
      final response = await _dio.post('/users/predict', data: formData);

      if (response.statusCode == 200) {
        return response.data; // This returns the JSON from Python
      }
      return null;
    } on DioException catch (e) {
      print("🔴 Flutter Error: ${e.response?.data ?? e.message}");
      return null;
    }
  }
}
