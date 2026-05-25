import 'package:geolocator/geolocator.dart';

class WeatherService {
  // 📍 Automatically Detect Location (SRD 4.8)
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        return Future.error('Denied');
    }
    return await Geolocator.getCurrentPosition();
  }

  // Mock Weather Data (Member 2 will plug in OpenWeather API here)
  Future<Map<String, dynamic>> getWeatherData(double lat, double lon) async {
    await Future.delayed(const Duration(seconds: 2));
    return {
      "temp": 24,
      "city": "Addis Ababa",
      "condition": "Cloudy",
      "humidity": 65,
      "wind": 12,
      "advisoryAm": "ዛሬ ተክሎችን ለመትከል ጥሩ ቀን ነው።",
      "advisoryEn": "Today is a great day for planting crops.",
      "alert": "Heavy Rain expected at 4 PM",
    };
  }
}
